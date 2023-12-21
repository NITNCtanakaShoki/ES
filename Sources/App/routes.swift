import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get { req async in
    "It works!"
  }

  app.get("hello") { req async -> String in
    "Hello, world!"
  }

  let title = Environment.get("TITLE") ?? "title"

  try app.register(collection: UserController(title: title))
  try app.register(collection: SendController())
  try app.register(collection: ResetController())

  app.post("random", ":count") { req async throws -> HTTPStatus in
    let count = try req.parameters.require("count", as: Int.self)
    let date = Date()
    let chunk = 1000
    for i in 0..<count / chunk {
      let events = (0..<chunk).map { j in
        let from = "user\(j % 2 + 1)"
        let to = "user\(j % 2 + 2)"
        return SendEvent(
          fromUsername: from,
          toUsername: to,
          point: Int.random(in: 1...1_000_000),
          createdAt: date.addingTimeInterval(TimeInterval(i * chunk + j))
        )
      }
      try await events.create(on: req.db)
    }
    return .created
  }
}
