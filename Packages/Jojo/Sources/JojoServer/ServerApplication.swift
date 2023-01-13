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

public struct UserResponse : Codable {
  internal init(accessToken: String, email: String? = nil, firstName: String? = nil, lastName: String? = nil) {
    self.accessToken = accessToken
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
  }
  
  let accessToken : String
  let email : String?
  let firstName : String?
  let lastName : String?
}

extension UserResponse : Content {
  init(accessToken: String, user: User) {
    self.init(accessToken: accessToken, email: user.email, firstName: user.firstName, lastName: user.lastName)
  }
}

public class ServerApplication {
  var env : Environment
  let app : Application
  
  public static func getSimulatorAppDataPath () throws -> String? {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = [
      "simctl",
      "get_app_container",
      "booted",
      "com.BrightDigit.Jojo.watchkitapp",
      "data"
    ]
    process.standardOutput = pipe
    try process.run()
    process.waitUntilExit()
    guard let data = try pipe.fileHandleForReading.readToEnd() else {
      return nil
    }
    
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  // configures your application
  fileprivate static func user(_ req: Request, _ token: AppleIdentityToken, _ userBody: SIWARequestBody) async throws -> User {
    let user = try await User.query(on: req.db)
      .filter(\.$appleUserIdentifier == token.subject.value)
      .first()
    
    if let user = user {
      user.patch(body: userBody)
      try await user.update(on: req.db)
      return user
    } else {
      let user = User(body: userBody)
      try await user.create(on: req.db)
      return user
    }
  }
  
  public static func configure(_ app: Application) throws {
      // uncomment to serve files from /Public folder
      // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.jwt.apple.applicationIdentifier = "com.BrightDigit.Jojo.SignInWithApple"
      // register routes
    app.get("apple") { req async throws -> UserResponse in
      let userBody = try req.content.decode(SIWARequestBody.self)
      
        let jwt = try await req.jwt.apple.verify(userBody.appleIdentityToken)
      let user = try await self.user(req, jwt, userBody)
      
      let token = try user.createAccessToken(req: req)
      try await token.save(on: req.db)
      
      return try UserResponse(accessToken: token.requireID(), user: user)
    }
    
    app.post("sim") { request async throws -> HTTPStatus in
      guard let dataDirectoryPath = try Self.getSimulatorAppDataPath() else {
        throw Abort(.notFound)
      }
      let dataDirectoryURL = URL(fileURLWithPath: dataDirectoryPath)
      
      let tmpDirectoryURL = dataDirectoryURL.appendingPathComponent("tmp", isDirectory: true)
      
      let fileURL = tmpDirectoryURL.appendingPathComponent( "com.BrightDigit.Jojo.SignInWithApple")
      
      let filePath = fileURL.absoluteURL.path
      guard let body = request.body.data  else {
        throw Abort(.noContent)
      }
      
      try FileManager.default.createFile(atPath: filePath, contents: Data(buffer: body))
      
      return .accepted
    }
    app.get("sim") { request async throws -> String in
   
      
      
      
      guard let path = try Self.getSimulatorAppDataPath() else {
        throw Abort(.notFound)
      }
      
      return path
    }
  }
  
  public init () throws {
    self.env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)
    self.app = Application(env)
    
    try Self.configure(app)

  }
  
  public func run () throws {
    defer { app.shutdown() }
    try app.run()
  }
  
}
