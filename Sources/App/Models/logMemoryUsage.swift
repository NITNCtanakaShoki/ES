import Foundation
import Vapor

func logMemoryUsage(title: String, logger: Logger) {
  Task.detached(priority: .background) {
    do {
      let contents = try String(contentsOfFile: "/proc/self/statm", encoding: .utf8)
      let parts = contents.split(separator: " ")
      if let pages = parts.first.map(String.init).flatMap(UInt64.init) {
        let pageSize: UInt64 = 4096
        logger.critical("\(title),MEMORY: \(pages * pageSize)") // Bytes
      }
    } catch {
      logger.error("\(title),MEMORY-ERR: \(error)")
    }
  }
}
