import SwiftUI

// Sheet 284, level 2: the item page. The Page's block (24,412 354x364) splits into FACTS (354x64, three columns
// 1.2 : 1 : 1) and BODY (354x292) drawn by the item's kind. The kit holds the frame, the facts row and the kinds;
// a room only says which kind an item is and hands over its data. To add a kind: add a body type that conforms to
// `ItemBodyKind` (in its own file next to `ItemBodies.swift`), a case on `ItemBody` and one arm in `ItemBody.name`,
// `ItemBody.render` and `ItemBodyView`.

/// One of the three facts: a number (Outfit Light 28 pt, unit at half size) over a small label. "about" sits small
/// before money.
struct ItemFact: Equatable, Sendable {
    var number: String
    var unit = ""
    var label: String
    /// Money reads "about" small before the number.
    var about = false
}

/// What the item page carries.
struct ItemPageData: Equatable {
    var facts: [ItemFact]
    var body: ItemBody
    var accent: Color
}

enum ItemPageLayout {
    /// The Facts row and the Body, in the Page's block.
    static let factsHeight: CGFloat = 64
    /// The Body starts 8 pt under the Facts (484 - 412 - 64).
    static let bodyGap: CGFloat = 8
    static let columnWeights: [CGFloat] = [1.2, 1, 1]
    static let numberSize: CGFloat = 28
    static let labelSize: CGFloat = 10.5

    /// The Facts frame in a block of `size` whose origin is `origin`.
    static func factsFrame(in block: CGRect) -> CGRect {
        CGRect(x: block.minX, y: block.minY, width: block.width, height: min(factsHeight, block.height))
    }

    /// The Body frame: the rest of the block.
    static func bodyFrame(in block: CGRect) -> CGRect {
        let top = min(factsHeight + bodyGap, block.height)
        return CGRect(x: block.minX, y: block.minY + top, width: block.width, height: max(0, block.height - top))
    }

    /// The three column rects of the Facts row.
    static func columns(in facts: CGRect, count: Int = 3) -> [CGRect] {
        let weights = Array(columnWeights.prefix(max(count, 1)))
        let sum = weights.reduce(0, +)
        var x = facts.minX
        return weights.map { weight in
            let width = facts.width * weight / sum
            defer { x += width }
            return CGRect(x: x, y: facts.minY, width: width, height: facts.height)
        }
    }

    /// Number, 3 pt, label: the block the column centres in the Facts row's 64 pt.
    static func blockHeight(scale: CGFloat) -> CGFloat {
        numberSize * scale * 1.1 + 3 + labelHeight
    }

    static let labelHeight: CGFloat = 14

    /// The number's rect inside its column, and the label's under it; the pair is centred in the row.
    static func numberRect(in column: CGRect, scale: CGFloat) -> CGRect {
        let top = column.minY + max(0, (column.height - blockHeight(scale: scale)) / 2)
        return CGRect(x: column.minX, y: top, width: column.width - 6, height: numberSize * scale * 1.1)
    }

    static func labelRect(in column: CGRect, scale: CGFloat = 1) -> CGRect {
        let number = numberRect(in: column, scale: scale)
        return CGRect(x: column.minX, y: number.maxY + 3, width: column.width - 6, height: labelHeight)
    }
}

// MARK: - The kinds

/// What every body kind answers: its name and how it places its words, so the element suite can check it.
protocol ItemBodyKind: Equatable, Sendable {
    static var name: String { get }
    /// The words the kind draws in `frame` at Dynamic Type `scale`, as the suite reads them.
    func render(in frame: CGRect, scale: CGFloat) -> ElementRender
}

/// The kinds of body. A new room's kind is a new case here (sheet 284 table): `steps`, `checks`, `hours`, `week`,
/// `ledger`, `text`, `tess`.
enum ItemBody: Equatable, Sendable {
    /// Deck: warm-up and sets, done in green, the next set in the room colour; last time underneath.
    case sets(SetsBody)
    /// Any row without its own page yet: the door's rows with this one in the room colour.
    case siblings(SiblingsBody)

