import Fluent


protocol TokenAuthenticatable : Model {
  associatedtype User: Model
  static var userKey: KeyPath<Self, Parent<User>> { get }
  //static var idKey: KeyPath<Self, Field<Self.IDValue> { get }
  static var updatedAtKey: KeyPath<Self, TimestampProperty<Token, DefaultTimestampFormat>> { get }
  var isValid: Bool { get }
}
