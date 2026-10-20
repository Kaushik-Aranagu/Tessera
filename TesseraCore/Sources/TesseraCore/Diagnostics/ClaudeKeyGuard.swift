import Foundation

/// What Tess says when a Claude key is refused: in the Bar, in Notes and from Siri.
public let claudeKeyLine = "That looks like a Claude key. It goes in Settings, under Claude."

/// The text with every Claude key taken out, for a field that must keep the rest of what was typed. A key pasted
/// across a line break or a space comes out whole: the long key-like runs right after it go too (QA R4 on #471).
public func withoutClaudeKeys(_ text: String) -> String {
    text.replacing(keyWithTail, with: "")
}

/// Whether text holds a Claude key (it starts with the Claude key prefix, in any case). Every interpreter and every
/// file writer checks this first,
/// so a pasted key never becomes a note, a log line or a backup (docs/research/claude-first-run.md).
///
/// The prefix is matched with space around its dashes and with its last dash missing too (Research KS06, KS07), so a
/// key mistyped or split by dictation is still held back.
public func looksLikeClaudeKey(_ text: String) -> Bool {
    text.firstMatch(of: keyPrefix) != nil
}

/// The key's prefix: space around its dashes, its last dash missing when a digit follows within 8 letters
/// (Research KS06, KS07; "risk-anticipation" is no key), and any dash a paste may carry (U+2010 to U+2014, U+2212).
nonisolated(unsafe) let keyPrefix = try! Regex( // swiftlint:disable:this force_try
    #"(?i)sk\s*[-\x{2010}-\x{2014}\x{2212}]\s*ant(?:\s*[-\x{2010}-\x{2014}\x{2212}]|(?=[a-z_-]{0,8}\d))"#
)
/// The prefix and the rest of the key, with long key-like runs split off it by a space or a line break.
nonisolated(unsafe) let keyWithTail = try! Regex( // swiftlint:disable:this force_try
    #"(?i)sk\s*[-\x{2010}-\x{2014}\x{2212}]\s*ant(?:\s*[-\x{2010}-\x{2014}\x{2212}]|(?=[a-z_-]{0,8}\d))"#
        + #"\S*(?:\s+(?=\S*\d)[A-Za-z0-9_\-]{8,}(?=\s|$))*"#
)
