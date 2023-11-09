import Foundation
import Vapor

func logMemoryUsage(title: String, logger: Logger) {
  Task.detached(priority: .background) {
    do {
      let contents = try String(contentsOfFile: "/proc/self/statm", encoding: .utf8)
      let parts = contents.split(separator: " ")
      if let pages = parts.first.map(String.init).flatMap(Int.init) {
        let pageSize: Int = 4096
        logger.info("\(title),MEMORY: \(pages * pageSize)")
      }
    } catch {
      logger.error("\(title),MEMORY-ERR: \(error)")
    }
  }
}
