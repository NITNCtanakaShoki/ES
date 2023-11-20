import Fluent
import PostgresKit
import Vapor

struct SendController: RouteCollection {
  
  func boot(routes: RoutesBuilder) throws {
    let point = routes.grouped("send", ":from", ":to")
    point.post(use: send)
  }

  func send(req: Request) async throws -> HTTPStatus {
    guard
      let fromUsername = req.parameters.get("from"),
      let toUsername = req.parameters.get("to")
    else {
      throw Abort(.badRequest)
    }

    let content = try req.content.decode(Point.self)

    let event = SendEvent(
      fromUsername: fromUsername,
      toUsername: toUsername,
      point: content.point
    )
    try await event.create(on: req.db)
    return .ok
  }
}

private struct Point: Content {
  var point: Int
}
