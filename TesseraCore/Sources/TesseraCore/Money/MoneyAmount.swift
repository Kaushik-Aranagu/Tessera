import Foundation

/// An amount as he said it: "12.40", "12,40", "€8", "£4.50", "$3", "20 eur", "23 quid", "500 rs", "₹500". Kept as
/// typed;
/// the code is set only when a known symbol or word says so (EUR, GBP, USD, INR), else nil. Never converted.
public struct MoneyAmount: Equatable, Sendable {
    public let amount: Decimal
    public let typed: String
    public let currency: String?

    static let symbols: [Character: String] = ["€": "EUR", "£": "GBP", "$": "USD", "₹": "INR"]
    static let words: [String: String] = [
        "eur": "EUR", "euro": "EUR", "euros": "EUR", "gbp": "GBP", "quid": "GBP", "pounds": "GBP", "usd": "USD",
        "dollars": "USD", "bucks": "USD", "inr": "INR", "rs": "INR", "rupees": "INR",
    ]

    /// The leading amount of `text`: a symbol and digits, or digits and an optional currency word. Nil when no
    /// number opens it.
    public static func parse(_ text: String) -> MoneyAmount? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let match = trimmed.firstMatch(of: /^([€£$₹])?\s*(\d+(?:[.,]\d{1,2})?)(?:\s*([A-Za-z]+))?/) else {
            return nil
        }
        let symbol = match.1.flatMap(\.first)
        let digits = String(match.2).replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        var code = symbol.flatMap { symbols[$0] }
        var typed = String(match.0)
        if code == nil, let word = match.3.map({ String($0).lowercased() }), let known = words[word] {
            code = known
        } else if let word = match.3, code == nil || words[String(word).lowercased()] == nil {
            // A trailing word that is not a currency belongs to the note, not to the amount.
            typed = String(typed.dropLast(word.count)).trimmingCharacters(in: .whitespaces)
        }
        return MoneyAmount(amount: amount, typed: typed.trimmingCharacters(in: .whitespaces), currency: code)
    }

    /// The text after the amount ("12.40 lunch with sam" gives "lunch with sam").
    public static func note(after text: String) -> String {
        guard let amount = parse(text) else { return text }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return String(trimmed.dropFirst(amount.typed.count)).trimmingCharacters(in: .whitespaces)
    }

    /// Two decimal places, no grouping: "312.40".
    public static func format(_ value: Decimal) -> String {
        var rounded = Decimal()
        var copy = value
        NSDecimalRound(&rounded, &copy, 2, .plain)
        let number = NSDecimalNumber(decimal: rounded)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: number) ?? number.stringValue
    }
}
