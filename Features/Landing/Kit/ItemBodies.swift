import SwiftUI

// The body kinds of sheet 284, one per item type, all in the same 354 x 292 block. `sets` (the Deck) and `siblings`
// (any row without its own page yet) come first; the other rooms add theirs next to these (see `ItemBody`).

// MARK: - sets (Deck)

enum SetState: String, Equatable, Sendable {
    /// Logged: green.
    case done
    /// The set to do next: the room colour.
    case next
    /// Still to come: ink.
    case todo
}

/// One line of the sets body: "Warm-up 40 kg x 8".
struct SetLine: Identifiable, Equatable, Sendable {
    let id: String
    var label: String
    var weight: String
    var unit: String
    var reps: String
    var state: SetState
}

/// Warm-up and sets, done in green, the next set in the room colour; last time underneath.
struct SetsBody: ItemBodyKind {
    static let name = "sets"

    var lines: [SetLine]
    /// "80 kg x 5, 5, 4": the last session, under the sets. Empty when there is none.
    var lastTime = ""
    var empty = "No sets yet"

    /// The lines the body can hold: at most eight, so a row is never under 28 pt.
    static let maxLines = 8
    static let lastHeight: CGFloat = 58
    static let rowMax: CGFloat = 46
    static let labelWidth: CGFloat = 130
    static let weightWidth: CGFloat = 124
    static let numberSize: CGFloat = 24
    static let labelSize: CGFloat = 17

    var shown: [SetLine] {
        Array(lines.prefix(Self.maxLines))
    }

    func rowHeight(in frame: CGRect) -> CGFloat {
        let area = max(0, frame.height - Self.lastHeight - 8)
        return min(Self.rowMax, area / CGFloat(max(shown.count, 1)))
    }

    func render(in frame: CGRect, scale: CGFloat) -> ElementRender {
        var render = ElementRender()
        let height = rowHeight(in: frame)
        for (index, line) in shown.enumerated() {
            let top = frame.minY + CGFloat(index) * height
            let ink = Self.ink(line.state)
            let label = Self.labelSize * scale
            render.runs.append(ElementRun(text: line.label, rect: CGRect(x: frame.minX, y: top + 2,
                                                                         width: Self.labelWidth - 8,
                                                                         height: height - 4),
                                          size: label, bold: line.state == .next, ink: ink))
            let number = min(Self.numberSize * scale, height * 0.62)
            let weightX = frame.minX + Self.labelWidth
            render.runs.append(ElementRun(text: line.weight, rect: CGRect(x: weightX, y: top + 2,
                                                                          width: Self.weightWidth - 40,
                                                                          height: height - 4),
                                          size: number, ink: ink))
            render.runs.append(ElementRun(text: line.unit, rect: CGRect(x: weightX + Self.weightWidth - 38, y: top + 2,
                                                                        width: 36, height: height - 4),
                                          size: max(10, number / 2), ink: .ink2, isUnit: true))
            render.runs.append(ElementRun(text: line.reps, rect: CGRect(x: weightX + Self.weightWidth + 8, y: top + 2,
                                                                        width: 60, height: height - 4),
                                          size: number, ink: ink))
            render.shown.append(line.label)
            if DoorText.width(line.label, size: label, bold: true) > Self.labelWidth - 8 {
                render.clipped = true
            }
        }
        render.lost = lines.count - shown.count
        if !lastTime.isEmpty {
            let top = frame.maxY - Self.lastHeight
            render.runs.append(ElementRun(
                text: "Last time",
                rect: CGRect(x: frame.minX, y: top, width: 200, height: 14),
                size: ItemPageLayout.labelSize,
                ink: .ink2,
                isUnit: true
            ))
            render.runs.append(ElementRun(text: lastTime, rect: CGRect(x: frame.minX, y: top + 18,
                                                                       width: frame.width, height: 24),
                                          size: 15, ink: .ink2))
            if DoorText.width(lastTime, size: 15, bold: false) > frame.width {
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

    var rows: [RankedRow]
    var current: String

    static let maxRows = RankedLayout.maxRows
    static let rowMax: CGFloat = 52
    static let titleSize: CGFloat = 20

    /// At most seven rows, the current one always among them, centred where it can be.
    static func make(rows: [RankedRow], current: String) -> Self {
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
            ZStack(alignment: .topLeading) {
                if data.shown.isEmpty {
                    Text(data.empty)
                        .font(.custom("Figtree", size: 17).weight(.medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(data.shown) { line in
                            SetLineView(line: line, accent: accent, scale: scale)
                                .frame(height: height)
                        }
                    }
                    .frame(width: proxy.size.width, alignment: .topLeading)
                }
                if !data.lastTime.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last time")
                            .font(.custom("Figtree", fixedSize: ItemPageLayout.labelSize).weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.1)
                            .foregroundStyle(Theme.Colors.RankInk.planned)
                        Text(data.lastTime)
                            .font(.custom("Figtree", fixedSize: 15 * min(scale, 1.2)))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: proxy.size.width, height: SetsBody.lastHeight, alignment: .topLeading)
                    .offset(y: proxy.size.height - SetsBody.lastHeight)
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
        HStack(spacing: 0) {
            Text(line.label)
                .font(.custom("Figtree", fixedSize: SetsBody.labelSize * scale)
                    .weight(line.state == .next ? .bold : .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: SetsBody.labelWidth, alignment: .leading)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(line.weight)
                    .font(.custom("Outfit", fixedSize: number).weight(.light))
                    .foregroundStyle(color)
                Text(line.unit)
                    .font(.custom("Figtree", fixedSize: max(10, number / 2)).weight(.regular))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .lineLimit(1)
            .fixedSize()
            .frame(width: SetsBody.weightWidth, alignment: .trailing)
            Spacer(minLength: 8)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\u{00D7}")
                    .font(.custom("Figtree", fixedSize: max(10, number / 2)).weight(.regular))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                Text(line.reps)
                    .font(.custom("Outfit", fixedSize: number).weight(.light))
                    .foregroundStyle(color)
            }
            .lineLimit(1)
            .fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line.label), \(line.weight) \(line.unit) for \(line.reps)\(Self.say(line.state))")
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
