import CoreGraphics
import Foundation
@testable import Tessera
import Testing

/// Sheet 284: the Page's rank weights, title sizes, the item page's frames, the Deck's sets, and the page elements
/// passing the conformance suite.
struct RankedPageTests {
    @Test(arguments: 1 ... 7)
    func rowsFillTheBlockExactlyAndTheFirstIsBiggest(count: Int) {
        let heights = RankedLayout.heights(count: count, total: 364)
        #expect(heights.count == count)
        #expect(abs(heights.reduce(0, +) - 364) < 0.001)
        #expect(heights == heights.sorted(by: >), "no row is taller than the one above it")
        if count > 1 {
            #expect(Set(heights.map { ($0 * 100).rounded() }).count == count, "no two rows are equal")
        }
    }

    @Test func sevenRowsFollowTheWeights() {
        let heights = RankedLayout.heights(count: 7, total: 364)
        let sum = RankedLayout.weights.reduce(0, +)
        #expect(abs(heights[0] - 364 * 1.7 / sum) < 0.001)
        #expect(abs(heights[6] - 364 * 0.84 / sum) < 0.001)
        #expect(heights[0] > 79 && heights[0] < 81)
    }

    @Test func titleSizeIsAThirtySixthPercentOfTheRowClampedTo17To34() {
        #expect(abs(RankedLayout.titleSize(rowHeight: 80) - 28.8) < 0.001)
        #expect(RankedLayout.titleSize(rowHeight: 20) == 17)
        #expect(RankedLayout.titleSize(rowHeight: 364) == 34)
    }

    @Test func aSubLineNeedsARowTallerThanFortyPoints() {
        let rows = RankedLayout.rows(count: 7, in: CGRect(x: 24, y: 412, width: 354, height: 364))
        #expect(rows[0].showsSub)
        #expect(!rows[6].showsSub, "39.5 pt is not taller than 40")
        let dropped = RankedLayout.rows(count: 7, in: CGRect(x: 24, y: 412, width: 354, height: 364), dropSubs: true)
        #expect(!dropped.contains { $0.showsSub }, "accessibility sizes drop sub lines first")
    }

    @Test func unitsAreHalfTheTitleButNeverUnderTenPoints() {
        for row in RankedLayout.rows(count: 7, in: CGRect(x: 0, y: 0, width: 354, height: 364)) {
            #expect(row.unitSize >= 10)
            #expect(abs(row.valueSize - row.titleSize * 0.82) < 0.001)
            #expect(row.titleSize * 1.25 <= row.rect.height, "a row holds its title")
        }
    }

    @Test func rowsNeverOverlapAtAnyDynamicTypeSize() {
        for scale in [0.86, 1, 1.21, 1.32] as [CGFloat] {
            let rows = RankedLayout.rows(count: 7, in: CGRect(x: 0, y: 0, width: 354, height: 300), scale: scale)
            for (above, below) in zip(rows, rows.dropFirst()) {
                #expect(above.rect.maxY <= below.rect.minY + 0.001)
            }
            #expect(rows.allSatisfy { $0.titleSize * 1.25 <= $0.rect.height })
        }
    }

    @Test func moreThanSevenRowsKeepSixAndAMoreRow() {
        let rows = (0 ..< 12).map { RankedRow(id: "r\($0)", title: "Lift \($0)") }
        let shown = RankedLayout.shown(rows, moreID: "more:library")
        #expect(shown.count == 7)
        #expect(shown.last?.id == "more:library")
        #expect(shown.last?.title == "6 more")
        #expect(RankedLayout.shown(rows, moreID: nil).count == 7)
        #expect(RankedLayout.shown(Array(rows.prefix(7)), moreID: "more:library").count == 7)
    }

    @Test func rowsSettleInAtThirtyEightHundredthsAndFortyFiveMillisecondsApart() {
        #expect(RankedLayout.rowSeconds == 0.38)
        #expect(RankedLayout.stagger(merging: false) == 0.045)
        // While a layout merges the stagger tightens so the last row lands with the change's clock.
        let last = 0.47 + 6 * RankedLayout.stagger(merging: true) + RankedLayout.rowSeconds
        #expect(last <= ShellTiming.whole)
    }

