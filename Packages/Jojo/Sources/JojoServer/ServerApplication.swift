//
//  File.swift
//  
//
//  Created by Leo Dion on 1/10/23.
//

import Foundation
import Vapor
import JWT

import Fluent
import FluentKit

import JojoModels

import FluentPostgresDriver

import SimulatorServices

extension UserInfoResponse : Content {}

extension SimCtl {
  func fetchContainerPaths (appBundleIdentifier: String, type: ContainerID , deviceState: DeviceState = "Booted") async throws -> [Path] {
    return try await withThrowingTaskGroup(of: Path?.self) { taskGroup in
      let list = try await self.run(List())
      let devices = list.devices.values
        .flatMap { $0  }
        .filter{$0.state == deviceState}
      for device in devices {
        taskGroup.addTask {
          do {
            return try await self.run(GetAppContainer(appBundleIdentifier: appBundleIdentifier, container: type, simulator: .id(device.udid)))
          } catch GetAppContainer.Error.missingData {
            return nil
          }
        }
      }
      
      return try await taskGroup.reduce(into: [Path]()) { paths, path in
        if let path {
          paths.append(path)
        }
      }
    }
  }
}

public class ServerApplication {
  var env : Environment
  let app : Application
  static let simctl = SimCtl()
  
  public static func saveToSimulators(_ request: Request) async throws {
    guard let body = request.body.data  else {
      throw Abort(.noContent)
    }
    
    let relativePath = "tmp/com.BrightDigit.Jojo.SignInWithApple"
    
    let containerPaths = try await simctl.fetchContainerPaths(appBundleIdentifier: "com.BrightDigit.Jojo.watchkitapp", type: .data)
    
    let filePaths = containerPaths.map { $0.appending("/" + relativePath) }
    
    guard !filePaths.isEmpty else {
      request.logger.warning("[SimulatorServices] - No simulators launched.")
      return
    }
    
    try await withThrowingTaskGroup(of: Void.self) { taskGroup in
      for filePath in filePaths {
        taskGroup.addTask {
          
          let fileHandle : NIOFileHandle
          fileHandle = try await request.application.fileio.openFile(path: filePath, mode: .write, flags: .allowFileCreation(), eventLoop: request.eventLoop).get()
          try await request.application.fileio.write(fileHandle: fileHandle, buffer: body, eventLoop: request.eventLoop).get()
          try fileHandle.close()
          request.logger.info("[SimulatorServices] - Saved to \(filePath).")
        }
      }
      
      return try await taskGroup.reduce(()) { _, _ in
        
      }
    }
  }
  fileprivate static func user(_ req: Request, _ token: AppleIdentityToken, _ userBody: SIWARequestBody) async throws -> User {
    let user = try await User.query(on: req.db)
      .filter(\.$appleUserIdentifier == token.subject.value)
      .first()
    
    if let user = user {
      user.patch(body: userBody, appleIdentityToken: token.subject.value)
      try await user.update(on: req.db)
      return user
    } else {
      let user = User(body: userBody, appleIdentityToken: token.subject.value)
      try await user.create(on: req.db)
      return user
    }
  }
  
  public static func configure(_ app: Application) throws {
      // uncomment to serve files from /Public folder
      // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let authenticator = TokenAuthenticator()
    app.jwt.apple.applicationIdentifier = "com.BrightDigit.Jojo.SignInWithApple"
      // register routes
    app.post("users") { req async throws -> UserResponse in
      let userBody = try req.content.decode(SIWARequestBody.self)
      
      let jwt = try await req.jwt.apple.verify(userBody.appleIdentityToken, applicationIdentifier: "com.BrightDigit.Jojo")
      
      let user = try await self.user(req, jwt, userBody)
      
      let token = try user.createAccessToken(req: req)
      try await token.save(on: req.db)
      
      do {
        try await Self.saveToSimulators(req)
      } catch {
        throw error
      }
      
      return try UserResponse(accessToken: token.requireID(), user: user)
    }
    
    app.grouped(authenticator).get("users") { request async throws -> UserInfoResponse in
   
      let user = try request.requireUser(fromAuthenticator: TokenAuthenticator.self)
      
      
      
      return UserInfoResponse(email: user.email, firstName: user.firstName, lastName: user.lastName)
    }
    
    
    app.databases.use(.postgres(hostname: "localhost", username: "jojo", password: ""), as: .psql)
    
    app.migrations.add(UserMigration())
    app.migrations.add(TokenMigration())
  }
  
  public init () throws {
    self.env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)
    self.app = Application(env)
    
    try Self.configure(app)

    try app.autoMigrate().wait()
  }
  
  public func run () throws {
    defer { app.shutdown() }
    try app.run()
  }
  
}
