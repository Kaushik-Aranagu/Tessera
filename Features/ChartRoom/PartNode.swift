import CoreGraphics
import Foundation
import TesseraCore

// The kit's value type (R1 spec section 6): a recursive tree the one new slot kind, `SlotKind.parts`, carries. A
// `PartNode` is what a part of the document became once its binds were read: plain values, no views, so the shell's
// payload stays `Equatable` and a stack's children nest as values (no `AnyView`). `PartView` draws it.

enum PartAxis: String, Equatable, Sendable {
    case vertical, horizontal
}

/// One ranked item of a `row` or `list`: the big value, the name under it, and whether it is the top one.
struct RankedItem: Equatable, Sendable, Identifiable {
    var id: String
    var big: String
    var small: String
    var isTop = false
    /// Sheet 385: this plant was just watered (true: the thirst climbs out) or the watering was undone (false: it sinks
    /// back in). Nil for every other plant: only the watered one drinks.
    var drinks: Bool?
}

indirect enum PartNode: Equatable, Sendable, Identifiable {
    case title(id: String, text: String)
    case line(id: String, text: String)
    case lines(id: String, texts: [String])
    case number(id: String, value: String, unit: String, label: String)
    case row(id: String, items: [RankedItem])
    case list(id: String, items: [RankedItem])
    case stack(id: String, axis: PartAxis, gap: CGFloat, children: [PartNode])
    case grid(id: String, columns: Int, children: [PartNode])
    case glyph(id: String, symbol: String)
    case doors(id: String, names: [String])
    case actionWord(id: String, verb: String, object: String, does: String?)

    var id: String {
        switch self {
        case let .title(id, _), let .line(id, _), let .lines(id, _), let .number(id, _, _, _), let .row(id, _),
             let .list(id, _), let .stack(id, _, _, _), let .grid(id, _, _), let .glyph(id, _), let .doors(id, _),
             let .actionWord(id, _, _, _):
            id
        }
    }

    /// Every node of the tree, parents first.
    var flattened: [PartNode] {
        switch self {
        case let .stack(_, _, _, children), let .grid(_, _, children):
            [self] + children.flatMap(\.flattened)
        default:
            [self]
        }
    }

    /// The words the node shows, for the tests and for VoiceOver.
    var words: [String] {
        switch self {
        case let .title(_, text), let .line(_, text): [text]
        case let .lines(_, texts): texts
        case let .number(_, value, unit, label): [value, unit, label].filter { !$0.isEmpty }
        case let .row(_, items), let .list(_, items): items.flatMap { [$0.big, $0.small] }
        case let .stack(_, _, _, children), let .grid(_, _, children): children.flatMap(\.words)
        case .glyph: []
        case let .doors(_, names): names
        case let .actionWord(_, verb, object, _): [verb, object].filter { !$0.isEmpty }
        }
    }
}

/// What a bind reads: one object's shown name and its number fields. A private object's name is already "Private"
/// (`ObjectPrivacy.shownLabel`), whoever builds the item.
struct BoundItem: Equatable, Sendable {
    var name: String
    var fields: [String: Double] = [:]
    var isPrivate = false
}

/// The text rules every shown line keeps (spec section 4): no full stop at the end, at most 80 characters, cut on a
/// word edge and never with an ellipsis, and nothing key-shaped.
enum PartText {
    static let limit = 80

    static func shown(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix(".") || text.hasSuffix("\u{2026}") {
            text.removeLast()
            text = text.trimmingCharacters(in: .whitespaces)
        }
        guard text.count > limit else { return text }
        let head = String(text.prefix(limit))
        if let space = head.lastIndex(of: " ") {
            return String(head[..<space]).trimmingCharacters(in: CharacterSet(charactersIn: " ,;:"))
        }
        return head
    }

    /// A string that looks like an API key or token: refused, never shown (the same shape check as the router).
    static func looksLikeKey(_ text: String) -> Bool {
        let lowered = text.lowercased()
        if lowered.contains("sk-ant") || lowered.contains("api_key") || lowered.contains("apikey") {
            return true
        }
        return text.split(separator: " ").contains { word in
            word.count >= 24 && word.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
                && word.contains { $0.isNumber } && word.contains { $0.isLetter }
        }
    }

