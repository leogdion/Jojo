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
    case firstName
    case lastName
    case appleUserIdentifier
  }
  
  @ID(key: .id)
  public var id: UUID?
  
  @Field(key: Key.firstName.rawValue)
  public var firstName: String?
  
  @Field(key: Key.lastName.rawValue)
  public var lastName: String?
  
  @Field(key: Key.appleUserIdentifier.rawValue)
  public var appleUserIdentifier: String
  
  public typealias IDValue = UUID
  
  public static let schema: String = "User"
  
  public init(appleUserIdentifier : String, firstName : String? = "", lastName : String? = nil, id: UUID? = nil) {
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
    self.appleUserIdentifier = body.appleIdentityToken
  }
}

public struct UserMigration : AsyncMigration {
  public func prepare(on database: FluentKit.Database) async throws {
    try await database.schema(User.schema)
      .id()
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
    
    app.get("sim") { request async throws -> String in
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
        throw Abort(.notFound)
      }
      
      guard let string = String(data: data, encoding: .utf8) else {
        throw Abort(.notFound)
      }
      
      
      
      return string
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
