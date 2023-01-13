import Fluent
import Vapor
import Foundation

protocol JWTTokenAuthenticatable : Model {
  static var updatedAtKey: KeyPath<Self, TimestampProperty<Token, DefaultTimestampFormat>> { get }
    associatedtype User: Model
    static var userKey: KeyPath<Self, Parent<User>> { get }
}
