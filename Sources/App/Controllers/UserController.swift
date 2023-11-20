import Fluent
import Vapor

struct UserController: RouteCollection {
  
  var title: String
  
  func boot(routes: RoutesBuilder) throws {
    let user = routes.grouped("user", ":username")
    user.get(use: index)
    user.get("log", use: logIndex)
    user.post(use: create)
    user.delete(use: delete)

  }

  func index(req: Request) async throws -> Int {
    guard let username = req.parameters.get("username") else {
      throw Abort(.badRequest)
    }
    guard let _ = try await User.find(username, on: req.db) else {
      throw Abort(.notFound)
    }
    return try await SendEvent.point(of: username, on: req.db)
  }

  func logIndex(req: Request) async throws -> Int {
    guard let username = req.parameters.get("username") else {
      req.logger.info("\(title): username is nil")
      throw Abort(.badRequest)
    }
    req.logger.info("username is \(username)")
    guard let _ = try await User.find(username, on: req.db) else {
      req.logger.info("\(title): user is nil")
      throw Abort(.notFound)
    }
    req.logger.info("\(title): user is not nil")
    return try await SendEvent.point(of: username, title: title, on: req.db)
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
