import Foundation
import TesseraCore

/// The live-workout set rules (S701 to S706, docs/research/fixtures/set-logger.md): while a workout is in front, a
/// number that could be a weight, a signed change or "at N" after a set never becomes a wrong set or a task.
extension TessGrammar {
    /// What the live guard decided: write this, or nothing (the model asks).
    struct Live {
        let parse: Parse?
    }

    /// S701 to S706 (docs/research/fixtures/set-logger.md): the live-workout set rules. Nil when the phrase isn't a
    /// set phrase (the other rules then read it); `Live(parse: nil)` when it is one the grammar mustn't guess.
    func parseLive(_ phrase: String, text: String, entry: ObjectRecord) -> Live? {
        let raw = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let model = Live(parse: nil)
        let exercise = store.linkedClass("exercise", of: entry)
        let kindOfKit = exercise.flatMap { store.equipmentKind(of: $0) }
        let dial = exercise.map { store.weightDial(for: $0) }
        // S706: load words.
        if let match = raw.firstMatch(of: /^(?:bodyweight|bw) (\d+)$/), let reps = Double(match.1) {
            guard kindOfKit == .bodyweight else { return model }
            return Live(parse: .set(entry: entry, weight: 0, reps: reps, kind: .working, phrase: .full))
        }
        if let match = raw.firstMatch(of: /^\+(\d+(?:\.\d+)?) ?(?:for|x) ?(\d+)$/), let added = Double(match.1),
           let reps = Double(match.2)
        {
            guard kindOfKit == .bodyweight else { return model }
            return Live(parse: snap(.set(entry: entry, weight: added, reps: reps, kind: .working, phrase: .full),
                                    entry: entry))
        }
        if let match = raw.firstMatch(of: /^bar ?(?:for|x) ?(\d+)$/), let reps = Double(match.1) {
            guard let bar = dial?.bar else { return model }
            return Live(parse: .set(entry: entry, weight: bar, reps: reps, kind: .working, phrase: .full))
        }
        // S702: a signed change alone, and "skip" (the screen's), write nothing.
        if raw.firstMatch(of: /^(?:[+-]|up |down )\d+(?:\.\d+)?(?: ?kg)?$/) != nil || raw == "skip" {
            return model
        }
        // S705: "fail at 6" is unclear (rep 6, or 6 reps).
        if raw.firstMatch(of: /^fail(?:ed)?(?: at)? \d+$/) != nil {
            return model
        }
        // S705: kind words; S704: "at N" / "@N" after a set is RPE.
        var core = text
        var kind: SetKind?
        if let match = core.firstMatch(of: /^(.+?) to failure$/) {
            core = String(match.1)
            kind = .failure
        }
        if let match = core.firstMatch(of: /^(?:warm ?-?up) (.+)$/) ?? core.firstMatch(of: /^(.+) (?:warm ?-?up)$/) {
            core = String(match.1)
            kind = .warmup
        }
        var rpe: Double?
        if let match = raw.firstMatch(of: /^(.+?) ?(?: at |@ ?)(\d+(?:\.\d+)?)$/),
           Self.isSetCore(Self.normalize(String(match.1)))
        {
            guard let value = Double(match.2), (5 ... 10).contains(value), (value * 2).rounded() == value * 2 else {
                // A set shape with an "at" that isn't an RPE: never a task here.
                return Self.looksLikeSet(String(match.1)) ? model : nil
            }
            rpe = value
            core = Self.normalize(String(match.1))
        }
        // S701: a bare number is reps only if it can't be a weight.
        if let number = Self.number(core) {
            guard let last = lastSet(in: entry), number.rounded() == number, (1 ... 50).contains(number),
                  !nearLastWeight(number, last: last.weight, dial: dial) else { return model }
        }
        guard let parsed = parseRelativeSet(core, entry: entry) else {
            return Self.looksLikeSet(core) || rpe != nil || kind != nil ? model : nil
        }
        guard case let .set(entry, weight, reps, setKind, how, unit, _, _) = parsed else { return Live(parse: parsed) }
        let withExtras = Parse.set(entry: entry, weight: weight, reps: reps, kind: kind ?? setKind, phrase: how,
                                   unit: unit, rpe: rpe)
        return Live(parse: snap(withExtras, entry: entry))
    }

    /// What can carry an RPE: a set shape, "same" and its kin, or bare reps ("call mum at 7" can't).
    static func isSetCore(_ text: String) -> Bool {
        looksLikeSet(text) || ["same", "same again", "again", "repeat", "one more"].contains(text)
            || number(text) != nil
    }

    /// "80 x 8", "100 for 5", "80x8": a set shape.
    static func looksLikeSet(_ text: String) -> Bool {
        text.firstMatch(of: /^\d+(?:\.\d+)?(?: ?kg| ?lb)?(?: ?x ?| for )\d+/) != nil
    }

    /// Within two loads of the last weight: "81" after 80 is a weight, not 81 reps.
    private func nearLastWeight(_ number: Double, last: Double, dial: WeightDial?) -> Bool {
        guard let dial, !dial.detents.isEmpty else { return abs(number - last) <= 5 }
        guard let lightest = dial.detents.first, let heaviest = dial.detents.last,
              number >= lightest - 0.001, number <= heaviest + 0.001 else { return false }
        let index = { (weight: Double) in dial.detents.firstIndex { $0 >= dial.snap(weight) - 0.001 } ?? 0 }
        return abs(index(number) - index(last)) <= 2
    }

    /// S703: a kilogram weight snaps to the nearest load the exercise's kit can make (a tie to the lighter); outside
    /// the kit's range, nil (the model asks). Pounds stay as said; "same" and bare reps reuse a logged weight.
    func snap(_ parse: Parse, entry: ObjectRecord) -> Parse? {
        guard case let .set(entry, weight, reps, kind, how, unit, rpe, _) = parse, unit == .kilograms,
              how == .full || how == .drop,
              let exercise = store.linkedClass("exercise", of: entry) else { return parse }
        let dial = store.weightDial(for: exercise)
        guard let lightest = dial.detents.first, let heaviest = dial.detents.last, weight > 0 || lightest == 0 else {
            return parse
        }
        guard weight >= lightest - 0.001, weight <= heaviest + 0.001 else { return nil }
        let snapped = dial.snap(weight)
        return .set(entry: entry, weight: snapped, reps: reps, kind: kind, phrase: how, unit: unit, rpe: rpe,
                    said: abs(snapped - weight) > 0.001 ? weight : nil)
    }
}
