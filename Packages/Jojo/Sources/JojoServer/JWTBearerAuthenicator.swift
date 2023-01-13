import Vapor
import JWT


protocol JWTBearerAuthenicator : AsyncMiddleware {
  associatedtype JWTPayloadType : JWTPayload
  associatedtype TokenModel : TokenAuthenticatable
  associatedtype UserKey : StorageKey where UserKey.Value == UserModel
  
  typealias UserModel = TokenModel.User
  
  func userID(fromToken token: JWTPayloadType) throws -> UserModel.IDValue
  func tokenID(fromBearer bearer: BearerAuthorization) throws -> TokenModel.IDValue
}

import Fluent

extension JWTBearerAuthenicator {
  func userID(fromAuthorization bearer: BearerAuthorization, withJWT jwt: Request.JWT) throws -> UserModel.IDValue {
    let token = try jwt.verify(bearer.token, as: JWTPayloadType.self)
    return try userID(fromToken: token)
  }
  
  fileprivate func userFrom(bearer: BearerAuthorization, jwt: Request.JWT, using db: Database) async throws -> UserModel {
    let userID = try self.userID(
      fromAuthorization: bearer,
      withJWT: jwt
    )
    
    if let user = try await UserModel.find(userID, on: db) {
      return user
    }
      let id = try tokenID(fromBearer: bearer)
      
      guard let token = try await TokenModel.find(id, on: db) else {
        throw Abort(.unauthorized)
      }
      guard token.isValid  else {
        throw Abort(.unauthorized)
      }
      let user = try await token[keyPath: TokenModel.userKey].get(on: db)
      token[keyPath: TokenModel.updatedAtKey].timestamp = Date()
      try await token.save(on: db)
      return user
    
  }
  
  func userFrom(request: Request) async throws -> UserModel {
    
    guard let bearer = request.headers.bearerAuthorization else {
      throw Abort(.unauthorized)
    }
    
    return try await userFrom(bearer: bearer, jwt: request.jwt, using: request.db)
  }
  
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    
    let user = try await userFrom(request: request)
    
    request.storage.set(UserKey.self, to: user)
    return try await next.respond(to: request)
      
  }
}


extension Request {
  func requireUser<JWTBearerAuthenicatorType : JWTBearerAuthenicator>(fromAuthenticator _:  JWTBearerAuthenicatorType.Type)  throws -> JWTBearerAuthenicatorType.UserModel {
    guard let user = storage.get(JWTBearerAuthenicatorType.UserKey.self) else {
      throw Abort(.internalServerError)
    }

    return user
  }
}
