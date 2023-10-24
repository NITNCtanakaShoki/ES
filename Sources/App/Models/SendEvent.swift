import Fluent
import Vapor

final class SendEvent: Model {

  static let schema = "send_events"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: "from_username")
  var from: User

  @Parent(key: "to_username")
  var to: User

  @Field(key: "point")
  var point: Int

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    fromUsername: User.IDValue,
    toUsername: User.IDValue,
    point: Int
  ) {
    self.id = id
    self.$from.id = fromUsername
    self.$to.id = toUsername
    self.point = point
  }
}

extension SendEvent: Comparable {
  static func < (lhs: SendEvent, rhs: SendEvent) -> Bool {
    guard let left = lhs.createdAt else {
      return true
    }
    guard let right = rhs.createdAt else {
      return false
    }
    return left < right
  }

  static func == (lhs: SendEvent, rhs: SendEvent) -> Bool {
    lhs.id == rhs.id
  }
}
