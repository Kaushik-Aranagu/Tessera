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
    func parseLive(_ phrase: String, text _: String, entry: ObjectRecord) -> Live? {
        // Dictation ends sentences: "Same at 9." (QA Q1).
        let raw = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacing(/[.!]+$/, with: "").replacing(/,/, with: " ")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
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
        // S704: "at N" / "@N" after a set is RPE (read first, so "to failure at 9" works; QA Q5). S705: kind words.
        var core = Self.normalize(raw)
        var rpe: Double?
        if let match = core.firstMatch(of: /^(.+?) ?(?: at |@ ?)(\d+(?:\.\d+)?)$/),
           Self.isSetCore(String(match.1))
        {
            // A set with an "at" that isn't an RPE ("same at 11", "8 at 4"): never a task here (QA Q3).
            guard let value = Double(match.2), (5 ... 10).contains(value), (value * 2).rounded() == value * 2 else {
                return model
            }
            rpe = value
            core = String(match.1)
        }
        var kind: SetKind?
        if let match = core.firstMatch(of: /^(.+?) to failure$/) {
            core = String(match.1)
            kind = .failure
        }
        if let match = core.firstMatch(of: /^(?:warm ?-?up) (.+)$/) ?? core.firstMatch(of: /^(.+) (?:warm ?-?up)$/) {
            core = String(match.1)
            kind = .warmup
        }
        // S701: a bare number is reps only if it can't be a weight. "N reps" says so: only the range applies.
        if let number = Self.number(core) {
            let saidReps = core.hasSuffix(" reps")
            guard let last = lastSet(in: entry), number.rounded() == number, (1 ... 50).contains(number),
                  saidReps ||
                  // On a bodyweight move the last "weight" is 0 added: nothing to confuse reps with (QA Q4).
                  kindOfKit == .bodyweight && last.weight == 0
                  || !nearLastWeight(number, last: last.weight, dial: dial) else { return model }
        }
        guard let parsed = parseRelativeSet(core, entry: entry) else {
            return Self.looksLikeSet(core) || rpe != nil || kind != nil ? model : nil
        }
        guard case let .set(entry, weight, reps, setKind, how, unit, _, _) = parsed else { return Live(parse: parsed) }
        // "3x10" with a light kit is 3 sets of 10, not 3 kg (a small number the kit can't load exactly): ask.
        if how == .full, unit == .kilograms, weight <= 10, let dial, !dial.detents.isEmpty,
           !dial.detents.contains(where: { abs($0 - weight) < 0.001 })
        {
            return model
        }
        let withExtras = Parse.set(entry: entry, weight: weight, reps: reps, kind: kind ?? setKind, phrase: how,
                                   unit: unit, rpe: rpe)
        return Live(parse: snap(withExtras, entry: entry))
    }

    /// What can carry an RPE: a set shape, "same" and its kin, or bare reps ("call mum at 7" can't).
    static func isSetCore(_ text: String) -> Bool {
        looksLikeSet(text) || ["same", "same again", "again", "repeat", "one more"].contains(text)
            || number(text) != nil || text.hasSuffix(" to failure") && looksLikeSet(text)
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
        // Below the lightest load ("0 x 8" on a barbell, QA Q6) or above the heaviest: the model asks.
        guard let lightest = dial.detents.first, let heaviest = dial.detents.last else { return parse }
        guard weight >= lightest - 0.001, weight <= heaviest + 0.001 else { return nil }
        let snapped = dial.snap(weight)
        return .set(entry: entry, weight: snapped, reps: reps, kind: kind, phrase: how, unit: unit, rpe: rpe,
                    said: abs(snapped - weight) > 0.001 ? weight : nil)
    }
}
