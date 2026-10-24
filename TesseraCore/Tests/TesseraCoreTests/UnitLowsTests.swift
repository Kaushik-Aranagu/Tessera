import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Old lows: "Up ... lb" deltas round to the unit's step, and Tess's set-count ask speaks in his weight unit.
@MainActor
struct UnitLowsTests {
    @Test func raisesRoundToTheUnitsStep() {
        #expect(MassUnit.kilograms.text(kilogramsDelta: 2.5) == "2.5")
        #expect(MassUnit.pounds.text(kilogramsDelta: 2.5) == "5.5")
        #expect(MassUnit.pounds.text(kilogramsDelta: 2.268) == "5")
        #expect(MassUnit.pounds.text(kilogramsDelta: 1.25) == "3")
        #expect(MassUnit.kilograms.text(kilogramsDelta: 1.2) == "1")
    }

    @Test func theSetCountAskSpeaksInPoundsAndHearsThem() {
        let ask = TessSetCountAsk(entry: UUID(), count: 2, reps: 10, bodyweight: false, unit: .pounds)
        #expect(ask.line == "2 × 10: 2 sets, or 2 lb?")
        #expect(ask.choice(for: "pounds") == .pounds)
        #expect(ask.choice(for: "2 lb") == .pounds)
        #expect(ask.choice(for: "2 kg") == .kilograms)
        #expect(ask.weightChoice == .pounds)
        #expect(ask.choice(for: "sets") == .sets)
        let plus = TessSetCountAsk(entry: UUID(), count: 5, reps: 8, bodyweight: true, unit: .pounds)
        #expect(plus.kilogramsAnswer == "+5 lb")
        let kilo = TessSetCountAsk(entry: UUID(), count: 2, reps: 10, bodyweight: false, unit: .kilograms)
        #expect(kilo.line == "2 × 10: 2 sets, or 2 kg?")
    }

    @Test func aPoundsAnswerStoresTheKilogramsOfThosePounds() async throws {
        let rig = try SetCountAskTests()
        let entry = try rig.entry(.db)
        // 5 is under half the 24 kg last set and 6 or less: she asks.
        let asked = await rig.tess.capture("5x10", context: rig.context(entry))
        #expect(asked.line == "5 × 10: 5 sets, or 5 kg?")
        let answered = await rig.tess.capture("5 lb", context: rig.context(entry))
        #expect(answered.records.count == 1)
        let stored = try #require(entry.orderedChildren.last.flatMap { rig.store.number("weight", of: $0) })
        #expect(abs(stored - 5 / MassUnit.poundsPerKilogram) < 0.001, "stored \(stored) kg")
        // The kilograms answer to the same kind of ask still stores the kilograms (dumbbells, 2 kg).
        let again = try SetCountAskTests()
        let other = try again.entry(.db)
        _ = await again.tess.capture("2x10", context: again.context(other))
        let kilos = again.tess.answer(.kilograms, context: again.context(other))
        #expect(kilos.records.count == 1)
        #expect(other.orderedChildren.last.flatMap { again.store.number("weight", of: $0) } == 2)
    }

    @Test func unitlessSetsDefaultToHisUnitAndAnEchoKeepsTheUnitHeSaid() throws {
        let rig = try SetCountAskTests()
        let entry = try rig.entry(.bar)
        TessUnits.weight = .pounds
        defer { TessUnits.weight = .kilograms }
        guard case let .set(_, weight, _, _, _, unit, _, _)? = rig.tess.grammar.parseRelativeSet(
            "100 x 5",
            entry: entry
        )
        else { Issue.record("not a set"); return }
        #expect(unit == .pounds && abs(weight - 100 / MassUnit.poundsPerKilogram) < 0.001)
        guard case let .set(_, said, _, _, _, saidUnit, _, _)? = rig.tess.grammar.parseRelativeSet(
            "100 kg x 5",
            entry: entry
        )
        else { Issue.record("not a set"); return }
        #expect(saidUnit == .kilograms && said == 100)
    }

    @Test func aTinyRaiseIsAtLeastOneStep() {
        #expect(MassUnit.pounds.text(kilogramsDelta: 0.05) == "0.5")
        #expect(MassUnit.kilograms.text(kilogramsDelta: 0.05) == "0.5")
    }

    @Test func poundsAreRangeCheckedLikeKilogramsSoZeroOnABarbellIsQuestioned() async throws {
        let rig = try SetCountAskTests()
        let entry = try rig.entry(.bar)
        // "0 lb x 8" on a barbell is under the bar: nothing is written, the same as "0 kg x 8".
        let before = entry.orderedChildren.count
        let zero = await rig.tess.capture("0 lb x 8", context: rig.context(entry))
        #expect(zero.records.isEmpty && entry.orderedChildren.count == before)
        let zeroKg = await rig.tess.capture("0 kg x 8", context: rig.context(entry))
        #expect(zeroKg.records.isEmpty)
        // A real pound weight is logged as said, not snapped: 135 lb is 61.2 kg, and 61.2 is stored.
        let ok = await rig.tess.capture("135 lb x 5", context: rig.context(entry))
        #expect(ok.records.count == 1)
        let stored = try #require(entry.orderedChildren.last.flatMap { rig.store.number("weight", of: $0) })
        #expect(abs(stored - 135 / MassUnit.poundsPerKilogram) < 0.01, "stored \(stored)")
    }
}
