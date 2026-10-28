import SwiftUI

// Sheet 284, level 1: the Page of a door. Rows split the block by rank weights so it is always full, the first row is
// always the biggest and no two rows are equal. Shared by every room (the Deck first); a room hands the shell
// `RankedPageData` and never draws a row itself. The layout is pure (`RankedLayout`), so the element suite, the stage
// and the view all place the same words.

extension Theme.Colors {
    /// The state colours of sheet 241, the same in every room: done green, late and thirsty wine, best and new gold,
    /// planned and automatic slate. Light then dark.
    enum RankInk {
        static var done: Color {
            Color(light: 0x25803D, dark: 0x8FC9A0)
        }

        static var late: Color {
            Color(light: 0x9A2541, dark: 0xEE8E9C)
        }

        static var best: Color {
            Color(light: 0x7E6A1E, dark: 0xD9C27A)
        }

        static var planned: Color {
            Color(light: 0x34506F, dark: 0xA7BCD6)
        }
    }
}

/// What a row's state colours it (sheet 284): none is ink.
enum RankState: String, Equatable, Sendable {
    case none, done, late, best, planned

    var color: Color? {
        switch self {
        case .none: nil
        case .done: Theme.Colors.RankInk.done
        case .late: Theme.Colors.RankInk.late
        case .best: Theme.Colors.RankInk.best
        case .planned: Theme.Colors.RankInk.planned
        }
    }
}

/// One row of a door page: a title, a value with its unit at half size, a sub line (only when the row is tall enough)
/// and a state. A private row carries only "Private workout"-style words: the room fills `title` and leaves the rest
/// empty, and `isPrivate` keeps it from ever being given a value.
struct RankedRow: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var value = ""
    var unit = ""
    var sub = ""
    var state: RankState = .none
    var isPrivate = false
}

/// The Page's payload: the rows in rank order, the room's colour, and the id of the "and N more" row when more rows
/// exist than the seven weights.
struct RankedPageData: Equatable {
    var rows: [RankedRow]
    var accent: Color
    /// A line to draw when the door holds nothing ("Nothing here yet").
    var empty = "Nothing here yet"
    /// The id the last row carries when it stands for the rows past the sixth; nil shows the first seven.
    var moreID: String?
}

/// One row placed: its rect in the Page's space and the sizes of its words.
struct RankedRowLayout: Equatable, Sendable {
    var rect: CGRect
    var titleSize: CGFloat
    var valueSize: CGFloat
    var unitSize: CGFloat
    var subSize: CGFloat
    var showsSub: Bool
}

enum RankedLayout {
    /// The rank weights, normalised over however many rows there are (at most seven).
    static let weights: [Double] = [1.7, 1.3, 1.08, 1, 0.94, 0.88, 0.84]
    static var maxRows: Int {
        weights.count
    }

    static let subSize: CGFloat = 13
    /// A sub line needs a row taller than this.
    static let subMinHeight: CGFloat = 40
    static let titleRatio: CGFloat = 0.36
    static let titleRange: ClosedRange<CGFloat> = 17 ... 34
    static let valueRatio: CGFloat = 0.82
    static let unitFloor: CGFloat = 10
    /// The mix of the room colour with ink for the first row (58% ink).
    static let firstRowInk = 0.58
    /// Gap between a title and its value.
    static let gap: CGFloat = 12

    /// The rows the Page draws: all of them up to seven; past seven, the first six and a last row that stands for the
    /// rest, so nothing is lost.
    static func shown(_ rows: [RankedRow], moreID: String?) -> [RankedRow] {
        guard rows.count > maxRows else { return rows }
        guard let moreID else { return Array(rows.prefix(maxRows)) }
        let rest = rows.count - (maxRows - 1)
        return Array(rows.prefix(maxRows - 1)) + [RankedRow(id: moreID, title: "\(rest) more", state: .planned)]
    }

    /// Row heights: the first `count` weights, normalised, so they add up to `total` exactly.
    static func heights(count: Int, total: CGFloat) -> [CGFloat] {
        let used = Array(weights.prefix(max(0, min(count, maxRows))))
        let sum = used.reduce(0, +)
        guard sum > 0 else { return [] }
        return used.map { total * CGFloat($0 / sum) }
    }

    /// Title size: 0.36 of the row height, between 17 and 34 pt.
    static func titleSize(rowHeight: CGFloat, ratio: CGFloat = titleRatio) -> CGFloat {
        min(max(rowHeight * ratio, titleRange.lowerBound), titleRange.upperBound)
    }