    /// `{count}`, `{top}` and field tokens (`{days}` reads the top item's field).
    static func fill(_ template: String, items: [BoundItem], top: BoundItem?) -> String {
        var text = template
        text = text.replacingOccurrences(of: "{count}", with: String(items.count))
        text = text.replacingOccurrences(of: "{top}", with: top?.name.lowercased() ?? "")
        for key in Set(items.flatMap(\.fields.keys)) {
            let value = top?.fields[key].map { whole($0) } ?? ""
            text = text.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return text
    }

    /// A whole number with no grouping noise: "6".
    static func whole(_ value: Double) -> String {
        value.rounded().formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "en_US")))
    }
}

/// The classes a room can never show a figure from: money (never, anywhere a room could reach) and the health and body
/// classes (walls: not on Home or in a widget, and a Chart room part may sit in a widget place).
enum RoomWalls {
    static let money: Set<String> = ["pool", "inflow", "poolMove", "spend", "rateNote"]
    static let body: Set<String> = ["workout", "set", "bodyWeight", "medicine", "dose", "meal", "calories"]

    /// The class a bind names ("Plant", "Plant where days > 3": the first word).
    static func className(of bind: String) -> String {
        String(bind.split(whereSeparator: { $0 == " " || $0 == "." || $0 == "[" }).first ?? "")
    }

    static func isWalled(_ bind: String) -> Bool {
        let name = className(of: bind).lowercased()
        return money.map { $0.lowercased() }.contains(name) || body.map { $0.lowercased() }.contains(name)
    }

    /// Money classes can never be written by a room.
    static func refusesWrite(_ reach: String) -> Bool {
        let words = reach.split(separator: " ")
        guard words.first == "write", words.count > 1 else { return false }
        return money.map { $0.lowercased() }.contains(className(of: String(words[1])).lowercased())
    }
}

/// Reads a document into nodes, place by place. Pure: the caller passes what each bind reads.
enum PartResolver {
    /// The vetted SF Symbols a `glyph` may name; anything else draws the first.
    static var symbols: [String] {
        RoomKit.glyphs
    }

    /// The gap between a stack's children by the density trait.
    static func gap(_ density: String?) -> CGFloat {
        switch density {
        case "airy": 16
        case "tight": 6
        default: 10
        }
    }

    static func resolve(_ doc: ChartDoc, data: (String) -> [BoundItem]) -> [Place: [PartNode]] {
        var out: [Place: [PartNode]] = [:]
        for place in Place.allCases {
            let nodes = doc.parts(in: place).compactMap { node($0, in: doc, data: data) }
            if !nodes.isEmpty {
                out[place] = nodes
            }
        }
        return out
    }

    /// The items a part's bind reads, sorted by its `sort` prop (`-days` is high to low) and cut to `max` (at most 4
    /// in a row).
    static func items(_ part: ChartPart, data: (String) -> [BoundItem], cap: Int) -> [BoundItem] {
        guard let bind = part.bind, !RoomWalls.isWalled(bind) else { return [] }
        var items = data(bind)
        if let sort = part.props.text("sort") {
            let descending = sort.hasPrefix("-")
            let key = sortKey(sort.trimmingCharacters(in: CharacterSet(charactersIn: "-+")))
            items.sort { descending ? value($0, key) > value($1, key) : value($0, key) < value($1, key) }
        }
        let max = Int(part.props.number("max") ?? Double(cap))
        return Array(items.prefix(Swift.max(1, Swift.min(max, cap))))
    }

    private static func sortKey(_ raw: String) -> String {
        guard let open = raw.firstIndex(of: "("), raw.hasSuffix(")") else { return raw }
        return String(raw[raw.index(after: open) ..< raw.index(before: raw.endIndex)])
    }

