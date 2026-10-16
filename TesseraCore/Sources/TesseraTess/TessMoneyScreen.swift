import Foundation
import TesseraCore

/// Money stays on the phone (Product 999df84, Research 129 MU2; docs/ai/architecture.md §7): a phrase that looks like a
/// spend never reaches Claude, whatever the switch says. The router checks it before any route's `isAvailable`, and
/// Claude's own route refuses it again as a second wall, so the inbox can't carry one there later either.
public enum TessMoneyScreen {
    /// Currency signs and words, spend verbs, and the memory screen's money words (one list for both walls).
    static let currencyWords: Set<String> = ["usd", "dollar", "dollars", "bucks", "buck", "gbp", "pound", "pounds",
                                             "quid", "tenner", "fiver", "eur", "euro", "euros", "inr", "rs", "rupee",
                                             "rupees", "cad", "aud", "chf", "jpy", "yen"]
    static let spendVerbs: Set<String> = ["spent", "spend", "paid", "pay", "bought", "cost", "costs", "refund",
                                          "refunded", "tip", "tipped", "venmo", "venmoed", "owe", "owes"]

    /// Whether a phrase is money-shaped: a currency sign, a currency word with an amount, a spend verb with an amount,
    /// or an amount with exactly two decimals and no reps after it ("costco 212.37", "coffee 6.25 today").
    /// Training notation ("82.50 x 8", "80 for 8", "5 reps") is never money.
    public static func isMoneyShaped(_ phrase: String) -> Bool {
        let text = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        let lower = text.lowercased()
        if lower.firstMatch(of: /\d\s*(?:x|×|for|by)\s*\d/) != nil || lower.firstMatch(of: /\d\s*reps?\b/) != nil {
            return false
        }
        if text.contains(where: { "$£€₹¥".contains($0) }) {
            return true
        }
        let words = lower.split { !$0.isLetter && !$0.isNumber && $0 != "." && $0 != "," }.map(String.init)
        let hasAmount = words.contains { $0.first?.isNumber == true }
        if hasAmount, words.contains(where: { currencyWords.contains($0) || spendVerbs.contains($0) }) {
            return true
        }
        if hasAmount, words.contains(where: { TessMemoryScreen.moneyWords.contains($0) }) {
            return true
        }
        return words.contains { $0.wholeMatch(of: /\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2}|\d+,\d{2}/) != nil }
    }
}
