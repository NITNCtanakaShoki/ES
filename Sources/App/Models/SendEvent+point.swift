import Fluent
import Vapor
import Foundation

extension SendEvent {

  static var maxChunk = 1024

  static func point(of username: String, on db: Database) async throws -> Int {
    let maxChunk = maxChunk
    var pointResult: Result<Int, Error> = .success(0)
    try await query(on: db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .chunk(max: maxChunk) { results in
        pointResult = results.reduce(pointResult) { (pointResult, eventResult) in
          pointResult.flatMap { point in
            eventResult.map { event in
              if event.$to.id == username {
                return point + event.point
              } else {
                return point - event.point
              }
            }
          }
        }
      }
    return try pointResult.get()
  }

  static func logPoint(of username: String, title: String, logger: Logger, on db: Database) async throws -> Int {
    var pointResult: Result<Int, Error> = .success(0)
    let start = Date()
    logger.info("BEGIN-QUERY")
    var count = 0
    try await query(on: db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .chunk(max: maxChunk) { results in
        count += results.count
        logger.info(
          "CHUNK-TIME: \(Date().timeIntervalSince(start)),CHUNK-COUNT: \(results.count)"
        )
        logMemoryUsage(title: "CHUNK-COUNT: \(results.count),", logger: logger)
        pointResult = results.reduce(pointResult) { (pointResult, eventResult) in
          pointResult.flatMap { point in
            eventResult.map { event in
              if event.$to.id == username {
                return point + event.point
              } else {
                return point - event.point
              }
            }
          }
        }
      }
    logger.info("END-QUERY, QUERY-TIME: \(Date().timeIntervalSince(start)),EVENT-COUNT: \(count)")
    return try pointResult.get()
  }
}
