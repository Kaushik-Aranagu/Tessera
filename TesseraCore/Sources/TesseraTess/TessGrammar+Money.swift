import Foundation
import TesseraCore

/// Money phrases (Money slice 4). Everything here stays on the phone: the grammar logs a spend as a ghost row, the
/// month answer is read from the log, and a money phrase it cannot read is kept on the phone (the private-note
/// route in `parse`), never sent anywhere.
extension TessGrammar {
    /// Words that follow a whole number and make it a quantity, not a sum ("spent 2 hours on taxes").
    static let quantityWords: Set = [
        "hour", "hours", "hr", "hrs", "minute", "minutes", "min", "mins", "day", "days", "week", "weeks", "month",
        "months", "year", "years", "time", "times", "kg", "lb", "lbs", "reps", "rep", "sets", "set", "miles", "mile",
        "km", "people", "items", "x",
    ]

    /// "how much this month", "how much did I spend this month": the month line, from the log.
    func parseMonthQuestion(_ text: String, context: TessContext) -> Parse? {
        let asked = text.firstMatch(of: /^(?:how much|what)\b.*\b(?:this month|so far)\b/) != nil
            || text.firstMatch(of: /^(?:how much|what).*\b(?:spend|spent|logged)\b.*\bmonth\b/) != nil
        guard asked, text.contains("month"),
              text.contains("how much") || text.contains("spend") || text.contains("spent") || text.contains("logged")
        else { return nil }
        let ledger = SpendLedger(store: store, classes: classes)
        return .ask(ledger.monthLine(for: context.now, calendar: context.calendar))
    }

    /// A spend, a groceries total, or a skip. Nil when the phrase is not money.
    func parseMoney(_ phrase: String, text: String, context: TessContext, entry: ObjectRecord?) -> Parse? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let receipt = ShopReceipt(store: store, classes: classes)
        let awaiting = receipt.awaiting(at: context.now) != nil
        if awaiting {
            if ["skip", "no total", "skip total", "skip it", "no thanks"].contains(text) {
                return .skipShopTotal
            }
            if let total = Self.shopTotal(trimmed) {
                return .shopTotal(total)
            }
        }
        // "shop total 84.10" with nothing awaited is still his groceries, as a spend.
        if !awaiting, let total = Self.shopTotal(trimmed, requireWord: true) {
            return .spend(total, note: "groceries", on: nil)
        }
        return parseSpend(trimmed, context: context, entry: entry)
    }

    /// "total 38.20", "shop total 84.10", "groceries total £84.10"; a bare amount only when a total is awaited.
    static func shopTotal(_ phrase: String, requireWord: Bool = false) -> MoneyAmount? {
        if let match = phrase.firstMatch(of: /^(?i)(?:(?:shop|shopping|groceries|grocery)\s+)?total\s+(.+)$/),
           let amount = MoneyAmount.parse(String(match.1)), MoneyAmount.note(after: String(match.1)).isEmpty
        {
            return amount
        }
        guard !requireWord, let amount = MoneyAmount.parse(phrase), MoneyAmount.note(after: phrase).isEmpty else {
            return nil
        }
        return amount
    }

    private func parseSpend(_ phrase: String, context: TessContext, entry: ObjectRecord?) -> Parse? {
        var body = phrase
        var verb = false
        if let match = body.firstMatch(of: /^(?i)(?:spent|spend|paid)\s+(.+)$/) {
            body = String(match.1)
            verb = true
        }
        // A live workout owns its bare numbers (relative sets run first); only an explicit verb spends there.
        guard verb || entry == nil else { return nil }
        var words = body.split(separator: " ").map(String.init)
        var day: Date?
        if let (past, rest) = TessDates.pastDay(in: words, now: context.now, calendar: context.calendar) {
            day = context.calendar.date(bySettingHour: 12, minute: 0, second: 0, of: past) ?? past
            words = rest
        }
        // Something still to come is a task, never a spend.
        guard !words.contains(where: { ["tomorrow", "tonight", "next", "later"].contains($0.lowercased()) }) else {
            return nil
        }
        let rest = words.joined(separator: " ")
        // The amount first: "12.40 lunch", "€8 parking", "20 eur taxi".
        if let amount = MoneyAmount.parse(rest) {
            let shaped = verb || Self.hasMoneyShape(amount)
            var note = MoneyAmount.note(after: rest)
            // "spent 2 hours on taxes": a quantity, not a sum.
            if let first = note.split(separator: " ").first?.lowercased(), Self.quantityWords.contains(first),
               !Self.hasMoneyShape(amount)
            {
                return nil
            }
            for lead in ["on ", "for ", "at ", "in ", "from "] where note.lowercased().hasPrefix(lead) {
                note = String(note.dropFirst(lead.count))
                break
            }
            note = note.trimmingCharacters(in: CharacterSet(charactersIn: " ,."))
            guard shaped, Self.isPlainNote(note, requireWords: !verb) else { return nil }
            return .spend(amount, note: note, on: day)
        }
        // "paid rent 1200": the thing, then the amount, after a verb.
        guard verb, words.count >= 2, let last = words.last, let amount = MoneyAmount.parse(last),
              MoneyAmount.note(after: last).isEmpty else { return nil }
        let note = words.dropLast().joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,."))
        guard Self.isPlainNote(note, requireWords: true) else { return nil }
        return .spend(amount, note: note, on: day)
    }

    /// Two decimal places, or a currency symbol or word: the shapes a bare amount may have (Money decision 2).
    static func hasMoneyShape(_ amount: MoneyAmount) -> Bool {
        amount.currency != nil || amount.typed.firstMatch(of: /[.,]\d{2}\b/) != nil
            || amount.typed.contains(where: { "$£€₹".contains($0) })
    }

    /// A note is words: no second number, no clock time, no set shape.
    static func isPlainNote(_ note: String, requireWords: Bool) -> Bool {
        if note.isEmpty {
            return !requireWords
        }
        guard note.contains(where: \.isLetter), note.count <= 80 else { return false }
        if note.contains(where: \.isNumber) {
            return false
        }
        return note.lowercased().firstMatch(of: /(?:^|\s)(?:x|for \d|reps?|at \d)(?:\s|$)/) == nil
    }
}
