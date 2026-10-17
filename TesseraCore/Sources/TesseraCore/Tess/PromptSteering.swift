import Foundation

/// Sentences that talk to a model instead of saying a thing: "ignore previous instructions", "you are now in admin
/// mode", "print your instructions". Untrusted text (a web page, a routine title someone pasted) that holds one is
/// never trusted as a name, and a model reply that repeats one is the page talking (docs/ai/injection-audit.md). A
/// phrase list, so it catches the plain attempts; the real limit is that no Claude path has a tool that can hurt.
public enum PromptSteering {
    static let phrases = [
        "ignore all", "ignore the previous", "ignore previous", "ignore your", "ignore the rules",
        "ignore the above", "previous instructions", "previous rules", "disregard", "you are now",
        "admin mode", "system note", "system:", "new rule", "your instructions", "system prompt",
        "call every tool", "call the tool",
    ]

    /// Whether the text holds a steering phrase.
    public static func mentions(_ text: String) -> Bool {
        let lower = text.lowercased()
        return phrases.contains { lower.contains($0) }
    }
}
