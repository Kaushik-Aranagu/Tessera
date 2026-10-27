import CoreGraphics
@testable import Tessera
import Testing

/// Sheet 320: the door summary is a ledger. The layout math and a Bounds-style frame check.
struct DoorLedgerTests {
    private let rows: [DialDoor.Row] = [
        .init(name: "Bench press", value: "185", unit: "lb"),
        .init(name: "Overhead press", value: "115", unit: "lb"),
        .init(name: "Cable row", value: "12", unit: "reps"),
        .init(name: "Triceps to finish"),
    ]
    private let bounds = CGRect(x: 0, y: 0, width: DoorLedgerLayout.width, height: DoorLedgerLayout.height)

    private func frames(_ layout: DoorLedgerLayout) -> [[CGRect]] {
        layout.slots.map { [$0.name, $0.number, $0.unit].compactMap(\.self) }
    }

    @Test func unitIsHalfTheNumeralAndNeverUnderTen() {
        #expect(DoorLedgerLayout.unitSize(numberSize: 18) == 10)
        #expect(DoorLedgerLayout.unitSize(numberSize: 40) == 20)
        #expect(DoorLedgerLayout.unitSize(numberSize: 12) == 10)
    }

    @Test func numbersShareOneRightEdgeAndUnitsHangAfterIt() {
        let layout = DoorLedgerLayout.make(rows: rows, hasLabel: true, hasMore: true)
        let numbers = layout.slots.compactMap(\.number)
        #expect(numbers.count == 3)
        #expect(Set(numbers.map(\.maxX)).count == 1)
        #expect(numbers[0].maxX == layout.numberEdge)
        for slot in layout.slots {
            if let unit = slot.unit {
                #expect(unit.minX > layout.numberEdge)
            }
        }
    }

    @Test(arguments: [CGFloat(1), 1.3])
    func noTextCrossesAnotherRowsFrameOrTheBounds(scale: CGFloat) {
        let layout = DoorLedgerLayout.make(rows: rows, hasLabel: true, hasMore: true, scale: scale)
        let all = frames(layout)
        for rects in all {
            for rect in rects {
                #expect(bounds.contains(rect))
            }
        }
        for (first, left) in all.enumerated() {
            for (second, right) in all.enumerated() where first < second {
                for lhs in left {
                    for rhs in right {
                        #expect(!lhs.intersects(rhs))
                    }
                }
            }
            if let number = layout.slots[first].number {
                #expect(layout.slots[first].name.maxX <= number.minX)
            }
        }
        if let label = layout.label, let first = layout.slots.first {
            #expect(label.maxY <= first.name.minY)
        }
        if let more = layout.more, let last = layout.slots.last {
            #expect(last.name.maxY <= more.minY)
        }
    }

    @Test func slotsAreFixedByIndexAndANewNumberMovesNothing() {
        var changed = rows
        changed[0].value = "190"
        let before = DoorLedgerLayout.make(rows: rows, hasLabel: true, hasMore: true)
        let after = DoorLedgerLayout.make(rows: changed, hasLabel: true, hasMore: true)
        #expect(before.numberEdge == after.numberEdge)
        #expect(before.slots.map(\.name.minY) == after.slots.map(\.name.minY))
        #expect(before.slots[1].number == after.slots[1].number)
    }

    @Test func aLongNameIsDroppedWholeNeverCutWithAnEllipsis() {
        let long = DialDoor.Row(name: String(repeating: "Extraordinarily long name ", count: 4), value: "9", unit: "lb")
        let layout = DoorLedgerLayout.make(rows: [long] + rows, hasLabel: false, hasMore: false)
        #expect(layout.dropped >= 1)
        #expect(!layout.slots.contains { $0.id == long.id })
        for slot in layout.slots {
            #expect(slot.nameSize == 16 || slot.nameSize == 16 * DoorLedgerLayout.nameStep)
        }
    }

    @Test func largeTypeDropsRowsFromTheEndInsteadOfOverflowing() {
        let many = (0 ..< 6).map { DialDoor.Row(name: "Row \($0)", value: "\($0)", unit: "lb") }
        let normal = DoorLedgerLayout.make(rows: many, hasLabel: true, hasMore: true, scale: 1)
        let large = DoorLedgerLayout.make(rows: many, hasLabel: true, hasMore: true, scale: 1.3)
        #expect(large.slots.count <= normal.slots.count)
        #expect(large.dropped >= normal.dropped)
        #expect(large.slots.map(\.id) == Array(many.prefix(large.slots.count)).map(\.id))
        #expect(frames(large).flatMap(\.self).allSatisfy { bounds.contains($0) })
    }

    @Test func aSentenceRowKeepsTheWholeWidth() {
        let layout = DoorLedgerLayout.make(rows: [.init(name: "Nothing yet, open to start")],
                                           hasLabel: false, hasMore: false)
        #expect(layout.slots.count == 1)
        #expect(layout.slots[0].number == nil)
    }
}
