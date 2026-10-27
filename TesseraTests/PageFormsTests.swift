import CoreGraphics
import SwiftUI
@testable import Tessera
import Testing

/// Sheet 293, page forms: ranked, even, columns, by time, and the shared switch move.
@MainActor
struct PageFormsTests {
    private let frame = CGRect(x: 0, y: 0, width: 354, height: 300)
    private let rows = [
        PageFormRow(name: "Stretch", detail: "9:00", minutes: 9 * 60),
        PageFormRow(name: "Lift", detail: "6:00", minutes: 18 * 60),
        PageFormRow(name: "Walk", detail: "done", minutes: nil, word: "done"),
        PageFormRow(name: "Water", detail: "", minutes: nil, word: "thirsty"),
        PageFormRow(name: "Read", detail: "10:30", minutes: 22 * 60 + 30),
    ]

    @Test func rankedWeightsRunFromOnePointSevenToZeroPointEightFour() {
        #expect(PageForms.rankedWeight(index: 0, count: 5) == 1.7)
        #expect(abs(PageForms.rankedWeight(index: 4, count: 5) - 0.84) < 0.0001)
        #expect(PageForms.rankedWeight(index: 1, count: 5) > PageForms.rankedWeight(index: 2, count: 5))
    }

    @Test func theFirstRankedRowIsBoldAndTheEvenFormsRowsAreAlike() {
        let ranked = PageForms.layout(rows: rows, form: .ranked, in: frame)
        #expect(ranked[0].bold)
        #expect(ranked[0].size > ranked[4].size)
        #expect(ranked.dropFirst().allSatisfy { !$0.bold })
        let even = PageForms.layout(rows: rows, form: .even, in: frame)
        #expect(Set(even.map(\.size)).count == 1)
        #expect(Set(even.map(\.name.height)).count == 1)
        #expect(even.allSatisfy { !$0.bold }, "the first keeps its colour but not its weight")
    }

    @Test func columnsAreNamesOnlyTwoAcrossFilledDownTheLeftFirst() {
        let places = PageForms.layout(rows: rows, form: .columns, in: frame)
        #expect(places.allSatisfy { $0.detail == nil && $0.time == nil })
        #expect(places.allSatisfy { $0.name.width == 171 && $0.name.height == 22 })
        #expect(places.filter { $0.name.minX == 0 }.count == 3, "3 and 2 for five rows")
        #expect(places.filter { $0.name.minX == 183 }.count == 2, "171 plus a 12 pt gap")
        #expect((places.map(\.name.maxY).max() ?? 0) <= 76)
        #expect(!PageForm.columns.showsDetails)
    }

    @Test func byTimePutsRowsWithNoTimeFirstThenTheNextTimeAfterNow() {
        let ordered = PageForms.byTime(rows, nowMinutes: 17 * 60 + 10)
        #expect(ordered.map(\.name) == ["Walk", "Water", "Lift", "Read", "Stretch"])
        // At 5:10 pm, 6:00 is tonight and comes before 9:00, which is tomorrow morning.
        #expect(PageForms.until(18 * 60, now: 17 * 60 + 10) == 50)
        #expect(PageForms.until(9 * 60, now: 17 * 60 + 10) == 950)
    }

    @Test func byTimeHasA52PointTimeColumnAndInk2ForRowsBehind() {
        let places = PageForms.layout(rows: rows, form: .byTime, in: frame, nowMinutes: 17 * 60 + 10)
        #expect(places.allSatisfy { $0.time?.width == 52 && $0.name.minX == 52 })
        #expect(places.filter(\.behind).map(\.id) == ["Walk", "Water"])
        #expect(places.filter(\.behind).allSatisfy { $0.size >= 13 })
    }

    @Test func byTimeIsOnlyOfferedWhereRowsHaveTimes() {
        #expect(PageForms.offersByTime(rows))
        #expect(!PageForms.offersByTime(rows.filter { $0.minutes == nil }))
    }

    @Test func everyFormKeepsEveryNameInsideThePageFrame() {
        for form in PageForm.allCases {
            let places = PageForms.layout(rows: rows, form: form, in: frame, nowMinutes: 0)
            #expect(places.count == rows.count)
            #expect(places.allSatisfy { frame.contains($0.name) }, "\(form)")
            let names = places.map(\.name)
            for (index, rect) in names.enumerated() {
                #expect(!names[(index + 1)...].contains { $0.intersects(rect) }, "\(form) rows never cross")
            }
        }
    }

    @Test func theUndoLineReadsPageByTimeUndo() {
        #expect(PageForm.byTime.undoLine(byTess: false) == "Page by time  Undo")
        #expect(PageForm.byTime.undoLine(byTess: true) == "Tess set the page by time  Undo")
        #expect(!PageForm.byTime.undoLine(byTess: false).hasSuffix("."))
    }

    @Test func handSwitchSetsTheFormAndTheUndoLineAndUndoRestores() async {
        let page = PageFormSwitch()
        await page.set(.byTime, byTess: false)
        #expect(page.form == .byTime)
        #expect(page.undoLine == "Page by time  Undo")
        #expect(!page.washing)
        page.undo()
        #expect(page.form == .ranked)
        #expect(page.undoLine == nil)
    }

    @Test func tessSwitchWashesThePageFirstThenTravels() async {
        let page = PageFormSwitch()
        let task = Task { await page.set(.even, byTess: true) }
        try? await Task.sleep(for: .milliseconds(150))
        #expect(page.washing, "the wash comes first")
        #expect(page.form == .ranked, "the names have not moved yet")
        await task.value
        #expect(page.form == .even)
        #expect(page.undoLine == "Tess set the page even  Undo")
    }

    @Test func anUnseenPageSwitchesWithNoWash() async {
        let page = PageFormSwitch()
        await page.set(.columns, byTess: true, isShown: false)
        #expect(page.form == .columns)
        #expect(!page.washing)
    }

    @Test func formsMapToTheirElementFormNames() {
        #expect(PageForm.columns.elementForm == "columns")
        #expect([PageForm.ranked, .even, .byTime].allSatisfy { $0.elementForm == "rows" })
    }
}
