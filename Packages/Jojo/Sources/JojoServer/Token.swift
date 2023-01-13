import Foundation
import Fluent


/// An ephermal authentication token that identifies a registered user.
final class Token: Model {
  init() {}

  static var schema: String = "UserToken"

  @ID(custom: .id, generatedBy: .user)
  var id: String?

  @Parent(key: "userID")
  var user: User

  @Timestamp(key: "updatedAt", on: .update)
  var updatedAt: Date?

  @Timestamp(key: "createdAt", on: .create)
  var createdAt: Date?
  
  /// Creates a new `UserToken`.
  init(token: String? = nil, userID: UUID) {
    self.id = id
    $user.id = userID
  }
}

extension Token {
  var lastAccessedAt : Date {
    get {
      self.updatedAt ?? .distantPast
    }
    set {
      self.updatedAt = newValue
    }
    
  }
  
  var age : TimeInterval {
    return -self.lastAccessedAt.timeIntervalSinceNow
  }
}

extension Token : JWTTokenAuthenticatable {

  
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
