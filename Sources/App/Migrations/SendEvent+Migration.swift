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
        .field("date", .datetime, .required)
        .create()

      let sql = database as! SQLDatabase
      _ = try await sql.raw(
        "CREATE INDEX send_events_index_1 ON send_events (date, id, from_username, to_username, date, id)"
      )
      .all()
      _ = try await sql.raw(
        "CREATE INDEX send_events_index_2 ON send_events (from_username, to_username, date, id)"
      )
      .all()
    }

    func revert(on database: Database) async throws {
      try await database.schema(Self.schema).delete()
    }
  }
}
