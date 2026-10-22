import Foundation
import TesseraCore

/// Money pools phrases (Part B, PR 2b). Parsed on the phone only, behind the Money pools switch (default Off); a
/// phrase that does not read here is never sent anywhere because of it. "got" is a common word, so an inflow needs an
/// amount AND a pool, a source word or a currency word: "got milk", "got it" and "got 20 minutes" log nothing. Every
/// log is one op with Tess's Undo.
extension TessGrammar {
    /// Words that name where money came from, mapped to the source it is stored as.
    static let poolSourceWords: [String: String] = [
        "paycheck": "paycheck", "paycheque": "paycheck", "salary": "paycheck", "payroll": "paycheck",
        "wages": "paycheck", "freelance": "freelance", "gift": "gift", "refund": "refund", "sale": "sale",
        "sold": "sale",
    ]
    /// Words in a pool's name that do not tell pools apart.
    static let poolGenericWords: Set = ["account", "accounts", "cash", "savings", "saving", "pool", "my", "the", "main"]

    func parsePools(_ phrase: String, context: TessContext) -> Parse? {
        guard context.moneyPools else { return nil }
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return parsePoolMove(trimmed, context: context) ?? parseInflow(trimmed)
    }

    /// The one live, plain-named pool a word of the phrase points at: the pool's name in the words, or a word of its
    /// name no other pool shares ("India" for "India account").
    func poolNamed(in words: [String]) -> ObjectRecord? {
        let book = PoolBook(store: store, classes: classes)
        let live = book.pools().filter {
            store.value("archivedAt", of: $0)?.dateValue == nil && !ObjectPrivacy.isPrivateWord($0.title, in: store)
        }
        let spoken = words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
        let line = " " + spoken.joined(separator: " ") + " "
        let whole = live.filter { line.contains(" \($0.title.lowercased()) ") }
        if whole.count == 1 {
            return whole[0]
        }
        var hits: [ObjectRecord] = []
        for pool in live {
            let own = pool.title.lowercased().split(separator: " ").map(String.init)
                .filter { $0.count >= 3 && !Self.poolGenericWords.contains($0) }
            let shared = live.filter { other in
                other.id != pool.id && own
                    .contains { other.title.lowercased().split(separator: " ").map(String.init).contains($0) }
            }
            if shared.isEmpty, own.contains(where: { spoken.contains($0) }) {
                hits.append(pool)
            }
        }
        return hits.count == 1 ? hits[0] : nil
    }

    private func parseInflow(_ phrase: String) -> Parse? {
        guard let head = phrase.firstMatch(of: /^(?i)(?:got|received|earned)\s+(.+)$/) else { return nil }
        let body = String(head.1)
        guard let amount = MoneyAmount.parse(body), amount.amount > 0 else { return nil }
        let note = MoneyAmount.note(after: body)
        let words = note.split(separator: " ").map(String.init)
        let source = words.lazy
            .compactMap { Self.poolSourceWords[$0.lowercased().trimmingCharacters(in: .punctuationCharacters)] }.first
        let pool = poolNamed(in: words)
        // Never on the amount alone: a pool, a source word or a currency must say it is money.
        guard source != nil || pool != nil || amount.currency != nil else { return nil }
        // "got 20 minutes" and "got 5 kg" are quantities, not sums, unless a currency says otherwise.
        if amount.currency == nil, let first = words.first?.lowercased(),
           Self.quantityWords.contains(first) || (amount.amount == 1 && Self.singularQuantityWords.contains(first)),
           source == nil, pool == nil
        {
            return nil
        }
        let filler: Set = ["in", "into", "to", "from", "on", "for", "as", "my", "the", "a", "an", "of"]
        let left = words.filter { word in
            let key = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let nameWord = pool
                .map { $0.title.lowercased().split(separator: " ").map(String.init).contains(key) } ?? false
            return Self.poolSourceWords[key] == nil && !nameWord && !filler.contains(key)
        }
        return .inflow(amount, source: source ?? "paycheck", pool: pool?.id, note: left.joined(separator: " "))
    }

    private func parsePoolMove(_ phrase: String, context _: TessContext) -> Parse? {
        guard let head = phrase.firstMatch(of: /^(?i)(?:moved?|sent|transferred?)\s+(.+)$/) else { return nil }
        let body = String(head.1)
        guard let sent = MoneyAmount.parse(body), sent.amount > 0 else { return nil }
        let rest = MoneyAmount.note(after: body)
        let parts = rest.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let first = parts.first else { return nil }
        let words = first.split(separator: " ").map(String.init)
        guard let toIndex = words.firstIndex(where: { $0.lowercased() == "to" }) else { return nil }
        guard let destination = poolNamed(in: Array(words[(toIndex + 1)...])) else { return nil }
        var source: ObjectRecord?
        if let fromIndex = words.firstIndex(where: { $0.lowercased() == "from" }), fromIndex < toIndex {
            source = poolNamed(in: Array(words[(fromIndex + 1) ..< toIndex]))
            guard source != nil else { return nil }
        }
        var arrived: MoneyAmount?
        var fee: MoneyAmount?
        for part in parts.dropFirst() {
            if let match = part.firstMatch(of: /^(?i)(?:got|arrived|received)\s+(.+)$/) {
                arrived = MoneyAmount.parse(String(match.1))
            } else if let match = part.firstMatch(of: /^(?i)fee\s+(.+)$/) {
                fee = MoneyAmount.parse(String(match.1))
            } else {
                return nil
            }
        }
        guard let arrived, arrived.amount > 0 else { return nil }
        let book = PoolBook(store: store, classes: classes)
        let code = sent.currency ?? "USD"
        guard let from = source ?? book.lastUsedPool(currency: code), from.id != destination.id else { return nil }
        return .poolMove(from: from.id, to: destination.id, sent: sent, arrived: arrived, fee: fee)
    }
}
