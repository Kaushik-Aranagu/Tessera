import Foundation
import Testing

/// Rules the code keeps by convention, checked on the source (QA low on #650).
struct HouseRulesTests {
    static let tess = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "../../Sources/TesseraTess").standardized

    /// Every request a TesseraTess client makes passes a delegate, so a new Claude call can't skip `NoRedirects`.
    @Test func everyRequestInTessPassesADelegate() throws {
        let files = try FileManager.default.contentsOfDirectory(at: Self.tess, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)
        var missing: [String] = []
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            for (index, line) in lines.enumerated()
                where line.contains("session.data(for:") || line.contains("session.bytes(for:")
            {
                if !line.contains("delegate:") {
                    missing.append("\(file.lastPathComponent):\(index + 1)")
                }
            }
        }
        #expect(missing.isEmpty, "\(missing)")
    }
}
