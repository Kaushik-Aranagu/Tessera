import Foundation
import TesseraTess

/// Tess's line while a pasted link is read (Product ruling on #993). It starts as "Reading the recipe from
/// seriouseats.com." (the host only, never the path) and switches to "Asking Claude to read the recipe." only at the
/// moment the reader hands the page to Claude: never at the start, never for a card or the page's own words, never
/// with "Tess asks Claude" off, no key, nothing to send or no room under the cap.
@MainActor
enum PasteLinkWait {
    /// The start line: the host alone, "www." dropped, so a path or query never shows.
    static func startLine(_ link: URL) -> String {
        guard let host = link.host(), !host.isEmpty else { return "Reading the recipe." }
        return "Reading the recipe from \(host.hasPrefix("www.") ? String(host.dropFirst(4)) : host)."
    }

    /// Core's words for the handoff to Claude.
    static let askingLine = RecipeLinkLine.askingClaude

    /// The reader for a pasted link: `line` gets Claude's line from Core's `willAskClaude`, just before the request
    /// leaves for Claude, and at no other time.
    static func reader(session: URLSession? = nil, claude: ClaudeRecipeReader?,
                       line: @escaping @MainActor (String) -> Void) -> RecipeLinkReader
    {
        var reader = session.map { RecipeLinkReader(session: $0, claude: claude) } ?? RecipeLinkReader(claude: claude)
        reader.willAskClaude = { line(askingLine) }
        return reader
    }
}
