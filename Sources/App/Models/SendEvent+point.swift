import Fluent
import Vapor
import Foundation

extension SendEvent {

  static var maxChunk = 1024

  static func point(of username: String, on db: Database) async throws -> Int {
    var pointResult: Result<Int, Error> = .success(0)
    try await query(on: db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .all { result in
        pointResult = pointResult.flatMap { point in
          result.map { event in
            if event.$to.id == username {
              return point + event.point
            } else {
              return point - event.point
            }
          }
        }
      }
    return try pointResult.get()
  }

  static func logPoint(of username: String, title: String, logger: Logger, on db: Database) async throws -> Int {
    var pointResult: Result<Int, Error> = .success(0)
    let start = Date()
    logger.critical("BEGIN-QUERY")
    var count = 0
    try await query(on: db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .all { result in
        count += 1
        if count % 10000 == 0{
          logger.critical(
            "CHUNK-TIME: \(Date().timeIntervalSince(start)),CHUNK-COUNT: 1"
          )
          logMemoryUsage(title: "CHUNK-COUNT: 1,", logger: logger)
        }
        pointResult = pointResult.flatMap { point in
          result.map { event in
            if event.$to.id == username {
              return point + event.point
            } else {
              return point - event.point
            }
          }
        }
      }
    logger.critical("END-QUERY, QUERY-TIME: \(Date().timeIntervalSince(start)),EVENT-COUNT: \(count)")
    return try pointResult.get()
  }
}
