import Fluent
import Foundation
import Vapor

extension SendEvent {

  static var maxChunk = 1024

  static func point(of username: String, on db: Database) async throws -> Int {
    let chunk = maxChunk

    var fromDate: Date?
    var fromID: UUID?

    var point = 0

    while true {
      var query = query(on: db)
      if let fromDate, let fromID {
        query = query.group(.or) {
          $0.filter(\.$createdAt > fromDate)
            .group(.and) {
              $0
                .filter(\.$createdAt == fromDate)
                .filter(\.$id > fromID)
            }
        }
      }
      let events =
        try await query
        .group(.or) {
          $0
            .filter(\.$from.$id == username)
            .filter(\.$to.$id == username)
        }
        .sort(\.$createdAt)
        .sort(\.$id)
        .limit(chunk)
        .all()
      if events.isEmpty {
        break
      }
      point = events.reduce(point) { point, event in
        if event.$to.id == username {
          return point + event.point
        } else {
          return point - event.point
        }
      }
      fromDate = events.last?.createdAt
      fromID = events.last?.id
    }
    return point
  }

  static func logPoint(of username: String, title: String, logger: Logger, on db: Database)
    async throws -> Int
  {
    var point = 0
    let start = Date()
    logger.critical("BEGIN-QUERY \(title)")
    var count = 0

    let chunk = maxChunk

    var fromDate: Date?
    var fromID: UUID?

    while true {
      var query = query(on: db)
      if let fromDate, let fromID {
        query = query.group(.or) {
          $0.filter(\.$createdAt > fromDate)
            .group(.and) {
              $0
                .filter(\.$createdAt == fromDate)
                .filter(\.$id > fromID)
            }
        }
      }
      let events =
        try await query
        .group(.or) {
          $0
            .filter(\.$from.$id == username)
            .filter(\.$to.$id == username)
        }
        .sort(\.$createdAt)
        .sort(\.$id)
        .limit(chunk)
        .all()

      count += events.count
      if count % 10000 < chunk {
        logger.critical(
          "CHUNK-TIME: \(Date().timeIntervalSince(start)),CHUNK-COUNT: \(events.count)"
        )
        logMemoryUsage(title: "CHUNK-COUNT: \(events.count),", logger: logger)
      }

      if events.isEmpty {
        break
      }
      point = events.reduce(point) { point, event in
        if event.$to.id == username {
          return point + event.point
        } else {
          return point - event.point
        }
      }
      fromDate = events.last?.createdAt
      fromID = events.last?.id
    }
    logger.critical(
      "END-QUERY, QUERY-TIME: \(Date().timeIntervalSince(start)),EVENT-COUNT: \(count)")
    return point
  }
}
