import Fluent
import Vapor
import PostgresKit

struct UserController: RouteCollection {
  
  func boot(routes: RoutesBuilder) throws {
    let users = routes.grouped("user")
    users.delete(use: allDelete)
    let user = users.grouped(":username")
    user.post(use: create)
    user.delete(use: delete)
  }
  
  func create(req: Request) async throws -> HTTPStatus {
    try await User(name: req.username).create(on: req.db)
    return .noContent
  }
  
  func delete(req: Request) async throws -> HTTPStatus {
    let sql = req.db as! SQLDatabase
    _ = try await sql.raw("TRUNCATE users CASCADE").all()
    return .noContent
  }
  
  func allDelete(req: Request) async throws -> HTTPStatus {
    try await req.db.transaction { transaction in
      try await SendEvent.query(on: transaction).delete()
      try await User.query(on: transaction).delete()
    }
    return .noContent
  }
}

extension Request {
  fileprivate var username: String {
    get throws {
      try parameters.require("username")
    }
  }
}
