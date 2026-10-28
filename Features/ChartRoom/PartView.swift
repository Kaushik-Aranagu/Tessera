import SwiftUI

// The pure view builder for the kit (R1 spec section 6): one `PartNode` in, one view out, recursive over stacks and
// grids, `ForEach` keyed by part id so an edit animates in place instead of remounting. No `AnyView`. Type and colour
// come from Theme and the shell's type scale; the top item takes the wine and breathes slowly (still under Reduce
// Motion).

extension Theme.Colors.Accent {
    /// The Chart room's slate (the 241 slate token): 34506F light, A7BCD6 dark.
    static var chart: Color {
        Color(light: 0x34506F, dark: 0xA7BCD6)
    }

    /// The wine the top item and a reach line wear: 9A2541 light, EE8E9C dark.
    static var wine: Color {
        Color(light: 0x9A2541, dark: 0xEE8E9C)
    }
}

/// The places' parts: a place's top-level nodes, one after another.
struct PartsView: View {
    let tree: PartTree

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(tree.nodes) { node in
                PartView(node: node, accent: tree.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct PartView: View {
    let node: PartNode
    let accent: Color

    var body: some View {
        switch node {
        case let .title(_, text):
            FitLine(forms: FitLine.cuts(text), size: 40, color: accent, weight: .bold)
                .accessibilityAddTraits(.isHeader)
        case let .line(_, text):
            FitLine(forms: FitLine.cuts(text), size: 26, color: Theme.Colors.ink, weight: .light)
                .padding(.top, 6)
        case let .lines(_, texts):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                    FitLine(forms: FitLine.cuts(text), size: 15,
                            color: index == 0 ? Theme.Colors.ink : Theme.Colors.inkSecondary,
                            weight: index == 0 ? .semibold : .regular)
                        .frame(height: 24, alignment: .leading)
                }
            }
        case let .number(_, value, unit, label):
            NumberPart(value: value, unit: unit, label: label)
        case let .row(_, items):
            RankedRow(items: items)
        case let .list(_, items):
            RankedList(items: items)
        case let .stack(_, axis, gap, children):
            if axis == .vertical {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(children) { PartView(node: $0, accent: accent) }
                }
            } else {
                HStack(alignment: .top, spacing: gap) {
                    ForEach(children) { PartView(node: $0, accent: accent) }
                }
            }
        case let .grid(_, columns, children):
            Grid(alignment: .topLeading, horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(rows(children, columns), id: \.first?.id) { row in
                    GridRow {
                        ForEach(row) { PartView(node: $0, accent: accent) }
                    }
                }
            }
        case let .glyph(_, symbol):
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(accent)
                .accessibilityHidden(true)
        case let .doors(_, names):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    FitLine(forms: FitLine.cuts(name), size: 20,
                            color: index == 0 ? accent : Theme.Colors.inkSecondary, weight: .bold)
                        .frame(height: 40, alignment: .leading)
                }
            }
        case let .actionWord(_, verb, object, _):
            VStack(alignment: .leading, spacing: 0) {
                FitLine(forms: FitLine.cuts(verb), size: 24, color: accent, weight: .semibold)
                if !object.isEmpty {
                    FitLine(forms: FitLine.cuts(object), size: 13, color: Theme.Colors.inkSecondary, weight: .medium)
                }
            }
        }
    }

    private func rows(_ children: [PartNode], _ columns: Int) -> [[PartNode]] {
        stride(from: 0, to: children.count, by: max(1, columns)).map {
            Array(children[$0 ..< min($0 + max(1, columns), children.count)])
        }
    }
}

/// Outfit numeral, its unit at half size (never under 10 pt), and its label.
private struct NumberPart: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: PartLayout.nameGap) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value)
                    .font(.custom("Outfit", size: PartLayout.numeral, relativeTo: .largeTitle).weight(.light))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.custom("Outfit", size: max(10, PartLayout.numeral / 2), relativeTo: .title2))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                }
            }
            if !label.isEmpty {
                FitLine(
                    forms: FitLine.cuts(label),
                    size: PartLayout.nameSize,
                    color: Theme.Colors.ink,
                    weight: .semibold
                )
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A ranked row: numerals over names in equal columns, bottom-aligned above the foot; the top one in wine.
private struct RankedRow: View {
    let items: [RankedItem]

    var body: some View {
        GeometryReader { proxy in
            let shown = Array(items.prefix(max(1, Int(proxy.size.width / PartLayout.minCell))))
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(shown) { item in
                    VStack(alignment: .leading, spacing: PartLayout.nameGap) {
                        Text(item.big)
                            .font(.custom("Outfit", size: PartLayout.numeral, relativeTo: .largeTitle).weight(.light))
                            .monospacedDigit()
                            .lineLimit(1)
                        Text(item.small)
                            .font(.custom("Figtree", size: PartLayout.nameSize, relativeTo: .callout).weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(item.isTop ? Theme.Colors.Accent.wine : Theme.Colors.ink)
                    .breathes(item.isTop)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.small), \(item.big)")
                }
            }
            .padding(.bottom, PartLayout.foot)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
        }
    }
}

/// A ranked list: the name left at 20 pt, the big value right at 26 pt; the top row in wine.
private struct RankedList: View {
    let items: [RankedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline) {
                    Text(item.small)
                        .font(.custom("Figtree", size: 20, relativeTo: .body).weight(.bold))
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(item.big)
                        .font(.custom("Outfit", size: 26, relativeTo: .title2).weight(.light))
                        .monospacedDigit()
                }
                .foregroundStyle(item.isTop ? Theme.Colors.Accent.wine : Theme.Colors.ink)
                .breathes(item.isTop)
                .frame(height: PartLayout.listRowHeight, alignment: .center)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.small), \(item.big)")
            }
        }
    }
}

/// The top item breathes slowly: opacity down to 60% and back over 3.6 s. Reduce Motion: it stays still.
private struct Breathing: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    func body(content: Content) -> some View {
        content
            .opacity(active && dim ? 0.6 : 1)
            .onAppear { start() }
            .onChange(of: active) { start() }
    }

    private func start() {
        guard active, !reduceMotion else {
            dim = false
            return
        }
        withTesseraAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), reduceMotion: reduceMotion) {
            dim = true
        }
    }
}

extension View {
    func breathes(_ active: Bool) -> some View {
        modifier(Breathing(active: active))
    }
}

/// The ghost (sheet 357): a proposed part at 38% ink, setting to full over 450 ms on the house ease.
enum PartGhost {
    static let opacity = 0.38
    static let sets = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.45)
    /// The drying line along the foot of each filled place: 2 s, linear, then the group commits.
    static let drying: TimeInterval = 2
}
