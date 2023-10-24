import Fluent
import Vapor

extension SendEvent {
  static func point(of username: String, on db: Database) async throws -> Int {
    var pointResult: Result<Int, Error> = .success(0)
    try await query(on: db)
      .group(.or) {
        $0
          .filter(\.$from.$id == username)
          .filter(\.$to.$id == username)
      }
      .sort(\.$createdAt)
      .chunk(max: 1024) { results in
        pointResult = results.reduce(pointResult) { (pointResult, eventResult) in
          pointResult.flatMap { point in
            eventResult.map { event in
              if event.$to.id == username {
                return point + event.point
              } else {
                return point - event.point
              }
            }
          }
        }
      }
    return try pointResult.get()
  }
}
