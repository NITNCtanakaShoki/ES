import Vapor
import Fluent
import Foundation

struct EventController: RouteCollection {
  func boot(routes: Vapor.RoutesBuilder) throws {
    let event = routes.grouped("event")
    event.post("random", ":count", ":username1", ":username2", use: createEvents)
    
    let eventCount = event.grouped("count")
    eventCount.get(use: allEventCount)
    eventCount.get(":username", use: userEventCount)
  }
  
  func allEventCount(req: Request) async throws -> Int {
    try await SendEvent.query(on: req.db).count()
  }
  
  func userEventCount(req: Request) async throws -> Int {
    let username = try req.parameters.require("username")
    return try await SendEvent.query(on: req.db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .count()
  }
  
  func createEvents(req: Request) async throws -> HTTPStatus {
    var count = try req.parameters.require("count", as: Int.self)
    let username1 = try req.parameters.require("username1")
    let username2 = try req.parameters.require("username2")
    
    let date = Date()
    let chunk = 10_000
    
    var loopCount = 0
    while count > 0 {
      let bulkCount = min(chunk, count)
      let events = (0 ..< bulkCount).map { j in
        let n = loopCount * chunk + j
        let even = n % 2 == 0
        return SendEvent(
          fromUsername: even ? username1 : username2,
          toUsername: even ? username2 : username1,
          point: Int.random(in: 1...10_000_000),
          date: date.addingTimeInterval(TimeInterval(n))
        )
      }
      try await events.create(on: req.db)
      count -= bulkCount
      loopCount += 1
    }
    return .noContent
  }
}
