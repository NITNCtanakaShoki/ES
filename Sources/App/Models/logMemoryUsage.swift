import Foundation
import Vapor

func logMemoryUsage(title: String, logger: Logger) {
  Task.detached(priority: .background) {
    do {
      let contents = try String(contentsOfFile: "/proc/self/statm", encoding: .utf8)
      let parts = contents.split(separator: " ")
      if let pages = Int64(parts[0]) {
        let pageSize: Int64 = 4096
        logger.info("\(title),MEMORY: \(pages * pageSize)")
      }
    } catch {
      logger.error("\(title),MEMORY-ERR: \(error)")
    }
  }
}
