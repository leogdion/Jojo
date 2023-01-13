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
  static var idKey: KeyPath<Self, Self.IDValue> { get }
  static var updatedAtKey: WritableKeyPath<Self, Date> { get }
  var isValid: Bool { get }
}

protocol JWTTokenAuthenicator {
  associatedtype UserModel : Model
  associatedtype JWTPayloadType : JWTPayload
  associatedtype TokenModel : TokenAuthenticatable
}

struct TokenAuthenticator<UserType : Model, JWTTokenType: JWTPayload, TokenType: TokenAuthenticatable>: AsyncMiddleware  where TokenType.User == UserType{
//  internal init(configuration: ApplicationConfiguration) {
//    #if DEBUG
//      skipAppleJWTVerification = configuration.skipAppleJWTVerification
//    #endif
//  }

//  #if DEBUG
//    let skipAppleJWTVerification: Bool
//  #endif
  struct UserKey: StorageKey {
    typealias Value = UserType
  }
  
  
  func userID(fromToken token: JWTTokenType) throws -> UserType.IDValue {
    //return UUID(token.sub.value)
    fatalError()
  }

  func userID(fromAuthorization bearer: BearerAuthorization, withJWT jwt: Request.JWT) throws -> UserType.IDValue {
    let token = try jwt.verify(bearer.token, as: JWTTokenType.self)
    return try userID(fromToken: token)
  }
  
  func tokenID(fromBearer bearer: BearerAuthorization) throws -> TokenType.IDValue {
    fatalError()
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
      
      
      guard let user = try await UserType.find(userID, on: request.db) else {
        throw Abort(.unauthorized)
      }
        
      
          request.storage.set(UserKey.self, to: user)
      return try await next.respond(to: request)
        
    } catch {
      let id = try tokenID(fromBearer: bearer)

      guard var token = try await TokenType.find(id, on: request.db) else {
        throw Abort(.unauthorized)
      }
      let user = try await token[keyPath: TokenType.userKey].get(on: request.db)
      guard token.isValid  else {
        throw Abort(.unauthorized)
      }
      request.storage.set(UserKey.self, to: user)
      token[keyPath: TokenType.updatedAtKey] = Date()
      try await token.save(on: request.db)
      return try await next.respond(to: request)
    }
  }
}

extension Request {
  func requireUser<UserType, JWTTokenType, TokenType>(fromAuthenticator _:  TokenAuthenticator<UserType, JWTTokenType, TokenType>.Type)  throws -> UserType{
    guard let user = storage.get(TokenAuthenticator<UserType, JWTTokenType, TokenType>.UserKey.self) else {
      throw Abort(.internalServerError)
    }

    return user
  }
}