    /// How much Dynamic Type scales a row's words (close to UIFontMetrics' curve).
    static func typeScale(_ size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: 0.86
        case .small: 0.93
        case .medium: 0.96
        case .large: 1
        case .xLarge: 1.07
        case .xxLarge: 1.14
        case .xxxLarge: 1.21
        case .accessibility1: 1.32
        default: 1.32
        }
    }

    /// The rows placed in `frame`. `scale` is Dynamic Type's; `ratio` is the title-to-height ratio (a fix steps it
    /// down); `dropSubs` removes every sub line (accessibility sizes, or a fix).
    static func rows(count: Int, in frame: CGRect, scale: CGFloat = 1, ratio: CGFloat = titleRatio,
                     dropSubs: Bool = false) -> [RankedRowLayout]
    {
        var y = frame.minY
        return heights(count: count, total: frame.height).map { height in
            let base = titleSize(rowHeight: height, ratio: ratio)
            // Never taller than the row can hold, so rows never overlap whatever the size.
            let title = min(base * scale, height * 0.62)
            let value = title * valueRatio
            let unit = max(unitFloor, title * 0.5)
            let sub = subSize * min(scale, 1.2)
            let fitsSub = title * 1.25 + sub * 1.3 + 4 <= height
            let layout = RankedRowLayout(rect: CGRect(x: frame.minX, y: y, width: frame.width, height: height),
                                         titleSize: title, valueSize: value, unitSize: unit, subSize: sub,
                                         showsSub: !dropSubs && height > subMinHeight && fitsSub)
            y += height
            return layout
        }
    }

    /// The ink a row's title and value wear: its state colour, else (the first row) the room colour mixed 58% with
    /// ink, else ink.
    static func color(for row: RankedRow, index: Int, accent: Color) -> Color {
        if let state = row.state.color {
            return state
        }
        return index == 0 ? accent.mix(with: Theme.Colors.ink, by: firstRowInk) : Theme.Colors.ink
    }

    /// How the Page's rows move: 0.38 s each, 45 ms apart; while a layout merges the stagger tightens to 20 ms so the
    /// last row lands with the change's clock.
    static let rowSeconds = 0.38
    static let rowStagger = 0.045
    static let mergeStagger = 0.02

    static func stagger(merging: Bool) -> Double {
        merging ? mergeStagger : rowStagger
    }
}

// MARK: - The view

/// The Page of a door (level 1): rows fill the block exactly. Tap a row to open its item. Rows settle in from the top
/// down, 0.38 s each and 45 ms apart; a page that changes in place (state) does not move.
struct RankedPage: View {
    let data: RankedPageData
    let settle: Bool
    let reduceMotion: Bool
    let start: Double
    let merging: Bool
    let open: (String) -> Void

    @State private var settled = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { proxy in
            let rows = RankedLayout.shown(data.rows, moreID: data.moreID)
            if rows.isEmpty {
                Text(data.empty)
                    .font(.custom("Figtree", size: 17).weight(.medium))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(width: proxy.size.width, height: min(proxy.size.height, 56), alignment: .topLeading)
            } else {
                let layouts = RankedLayout.rows(
                    count: rows.count,
                    in: CGRect(origin: .zero, size: proxy.size),
                    scale: RankedLayout.typeScale(typeSize),
                    dropSubs: typeSize.isAccessibilitySize
                )
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        RankedRowView(row: row, index: index, layout: layouts[index], accent: data.accent) {
                            open(row.id)
                        }
                        .frame(height: layouts[index].rect.height)
                        .offset(y: settled || !settle ? 0 : -10)
                        .opacity(settled || !settle ? 1 : 0)
                        .animation(rowAnimation(index), value: settled)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .onAppear { settled = true }
    }

    private func rowAnimation(_ index: Int) -> Animation? {
        guard settle else { return nil }
        let delay = start + Double(index) * RankedLayout.stagger(merging: merging)
        return MotionPolicy.resolve(.timingCurve(0.2, 0.8, 0.2, 1, duration: RankedLayout.rowSeconds).delay(delay),
                                    reduceMotion: reduceMotion)
    }
}

/// One row: title (and a sub line under it when the row is tall enough) on the left, the value and its unit on the
/// right. A value never wraps; the title yields to it.
private struct RankedRowView: View {
    let row: RankedRow
    let index: Int
    let layout: RankedRowLayout
    let accent: Color
    let open: () -> Void

    var body: some View {
        let ink = RankedLayout.color(for: row, index: index, accent: accent)
        Button(action: open) {
            HStack(alignment: .center, spacing: RankedLayout.gap) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.title)
                        .font(.custom("Figtree", fixedSize: layout.titleSize).weight(index == 0 ? .bold : .medium))
                        .foregroundStyle(row.isPrivate ? Theme.Colors.inkSecondary : ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if layout.showsSub, !row.sub.isEmpty {
                        Text(row.sub)
                            .font(.custom("Figtree", fixedSize: layout.subSize))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
                if !row.value.isEmpty {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(row.value)
                            .font(.custom("Outfit", fixedSize: layout.valueSize).weight(.light))
                            .foregroundStyle(ink)
                        if !row.unit.isEmpty {
                            Text(row.unit)
                                .font(.custom("Figtree", fixedSize: layout.unitSize).weight(.regular))
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                    }
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityIdentifier("shell.row.\(row.id)")
    }

    private var label: String {
        var parts = [row.title]
        if !row.value.isEmpty {
            parts.append(row.unit.isEmpty ? row.value : "\(row.value) \(row.unit)")
        }
        if !row.sub.isEmpty {
            parts.append(row.sub)
        }
        return parts.joined(separator: ", ")
    }
}
