import Foundation
import Fluent



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
    self.appleUserIdentifier = appleUserIdentifier
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
    self.id = id
  }
}

import Vapor

// MARK: - Token Creation
extension User {
  func createAccessToken(req: Request) throws -> Token {
    return try Token(
      token: [UInt8].random(count: 32).base64,
      userID: self.requireID()
    )
  }
}
