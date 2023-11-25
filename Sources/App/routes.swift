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
}
