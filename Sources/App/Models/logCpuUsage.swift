import Foundation
import Vapor

func logCpuUsage(title: String, logger: Logger) {
  Task.detached(priority: .background) {
    do {
      let contents = try String(contentsOfFile: "/proc/stat", encoding: .utf8)
      let lines = contents.split(separator: "\n")

      var totalIdleTime: UInt64 = 0
      var totalTime: UInt64 = 0

      for line in lines {
        let parts = line.split(separator: " ")
        if parts.first?.starts(with: "cpu") ?? false, parts.count > 4 {
          let userTime = UInt64(parts[1]) ?? 0
          let niceTime = UInt64(parts[2]) ?? 0
          let systemTime = UInt64(parts[3]) ?? 0
          let idleTime = UInt64(parts[4]) ?? 0

          totalIdleTime += idleTime
          totalTime += userTime + niceTime + systemTime + idleTime
        }
      }

      if totalTime > 0 {
        let totalUsage = 100.0 - (Double(totalIdleTime) / Double(totalTime) * 100.0)
        logger.critical("\(title), CPU USAGE: \(totalUsage)%")
      } else {
        logger.error("\(title), CPU USAGE-ERR: \(lines)")
      }
    } catch {
      logger.error("\(title), CPU USAGE-ERR: \(error)")
    }
  }
}
