import Foundation
import Testing

/// Rules the code keeps by convention, checked on the source (QA low on #650, #654).
struct HouseRulesTests {
    static let root = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "../../..").standardized
    static let roots = ["TesseraCore/Sources", "Features", "App"]

    nonisolated(unsafe) static let requestCall =
        /\.data\(for:|\.data\(from:|\.bytes\(for:|\.bytes\(from:|\.upload\(for:|\.download\(for:|\.dataTask\(with:|URLSession\.shared/

    /// What marks a file as talking to Claude: the host itself, or the constant the clients share.
    static func talksToClaude(_ source: String) -> Bool {
        source.contains("api.anthropic.com") || source.contains("ClaudeKeyCheck.base")
    }

    /// 1-based lines of requests that skip the rule: no `delegate:` anywhere, or, in a Claude file, no
    /// `NoRedirects.shared`. A statement is its line joined with the next two, so a split call is still seen.
    static func violations(in source: String) -> [Int] {
        let lines = source.components(separatedBy: .newlines)
        let claude = talksToClaude(source)
        var hits: [Int] = []
        for index in lines.indices where lines[index].firstMatch(of: requestCall) != nil {
            let statement = lines[index ... min(index + 2, lines.count - 1)].joined(separator: " ")
            let ok = claude
                ? statement.contains("NoRedirects.shared") || statement.contains("delegate: redirects")
                : statement.contains("delegate:")
            if !ok {
                hits.append(index + 1)
            }
        }
        return hits
    }

    static func swiftFiles() throws -> [URL] {
        var files: [URL] = []
        for sub in roots {
            let dir = root.appending(path: sub)
            guard let walker = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil)
            else { continue }
            files += walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        }
        return files
    }

    /// Every request any client makes passes a delegate, and a Claude call passes `NoRedirects.shared`, so a new
    /// call can't skip it. The recipe page fetch keeps its own `RedirectGuard`.
    @Test func everyRequestInTessPassesADelegate() throws {
        let files = try Self.swiftFiles()
        #expect(!files.isEmpty)
        var missing: [String] = []
        var claudeSites: Set<String> = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let name = file.lastPathComponent
            if Self.talksToClaude(source), source.firstMatch(of: Self.requestCall) != nil {
                claudeSites.insert(name)
            }
            missing += Self.violations(in: source).map { "\(name):\($0)" }
        }
        #expect(missing.isEmpty, "\(missing)")
        for known in ["ClaudeKey.swift", "ClaudeTessModel.swift", "PlanWording.swift", "RecipeLinkReader.swift"] {
            #expect(claudeSites.contains(known), "\(known) not found as a Claude site")
        }
    }

    @Test func theMatcherSeesACallWithNoDelegate() {
        let bare = "let (data, _) = try await session.data(for: request)"
        #expect(Self.violations(in: bare) == [1])
        let split = "try await session\n    .data(for: request,\n            delegate: NoRedirects.shared)"
        #expect(Self.violations(in: split).isEmpty)
        let shared = "let x = try await URLSession.shared.data(from: url)"
        #expect(Self.violations(in: shared) == [1])
        // A Claude file needs NoRedirects.shared, not just any delegate.
        let claude = "let host = \"api.anthropic.com\"\ntry await session.data(for: r, delegate: Other())"
        #expect(Self.violations(in: claude) == [2])
    }
}
