import Foundation
import TesseraCore

/// The Paste screen's link path (Kitchen gap hunt 8, G54; K87.4, ER1, FW54): a paste that is one bare https link is
/// read through `RecipeLinkReader` on his tap, never as one title line. Offline, the link is kept on the shelf and Tess
/// says "Recipe link, kept for later."; it reads again only on his tap, never by itself (ruled Oct 17, K86.7). Claude
/// (L3) runs only while "Tess asks Claude" is on; with it off the on-phone reader alone reads the page (G32).
@MainActor
public enum RecipePasteLink {
    /// The paste as a link, when it is exactly one: "https://…", "http://…" or "www.…", nothing else around it. A
    /// link with a user or password in it is never one (`isSecretLink`).
    public static func bareLink(_ text: String) -> URL? {
        guard let trimmed = linkShaped(text) else { return nil }
        return RecipeLinkReader.safeURL(trimmed)
    }

    /// A pasted link with a name or password before its host: say `RecipeLinkLine.secretLink`, and read, keep and
    /// save nothing (QA on #807).
    public static func isSecretLink(_ text: String) -> Bool {
        linkShaped(text).map(RecipeLinkReader.hasCredentials) ?? false
    }

    private static func linkShaped(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace),
              lower.hasPrefix("https://") || lower.hasPrefix("http://") || lower.hasPrefix("www."),
              !looksLikeClaudeKey(trimmed) else { return nil }
        return trimmed
    }

    /// The line for a link that waits after a retryable failure (offline already says its own).
    private static func keptLine(_ retry: RecipeLinkResult.Retry) -> String {
        switch retry {
        case .busySite, .claudeBusy, .claudeTimeout: RecipeLinkLine.offline
        case .claudePaused: RecipeLinkLine.keptUntilClaude
        case .badKey: RecipeLinkLine.keptCheckKey
        }
    }

    /// What reading the pasted link gave. `kept` means it is on the shelf for a later tap.
    public struct Outcome: Sendable, Equatable {
        public let result: RecipeLinkResult
        public let kept: Bool
        let keptLine: String?

        /// What Tess says: a kept link says it is kept, never "Paste the text instead." while it waits.
        public var line: String {
            keptLine ?? result.line
        }
    }

    /// Reads a pasted link once, on his tap. Offline (the page or Claude unreachable) keeps it on the shelf; a link
    /// that reads, or fails for any other reason, leaves the shelf. Claude is never asked unless `asksClaude`.
    public static func read(_ link: URL, reader: RecipeLinkReader, asksClaude: Bool,
                            shelf: RecipeLinkShelf?) async -> Outcome
    {
        var reader = reader
        if !asksClaude {
            // Off reads as off ("Claude is off. Paste the text instead."), with no call.
            reader.claude?.allowed = { false }
        }
        let result = await reader.read(link.absoluteString)
        // Offline, or a failure that may pass (a busy site, Claude busy, timed out, paused, a bad key): the link waits,
        // with a line that says so. A read, or a firm refusal (including "Claude is off"), takes it off the shelf.
        let waits = result.isOffline || result.isRetryable
        if waits {
            shelf?.keep(link)
        } else {
            shelf?.remove(link)
        }
        return Outcome(result: result, kept: waits, keptLine: result.retry.flatMap(Self.keptLine))
    }
}

/// Recipe links kept for later (K86.7): a small file beside the store, the links only, tracking stripped, oldest
/// first. Nothing here reads a link; the Paste screen reads one on his tap. A file that can't be read (a locked phone)
/// is never written over.
@MainActor
public final class RecipeLinkShelf {
    public let fileURL: URL
    /// The file's name beside the store, for anything that erases everything (QA on #807).
    public static let fileName = "recipe-links.json"
    /// The most links kept; the oldest goes first (QA on #807).
    public static let limit = 50
    /// Tests on a locked Mac turn this off; the app never does.
    public var fileProtection: Data.WritingOptions = .completeFileProtection

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The shelf for a store's folder: `recipe-links.json` beside `tessera.sqlite`.
    public static func beside(_ store: ObjectStore) -> RecipeLinkShelf? {
        guard let folder = store.context.url?.deletingLastPathComponent() else { return nil }
        return RecipeLinkShelf(fileURL: folder.appending(path: fileName))
    }

    /// Oldest first; empty when there is no file or it can't be read.
    public func waiting() -> [URL] {
        (load() ?? []).compactMap(URL.init(string:))
    }

    public func keep(_ link: URL) {
        // A link that came with a user or password is refused whole, before anything is stripped from it.
        guard !RecipeLinkReader.hasCredentials(link.absoluteString) else { return }
        let text = RecipeLinkReader.stripTracking(link).absoluteString
        guard var links = loadForWrite(), !links.contains(where: { Self.sameLink($0, text) }) else { return }
        links.append(text)
        save(Array(links.suffix(Self.limit)))
    }

    /// Takes one waiting link off, whichever way it was kept: links kept before tracking was stripped on the way in
    /// are matched by their stripped form too, so an old one can be removed.
    public func remove(_ link: URL) {
        let text = RecipeLinkReader.stripTracking(link).absoluteString
        guard var links = loadForWrite() else { return }
        let before = links.count
        links.removeAll { Self.sameLink($0, text) }
        if links.count != before {
            save(links)
        }
    }

    /// A stored link is the same link when it matches as kept, or once stripped (old ones kept their tracking).
    private static func sameLink(_ stored: String, _ stripped: String) -> Bool {
        stored == stripped
            || URL(string: stored).map { RecipeLinkReader.stripTracking($0).absoluteString == stripped } ?? false
    }

    /// Takes the shelf off the phone: its file goes.
    public func erase() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() -> [String]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    /// Nil when a file is there but unreadable, so it is never written over.
    private func loadForWrite() -> [String]? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return [] }
        return load()
    }

    private func save(_ links: [String]) {
        guard let data = try? JSONEncoder().encode(links) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: fileProtection.union(.atomic))
    }
}