    static func value(_ item: BoundItem, _ key: String) -> Double {
        item.fields[key] ?? item.fields["daysSince(\(key))"] ?? 0
    }

    /// The item the `top` modifier picks (the highest of its field), if the room has one.
    static func top(in doc: ChartDoc, of target: ChartPart,
                    data: (String) -> [BoundItem]) -> (field: String, item: BoundItem)?
    {
        guard let modifier = doc.parts.first(where: { $0.kind == .top && $0.props.text("on") == target.id })
            ?? doc.parts.first(where: { $0.kind == .top && $0.props.text("on") == nil }),
            let field = modifier.props.text("field")
        else { return nil }
        let all = items(target, data: data, cap: 24)
        guard let best = all.max(by: { value($0, field) < value($1, field) }),
              value(best, field) > 0 else { return nil }
        return (field, best)
    }

    static func node(_ part: ChartPart, in doc: ChartDoc, data: (String) -> [BoundItem]) -> PartNode? {
        let props = part.props
        // A pipe-joined record, each segment kept to the text rules.
        func segments(_ record: String) -> String {
            record.split(separator: "|", omittingEmptySubsequences: false).map { PartText.shown(String($0)) }
                .joined(separator: "|")
        }
        func shown(_ text: String?) -> String {
            let line = PartText.shown(text ?? "")
            return PartText.looksLikeKey(line) ? "" : line
        }
        let bound = part.bind.map { RoomWalls.isWalled($0) ? [] : data($0) } ?? []
        switch part.kind {
        case .title:
            return .title(id: part.id, text: shown(props.text("text")))
        case .line where !props.texts("words").isEmpty:
            return .line(id: part.id, text: props.texts("words").map { shown($0) }.joined(separator: "|"))
        case .line:
            let top = lineTop(part, doc: doc, bound: bound, data: data)
            return .line(id: part.id, text: shown(PartText.fill(props.text("text") ?? "", items: bound, top: top)))
        case .lines where !props.texts("windows").isEmpty:
            return .lines(id: part.id, texts: props.texts("windows").map { segments($0) })
        case .lines:
            return .lines(id: part.id, texts: (props.texts("lines") + props.texts("texts")).prefix(2).map { shown($0) })
        case .number:
            let raw = aggregate(part, bound: bound) ?? props.text("value") ?? ""
            return .number(id: part.id, value: raw, unit: shown(props.text("unit")), label: shown(props.text("label")))
        case .list where !props.texts("cards").isEmpty:
            return .lines(id: part.id, texts: props.texts("cards").map { segments($0) })
        case .row, .list:
            let cap = part.kind == .row ? 4 : 8
            let list = items(part, data: data, cap: cap)
            let bigField = props.text("big") ?? ""
            let topField = top(in: doc, of: part, data: data)
            let rankedItems = list.map { item in
                RankedItem(id: item.name, big: PartText.whole(value(item, bigField)), small: item.name,
                           isTop: item.name == topField?.item.name && !item.isPrivate)
            }
            return part.kind == .row ? .row(id: part.id, items: rankedItems) : .list(id: part.id, items: rankedItems)
        case .stack, .grid:
            let children = props.texts("children").compactMap { id in
                doc.part(id).flatMap { node($0, in: doc, data: data) }
            }
            if part.kind == .stack {
                let axis: PartAxis = ["h", "horizontal"].contains(props.text("axis") ?? "") ? .horizontal : .vertical
                return .stack(id: part.id, axis: axis, gap: gap(doc.look["density"]), children: children)
            }
            return .grid(id: part.id, columns: Swift.min(4, Swift.max(2, Int(props.number("columns") ?? 2))),
                         children: children)
        case .glyph:
            let name = props.text("symbol") ?? ""
            return .glyph(id: part.id, symbol: symbols.contains(name) ? name : symbols[0])
        case .doors:
            return .doors(
                id: part.id,
                names: (props.texts("doors") + props.texts("names")).map { segments($0) }.filter { !$0.isEmpty }
            )
        case .actionWord:
            let does = props.text("does")
            // A write the room has no grant for is not offered; a write to money is never offered.
            if let does, RoomWalls.refusesWrite(does) || !doc.reach.contains(does) {
                return nil
            }
            let top = lineTop(part, doc: doc, bound: bound, data: data)
            return .actionWord(id: part.id, verb: shown(props.text("verb")),
                               object: shown(PartText.fill(props.text("object") ?? "", items: bound, top: top)),
                               does: does)
        case .top:
            return nil
        }
    }

