import Foundation

/// Whether text holds a Claude key ("sk-ant-…", any case). Every interpreter and every file writer checks this first,
/// so a pasted key never becomes a note, a log line or a backup (docs/research/claude-first-run.md).
public func looksLikeClaudeKey(_ text: String) -> Bool {
    text.range(of: "sk-ant-", options: .caseInsensitive) != nil
}