    var name: String {
        switch self {
        case .sets: SetsBody.name
        case .siblings: SiblingsBody.name
        }
    }

    func render(in frame: CGRect, scale: CGFloat) -> ElementRender {
        switch self {
        case let .sets(body): body.render(in: frame, scale: scale)
        case let .siblings(body): body.render(in: frame, scale: scale)
        }
    }
}

// MARK: - The view

/// The item page (level 2): Facts over Body. Rows leave softly and settle from the top, as the Page's do.
struct ItemPage: View {
    let data: ItemPageData
    let settle: Bool
    let reduceMotion: Bool
    let start: Double
    let merging: Bool
    let open: (String) -> Void

    @State private var settled = false

    var body: some View {
        GeometryReader { proxy in
            let block = CGRect(origin: .zero, size: proxy.size)
            let facts = ItemPageLayout.factsFrame(in: block)
            let bodyFrame = ItemPageLayout.bodyFrame(in: block)
            ZStack(alignment: .topLeading) {
                FactsRow(facts: data.facts, accent: data.accent)
                    .frame(width: facts.width, height: facts.height, alignment: .topLeading)
                    .offset(y: settled || !settle ? 0 : -8)
                    .blur(radius: settled || !settle ? 0 : 2)
                    .opacity(settled || !settle ? 1 : 0)
                    .animation(animation(0), value: settled)
                ItemBodyView(kind: data.body, accent: data.accent, open: open)
                    .frame(width: bodyFrame.width, height: bodyFrame.height, alignment: .topLeading)
                    .offset(x: bodyFrame.minX, y: bodyFrame.minY + (settled || !settle ? 0 : -8))
                    .blur(radius: settled || !settle ? 0 : 2)
                    .opacity(settled || !settle ? 1 : 0)
                    .animation(animation(1), value: settled)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .onAppear { settled = true }
    }

    private func animation(_ index: Int) -> Animation? {
        guard settle else { return nil }
        let delay = start + Double(index) * RankedLayout.stagger(merging: merging)
        return MotionPolicy.resolve(.timingCurve(0.2, 0.8, 0.2, 1, duration: RankedLayout.rowSeconds).delay(delay),
                                    reduceMotion: reduceMotion)
    }
}

/// Three facts in columns of 1.2 : 1 : 1; the first number wears the room colour.
struct FactsRow: View {
    let facts: [ItemFact]
    let accent: Color

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let scale = RankedLayout.typeScale(typeSize)
        GeometryReader { proxy in
            let columns = ItemPageLayout.columns(in: CGRect(origin: .zero, size: proxy.size))
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                    Group {
                        if facts.indices.contains(index) {
                            FactCell(fact: facts[index], color: index == 0 ? accent : Theme.Colors.ink, scale: scale,
                                     weight: index == 0 ? .regular : .light)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: column.width, height: proxy.size.height, alignment: .leading)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FactCell: View {
    let fact: ItemFact
    let color: Color
    let scale: CGFloat
    var weight: Font.Weight = .light

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                if fact.about {
                    Text("about")
                        .font(.custom("Figtree", fixedSize: max(10, ItemPageLayout.numberSize * scale * 0.5)))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                Text(fact.number)
                    .font(.custom("Outfit", fixedSize: ItemPageLayout.numberSize * scale).weight(weight))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !fact.unit.isEmpty {
                    Text(fact.unit)
                        .font(.custom("Outfit", fixedSize: max(10, ItemPageLayout.numberSize * scale * 0.5))
                            .weight(.light))
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            Text(fact.label)
                .font(.custom("Figtree", fixedSize: ItemPageLayout.labelSize).weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.05)
                .foregroundStyle(Theme.Colors.RankInk.planned)
                .lineLimit(1)
        }
    }
}
