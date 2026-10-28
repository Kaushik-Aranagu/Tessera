import SwiftUI

// The body kinds of sheet 284, one per item type, all in the same 354 x 292 block. `sets` (the Deck) and `siblings`
// (any row without its own page yet) come first; the other rooms add theirs next to these (see `ItemBody`).

// MARK: - sets (Deck)

enum SetState: String, Equatable, Sendable {
    /// Logged: green.
    case done
    /// The set to do next: the room colour.
    case next
    /// Still to come: ink 2 for the label, ink for the numbers.
    case todo
}

/// One line of the sets body: "Warm-up 40 kg, 8".
struct SetLine: Identifiable, Equatable, Sendable {
    let id: String
    var label: String
    var weight: String
    var unit: String
    var reps: String
    var state: SetState
}

/// Warm-up and sets, done in green, the next set in the room colour; last time underneath (sheet 284 board: 44 pt
/// lines, the label small on the left, the load in Outfit Light on the right, then a 15 pt note 12 pt below).
struct SetsBody: ItemBodyKind {
    static let name = "sets"

    var lines: [SetLine]
    /// "80 kg x 5, 5, 4": the last session, under the sets. Empty when there is none.
    var lastTime = ""
    var empty = "No sets yet"

    /// The lines the body can hold: at most eight.
    static let maxLines = 8
    static let rowMax: CGFloat = 44
    static let noteGap: CGFloat = 12
    static let noteHeight: CGFloat = 22
    static let labelWidth: CGFloat = 96
    static let numberSize: CGFloat = 20
    static let labelSize: CGFloat = 14
    static let notePrefix = "Last time: "

    var shown: [SetLine] {
        Array(lines.prefix(Self.maxLines))
    }

    func rowHeight(in frame: CGRect) -> CGFloat {
        let note = lastTime.isEmpty ? 0 : Self.noteGap + Self.noteHeight
        let area = max(0, frame.height - note)
        return min(Self.rowMax, area / CGFloat(max(shown.count, 1)))
    }

    func render(in frame: CGRect, scale: CGFloat) -> ElementRender {
        var render = ElementRender()
        let height = rowHeight(in: frame)
        for (index, line) in shown.enumerated() {
            let top = frame.minY + CGFloat(index) * height
            let ink = Self.ink(line.state)
            let label = Self.labelSize * scale
            let number = min(Self.numberSize * scale, height * 0.62)
            let unitSize = max(10, number * 0.41)
            let numberWidth = DoorText.width(line.weight, size: number, bold: false)
            let unitWidth = line.unit.isEmpty ? 0 : DoorText.width(line.unit, size: unitSize, bold: false) + 3
            let repsText = ", \(line.reps)"
            let repsWidth = DoorText.width(repsText, size: number, bold: false)
            let load = numberWidth + unitWidth + repsWidth
            let labelWidth = min(frame.width - load - 12, Self.labelWidth * max(scale, 1))
            render.runs.append(ElementRun(text: line.label, rect: CGRect(x: frame.minX, y: top + 2, width: labelWidth,
                                                                         height: height - 4),
                                          size: label, bold: line.state == .next,
                                          ink: line.state == .todo ? .ink2 : ink))
            if DoorText.width(line.label, size: label, bold: true) > labelWidth {
                render.clipped = true
            }
            var x = frame.maxX - load
            render.runs.append(ElementRun(text: line.weight, rect: CGRect(x: x, y: top + 2, width: numberWidth,
                                                                          height: height - 4),
                                          size: number, ink: ink))
            x += numberWidth
            if unitWidth > 0 {
                render.runs.append(ElementRun(text: line.unit, rect: CGRect(x: x + 3, y: top + 2,
                                                                            width: unitWidth - 3, height: height - 4),
                                              size: unitSize, ink: .ink, isUnit: true))
                x += unitWidth
            }
            render.runs.append(ElementRun(text: repsText, rect: CGRect(x: x, y: top + 2, width: frame.maxX - x,
                                                                       height: height - 4),
                                          size: number, ink: ink))
            render.shown.append(line.label)
        }
        render.lost = lines.count - shown.count
        if !lastTime.isEmpty {
            let top = frame.minY + CGFloat(shown.count) * height + Self.noteGap
            let note = Self.notePrefix + lastTime
            render.runs.append(ElementRun(text: note, rect: CGRect(x: frame.minX, y: top, width: frame.width,
                                                                   height: Self.noteHeight),
                                          size: 15, ink: .ink2))
            if DoorText.width(note, size: 15, bold: false) > frame.width {
                render.clipped = true
            }
        }
        return render
    }

    static func ink(_ state: SetState) -> ElementInk {
        switch state {
        case .done: .done
        case .next: .room
        case .todo: .ink
        }
    }
}

// MARK: - siblings (any row without its own page yet)

/// The door's rows with this one in the room colour. Tapping another opens it.
struct SiblingsBody: ItemBodyKind {
    static let name = "siblings"

    var rows: [LevelRow]
    var current: String

    static let maxRows = RankedLayout.maxRows
    static let rowMax: CGFloat = 52
    static let titleSize: CGFloat = 20

    /// At most seven rows, the current one always among them, centred where it can be.
    static func make(rows: [LevelRow], current: String) -> Self {
        guard rows.count > maxRows, let place = rows.firstIndex(where: { $0.id == current }) else {
            return Self(rows: Array(rows.prefix(maxRows)), current: current)
        }
        let start = min(max(place - maxRows / 2, 0), rows.count - maxRows)
        return Self(rows: Array(rows[start ..< start + maxRows]), current: current)
    }