    @Test func theItemPageSplitsTheBlockIntoFactsAndBody() {
        let block = CGRect(x: 24, y: 412, width: 354, height: 364)
        #expect(ItemPageLayout.factsFrame(in: block) == CGRect(x: 24, y: 412, width: 354, height: 64))
        #expect(ItemPageLayout.bodyFrame(in: block) == CGRect(x: 24, y: 484, width: 354, height: 292))
        let columns = ItemPageLayout.columns(in: ItemPageLayout.factsFrame(in: block))
        #expect(abs(columns[0].width / columns[1].width - 1.2) < 0.001)
        #expect(columns[1].width == columns[2].width)
        #expect(abs(columns.map(\.width).reduce(0, +) - 354) < 0.001)
    }

    @Test func thePageBlockIsTheShellsPageRect() {
        #expect(PageFrames.block == CGRect(x: 24, y: 412, width: 354, height: 364))
        #expect(PageFrames.block == ShellLayout.mergedFrame(.page))
    }

    @Test func theSetsBodyShowsWarmUpsDoneNextAndTodo() {
        let lines = DeckSets.lines(last: [DeckSets.Entry(weight: 80, reps: 5), DeckSets.Entry(weight: 80, reps: 5),
                                          DeckSets.Entry(weight: 80, reps: 4)],
                                   today: [DeckSets.Entry(weight: 80, reps: 5)], planned: 3)
        #expect(lines.map(\.label) == ["Warm-up", "Warm-up", "Set 1", "Set 2", "Set 3"])
        #expect(lines.map(\.state) == [.done, .done, .done, .next, .todo])
        #expect(lines.first?.weight == DeckSets.weightText(40).number)
        #expect(lines[4].reps == "4", "a set shows what last time did at that place")
    }

    @Test func nothingLoggedMakesTheFirstLineNext() {
        let lines = DeckSets.lines(last: [DeckSets.Entry(weight: 60, reps: 8)], today: [], planned: 2)
        #expect(lines.first?.state == .next)
        #expect(lines.filter { $0.state == .next }.count == 1)
        #expect(DeckSets.lines(last: [], today: [], planned: 3).isEmpty)
    }

    @Test func bodyweightSetsReadBW() {
        let lines = DeckSets.lines(last: [DeckSets.Entry(weight: 0, reps: 12)], today: [], planned: 1)
        #expect(lines.map(\.weight) == ["BW"])
        #expect(lines.map(\.label) == ["Set 1"], "no warm-up ramp from a bodyweight lift")
    }

    @Test func lastTimeSaysOneWeightOnce() {
        let same = [DeckSets.Entry(weight: 80, reps: 5), DeckSets.Entry(weight: 80, reps: 5),
                    DeckSets.Entry(weight: 80, reps: 4)]
        #expect(DeckSets.lastTime(same).hasSuffix("5, 5, 4"))
        #expect(DeckSets.lastTime(same).components(separatedBy: "\u{00D7}").count == 2)
        #expect(DeckSets.lastTime([]) == "")
    }

    @Test func theSiblingsWindowKeepsTheCurrentRow() {
        let rows = (0 ..< 12).map { RankedRow(id: "r\($0)", title: "Lift \($0)") }
        for current in ["r0", "r6", "r11"] {
            let body = SiblingsBody.make(rows: rows, current: current)
            #expect(body.rows.count == 7)
            #expect(body.rows.contains { $0.id == current })
        }
    }

    @Test func theStateColoursAreSheet241sOnly() {
        #expect(RankState.none.color == nil)
        for state in [RankState.done, .late, .best, .planned] {
            #expect(state.color != nil)
        }
    }

    @Test func thePageElementsAreRegisteredAndPassTheSuite() {
        let elements: [any TesseraElement] = [RankedPageElement(), ItemPageElement.sets, ItemPageElement.siblings]
        for element in elements {
            #expect(ElementRegistry.contains(element.spec.name), "\(element.spec.name) is registered")
            let results = ElementConformance.run(spec: element.spec)
            let blocks = ElementConformance.blocks(results)
            #expect(blocks.isEmpty, "\(ElementConformance.report(blocks).joined(separator: "\n"))")
        }
    }
}
