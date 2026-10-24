import SwiftUI
import TesseraCore

/// What a gesture on a Pantry row asks for.
enum PantryMove {
    case usedUp, notNow, pin, toggle
}

/// Which section each thing sits in (sheet 234 v4): the fridge has Leftovers, Dairy and eggs, Meat and fish and Produce
/// (Leftovers wait on Core's 234 PR and stay empty); any other place, and To get, groups by shop aisle. At most four
/// sections a place; whatever is uncategorised, and whatever is past the fourth, goes in the last one. Pure.
enum PantrySectionMap {
    struct Group: Equatable {
        let title: String
        let items: [PantryRoomItem]
    }

    static let fridge = ["Leftovers", "Dairy and eggs", "Meat and fish", "Produce"]

    static func groups(place: String, items: [PantryRoomItem]) -> [Group] {
        if place.lowercased() == "fridge" {
            return fridgeGroups(items)
        }
        // By shop aisle in walking order; more than four: the rest join the last.
        var byTitle: [(title: String, order: Int, items: [PantryRoomItem])] = []
        for item in items {
            let title = item.aisle?.rawValue ?? "Other"
            let order = item.aisle.flatMap { Aisle.allCases.firstIndex(of: $0) } ?? Aisle.allCases.count
            if let index = byTitle.firstIndex(where: { $0.title == title }) {
                byTitle[index].items.append(item)
            } else {
                byTitle.append((title, order, [item]))
            }
        }
        byTitle.sort { $0.order < $1.order }
        var groups = byTitle.map { Group(title: $0.title, items: $0.items) }
        if groups.count > 4 {
            let tail = groups[3...].flatMap(\.items)
            groups = Array(groups[0 ..< 3]) + [Group(title: groups[3].title, items: tail)]
        }
        return groups
    }

    private static func fridgeGroups(_ items: [PantryRoomItem]) -> [Group] {
        func title(_ item: PantryRoomItem) -> String {
            switch item.aisle {
            case .dairy: "Dairy and eggs"
            case .meatSeafood: "Meat and fish"
            default: "Produce"
            }
        }
        // Pinned items sit at the top of their own section, counted in its rows (the items arrive pinned first).
        return fridge.compactMap { name in
            let inside = items.filter { title($0) == name }
            return inside.isEmpty ? nil : Group(title: name, items: inside)
        }
    }

    /// Rows low or near their day.
    static func urgent(_ group: Group) -> Int {
        group.items.filter(\.isLow).count
    }
}

/// How one row lays out (sheet 234 v6 to v8), pure so it is fit-tested without a screen. A value sits beside the name
/// when the name at 17 pt, an 8 pt gap and the value at 10.5 pt Light fit the column, else it drops under the name at
/// 8 pt Light on a 12 pt line. A row with beside (or no) value is 28 pt, a row with the value below is 34 pt. From the
/// first accessibility size the value is at least 11 pt Regular and the rows grow with the text.
@MainActor
enum PantryRowLayout {
    static let nameSize: CGFloat = 17
    static let besideValue: CGFloat = 10.5
    static let belowValue: CGFloat = 8
    static let gap: CGFloat = 8

    struct Fit: Equatable {
        let beside: Bool
        let height: CGFloat
    }

    /// `scale` is the text-size scale (1 at the default size); `large` is the first accessibility size and up.
    static func fit(name: String, value: String?, column: CGFloat, scale: CGFloat = 1, large: Bool = false) -> Fit {
        let nameWidth = KitchenText.width(name, weight: .regular, size: nameSize * scale)
        let line = max(28, 22 * scale + 6)
        guard let value, !value.isEmpty else { return Fit(beside: true, height: line) }
        let valueSize = (large ? max(besideValue * scale, 11) : besideValue * scale)
        let valueWidth = KitchenText.width(value, weight: large ? .regular : .light, size: valueSize)
        if nameWidth + gap + valueWidth <= column {
            return Fit(beside: true, height: line)
        }
        // The name line (22) and the value line (12), both growing with the text; at least 11 pt value at AX1 and up.
        let valueLine = large ? max(belowValue * scale, 11) * 1.3 : 12 * scale
        return Fit(beside: false, height: 22 * scale + valueLine)
    }
}

