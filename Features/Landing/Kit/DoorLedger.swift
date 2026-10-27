import SwiftUI

// Sheet 320: the door summary is a ledger. Names on the left in the room's text face, numbers in one right-aligned
// column in the number face (tabular), units hung after the numbers at half the numeral's size (never under 10 pt,
// Figtree 400). Fixed slots: nothing wraps, nothing shifts on a live change, no "...". When a name does not fit it
// steps down to 0.9, and when it still does not fit the row is dropped.

extension DialDoor {
    /// One ledger row of a door: a name, a number and its unit. A row with no value stays a plain sentence.
    struct Row: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        var value: String?
        var unit: String?

        init(id: String? = nil, name: String, value: String? = nil, unit: String? = nil) {
            self.id = id ?? name
            self.name = name
            self.value = value
            self.unit = unit
        }
    }
}

/// The ledger's layout math, apart from any view so the tests can check every frame. All frames are in the
/// summary's own space (192 x 116, origin top left).
struct DoorLedgerLayout: Equatable, Sendable {
    static let width: CGFloat = 192
    static let height: CGFloat = 116
    static let labelHeight: CGFloat = 20
    static let moreHeight: CGFloat = 16
    /// Row pitch at the default size (16/26).
    static let pitch: CGFloat = 26
    static let nameSize: CGFloat = 16
    static let numberSize: CGFloat = 18
    static let labelSize: CGFloat = 13
    static let moreSize: CGFloat = 12
    static let unitFloor: CGFloat = 10
    static let nameStep: CGFloat = 0.9
    /// Space between a name and the number column, and between a number and its unit.
    static let nameGap: CGFloat = 8
    static let unitGap: CGFloat = 3
    /// The unit slot at the default size; wider only when a unit really is wider, so the column holds still.
    static let unitSlot: CGFloat = 30
    /// Dynamic Type grows the ledger no more than this; past it rows drop out instead of the text growing.
    static let maxScale: CGFloat = 1.3

    struct Slot: Equatable, Sendable {
        var id: String
        var name: CGRect
        var nameSize: CGFloat
        var number: CGRect?
        var unit: CGRect?
    }

    var scale: CGFloat
    var label: CGRect?
    var slots: [Slot]
    var more: CGRect?
    /// Rows left out because they would not fit whole.
    var dropped: Int
    /// The x of the number column's right edge (units hang after it).
    var numberEdge: CGFloat

    /// The unit's size: half the numeral's, never under 10 pt.
    static func unitSize(numberSize: CGFloat) -> CGFloat {
        max(unitFloor, (numberSize * 0.5).rounded(.up))
    }

