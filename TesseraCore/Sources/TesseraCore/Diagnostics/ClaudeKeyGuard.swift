import Foundation

/// What Tess says when a Claude key is refused: in the Bar, in Notes and from Siri.
public let claudeKeyLine = "That looks like a Claude key. It goes in Review, under Claude."

/// The text with every Claude key taken out, for a field that must keep the rest of what was typed. A key pasted
/// across a line break or a space comes out whole: the long key-like runs right after it go too (QA R4 on #471).
public func withoutClaudeKeys(_ text: String) -> String {
    text.replacing(/(?i)sk-ant-\S*(?:\s+(?=\S*\d)[A-Za-z0-9_\-]{8,}(?=\s|$))*/, with: "")
}

/// Whether text holds a Claude key ("sk-ant-…", any case). Every interpreter and every file writer checks this first,
/// so a pasted key never becomes a note, a log line or a backup (docs/research/claude-first-run.md).
public func looksLikeClaudeKey(_ text: String) -> Bool {
    text.range(of: "sk-ant-", options: .caseInsensitive) != nil
}
