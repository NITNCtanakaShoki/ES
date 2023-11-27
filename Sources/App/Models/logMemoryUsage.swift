import Foundation
import Vapor

func logMemoryUsage(title: String, logger: Logger) {
  Task.detached(priority: .background) {
    do {
      let contents = try String(contentsOfFile: "/proc/meminfo", encoding: .utf8)
      let lines = contents.split(separator: "\n")

      var memInfo = [String: UInt64]()
      for line in lines {
        let parts = line.split(separator: " ")
        if let key = parts.first, let valueString = parts.dropFirst().first,
          let value = UInt64(valueString.trimmingCharacters(in: .whitespacesAndNewlines))
        {
          memInfo[String(key.dropLast())] = value
        }
      }

      if let memTotal = memInfo["MemTotal"],
        let memFree = memInfo["MemFree"],
        let buffers = memInfo["Buffers"],
        let cached = memInfo["Cached"]
      {
        let usedMemory = memTotal - (memFree + buffers + cached)
        logger.critical("\(title), MEMORY: \(usedMemory) [KB]")
      } else {
        logger.error("\(title), MEMORY-ERR: \(memInfo)")
      }
    } catch {
      logger.error("\(title), MEMORY-ERR: \(error)")
    }
  }
}
