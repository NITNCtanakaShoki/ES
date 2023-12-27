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

  @Field(key: "date")
  var date: Date

  init() {}

  init(
    id: UUID? = nil,
    fromUsername: User.IDValue,
    toUsername: User.IDValue,
    point: Int,
    createdAt: Date
  ) {
    self.id = id
    self.$from.id = fromUsername
    self.$to.id = toUsername
    self.point = point
  }
}

extension SendEvent: Comparable {
  static func < (lhs: SendEvent, rhs: SendEvent) -> Bool {
    lhs.date < rhs.date
  }

  static func == (lhs: SendEvent, rhs: SendEvent) -> Bool {
    lhs.id == rhs.id
  }
}
