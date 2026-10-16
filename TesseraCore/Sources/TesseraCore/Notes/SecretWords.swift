import Foundation

/// Secret words (Research 134, Product NE1/NE2 and Q1): a line with a password, PIN, passcode, code or wifi key in it
/// becomes a private note on the phone. It never reaches the on-device model, Claude, memory or the miss log, and
/// outside the note itself it reads "Private note". It does ride in his own backups (Q1).
public enum SecretWords {
    /// What a private note is called everywhere outside its own page.
    public static let title = "Private note"

    /// Whole words only: "pin" never catches "pinch" or "spinach".
    static let words: Set<String> = ["password", "passwords", "passcode", "passcodes", "pin", "pins", "code", "codes",
                                     "combo", "combination", "passphrase"]

    /// The words of a line, lowercased, punctuation off, ":" kept as its own word.
    static func tokens(_ text: String) -> [String] {
        text.lowercased().replacingOccurrences(of: ":", with: " : ").split(separator: " ")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;'\"()")) }
            .filter { !$0.isEmpty }
    }

    /// Where the secret words sit in a line (indexes into `tokens`). "wifi" counts only before ":" or "is".
    static func secretIndexes(_ tokens: [String]) -> [Int] {
        tokens.indices.filter { index in
            if words.contains(tokens[index]) {
                return true
            }
            guard tokens[index] == "wifi", index + 1 < tokens.count else { return false }
            return [":", "is"].contains(tokens[index + 1])
        }
    }

    /// Whether a line holds a secret word at all.
    public static func mentions(_ text: String) -> Bool {
        !secretIndexes(tokens(text)).isEmpty
    }

    /// Whether the line carries a value after a secret word: the next word with a digit, letters mixed with digits or
    /// symbols, three or more spoken digits, or any word after "is" or ":" that follows the secret word (R3).
    public static func hasValue(_ text: String) -> Bool {
        let tokens = tokens(text)
        for index in secretIndexes(tokens) {
            var next = index + 1
            // "wifi password is …": skip a second secret word.
            while next < tokens.count, words.contains(tokens[next]) {
                next += 1
            }
            guard next < tokens.count else { continue }
            if [":", "is", "=", "-"].contains(tokens[next]) {
                return next + 1 < tokens.count
            }
            let word = tokens[next]
            if word.contains(where: \.isNumber) || word.contains(where: { "@#$%&*_/".contains($0) }) {
                return true
            }
            let spokenDigits: Set = ["zero", "oh", "one", "two", "three", "four", "five", "six", "seven", "eight",
                                     "nine"]
            if tokens[next...].prefix(while: { spokenDigits.contains($0) }).count >= 3 {
                return true
            }
        }
        return false
    }
}

public extension TessMemoryScreen {
    /// A secret word in a line meant for memory: never kept there (Research 134 SW3).
    static func isSecret(_ text: String) -> Bool {
        SecretWords.mentions(text)
    }
}
