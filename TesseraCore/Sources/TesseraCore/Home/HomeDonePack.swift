import Foundation

/// What Home's done job may send Claude about one finished workout (board 0al, docs/ai/home-lines-job.md §2c): the
/// routine title, the finish clock word, the day label, the bests, days since the same routine, the rules line, and
/// the numbers and names a returned line may use. Nothing else: no weights, reps, volume, notes, health or money.
///
/// The wall runs here, at pack time, and trusts no source (Research home-pack-walls W1 to W16, decisions 7:22 and
/// 7:31 PM PT Oct 16): routine titles and exercise names are his free text, exempt from the engine wall when he
/// renames them, so the title and every best name go through it. On any hit there is no pack and no call at all; a
/// partial mask would still leak through the rules line.
public struct HomeDonePack: Equatable, Sendable {
    /// Why no pack was built.
    public enum Skip: Error, Equatable, Sendable {
        /// Not a finished workout.
        case notDone
        /// Finished with no sets: skipped before the wall runs (W12a).
        case noSets
        /// No best and under 4 days since the same routine: nothing Claude could add (AI-5).
        case nothingToAdd
        /// The title or a best name tripped the wall.
        case walled
    }

    public let title: String
    /// "7:40 pm": the finish, as a clock word (no `now`, no part of day; §2c item 2).
    public let finish: String
    /// "Thursday night": the house day the finish belongs to.
    public let dayLabel: String
    public let bests: [String]
    public let sinceLastDays: Int?
    /// The phone's own line, which shows first and stays unless Claude's words pass every check.
    public let rulesLine: String
    /// The numbers a returned line may hold: the facts' counts and the finish clock's digits only, never digits from
    /// the title (W14: "Push B 5x5 80 for 8" licenses no 5, 80 or 8).
    public let numbers: [Int]
    /// The names a returned line may use: the title and the bests.
    public let names: [String]

    /// The pack for a done workout, or why there is none.
    /// His last weight is read from the store here, so no caller can leave the bare-number wall without it.
    @MainActor
    public static func build(_ fact: HomeFact, dayLabel: String, calendar: Calendar,
                             store: ObjectStore) -> Result<HomeDonePack, Skip>
    {
        build(fact, dayLabel: dayLabel, calendar: calendar, lastWeightKg: BodyWeight.lastKg(in: store))
    }

    static func build(_ fact: HomeFact, dayLabel: String, calendar: Calendar,
                      lastWeightKg: Double?) -> Result<HomeDonePack, Skip>
    {
        guard fact.kind == .workout, fact.state == .done, let ended = fact.endedAt else { return .failure(.notDone) }
        guard fact.sets > 0 else { return .failure(.noSets) }
        guard !fact.records.isEmpty || (fact.sinceLastDays ?? 0) >= 4 else { return .failure(.nothingToAdd) }
        guard !([fact.title] + fact.records).contains(where: { isWalled($0, lastWeightKg: lastWeightKg) }) else {
            return .failure(.walled)
        }
        let finish = HouseTime.clock(ended, calendar: calendar)
        let numbers = Array(Set(fact.factNumbers + HomeLines.digits(in: finish))).sorted()
        return .success(HomeDonePack(
            title: fact.title, finish: finish, dayLabel: dayLabel, bests: fact.records,
            sinceLastDays: fact.sinceLastDays,
            rulesLine: HomeLines.workoutText(for: fact, now: ended, calendar: calendar),
            numbers: numbers, names: [fact.title] + fact.records
        ))
    }

    /// Whether a title or an exercise name must never be packed: a secret word (failing closed, so "Pin press" is
    /// walled too; W5), money, a body or health fact, a Claude key, or a decimal or a 3-plus digit number that isn't
    /// training notation (W9, Home pack only).
    public static func isWalled(_ name: String, lastWeightKg: Double?) -> Bool {
        let lower = name.lowercased()
        if looksLikeClaudeKey(name) || SecretWords.mentions(name) || PrivateFacts.isWalled(
            name,
            lastWeightKg: lastWeightKg
        ) {
            return true
        }
        // Set notation never excuses a weigh-in (AI architecture on #643): a weigh word or bmi with a number, or a
        // decimal with no lift named, is his body even beside "5x5". "Bench 82.4 kg 5x5" is the bar (MB31, MB32).
        let words = PrivateFacts.words(lower)
        let hasNumber = words.contains { $0.first?.isNumber == true }
        let weighs = words.contains { PrivateFacts.weighWords.contains($0) || $0 == "bmi" }
        if weighs, hasNumber {
            return true
        }
        // Only the set itself is the bar (D1): the rest is read for a decimal or a long number. A bar weight right
        // before its sets, with a lift named, is the set's own ("Bench 82.4 kg 5x5"); with no lift it is not
        // ("Morning 82.4 5x5"), and nor is one standing alone (W9: "Bench 182.4").
        let lifted = words.contains(where: PrivateFacts.liftWords.contains)
        let barOfASet = /\d+(?:[.,]\d+)?\s*(?:kg|kgs|lb|lbs)?\s+\d+\s*[x×]\s*\d+/
        let rest = PrivateFacts.withoutNotation(lifted ? lower.replacing(barOfASet, with: " ") : lower)
        return rest.firstMatch(of: /\d+[.,]\d+|\d{3,}/) != nil
    }

    /// The `<facts>` item as JSON, keys sorted, for the request body.
    public var json: String {
        var item: [String: Any] = ["item": "h1", "title": title, "finish": finish, "dayLabel": dayLabel,
                                   "bests": bests, "rules": rulesLine, "numbers": numbers, "names": names]
        if let sinceLastDays {
            item["sinceLastDays"] = sinceLastDays
        }
        let data = (try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
