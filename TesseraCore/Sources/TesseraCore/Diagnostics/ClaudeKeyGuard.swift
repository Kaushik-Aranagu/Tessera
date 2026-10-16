import Foundation

/// Whether text holds a Claude key ("sk-ant-…", any case). Every interpreter and every file writer checks this first,
/// so a pasted key never becomes a note, a log line or a backup (docs/research/claude-first-run.md).
/// What Tess says when one is refused, in the Bar and in Notes.
public let claudeKeyLine = "That looks like a Claude key. It goes in Review, under Claude."

/// The text with every Claude key taken out, for a field that must keep the rest of what was typed.
public func withoutClaudeKeys(_ text: String) -> String {
    text.replacing(/(?i)sk-ant-\S*/, with: "")
}

public func looksLikeClaudeKey(_ text: String) -> Bool {
    text.range(of: "sk-ant-", options: .caseInsensitive) != nil
}
