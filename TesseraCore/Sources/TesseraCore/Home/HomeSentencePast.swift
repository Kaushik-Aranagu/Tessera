import Foundation

/// The same sentence about a day that is over (Together, sheet 139): built only from the Day log's own lines, which
/// come from what was done. Money is words only ("Rent paid."), never an amount; a calorie, health or body line is
/// not here at all (the Day log keeps those apart); a private workout or recipe reads as such.
@MainActor
public extension HomeSentence {
    static func past(engine: ActionEngine, on day: Date, calendar: Calendar = .current, now: Date = .now) -> [Clause] {
        let store = engine.store, classes = engine.classes
        let lines = DayStory.lines(engine: engine, on: day, calendar: calendar, now: now)
            .filter { $0.kind == .finished && $0.time != nil }
        let clauses = lines.compactMap { line -> Clause? in
            let first = line.objectIDs.first.flatMap { store.object(id: $0) }
            let key = first?.classDef.flatMap { classDef in
                SystemCatalog.Key.allCases.first { classes[$0]?.id == classDef.id }
            }
            var app: AppID?
            var text = line.text
            switch key {
            case .workout, .exerciseEntry, .set: app = .training
            case .cook, .recipe: app = .kitchen
            case .spend:
                app = .money
                text = spendWords(line.objectIDs.compactMap { store.object(id: $0) }, store: store)
            case .note: app = .notes
            case .listItem, .list: app = .lists
            default: break
            }
            let sentence = text.hasSuffix(".") ? text : text + "."
            return Clause(app: app, sentence: LandingSentence(text: sentence, key: nil),
                          opens: first.map { .object($0.id) } ?? .app(app ?? .notes), time: line.time)
        }
        return Array(clauses.sorted { ($0.time ?? .distantPast) < ($1.time ?? .distantPast) }.prefix(maxClauses))
    }

    /// "Rent paid" for one spend with a word, "Money logged" otherwise; never the amount or the currency.
    private static func spendWords(_ spends: [ObjectRecord], store: ObjectStore) -> String {
        guard spends.count == 1, let spend = spends.first else { return "Money logged" }
        let note = (store.value("note", of: spend)?.stringValue ?? "").trimmingCharacters(in: .whitespaces)
        guard let word = note.split(separator: " ").first.map(String.init), !word.isEmpty else { return "Money logged" }
        if ObjectPrivacy.isPrivateWord(note, in: store) {
            return "Private spend paid"
        }
        return word.prefix(1).uppercased() + word.dropFirst().lowercased() + " paid"
    }
}
