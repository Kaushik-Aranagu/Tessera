import Foundation

/// Splits a typed or spoken groceries phrase into lines: "eggs, bread and 2 lemons" is three rows. Pairs that are one
/// food ("mac and cheese", "salt and pepper") stay one row (kitchen-v2-acceptance G1).
public enum GroceryLines {
    /// Foods whose name has "and" in it. Matched whole words, any case.
    static let knownPairs = [
        "mac and cheese", "macaroni and cheese", "salt and pepper", "salt and vinegar", "fish and chips",
        "bread and butter", "peanut butter and jelly", "rice and beans", "beans and rice", "surf and turf",
        "cookies and cream", "oil and vinegar", "pork and beans", "chips and salsa", "chips and dip",
        "cream and sugar", "sweet and sour", "black beans and rice", "lemon and herb", "ham and cheese",
        "bacon and eggs", "eggs and bacon", "franks and beans",
    ]

    private static let joiner = "\u{1}"

    public static func split(_ text: String) -> [String] {
        var masked = text
        for pair in knownPairs {
            let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: pair) + "(?![\\p{L}\\p{N}])"
            guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(masked.startIndex..., in: masked)
            // Keep the typed case: swap only the " and " between the words.
            let matches = expression.matches(in: masked, range: range).reversed()
            for match in matches {
                guard let swiftRange = Range(match.range, in: masked) else { continue }
                let found = String(masked[swiftRange])
                let replaced = found.replacing(/(?i)\s+and\s+/, with: joiner)
                masked.replaceSubrange(swiftRange, with: replaced)
            }
        }
        return masked.replacing(/\s+and\s+/, with: ",")
            .split(separator: ",")
            .map { $0.replacingOccurrences(of: joiner, with: " and ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
