import Foundation

/// What Tess says when a Claude key is refused: in the Bar, in Notes and from Siri.
public let claudeKeyLine = "That looks like a Claude key. It goes in Review, under Claude."

/// The text with every Claude key taken out, for a field that must keep the rest of what was typed. A key pasted
/// across a line break or a space comes out whole: the long key-like runs right after it go too (QA R4 on #471).
public func withoutClaudeKeys(_ text: String) -> String {
    text.replacing(/(?i)sk\s*-\s*ant(?:\s*-|(?=[a-z0-9_-]{8}))\S*(?:\s+(?=\S*\d)[A-Za-z0-9_\-]{8,}(?=\s|$))*/, with: "")
}

/// Whether text holds a Claude key (it starts with the Claude key prefix, in any case). Every interpreter and every
/// file writer checks this first,
/// so a pasted key never becomes a note, a log line or a backup (docs/research/claude-first-run.md).
///
/// The prefix is matched with space around its dashes and with its last dash missing too (Research KS06, KS07), so a
/// key mistyped or split by dictation is still held back.
public func looksLikeClaudeKey(_ text: String) -> Bool {
    text.firstMatch(of: /(?i)sk\s*-\s*ant(?:\s*-|(?=[a-z0-9_-]{8}))/) != nil
}
