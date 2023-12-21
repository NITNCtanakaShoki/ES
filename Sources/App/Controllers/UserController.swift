import Fluent
import Vapor

struct UserController: RouteCollection {

  var title: String

  func boot(routes: RoutesBuilder) throws {
    let user = routes.grouped("user", ":username")
    user.post(use: create)
    user.delete(use: delete)

    user.get("streamPoint") { req in
      try await SendEvent.streamPoint(of: req.username, on: req.db)
    }

    let chunk = user.grouped(":chunk")

    chunk.get("chunkPoint") { req in
      try await req.logTime {
        try await SendEvent.chunkPoint(
          of: req.username,
          chunk: req.chunk,
          on: req.db,
          logger: req.logger
        )
      }
    }

    chunk.get("pagingOffset") { req in
      try await req.logTime {
        try await SendEvent.pagingByOffsetPoint(
          of: req.username,
          chunk: req.chunk,
          on: req.db
        )
      }
    }

    chunk.get("pagingLast") { req in
      try await req.logTime {
        try await SendEvent.pagingByLastPoint(
          of: req.username,
          chunk: req.chunk,
          on: req.db
        )
      }
    }

    chunk.get("pagingLastAsync") { req in
      try await req.logTime {
        try await SendEvent.pagingByLastAsyncPoint(
          of: req.username,
          chunk: req.chunk,
          on: req.db
        )
      }
    }
  }

  func create(req: Request) async throws -> HTTPStatus {
    guard let username = req.parameters.get("username") else {
      throw Abort(.badRequest)
    }
    let user = User(name: username)
    try await user.create(on: req.db)
    return .created
  }

  func delete(req: Request) async throws -> HTTPStatus {
    guard let username = req.parameters.get("username") else {
      throw Abort(.badRequest)
    }
    guard let user = try await User.find(username, on: req.db) else {
      throw Abort(.notFound)
    }
    try await SendEvent.query(on: req.db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .delete()
    try await user.delete(on: req.db)
    return .ok
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
  
  fileprivate func logTime(cb: () async throws -> Int) async throws ->  MeasureResult {
    let start = Date()
    
    defer {
      let end = Date()
      logger.info("\(end.timeIntervalSince(start))")
    }
    let result = try await cb()
    return .init(time: Date().timeIntervalSince(start), result: result)
  }
}

struct MeasureResult: Content {
  var time: TimeInterval
  var result: Int
}