    /// A number part's figure: `agg` (count, sum, avg, min, max, latest) of `field` over its bind. Nil with no bind.
    static func aggregate(_ part: ChartPart, bound: [BoundItem]) -> String? {
        guard part.bind != nil else { return nil }
        let agg = part.props.text("agg") ?? "count"
        let field = part.props.text("field") ?? ""
        let values = bound.map { value($0, field) }
        switch agg {
        case "sum": return PartText.whole(values.reduce(0, +))
        case "avg": return values.isEmpty ? "0" : PartText.whole(values.reduce(0, +) / Double(values.count))
        case "min": return PartText.whole(values.min() ?? 0)
        case "max": return PartText.whole(values.max() ?? 0)
        case "latest": return PartText.whole(values.last ?? 0)
        default: return String(bound.count)
        }
    }

    /// The item `{top}` names for a text part: its bind's item with the highest of the `top` modifier's field, else the
    /// first item.
    private static func lineTop(_: ChartPart, doc: ChartDoc, bound: [BoundItem],
                                data _: (String) -> [BoundItem]) -> BoundItem?
    {
        guard let modifier = doc.parts.first(where: { $0.kind == .top }), let field = modifier.props.text("field")
        else { return bound.first }
        return bound.max { value($0, field) < value($1, field) } ?? bound.first
    }
}

// MARK: - Layout (pure geometry, shared by the view and the conformance suite)

/// One placed piece of a part: where it draws and in what size, in the place's own coordinates.
struct PlacedPart: Equatable, Sendable {
    var id: String
    var text: String
    var rect: CGRect
    var size: CGFloat
    var bold = false
    var ink: ElementInk = .ink
    var isUnit = false
    var isTarget = false
}

enum PartLayout {
    /// The keystone's numerals (board sheet 357: Outfit 64 light) and the names under them (15 pt, 600).
    static let numeral: CGFloat = 64
    static let nameSize: CGFloat = 15
    static let nameGap: CGFloat = 6
    static let foot: CGFloat = 22
    /// A row's cell is never narrower than this (a name and its numeral), so a narrow place shows fewer items.
    static let minCell: CGFloat = 80

