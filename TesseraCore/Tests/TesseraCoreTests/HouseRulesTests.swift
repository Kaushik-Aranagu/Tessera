import Foundation
import Testing

/// Rules the code keeps by convention, checked on the source (QA low on #650, #654).
struct HouseRulesTests {
    static let root = URL(filePath: #filePath).deletingLastPathComponent()
        .appending(path: "../../..").standardized
    static let roots = ["TesseraCore/Sources", "Features", "App", "Widgets", "Shared", "DesignSystem"]
    static let redirectsFile = "RecipeLinkReader.swift"

    nonisolated(unsafe) static let requestCall = /\.data\(for:|\.data\(from:|\.bytes\(for:|\.bytes\(from:|\.upload\(for:/
    nonisolated(unsafe) static let moreCalls = /\.download\(for:|\.download\(from:|URLSession\.shared/
    nonisolated(unsafe) static let taskCalls = /\.dataTask\(with:|\.uploadTask\(with:|\.downloadTask\(with:/
    static func isRequest(_ line: String) -> Bool {
        line.firstMatch(of: requestCall) != nil || line.firstMatch(of: moreCalls) != nil || line
            .firstMatch(of: taskCalls) != nil
    }

    /// What marks a file as talking to Claude: the host, the constant the clients share, or its two headers.
    static func talksToClaude(_ source: String) -> Bool {
        ["api.anthropic.com", "ClaudeKeyCheck.base", "x-api-key", "anthropic-version"]
            .contains { source.contains($0) }
    }

    /// The request statements of a source: 1-based line and the line joined with the next two, so a split call is
    /// still seen.
    static func statements(in source: String) -> [(line: Int, text: String)] {
        let lines = source.components(separatedBy: .newlines)
        return lines.indices.filter { isRequest(lines[$0]) }.map {
            ($0 + 1, lines[$0 ... min($0 + 2, lines.count - 1)].joined(separator: " "))
        }
    }

    /// 1-based lines of requests that skip the rule: no `delegate:` anywhere, or, in a Claude file, no
    /// `NoRedirects.shared`. `delegate: redirects` is allowed only in `RecipeLinkReader.swift`.
    static func violations(in source: String, file: String = "") -> [Int] {
        let claude = talksToClaude(source)
        return statements(in: source).compactMap { line, statement in
            let passes = claude
                ? statement.contains("NoRedirects.shared")
                : statement.contains("delegate:")
            let ownRedirects = claude && file == redirectsFile && statement.contains("delegate: redirects")
            return passes || ownRedirects ? nil : line
        }
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
    /// call can't skip it. Only the recipe page fetch keeps its own `RedirectGuard` (`delegate: redirects`).
    @Test func everyRequestInTessPassesADelegate() throws {
        let files = try Self.swiftFiles()
        #expect(!files.isEmpty)
        var missing: [String] = []
        var claudeSites: Set<String> = []
        var redirectSites: [String] = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let name = file.lastPathComponent
            if Self.talksToClaude(source), source.components(separatedBy: .newlines).contains(where: Self.isRequest) {
                claudeSites.insert(name)
            }
            redirectSites += Self.statements(in: source).filter { $0.text.contains("delegate: redirects") }
                .map { "\(name):\($0.line)" }
            missing += Self.violations(in: source, file: name).map { "\(name):\($0)" }
        }
        #expect(missing.isEmpty, "\(missing)")
        var expected: Set = ["ClaudeKey.swift", "ClaudeTessModel.swift", "PlanWording.swift", "RecipeLinkReader.swift"]
        if files.contains(where: { $0.lastPathComponent == "HomeDoneWording.swift" }) {
            expected.insert("HomeDoneWording.swift")
        }
        #expect(claudeSites == expected, "\(claudeSites.sorted())")
        #expect(redirectSites.count == 1, "\(redirectSites)")
        #expect(redirectSites.allSatisfy { $0.hasPrefix(Self.redirectsFile + ":") }, "\(redirectSites)")
    }

    @Test func theMatcherSeesACallWithNoDelegate() {
        let bare = "let (data, _) = try await session.data(for: request)"
        #expect(Self.violations(in: bare) == [1])
        let split = "try await session\n    .data(for: request,\n            delegate: NoRedirects.shared)"
        #expect(Self.violations(in: split).isEmpty)
        let shared = "let x = try await URLSession.shared.data(from: url)"
        #expect(Self.violations(in: shared) == [1])
        for call in [
            "session.download(from: u)",
            "session.uploadTask(with: r, from: d)",
            "session.downloadTask(with: r)",
        ] {
            #expect(Self.violations(in: call) == [1], "\(call)")
        }
        // A Claude file needs NoRedirects.shared, not just any delegate.
        let claude = "let host = \"api.anthropic.com\"\ntry await session.data(for: r, delegate: Other())"
        #expect(Self.violations(in: claude) == [2])
        // The headers alone mark a Claude file.
        for header in ["x-api-key", "anthropic-version"] {
            let source = "req.setValue(k, forHTTPHeaderField: \"\(header)\")\ntry await session.data(for: r, delegate: Other())"
            #expect(Self.violations(in: source) == [2], "\(header)")
        }
        // `delegate: redirects` in a Claude file is flagged anywhere but RecipeLinkReader.swift.
        let redirects = "let host = \"api.anthropic.com\"\ntry await session.bytes(for: r, delegate: redirects)"
        #expect(Self.violations(in: redirects, file: "ClaudeKey.swift") == [2])
        #expect(Self.violations(in: redirects, file: Self.redirectsFile).isEmpty)
    }
}
