import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Input hygiene H9 (docs/ai/harness/input-hygiene.md): every tuning number is a knob in one table, each move is
/// logged with who and why, and nothing but his own hand loosens a wall.
struct KnobTableTests {
    static let noteCap = Knob("test.noteCap", "Most characters of a note a leaf keeps", shipped: 280,
                              range: 40 ... 1000, guarded: .wall(tightensDown: true), whole: true)
    static let minScore = Knob("test.minScore", "Least score a match needs", shipped: 0.5, range: 0 ... 1,
                               guarded: .wall(tightensDown: false))

    @Test func theKnobsShipAsTheNumbersTheyReplaced() {
        #expect(BudgetTuner.faultRate == 0.3 && BudgetTuner.growth == 1.5 && BudgetTuner.floorStep == 0.05)
        #expect(BudgetTuner.lowestFloor == 0.3 && BudgetTuner.minimumRuns == 5)
        let table = KnobTable()
        for knob in Knob.all {
            #expect(table.value(knob) == knob.shipped, "\(knob.id)")
            #expect(knob.range.contains(knob.shipped), "\(knob.id)")
        }
        #expect(Set(Knob.all.map(\.id)).count == Knob.all.count)
    }

    @Test func aMoveIsCheckedAndLogged() throws {
        var table = KnobTable()
        let at = Date(timeIntervalSince1970: 1_800_000_000)
        try table.set(.budgetFaultRate, to: 0.4, by: .tuner, why: "fewer growths", at: at)
        #expect(table.value(.budgetFaultRate) == 0.4)
        #expect(table.log == [KnobChange(knob: "budget.faultRate", from: 0.3, to: 0.4, by: .tuner,
                                         why: "fewer growths", at: at)])
        #expect(throws: KnobTable.Refusal.outOfRange) { try table.set(.budgetFaultRate, to: 2, by: .owner, why: "") }
        #expect(throws: KnobTable.Refusal.notWhole) { try table.set(.budgetMinimumRuns, to: 4.5, by: .owner, why: "") }
        // Setting it where it is logs nothing; back to shipped clears the file entry but is logged.
        try table.set(.budgetFaultRate, to: 0.4, by: .tuner, why: "same")
        #expect(table.log.count == 1)
        try table.set(.budgetFaultRate, to: 0.3, by: .owner, why: "back")
        #expect(table.values.isEmpty && table.log.count == 2)
    }

    @Test func onlyHeLoosensAWall() throws {
        var table = KnobTable()
        // Lower is stricter for a cap: a tuner may lower it, never raise it.
        try table.set(Self.noteCap, to: 200, by: .tuner, why: "tighter")
        #expect(throws: KnobTable.Refusal.loosensAWall) {
            try table.set(Self.noteCap, to: 240, by: .tuner, why: "looser")
        }
        #expect(throws: KnobTable.Refusal.loosensAWall) {
            try table.set(Self.noteCap, to: 400, by: .developer, why: "looser")
        }
        try table.set(Self.noteCap, to: 400, by: .owner, why: "his call")
        #expect(table.int(Self.noteCap) == 400)
        // Higher is stricter for a threshold.
        #expect(throws: KnobTable.Refusal.loosensAWall) {
            try table.set(Self.minScore, to: 0.4, by: .tuner, why: "looser")
        }
        try table.set(Self.minScore, to: 0.7, by: .tuner, why: "tighter")
        #expect(table.value(Self.minScore) == 0.7)
    }

    @Test func aValueOutOfRangeInTheFileReadsAsShipped() throws {
        let file = #"{"values":{"budget.growth":9,"budget.faultRate":0.5},"log":[]}"#
        let table = try JSONDecoder().decode(KnobTable.self, from: Data(file.utf8))
        #expect(table.value(.budgetGrowth) == 1.5 && table.value(.budgetFaultRate) == 0.5)
    }

    @Test func resetLogsEveryMoveAndTheLogIsCapped() throws {
        var table = KnobTable()
        try table.set(.budgetGrowth, to: 2, by: .owner, why: "")
        try table.set(.budgetMinimumRuns, to: 8, by: .owner, why: "")
        table.reset(by: .developer)
        #expect(table.values.isEmpty)
        #expect(table.log.suffix(2).allSatisfy { $0.why == "reset" && $0.by == .developer })
        for index in 0 ... KnobTable.logLimit {
            try table.set(.budgetFaultRate, to: index.isMultiple(of: 2) ? 0.4 : 0.5, by: .tuner, why: "")
        }
        #expect(table.log.count == KnobTable.logLimit)
    }

    @Test func theTableSurvivesItsFile() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "knobs-\(UUID().uuidString).json")
        var table = KnobTable()
        try table.set(.budgetGrowth, to: 2, by: .owner, why: "keep")
        table.save(to: url)
        #expect(KnobTable.load(from: url) == table)
        #expect(KnobTable.load(from: nil) == KnobTable())
        try? FileManager.default.removeItem(at: url)
    }
}