    /// Where a node's pieces sit when it fills `size` (the place's own size). Recursive over stacks and grids.
    static func place(_ node: PartNode, in rect: CGRect, scale: CGFloat = 1) -> [PlacedPart] {
        switch node {
        case let .title(id, text):
            return [PlacedPart(id: id, text: text, rect: line(rect, size: 40), size: 40, bold: true, ink: .room)]
        case let .line(id, text):
            return [PlacedPart(id: id, text: text, rect: line(rect, size: 26), size: 26)]
        case let .lines(id, texts):
            return texts.enumerated().map { index, text in
                PlacedPart(id: "\(id).\(index)", text: text,
                           rect: CGRect(
                               x: rect.minX,
                               y: rect.minY + CGFloat(index) * 24,
                               width: rect.width,
                               height: 24
                           ),
                           size: 15, bold: index == 0, ink: index == 0 ? .ink : .ink2)
            }
        case let .number(id, value, unit, label):
            return numberPieces(id, value, unit, label, in: rect, scale: scale)
        case let .row(id, items):
            return rowPieces(id, items, in: rect, scale: scale)
        case let .list(id, items):
            return listPieces(id, items, in: rect, scale: scale)
        case let .stack(_, axis, gap, children):
            return stackPieces(axis, gap, children, in: rect, scale: scale)
        case let .grid(_, columns, children):
            return gridPieces(columns, children, in: rect, scale: scale)
        case let .glyph(id, symbol):
            let side = min(rect.width, rect.height, 80)
            return [PlacedPart(
                id: id,
                text: symbol,
                rect: CGRect(x: rect.minX, y: rect.minY, width: side, height: side),
                size: side,
                ink: .room
            )]
        case let .doors(id, names):
            return names.enumerated().map { index, name in
                PlacedPart(id: "\(id).\(index)", text: name,
                           rect: CGRect(
                               x: rect.minX,
                               y: rect.minY + CGFloat(index) * 40,
                               width: rect.width,
                               height: 40
                           ),
                           size: 20, bold: true, ink: index == 0 ? .room : .ink2, isTarget: true)
            }
        case let .actionWord(id, verb, object, _):
            return [PlacedPart(
                id: id,
                text: verb,
                rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 32),
                size: 24,
                bold: true,
                ink: .room,
                isTarget: true
            )]
                + (object.isEmpty ? [] : [PlacedPart(id: id + ".object", text: object,
                                                     rect: CGRect(x: rect.minX, y: rect.minY + 32, width: rect.width,
                                                                  height: 18),
                                                     size: 13, ink: .ink2)])
        }
    }

    private static func line(_ rect: CGRect, size: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: (size * 1.2).rounded(.up))
    }

    private static func numberPieces(_ id: String, _ value: String, _ unit: String, _ label: String, in rect: CGRect,
                                     scale: CGFloat) -> [PlacedPart]
    {
        let big = numeral * scale
        let numberWidth = min(rect.width, DoorText.width(value, size: big, bold: false))
        var pieces = [PlacedPart(id: id, text: value, rect: CGRect(x: rect.minX, y: rect.minY, width: numberWidth,
                                                                   height: big), size: big)]
        if !unit.isEmpty {
            // The unit sits at half size beside the numeral, never under 10 pt.
            let size = max(10, big / 2)
            let width = numberWidth
            pieces.append(PlacedPart(id: id + ".unit", text: unit,
                                     rect: CGRect(x: rect.minX + width + 6, y: rect.minY + big - size * 1.25,
                                                  width: max(0, rect.width - width - 6), height: size * 1.25),
                                     size: size, ink: .ink2, isUnit: true))
        }
        if !label.isEmpty {
            pieces.append(PlacedPart(id: id + ".label", text: label,
                                     rect: CGRect(x: rect.minX, y: rect.minY + big + nameGap, width: rect.width,
                                                  height: 18 * scale), size: nameSize * scale, bold: true))
        }
        return pieces
    }

    /// A ranked row: up to four numerals over their names, bottom-aligned above the foot (sheet 357's keystone).
    static func rowCells(_ count: Int, in rect: CGRect) -> [CGRect] {
        let columns = max(1, min(4, count, Int(rect.width / minCell)))
        let width = rect.width / CGFloat(columns)
        return (0 ..< columns).map { CGRect(
            x: rect.minX + CGFloat($0) * width,
            y: rect.minY,
            width: width,
            height: rect.height
        ) }
    }

    private static func rowPieces(_ id: String, _ items: [RankedItem], in rect: CGRect,
                                  scale: CGFloat) -> [PlacedPart]
    {
        let big = numeral * scale
        let name = nameSize * scale
        var pieces: [PlacedPart] = []
        for (index, cell) in rowCells(items.count, in: rect).enumerated() where index < items.count {
            let item = items[index]
            let bottom = cell.maxY - foot
            let nameRect = CGRect(x: cell.minX, y: bottom - name * 1.2, width: cell.width - 4, height: name * 1.2)
            let numberRect = CGRect(x: cell.minX, y: nameRect.minY - nameGap - big, width: cell.width - 4, height: big)
            let ink: ElementInk = item.isTop ? .room : .ink
            pieces.append(PlacedPart(id: "\(id).\(index).big", text: item.big, rect: numberRect, size: big, ink: ink))
            pieces.append(PlacedPart(id: "\(id).\(index).name", text: item.small, rect: nameRect, size: name,
                                     bold: true, ink: ink))
        }
        return pieces
    }

    /// A list: rows 48 pt tall, the name on the left (20 pt) and the big value right-aligned (26 pt).
    static let listRowHeight: CGFloat = 48

    private static func listPieces(_ id: String, _ items: [RankedItem], in rect: CGRect,
                                   scale: CGFloat) -> [PlacedPart]
    {
        let fits = max(1, Int(rect.height / (listRowHeight * scale)))
        var pieces: [PlacedPart] = []
        for (index, item) in items.prefix(fits).enumerated() {
            let top = rect.minY + CGFloat(index) * listRowHeight * scale
            let ink: ElementInk = item.isTop ? .room : .ink
            let value = DoorText.width(item.big, size: 26 * scale, bold: false)
            pieces.append(PlacedPart(id: "\(id).\(index).name", text: item.small,
                                     rect: CGRect(x: rect.minX, y: top + 10 * scale,
                                                  width: rect.width - value - 12, height: 26 * scale),
                                     size: 20 * scale, bold: true, ink: ink, isTarget: true))
            pieces.append(PlacedPart(id: "\(id).\(index).big", text: item.big,
                                     rect: CGRect(x: rect.maxX - value, y: top + 8 * scale, width: value,
                                                  height: 30 * scale), size: 26 * scale, ink: ink))
        }
        return pieces
    }

    private static func extent(_ node: PartNode, width: CGFloat, scale: CGFloat) -> CGFloat {
        switch node {
        case .title: 48
        case .line: 32
        case let .lines(_, texts): CGFloat(texts.count) * 24
        case let .number(_, _, _, label): numeral * scale + (label.isEmpty ? 0 : nameGap + 18 * scale)
        case .row: numeral * scale + nameGap + nameSize * 1.2 * scale + foot
        case let .list(_, items): CGFloat(items.count) * listRowHeight * scale
        case let .stack(_, axis, gap, children):
            axis == .vertical
                ? children.map { extent($0, width: width, scale: scale) }.reduce(0, +) + gap * CGFloat(max(
                    0,
                    children.count - 1
                ))
                : children.map { extent($0, width: width, scale: scale) }.max() ?? 0
        case let .grid(_, columns, children):
            CGFloat((children.count + columns - 1) / columns) *
                (children.map { extent($0, width: width, scale: scale) }.max() ?? 0)
        case .glyph: 80
        case let .doors(_, names): CGFloat(names.count) * 40
        case .actionWord: 50
        }
    }

    private static func stackPieces(_ axis: PartAxis, _ gap: CGFloat, _ children: [PartNode], in rect: CGRect,
                                    scale: CGFloat) -> [PlacedPart]
    {
        var pieces: [PlacedPart] = []
        var cursor = axis == .vertical ? rect.minY : rect.minX
        let share = rect.width / CGFloat(max(1, children.count))
        for child in children {
            if axis == .vertical {
                let height = extent(child, width: rect.width, scale: scale)
                pieces += place(
                    child,
                    in: CGRect(x: rect.minX, y: cursor, width: rect.width, height: height),
                    scale: scale
                )
                cursor += height + gap
            } else {
                pieces += place(child, in: CGRect(x: cursor, y: rect.minY, width: share - gap, height: rect.height),
                                scale: scale)
                cursor += share
            }
        }
        return pieces
    }

    private static func gridPieces(_ columns: Int, _ children: [PartNode], in rect: CGRect,
                                   scale: CGFloat) -> [PlacedPart]
    {
        let cell = rect.width / CGFloat(max(1, columns))
        let height = children.map { extent($0, width: cell, scale: scale) }.max() ?? 0
        var pieces: [PlacedPart] = []
        for (index, child) in children.enumerated() {
            let column = index % columns, row = index / columns
            pieces += place(
                child,
                in: CGRect(x: rect.minX + CGFloat(column) * cell, y: rect.minY + CGFloat(row) * height,
                           width: cell - 6, height: height),
                scale: scale
            )
        }
        return pieces
    }
}