    static func make(rows: [DialDoor.Row], hasLabel: Bool, hasMore: Bool, scale rawScale: CGFloat = 1) -> Self {
        let scale = min(max(rawScale, 1), maxScale)
        let top = hasLabel ? labelHeight * scale : 0
        let foot = hasMore ? moreHeight * scale : 0
        let pitch = (Self.pitch * scale).rounded(.up)
        let capacity = max(0, Int(((height - top - foot) / pitch).rounded(.down)))

        let numberSize = Self.numberSize * scale
        let unitSize = unitSize(numberSize: numberSize)
        let anyUnit = rows.contains { $0.unit != nil }
        let widestUnit = rows.compactMap(\.unit).map { measure($0, size: unitSize, family: .text) }.max() ?? 0
        let unitColumn = anyUnit ? max(unitSlot * scale, widestUnit) + unitGap : 0
        let edge = width - unitColumn
        let widestNumber = rows.compactMap(\.value).map { measure($0, size: numberSize, family: .number) }.max() ?? 0
        let numberLeft = edge - widestNumber

        var slots: [Slot] = []
        var dropped = 0
        for row in rows {
            guard slots.count < capacity else {
                dropped += 1
                continue
            }
            let y = top + CGFloat(slots.count) * pitch
            guard let slot = place(row, y: y, pitch: pitch, scale: scale, edge: edge,
                                   numberLeft: numberLeft, unitSize: unitSize, numberSize: numberSize)
            else {
                dropped += 1
                continue
            }
            slots.append(slot)
        }
        return Self(
            scale: scale,
            label: hasLabel ? CGRect(x: 0, y: 0, width: width, height: top) : nil,
            slots: slots,
            more: hasMore ? CGRect(x: 0, y: height - foot, width: width, height: foot) : nil,
            dropped: dropped,
            numberEdge: edge
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func place(_ row: DialDoor.Row, y: CGFloat, pitch: CGFloat, scale: CGFloat, edge: CGFloat,
                              numberLeft: CGFloat, unitSize: CGFloat, numberSize: CGFloat) -> Slot?
    {
        // A sentence row (no number) has the whole width; a ledger row stops short of the number column.
        let available = (row.value == nil ? width : numberLeft - nameGap)
        var size = nameSize * scale
        var nameWidth = measure(row.name, size: size, family: .text)
        if nameWidth > available {
            size *= nameStep
            nameWidth = measure(row.name, size: size, family: .text)
        }
        guard nameWidth <= available else { return nil }
        let name = CGRect(x: 0, y: y, width: nameWidth, height: pitch)
        var number: CGRect?
        var unit: CGRect?
        if let value = row.value {
            let valueWidth = measure(value, size: numberSize, family: .number)
            number = CGRect(x: edge - valueWidth, y: y, width: valueWidth, height: pitch)
            if let text = row.unit {
                let unitWidth = measure(text, size: unitSize, family: .text)
                unit = CGRect(x: edge + unitGap, y: y, width: unitWidth, height: pitch)
            }
        }
        return Slot(id: row.id, name: name, nameSize: size, number: number, unit: unit)
    }

    enum Family { case text, number }

    /// Measured the way the ledger draws (Figtree text, Outfit tabular numerals), with 3% air so a run never
    /// measures narrower than it draws.
    static func measure(_ text: String, size: CGFloat, family: Family) -> CGFloat {
        let font = switch family {
        case .text:
            UIFont(name: "Figtree-Variable", size: size) ?? .systemFont(ofSize: size)
        case .number:
            UIFont(name: "Outfit", size: size) ?? .monospacedDigitSystemFont(ofSize: size, weight: .regular)
        }
        return ceil((text as NSString).size(withAttributes: [.font: font]).width * 1.03)
    }
}

/// The ledger of one door: a label (what the door holds), rows, and a quiet last line (what opening it adds).
/// `DoorSummary` draws it when the door carries rows.
struct DoorLedger: View {
    var label: String?
    var rows: [DialDoor.Row]
    var more: String?

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var layout: DoorLedgerLayout {
        .make(rows: rows, hasLabel: label != nil, hasMore: more != nil, scale: Self.scale(typeSize))
    }

    /// Dynamic Type as a multiplier of the default size.
    static func scale(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall, .small, .medium, .large: 1
        case .xLarge: 1.1
        case .xxLarge: 1.2
        default: 1.3
        }
    }

    var body: some View {
        let layout = layout
        ZStack(alignment: .topLeading) {
            if let label, let frame = layout.label {
                Text(label)
                    .font(.custom("Figtree", size: DoorLedgerLayout.labelSize * layout.scale, relativeTo: .footnote))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1).fixedSize()
                    .frame(width: frame.width, height: frame.height, alignment: .leading)
            }
            ForEach(layout.slots, id: \.id) { slot in
                rowView(slot, scale: layout.scale)
                    .frame(width: DoorLedgerLayout.width, height: slot.name.height, alignment: .topLeading)
                    .offset(y: slot.name.minY)
                    .transition(.opacity)
            }
            if let more, let frame = layout.more {
                Text(more)
                    .font(.custom("Figtree", size: DoorLedgerLayout.moreSize * layout.scale, relativeTo: .caption))
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .lineLimit(1).fixedSize()
                    .frame(width: frame.width, height: frame.height, alignment: .leading)
                    .offset(y: frame.minY)
            }
        }
        .frame(width: DoorLedgerLayout.width, height: DoorLedgerLayout.height, alignment: .topLeading)
        .tesseraAnimation(Theme.Motion.firm, value: layout)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func rowView(_ slot: DoorLedgerLayout.Slot, scale: CGFloat) -> some View {
        let row = rows.first { $0.id == slot.id }
        return ZStack(alignment: .topLeading) {
            Text(row?.name ?? "")
                .font(.custom("Figtree", size: slot.nameSize, relativeTo: .body))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1).fixedSize()
                .frame(height: slot.name.height, alignment: .leading)
            if let number = slot.number, let value = row?.value {
                Text(value)
                    .font(.custom("Outfit", size: DoorLedgerLayout.numberSize * scale, relativeTo: .body))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .lineLimit(1).fixedSize()
                    .frame(width: number.width, height: number.height, alignment: .trailing)
                    .offset(x: number.minX)
            }
            if let unit = slot.unit, let text = row?.unit {
                Text(text)
                    .font(.custom(
                        "Figtree",
                        size: DoorLedgerLayout.unitSize(numberSize: DoorLedgerLayout.numberSize * scale),
                        relativeTo: .caption2
                    ).weight(.regular))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1).fixedSize()
                    .frame(width: unit.width, height: unit.height, alignment: .leading)
                    .offset(x: unit.minX)
            }
        }
    }

    private var spoken: String {
        let lines = rows.map { row in
            [row.name, row.value, row.unit].compactMap(\.self).joined(separator: " ")
        }
        return ([label] + lines + [more]).compactMap(\.self).joined(separator: ", ")
    }
}

#Preview("Door ledger") {
    VStack(alignment: .leading, spacing: 24) {
        DoorLedger(
            label: "Push A, 4 lifts",
            rows: [
                .init(name: "Bench press", value: "185", unit: "lb"),
                .init(name: "Overhead press", value: "115", unit: "lb"),
                .init(name: "Cable row", value: "12", unit: "reps"),
                .init(name: "Triceps, to finish"),
            ],
            more: "Then triceps, about 45 min in all"
        )
    }
    .padding(24)
}
