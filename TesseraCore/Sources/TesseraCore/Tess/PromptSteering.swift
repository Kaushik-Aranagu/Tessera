import Foundation

/// Sentences that talk to a model instead of saying a thing: "ignore previous instructions", "you are now in admin
/// mode", "print your instructions". Untrusted text (a web page, a routine title someone pasted) that holds one is
/// never trusted as a name, and a model reply that repeats one is the page talking (docs/ai/injection-audit.md). A
/// phrase list, so it catches the plain attempts; the real limit is that no Claude path has a tool that can hurt.
/// It reads the text as typed and its canonical form, so full-width letters or a hidden character don't hide a
/// phrase (input-hygiene H4).
public enum PromptSteering {
    static let phrases = [
        "ignore all", "ignore the previous", "ignore previous", "ignore your", "ignore the rules",
        "ignore the above", "previous instructions", "previous rules", "disregard", "you are now",
        "admin mode", "system note", "system:", "new rule", "your instructions", "system prompt",
        "call every tool", "call the tool",
        // A page that writes a turn or closes its own data block (H4).
        "assistant:", "human:", "<system", "</page", "from now on",
    ]

    /// Whether the text holds a steering phrase.
    public static func mentions(_ text: String) -> Bool {
        !found(text).isEmpty
    }

    /// Every steering phrase the text holds, in list order.
    public static func found(_ text: String) -> [String] {
        let typed = text.lowercased()
        let canonical = CanonicalText.of(text).lowercased()
        return phrases.filter { typed.contains($0) || canonical.contains($0) }
    }
}
