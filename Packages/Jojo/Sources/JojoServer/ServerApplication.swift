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

extension SIWARequestBody : Content {}

public final class User: Model {
  public init () {
    
  }
  
  enum Key : FieldKey {
    case email
    case firstName
    case lastName
    case appleUserIdentifier
  }
  
  @ID(key: .id)
  public var id: UUID?
  
  
  @Field(key: Key.email.rawValue)
  public var email: String?
  
  @Field(key: Key.firstName.rawValue)
  public var firstName: String?
  
  @Field(key: Key.lastName.rawValue)
  public var lastName: String?
  
  @Field(key: Key.appleUserIdentifier.rawValue)
  public var appleUserIdentifier: String
  
  public typealias IDValue = UUID
  
  public static let schema: String = "User"
  
  public init(appleUserIdentifier : String, email: String? = nil, firstName : String? = nil, lastName : String? = nil, id: UUID? = nil) {
    self.id = id
  }
}

extension User {
  convenience init(body: SIWARequestBody) {
    self.init(appleUserIdentifier: body.appleIdentityToken, firstName: body.firstName, lastName: body.lastName)
  }
  
  func patch(body: SIWARequestBody) {
    self.lastName = body.lastName ?? self.lastName
    self.firstName = body.firstName ?? self.firstName
    self.email = body.email ?? self.email
    self.appleUserIdentifier = body.appleIdentityToken
  }
}

public struct UserMigration : AsyncMigration {
  public func prepare(on database: FluentKit.Database) async throws {
    try await database.schema(User.schema)
      .id()
      .field(User.Key.email.rawValue, .string)
      .field(User.Key.firstName.rawValue, .string)
      .field(User.Key.lastName.rawValue, .string)
      .field(User.Key.appleUserIdentifier.rawValue, .string, .required)
      .unique(on: User.Key.appleUserIdentifier.rawValue)
      .create()
  }
  public func revert(on database: Database) async throws {
    try await database.schema(User.schema)
      .delete()
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
    
    return String(data: data, encoding: .utf8)
  }
  // configures your application
  public static func configure(_ app: Application) throws {
      // uncomment to serve files from /Public folder
      // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.jwt.apple.applicationIdentifier = "com.BrightDigit.Jojo.SignInWithApple"
      // register routes
    app.get("apple") { req async throws -> HTTPStatus in
      let userBody = try req.content.decode(SIWARequestBody.self)
      
        let token = try await req.jwt.apple.verify(userBody.appleIdentityToken)
      let user = try await User.query(on: req.db).filter(\.$appleUserIdentifier == token.subject.value).first()
      
      if let user = user {
        user.patch(body: userBody)
        try await user.update(on: req.db)
      } else {
        let user = User(body: userBody)
        try await user.create(on: req.db)
      }
        return .ok
    }
    
    app.post("sim") { request async throws -> HTTPStatus in
      guard let dataDirectoryPath = try Self.getSimulatorAppDataPath() else {
        throw Abort(.notFound)
      }
      let dataDirectoryURL = URL(fileURLWithPath: dataDirectoryPath)
      let tmpDirectoryURL = dataDirectoryURL.appendingPathComponent("tmp", isDirectory: true)
      let filePath = tmpDirectoryURL.appendingPathComponent( "com.BrightDigit.Jojo.SignInWithApple").path
      
      guard let body = request.body.data  else {
        throw Abort(.noContent)
      }
      
      print(filePath)
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
