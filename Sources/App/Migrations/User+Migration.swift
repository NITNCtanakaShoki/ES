import Fluent

extension User {
  struct Migration: AsyncMigration {

    static let schema = "users"

    func prepare(on database: Database) async throws {
      try await database.schema(Self.schema)
        .field("name", .string, .required, .identifier(auto: false))
        .field("created_at", .datetime, .required)
        .field("updated_at", .datetime, .required)
        .create()
    }

    func revert(on database: Database) async throws {
      try await database.schema(Self.schema).delete()
    }
  }
}
