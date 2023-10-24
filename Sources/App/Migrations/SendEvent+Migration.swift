import Fluent
import PostgresKit

extension SendEvent {
  struct Migration: AsyncMigration {

    static let schema = "send_events"

    func prepare(on database: Database) async throws {
      try await database.schema(Self.schema)
        .id()
        .field("from_username", .string, .required, .references("users", "name"))
        .field("to_username", .string, .required, .references("users", "name"))
        .field("point", .int, .required)
        .field("created_at", .datetime, .required)
        .create()

      let sql = database as! SQLDatabase
      _ = try await sql.raw(
        "CREATE INDEX send_events_from_username_index ON send_events (from_username)"
      ).all()
      _ = try await sql.raw(
        "CREATE INDEX send_events_to_username_index ON send_events (to_username)"
      ).all()
      _ = try await sql.raw("CREATE INDEX send_events_created_at_index ON send_events (created_at)")
        .all()
    }

    func revert(on database: Database) async throws {
      try await database.schema(Self.schema).delete()
    }
  }
}
