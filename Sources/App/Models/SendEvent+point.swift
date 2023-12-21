import Fluent
import Foundation
import Vapor

extension SendEvent {

  /// ストリームでモデルを受け取って計算する
  static func streamPoint(of username: String, on db: Database) async throws -> Int {
    var aggregationResult = Result<Int, any Error>.success(0)

    try await query(on: db)
      .group(.or) {
        $0.filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .sort(\.$id)
      .all { eventResult in
        aggregationResult = aggregationResult.flatMap { aggregation in
          eventResult.map { event in
            aggregation + (event.$to.id == username ? event.point : -event.point)
          }
        }
      }

    return try aggregationResult.get()
  }

  // 一定数ずつ区切って取得する
  static func chunkPoint(of username: String, chunk: Int, on db: Database, logger: Logger)
    async throws -> Int
  {
    var aggregationResult = Result<Int, any Error>.success(0)

    try await query(on: db)
      .group(.or) {
        $0.filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .sort(\.$id)
      .chunk(max: chunk) { eventResults in
        if eventResults.count > chunk {
          logger.critical("eventResults.count: \(eventResults.count) > chunk: \(chunk)")
        }
        aggregationResult = eventResults.reduce(aggregationResult) { (sumResult, eventResult) in
          sumResult.flatMap { sum in
            eventResult.map { event in
              sum + (event.$to.id == username ? event.point : -event.point)
            }
          }
        }
      }

    return try aggregationResult.get()
  }

  // 一定数ずつ区切って取得する
  struct ChunkResult {
    var point: Int
    var counts: [Int]
  }
  static func logChunkPoint(of username: String, chunk: Int, on db: Database) async throws
    -> ChunkResult
  {
    var aggregationResult = Result<Int, any Error>.success(0)

    var counts = [Int]()

    try await query(on: db)
      .group(.or) {
        $0.filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .sort(\.$id)
      .chunk(max: chunk) { eventResults in
        counts.append(eventResults.count)

        aggregationResult = eventResults.reduce(aggregationResult) { (sumResult, eventResult) in
          sumResult.flatMap { sum in
            eventResult.map { event in
              sum + (event.$to.id == username ? event.point : -event.point)
            }
          }
        }
      }

    return .init(point: try aggregationResult.get(), counts: counts)
  }

  static func pagingByOffsetPoint(of username: String, chunk: Int, on db: Database) async throws
    -> Int
  {
    var offset = 0
    var point = 0

    while true {
      let events = try await query(on: db)
        .group(.or) {
          $0
            .filter(\.$from.$id == username)
            .filter(\.$to.$id == username)
        }
        .sort(\.$createdAt)
        .sort(\.$id)
        .offset(offset)
        .limit(chunk)
        .all()
      if events.isEmpty {
        break
      }
      point = events.reduce(point) { point, event in
        point + (event.$to.id == username ? event.point : -event.point)
      }
      offset += chunk
    }
    return point
  }

  /// 最後の日付からINDEXを有効活用したページング
  static func pagingByLastPoint(of username: String, chunk: Int, on db: Database) async throws
    -> Int
  {
    var from: (Date, UUID)?
    var point = 0

    while true {
      let events = try await fetchPagingEvents(
        of: username, fromDate: from?.0, fromID: from?.1, limit: chunk, on: db)
      if events.isEmpty {
        break
      }
      point = events.reduce(point) { point, event in
        point + (event.$to.id == username ? event.point : -event.point)
      }
      if let last = events.last, let id = last.id {
        from = (last.createdAt, id)
      }
    }
    return point
  }

  /// 並行に取得と処理を進める
  static func pagingByLastAsyncPoint(of username: String, chunk: Int, on db: Database) async throws
    -> Int
  {
    var point = 0
    var events = [SendEvent]()

    while true {
      let fromDate = events.last?.createdAt
      let fromID = events.last?.id
      async let fetching = fetchPagingEvents(
        of: username, fromDate: fromDate, fromID: fromID, limit: chunk, on: db)

      point = events.reduce(point) { point, event in
        point + (event.$to.id == username ? event.point : -event.point)
      }

      events = try await fetching

      if events.isEmpty {
        break
      }
    }
    return point
  }

  private static func fetchPagingEvents(
    of username: String, fromDate: Date?, fromID: UUID?, limit: Int, on db: Database
  ) async throws -> [SendEvent] {
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
    return
      try await query
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .sort(\.$id)
      .limit(limit)
      .all()
  }
}