/// The body of a Pantry place (sheet 234 v4 to v8): columns of sections, each 232 pt tall and 16 pt apart. A section is
/// a 26 pt header and its rows; a section too tall for a column carries on in the next step. The step swipe starts only
/// on a header or in the space under the last thing, never within 20 pt of the left edge; a row swipe is used up or
/// not now at 70 pt, held to its column's clip. A tap flips in and low, a hold of 0.5 s pins. A low thing shows in its
/// name (wine, weight 500), never a word. From the first accessibility size there is one column with the same rules.
struct PantryColumnsView: View {
    let place: String
    let groups: [PantrySectionMap.Group]
    let perform: (PantryMove, PantryRoomItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// What each place was last packed as, kept for the visit.
    @State private var packers: [String: PantryPacker] = [:]
    @State private var width: CGFloat = 0
    @State private var touch: Touch?
    @State private var rowOffset: CGFloat = 0
    @State private var nudge: CGFloat = 0
    @State private var steps = 0
    @State private var bumps = 0

    static let gap: CGFloat = 16
    static let swipe: CGFloat = 70

    private struct Touch {
        var start: CGPoint
        var hit: Hit
        var axis: Axis?
        var held = false
        var holdTask: Task<Void, Never>?
    }

    private enum Axis { case horizontal, vertical }

    private enum Hit: Equatable {
        case row(column: Int, block: Int, row: Int)
        case more, header, space
    }

    private var columnCount: Int {
        typeSize >= .accessibility1 ? 1 : 2
    }

    private var scale: CGFloat {
        UIFontMetrics(forTextStyle: .body).scaledValue(for: 1)
    }

    private var columnWidth: CGFloat {
        guard width > 0 else { return 160 }
        return (width - Self.gap * CGFloat(columnCount - 1)) / CGFloat(columnCount)
    }

    /// The row layouts for the current column width and text size.
    private var fits: [[PantryRowLayout.Fit]] {
        groups.map { group in
            group.items.map {
                PantryRowLayout.fit(name: KitchenText.short($0.name, limit: 18), value: $0.amount,
                                    column: columnWidth, scale: scale, large: typeSize >= .accessibility1)
            }
        }
    }

    private func build() -> PantryPacker {
        let layouts = fits
        let sections = groups.indices.map { index in
            PantryPacker.Section(title: groups[index].title, heights: layouts[index].map(\.height),
                                 urgent: PantrySectionMap.urgent(groups[index]))
        }
        return PantryPacker(sections: sections, columnCount: columnCount)
    }

    private var packer: PantryPacker {
        packers[place] ?? build()
    }

    /// The shape of the sections; the packing is rebuilt when it changes (a thing leaves, a thing arrives, the text
    /// size or the width changes), and the beside-or-below choice with it.
    private var signature: String {
        "\(columnCount)|\(Int(columnWidth))|\(Int(scale * 100))|"
            + groups.map { "\($0.title):\($0.items.count)" }.joined(separator: ",")
    }

    var body: some View {
        let current = packer
        VStack(alignment: .leading, spacing: 0) {
            nextLine(current)
            columns(current)
                .frame(height: PantryPacker.capacity)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        }
        .onAppear { packers[place] = build() }
        .onChange(of: signature) { packers[place] = build() }
        .tesseraFeedback(.dialStep, trigger: steps)
        .tesseraFeedback(.notNow, trigger: bumps)
    }

    // MARK: Drawing

    private func columns(_ packer: PantryPacker) -> some View {
        let layouts = fits
        let columnWidth = columnWidth
        return HStack(alignment: .top, spacing: Self.gap) {
            ForEach(0 ..< columnCount, id: \.self) { column in
                columnView(packer, layouts: layouts, column: column)
                    .frame(width: columnWidth, height: PantryPacker.capacity, alignment: .top)
                    .clipped()
            }
        }
        .offset(x: nudge)
        .contentShape(Rectangle())
        .coordinateSpace(.named("pantryColumns"))
        .gesture(gesture(packer, layouts: layouts, width: columnWidth))
    }

    private func nextLine(_ packer: PantryPacker) -> some View {
        Button { step(forward: true) } label: {
            Text(packer.nextLine ?? " ")
                .font(Theme.voice(size: 13))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(packer.nextLine == nil)
        .accessibilityLabel(packer.nextLine ?? "")
        .accessibilityHint("Shows the next part")
    }

    private func columnView(_ packer: PantryPacker, layouts: [[PantryRowLayout.Fit]], column: Int) -> some View {
        let blocks = column < packer.columns.count ? packer.columns[column] : []
        let signature = blocks.map { "\($0.section)-\($0.start)" }
        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: PantryPacker.gap) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { blockIndex, block in
                    blockView(block, blockIndex: blockIndex, column: column, packer: packer, layouts: layouts)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .id(signature.joined())
            .transition(reduceMotion ? .identity : .asymmetric(insertion: .move(edge: .trailing),
                                                               removal: .move(edge: .leading)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(MotionPolicy.resolve(Theme.Motion.firm.delay(0.06 * Double(column)), reduceMotion: reduceMotion),
                   value: signature)
    }

    private func blockView(_ block: PantryPacker.Block, blockIndex: Int, column: Int, packer: PantryPacker,
                           layouts: [[PantryRowLayout.Fit]]) -> some View
    {
        let group = groups[block.section]
        let end = min(block.start + block.count, group.items.count)
        let rows = Array(group.items[block.start ..< end])
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.title)
                        .font(Theme.voice(size: 14).weight(.semibold).smallCaps())
                        .tracking(0.015 * 14)
                        .foregroundStyle(Theme.Colors.Accent.kitchenSection)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(group.items.count)")
                        .font(Theme.numeral(15, weight: .light))
                        .foregroundStyle(PantrySectionMap.urgent(group) > 0 ? Theme.Colors.Accent.kitchenWarn
                            : Theme.Colors.inkSecondary)
                }
                .frame(height: PantryPacker.header - 1, alignment: .bottom)
                Rectangle().fill(Theme.Colors.Accent.kitchenSection.opacity(0.5)).frame(height: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(packer.spokenHeader(block))
            .accessibilityAction(named: "Next") { step(forward: true) }
            .accessibilityAction(named: "Back") { step(forward: false) }
            ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, item in
                let fit = layouts[block.section][block.start + rowIndex]
                rowView(item, fit: fit)
                    .offset(x: swiping(column: column, block: blockIndex, row: rowIndex) ? rowOffset : 0)
            }
            if block.more > 0 {
                Text("\(block.more) more, swipe")
                    .font(Theme.voice(size: 8))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: PantryPacker.moreRow, alignment: .leading)
                    .accessibilityLabel("\(block.more) more")
                    .accessibilityAction(named: "Next") { step(forward: true) }
            }
        }
    }

