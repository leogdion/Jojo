import Fluent


public struct UserMigration : AsyncMigration {
  public func prepare(on database: Database) async throws {
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