    func rowHeight(in frame: CGRect) -> CGFloat {
        min(Self.rowMax, frame.height / CGFloat(max(rows.count, 1)))
    }

    func render(in frame: CGRect, scale: CGFloat) -> ElementRender {
        var render = ElementRender()
        let height = rowHeight(in: frame)
        for (index, row) in rows.enumerated() {
            let top = frame.minY + CGFloat(index) * height
            let isCurrent = row.id == current
            let size = min(Self.titleSize * scale, height * 0.62)
            let valueWidth: CGFloat = row.value.isEmpty ? 0 : 90
            render.runs.append(ElementRun(text: row.title, rect: CGRect(x: frame.minX, y: top + 2,
                                                                        width: frame.width - valueWidth - 12,
                                                                        height: height - 4),
                                          size: size, bold: isCurrent, ink: isCurrent ? .room : .ink, isTarget: true))
            if !row.value.isEmpty {
                render.runs.append(ElementRun(text: row.value, rect: CGRect(x: frame.maxX - valueWidth, y: top + 2,
                                                                            width: valueWidth, height: height - 4),
                                              size: size * 0.82, ink: isCurrent ? .room : .ink))
            }
            render.targets.append(CGRect(x: frame.minX, y: top, width: frame.width, height: height))
            render.shown.append(row.title)
            if DoorText.width(row.title, size: size, bold: true) > frame.width - valueWidth - 12 {
                render.clipped = true
            }
        }
        return render
    }
}

// MARK: - The view

/// Draws the kind's body.
struct ItemBodyView: View {
    let kind: ItemBody
    let accent: Color
    let open: (String) -> Void

    var body: some View {
        switch kind {
        case let .sets(data): SetsBodyView(data: data, accent: accent)
        case let .siblings(data): SiblingsBodyView(data: data, accent: accent, open: open)
        }
    }
}

private struct SetsBodyView: View {
    let data: SetsBody
    let accent: Color

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            let frame = CGRect(origin: .zero, size: proxy.size)
            let scale = RankedLayout.typeScale(typeSize)
            let height = data.rowHeight(in: frame)
            VStack(alignment: .leading, spacing: 0) {
                if data.shown.isEmpty {
                    Text(data.empty)
                        .font(.custom("Figtree", size: 17).weight(.medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    ForEach(data.shown) { line in
                        SetLineView(line: line, accent: accent, scale: scale)
                            .frame(height: height)
                    }
                    if !data.lastTime.isEmpty {
                        Text(SetsBody.notePrefix + data.lastTime)
                            .font(.custom("Figtree", fixedSize: 15 * min(scale, 1.2)))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.top, SetsBody.noteGap)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SetLineView: View {
    let line: SetLine
    let accent: Color
    let scale: CGFloat

    var body: some View {
        let color = Self.color(line.state, accent: accent)
        let number = SetsBody.numberSize * scale
        let weight: Font.Weight = line.state == .next ? .regular : .light
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(line.label)
                .font(.custom("Figtree", fixedSize: SetsBody.labelSize * scale)
                    .weight(line.state == .next ? .semibold : .regular))
                .foregroundStyle(line.state == .todo ? Theme.Colors.inkSecondary : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            Text(line.weight)
                .font(.custom("Outfit", fixedSize: number).weight(weight))
                .foregroundStyle(color)
            if !line.unit.isEmpty {
                Text(line.unit)
                    .font(.custom("Outfit", fixedSize: max(10, number * 0.41)).weight(.light))
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.leading, 3)
            }
            Text(", \(line.reps)")
                .font(.custom("Outfit", fixedSize: number).weight(weight))
                .foregroundStyle(color)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line.label), \(line.weight) \(line.unit), \(line.reps) reps\(Self.say(line.state))")
    }

    private static func say(_ state: SetState) -> String {
        switch state {
        case .done: ", done"
        case .next: ", next"
        case .todo: ""
        }
    }

    static func color(_ state: SetState, accent: Color) -> Color {
        switch state {
        case .done: Theme.Colors.RankInk.done
        case .next: accent
        case .todo: Theme.Colors.ink
        }
    }
}

private struct SiblingsBodyView: View {
    let data: SiblingsBody
    let accent: Color
    let open: (String) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            let frame = CGRect(origin: .zero, size: proxy.size)
            let height = data.rowHeight(in: frame)
            let scale = RankedLayout.typeScale(typeSize)
            let size = min(SiblingsBody.titleSize * scale, height * 0.62)
            VStack(spacing: 0) {
                ForEach(data.rows) { row in
                    let isCurrent = row.id == data.current
                    Button { open(row.id) } label: {
                        HStack(alignment: .center, spacing: RankedLayout.gap) {
                            Text(row.title)
                                .font(.custom("Figtree", fixedSize: size).weight(isCurrent ? .bold : .medium))
                                .foregroundStyle(isCurrent ? accent : Theme.Colors.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer(minLength: 0)
                            if !row.value.isEmpty {
                                Text(row.value)
                                    .font(.custom("Outfit", fixedSize: size * 0.82).weight(.light))
                                    .foregroundStyle(isCurrent ? accent : Theme.Colors.ink)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(height: height)
                    .accessibilityIdentifier("shell.sibling.\(row.id)")
                    .accessibilityAddTraits(isCurrent ? .isSelected : [])
                }
            }
            .frame(width: proxy.size.width, alignment: .topLeading)
        }
    }
}
