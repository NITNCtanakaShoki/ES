import Vapor

struct PointController: RouteCollection {
  func boot(routes: Vapor.RoutesBuilder) throws {
    let point = routes.grouped("point")
    point.get("stream", ":username", use: stream)
    point.get("chunk", ":chunk", ":username", use: chunk)
    point.get("paging-offset", ":chunk", ":username", use: pagingOffset)
    point.get("paging-last", ":chunk", ":username", use: pagingLast)
    point.get("paging-last-async", ":chunk", ":username", use: pagingLastAsync)
  }
  
  func stream(req: Request) async throws -> PointJSON {
    try await req.logTime {
      try await SendEvent.streamPoint(
        of: req.username,
        on: req.db
      )
    }
  }
  
  func chunk(req: Request) async throws -> PointJSON {
    try await req.logTime {
      try await SendEvent.chunkPoint(
        of: req.username,
        chunk: req.chunk,
        on: req.db,
        logger: req.logger
      )
    }
  }
  
  
  func pagingOffset(req: Request) async throws -> PointJSON {
    try await req.logTime {
      try await SendEvent.pagingByOffsetPoint(
        of: req.username,
        chunk: req.chunk,
        on: req.db
      )
    }
  }
  
  func pagingLast(req: Request) async throws -> PointJSON {
    try await req.logTime {
      try await SendEvent.pagingByLastPoint(
        of: req.username,
        chunk: req.chunk,
        on: req.db
      )
    }
  }
  
  func pagingLastAsync(req: Request) async throws -> PointJSON {
    try await req.logTime {
      try await SendEvent.pagingByLastAsyncPoint(
        of: req.username,
        chunk: req.chunk,
        on: req.db
      )
    }
  }
}

extension Request {
  fileprivate var username: String {
    get throws {
      try parameters.require("username")
    }
  }

  fileprivate var chunk: Int {
    get throws {
      try parameters.require("chunk", as: Int.self)
    }
  }
  
  fileprivate func logTime(cb: () async throws -> Int) async throws -> PointJSON {
    let start = Date()
    let point = try await cb()
    return .init(point: point, time: Date().timeIntervalSince(start))
  }
}

struct PointJSON: Content {
  var point: Int
  var time: TimeInterval
}

