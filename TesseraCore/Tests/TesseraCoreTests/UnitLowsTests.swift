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
        #expect(ask.choice(for: "pounds") == .kilograms)
        #expect(ask.choice(for: "2 lb") == .kilograms)
        #expect(ask.choice(for: "sets") == .sets)
        let plus = TessSetCountAsk(entry: UUID(), count: 5, reps: 8, bodyweight: true, unit: .pounds)
        #expect(plus.kilogramsAnswer == "+5 lb")
        let kilo = TessSetCountAsk(entry: UUID(), count: 2, reps: 10, bodyweight: false, unit: .kilograms)
        #expect(kilo.line == "2 × 10: 2 sets, or 2 kg?")
    }
}
