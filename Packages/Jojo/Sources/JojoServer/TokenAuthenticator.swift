//
// TokenAuthenticator.swift
// Copyright © 2022 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Vapor
import JWT
import Fluent



struct JWTToken: JWTPayload {
  let sub: SubjectClaim
  let exp: ExpirationClaim

  init(subject: String, expiresAt: Date) {
    sub = .init(value: subject)
    exp = .init(value: expiresAt)
  }

  func verify(using signer: JWTSigner) throws {
    
    try exp.verifyNotExpired()
  }
}

protocol TokenAuthenticatable : Model {
  associatedtype User: Model & Authenticatable
  static var userKey: KeyPath<Self, Parent<User>> { get }
  //static var idKey: KeyPath<Self, Field<Self.IDValue> { get }
  static var updatedAtKey: KeyPath<Self, TimestampProperty<Token, DefaultTimestampFormat>> { get }
  var isValid: Bool { get }
}

extension User: Authenticatable {
  
}

extension Token : TokenAuthenticatable {
  
  static var userKey: KeyPath<Token, Parent<User>> {
    return \.$user
  }
  
  static var updatedAtKey: KeyPath<Token, TimestampProperty<Token, DefaultTimestampFormat>> {
    return \.$updatedAt
  }
  
  var isValid: Bool {
    return self.age < 60 * 60 * 24
  }
  
  
  
}

protocol JWTBearerAuthenicator : AsyncMiddleware {
  associatedtype JWTPayloadType : JWTPayload
  associatedtype TokenModel : TokenAuthenticatable
  associatedtype UserKey : StorageKey where UserKey.Value == UserModel
  
  typealias UserModel = TokenModel.User
  
  func userID(fromToken token: JWTPayloadType) throws -> UserModel.IDValue
  func tokenID(fromBearer bearer: BearerAuthorization) throws -> TokenModel.IDValue
}

extension JWTBearerAuthenicator {
  func userID(fromAuthorization bearer: BearerAuthorization, withJWT jwt: Request.JWT) throws -> UserModel.IDValue {
    let token = try jwt.verify(bearer.token, as: JWTPayloadType.self)
    return try userID(fromToken: token)
  }
  
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    
    guard let bearer = request.headers.bearerAuthorization else {
      throw Abort(.unauthorized)
    }

    do {
      let userID = try self.userID(
        fromAuthorization: bearer,
        withJWT: request.jwt
      )
      
      
      guard let user = try await UserModel.find(userID, on: request.db) else {
        throw Abort(.unauthorized)
      }
        
      
          request.storage.set(UserKey.self, to: user)
      return try await next.respond(to: request)
        
    } catch {
      let id = try tokenID(fromBearer: bearer)

      guard let token = try await TokenModel.find(id, on: request.db) else {
        throw Abort(.unauthorized)
      }
      let user = try await token[keyPath: TokenModel.userKey].get(on: request.db)
      guard token.isValid  else {
        throw Abort(.unauthorized)
      }
      request.storage.set(UserKey.self, to: user)
      token[keyPath: TokenModel.updatedAtKey].timestamp = Date()
      try await token.save(on: request.db)
      return try await next.respond(to: request)
    }
  }
}

//
//struct TokenAuthenticator<UserType : Model, JWTTokenType: JWTPayload, TokenType: TokenAuthenticatable>: AsyncMiddleware  where TokenType.User == UserType{
////  internal init(configuration: ApplicationConfiguration) {
////    #if DEBUG
////      skipAppleJWTVerification = configuration.skipAppleJWTVerification
////    #endif
////  }
//
////  #if DEBUG
////    let skipAppleJWTVerification: Bool
////  #endif
//  struct UserKey: StorageKey {
//    typealias Value = UserType
//  }
//
//
//  func userID(fromToken token: JWTTokenType) throws -> UserType.IDValue {
//    //return UUID(token.sub.value)
//    fatalError()
//  }
//
//  func userID(fromAuthorization bearer: BearerAuthorization, withJWT jwt: Request.JWT) throws -> UserType.IDValue {
//    let token = try jwt.verify(bearer.token, as: JWTTokenType.self)
//    return try userID(fromToken: token)
//  }
//
//  func tokenID(fromBearer bearer: BearerAuthorization) throws -> TokenType.IDValue {
//    fatalError()
//  }
//
//  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
//
//    guard let bearer = request.headers.bearerAuthorization else {
//      throw Abort(.unauthorized)
//    }
//
//    do {
//      let userID = try self.userID(
//        fromAuthorization: bearer,
//        withJWT: request.jwt
//      )
//
//
//      guard let user = try await UserType.find(userID, on: request.db) else {
//        throw Abort(.unauthorized)
//      }
//
//
//          request.storage.set(UserKey.self, to: user)
//      return try await next.respond(to: request)
//
//    } catch {
//      let id = try tokenID(fromBearer: bearer)
//
//      guard var token = try await TokenType.find(id, on: request.db) else {
//        throw Abort(.unauthorized)
//      }
//      let user = try await token[keyPath: TokenType.userKey].get(on: request.db)
//      guard token.isValid  else {
//        throw Abort(.unauthorized)
//      }
//      request.storage.set(UserKey.self, to: user)
//      token[keyPath: TokenType.updatedAtKey] = Date()
//      try await token.save(on: request.db)
//      return try await next.respond(to: request)
//    }
//  }
//}


struct TokenAuthenticator : JWTBearerAuthenicator{
  func userID(fromToken token: JWTToken) throws -> UUID {
    guard let userID = UUID(token.sub.value) else {
      throw Abort(.internalServerError)
    }
    
    return userID
  }
  
  func tokenID(fromBearer bearer: Vapor.BearerAuthorization) throws -> UUID {
    guard let tokenID = UUID(bearer.token) else {
      throw Abort(.internalServerError)
    }
    
    return tokenID
  }
  
  
  
  
  typealias JWTPayloadType = JWTToken
  
  typealias TokenModel = Token
  

  struct UserKey: StorageKey {
    typealias Value = User
  }
  
  
//  func userID(fromToken token: JWTTokenType) throws -> UserType.IDValue {
//    //return UUID(token.sub.value)
//    fatalError()
//  }
//
//
//  func tokenID(fromBearer bearer: BearerAuthorization) throws -> TokenType.IDValue {
//    fatalError()
//  }
  
}
extension Request {
  func requireUser<JWTBearerAuthenicatorType : JWTBearerAuthenicator>(fromAuthenticator _:  JWTBearerAuthenicatorType.Type)  throws -> JWTBearerAuthenicatorType.UserModel {
    guard let user = storage.get(JWTBearerAuthenicatorType.UserKey.self) else {
      throw Abort(.internalServerError)
    }

    return user
  }
}
