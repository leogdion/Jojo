import Fluent

public struct TokenMigration : AsyncMigration {
  public func prepare(on database: Database) async throws {
    try await database.schema(Token.schema)
      .field(.id, .string, .identifier(auto: false))
      .field("userID", .uuid, .references(User.schema, "id", onDelete: .cascade, onUpdate: .cascade))
      .field("createdAt", .datetime)
      .field("updatedAt", .datetime)
      .create()
  }
  
  public func revert(on database: Database) async throws {
    try await database.schema(Token.schema)
      .delete()
  }
}
