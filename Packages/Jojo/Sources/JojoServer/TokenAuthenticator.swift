//
// TokenAuthenticator.swift
// Copyright © 2022 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Vapor
import JWT
import Fluent



  



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
  
  
}