    /// A row: the name (wine and weight 500 when low, never a word), the value beside it or under it in ink 2 Light.
    private func rowView(_ item: PantryRoomItem, fit: PantryRowLayout.Fit) -> some View {
        let large = typeSize >= .accessibility1
        let valueSize = fit.beside ? max(PantryRowLayout.besideValue * scale, large ? 11 : 0)
            : max(PantryRowLayout.belowValue * scale, large ? 11 : 0)
        let valueWeight: Font.Weight = large ? .regular : .light
        return Group {
            if fit.beside {
                HStack(alignment: .firstTextBaseline, spacing: PantryRowLayout.gap) {
                    name(item)
                    Spacer(minLength: 0)
                    if let value = item.amount {
                        Text(value).font(Theme.voice(size: valueSize).weight(valueWeight)).tracking(0.01 * valueSize)
                            .foregroundStyle(Theme.Colors.inkSecondary).lineLimit(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    name(item)
                    if let value = item.amount {
                        Text(value).font(Theme.voice(size: valueSize).weight(valueWeight)).tracking(0.03 * valueSize)
                            .foregroundStyle(Theme.Colors.inkSecondary).lineLimit(1).frame(height: 12 * scale)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: fit.height, maxHeight: fit.height, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spoken)
        .accessibilityAction(named: "Used up") { perform(.usedUp, item) }
        .accessibilityAction(named: "Not now") { perform(.notNow, item) }
        .accessibilityAction(named: item.isPinned ? "Unpin" : "Pin") { perform(.pin, item) }
        .accessibilityAction(named: item.isLow ? "Back in" : "Running low") { perform(.toggle, item) }
    }

    private func name(_ item: PantryRoomItem) -> some View {
        Text(KitchenText.short(item.name, limit: 18))
            .font(Theme.voice(size: PantryRowLayout.nameSize).weight(item.isLow || item.isPinned ? .medium : .regular))
            .foregroundStyle(item.isLow ? Theme.Colors.Accent.kitchenWarn : Theme.Colors.ink)
            .lineLimit(1)
    }

    private func swiping(column: Int, block: Int, row: Int) -> Bool {
        guard let touch, touch.axis == .horizontal, case let .row(c, b, r) = touch.hit else { return false }
        return c == column && b == block && r == row
    }

    // MARK: Gestures

    private func step(forward: Bool) {
        var next = packer
        let moved = forward ? next.advance() : next.back()
        if moved {
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { packers[place] = next }
            steps += 1
        } else if reduceMotion {
            bumps += 1
        } else {
            // Nothing moves: a 10 pt nudge toward the swipe and back.
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: false) { nudge = forward ? -10 : 10 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: false) { nudge = 0 }
            }
        }
    }

    /// Where a touch landed, from the columns' own geometry and the rows' real heights. A touch just outside a row
    /// (within the 44 pt target) counts for the nearest row.
    private func hit(_ point: CGPoint, packer: PantryPacker, layouts: [[PantryRowLayout.Fit]], width: CGFloat) -> Hit {
        let column = Int(point.x / (width + Self.gap))
        guard column < columnCount, point.x - CGFloat(column) * (width + Self.gap) <= width,
              column < packer.columns.count else { return .space }
        var y: CGFloat = 0
        for (blockIndex, block) in packer.columns[column].enumerated() {
            if blockIndex > 0 {
                y += PantryPacker.gap
            }
            if point.y < y + PantryPacker.header {
                return .header
            }
            y += PantryPacker.header
            for row in 0 ..< block.count {
                let height = layouts[block.section][block.start + row].height
                // The touch target is at least 44 pt: it reaches past a short row into the space around it.
                let reach = max(0, (44 - height) / 2)
                if point.y < y + height + reach {
                    return .row(column: column, block: blockIndex, row: row)
                }
                y += height
            }
            if block.more > 0 {
                if point.y < y + PantryPacker.moreRow {
                    return .more
                }
                y += PantryPacker.moreRow
            }
        }
        return .space
    }

    private func item(for hit: Hit, packer: PantryPacker) -> PantryRoomItem? {
        guard case let .row(column, blockIndex, row) = hit else { return nil }
        let block = packer.columns[column][blockIndex]
        let items = groups[block.section].items
        let index = block.start + row
        return items.indices.contains(index) ? items[index] : nil
    }

    private func gesture(_ packer: PantryPacker, layouts: [[PantryRowLayout.Fit]], width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pantryColumns"))
            .onChanged { value in
                if touch == nil {
                    let landed = hit(value.location, packer: packer, layouts: layouts, width: width)
                    var next = Touch(start: value.location, hit: landed)
                    if case .row = landed {
                        next.holdTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(500))
                            guard !Task.isCancelled, touch?.axis == nil, let held = item(for: landed, packer: packer)
                            else { return }
                            touch?.held = true
                            perform(.pin, held)
                        }
                    }
                    touch = next
                    return
                }
                let dx = value.translation.width, dy = value.translation.height
                if hypot(dx, dy) > 3 {
                    touch?.holdTask?.cancel()
                }
                if touch?.axis == nil, hypot(dx, dy) > 10, touch?.held == false {
                    touch?.axis = abs(dx) > abs(dy) ? .horizontal : .vertical
                }
                if touch?.axis == .horizontal, case .row = touch?.hit {
                    // Contained in the column's clip: never past its own width.
                    rowOffset = max(-width, min(width, dx))
                }
            }
            .onEnded { value in
                defer {
                    touch?.holdTask?.cancel()
                    touch = nil
                    withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { rowOffset = 0 }
                }
                guard let touch, !touch.held else { return }
                let dx = value.translation.width
                switch (touch.hit, touch.axis) {
                case let (landed, .horizontal?) where landed != .more && landed != .header && landed != .space:
                    guard abs(dx) >= Self.swipe, let held = item(for: landed, packer: packer) else { return }
                    perform(dx > 0 ? .usedUp : .notNow, held)
                case (.header, .horizontal?), (.space, .horizontal?), (.more, .horizontal?):
                    // The step swipe never starts within 20 pt of the left edge of the screen.
                    guard abs(dx) > 40, touch.start.x >= 0 else { return }
                    step(forward: dx < 0)
                case (.more, nil):
                    step(forward: true)
                case (.row, nil):
                    if let tapped = item(for: touch.hit, packer: packer) {
                        perform(.toggle, tapped)
                    }
                default:
                    break
                }
            }
    }
}
