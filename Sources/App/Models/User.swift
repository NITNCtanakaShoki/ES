import Fluent
import Vapor

final class User: Model, Content {
  static let schema = "users"

  @ID(custom: "name")
  var id: String?

  var name: String? {
    get { id }
    set { id = newValue }
  }

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(name: String) {
    self.name = name
  }
}

extension User: Equatable {
  static func == (lhs: User, rhs: User) -> Bool {
    lhs.name == rhs.name
  }
}
