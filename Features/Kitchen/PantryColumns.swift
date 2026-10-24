import SwiftUI
import TesseraCore

/// What a gesture on a Pantry row asks for.
enum PantryMove: Hashable {
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

/// A target may grow only into empty space, never a header, paging control, another target or the column clip.
enum PantryTouch {
    static let minimum: CGFloat = 44

    static func accepts(_ point: CGPoint, in size: CGSize) -> Bool {
        point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height
    }

    static func target(for index: Int, rows: [CGRect], protected: [CGRect], bounds: CGRect) -> CGRect? {
        guard rows.indices.contains(index) else { return nil }
        func expanded(_ row: CGRect) -> CGRect {
            row.insetBy(dx: 0, dy: -max(0, (minimum - row.height) / 2))
        }
        let target = expanded(rows[index])
        guard bounds.contains(target), !protected.contains(where: { $0.intersects(target) }),
              !rows.indices.contains(where: { $0 != index && expanded(rows[$0]).intersects(target) })
        else { return nil }
        return target
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

/// Compact columns keep the approved 28/34 pt drawing. Only unambiguous 44 pt targets mutate directly;
/// compact targets open the item actions instead. Paging belongs to headers and empty space, never a row.
struct PantryColumnsView: View {
    let place: String
    let groups: [PantrySectionMap.Group]
    let perform: (PantryMove, PantryRoomItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// What each place was last packed as, kept for the visit.
    @State private var packers: [String: PantryPacker] = [:]
    @State private var width: CGFloat = 0
    @State private var showingActions = false
    @State private var selectedID: UUID?
    @State private var nudge: CGFloat = 0
    @State private var steps = 0
    @State private var bumps = 0

    static let gap: CGFloat = 16
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
        // A mutation can change the rows before onChange stores their new packing. Never index old blocks meanwhile.
        let fresh = build()
        guard let saved = packers[place], saved.sections == fresh.sections,
              saved.columns.count == columnCount else { return fresh }
        return saved
    }

    /// The shape of the sections; the packing is rebuilt when it changes (a thing leaves, a thing arrives, the text
    /// size or the width changes), and the beside-or-below choice with it.
    private var signature: String {
        "\(columnCount)|\(Int(columnWidth))|\(Int(scale * 100))|"
            + groups.map { "\($0.title):\($0.items.count)" }.joined(separator: ",")
            + fits.flatMap { $0.map { String(describing: $0.height) } }.joined(separator: ",")
    }

    var body: some View {
        let current = packer
        VStack(alignment: .leading, spacing: 0) {
            nextLine(current)
            columns(current)
                .frame(height: PantryPacker.capacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Measure the available room, not the fixed-width columns (which would keep feeding their 160 pt fallback).
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .sheet(isPresented: $showingActions) {
            PantryItemActions(items: groups.flatMap(\.items), selectedID: selectedID, perform: perform)
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
                    .contentShape(Rectangle())
                    .clipped()
            }
        }
        .offset(x: nudge)
    }

    private func nextLine(_ packer: PantryPacker) -> some View {
        let lineHeight = typeSize >= .accessibility3
            ? max(PantryTouch.minimum, UIFontMetrics(forTextStyle: .body).scaledValue(for: 28))
            : PantryTouch.minimum
        return HStack(spacing: Theme.Spacing.s) {
            Button {
                selectedID = nil
                showingActions = true
            } label: {
                Text("Choose a thing")
                    .frame(minWidth: PantryTouch.minimum, minHeight: lineHeight, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("pantry.chooseThing")
            .disabled(groups.allSatisfy(\.items.isEmpty))
            Spacer(minLength: 0)
            Button { step(forward: true) } label: {
                Text(packer.nextLine ?? " ")
                    .frame(minHeight: lineHeight, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .disabled(packer.nextLine == nil)
            .accessibilityLabel(packer.nextLine ?? "")
            .accessibilityHint("Shows the next part")
        }
        .font(Theme.voice(size: 13))
        .foregroundStyle(Theme.Colors.inkSecondary)
        .buttonStyle(.plain)
    }

    private struct RowFrame {
        let section: Int
        let row: Int
        let rect: CGRect
    }

    private func targets(_ blocks: [PantryPacker.Block], layouts: [[PantryRowLayout.Fit]]) -> [UUID: CGFloat] {
        var rows: [RowFrame] = []
        var protected: [CGRect] = []
        var y: CGFloat = 0
        for (index, block) in blocks.enumerated() {
            if index > 0 {
                y += PantryPacker.gap
            }
            protected.append(CGRect(x: 0, y: y, width: columnWidth, height: PantryPacker.header))
            y += PantryPacker.header
            for row in block.start ..< block.start + block.count {
                let height = layouts[block.section][row].height
                rows.append(RowFrame(section: block.section, row: row,
                                     rect: CGRect(x: 0, y: y, width: columnWidth, height: height)))
                y += height
            }
            if block.more > 0 {
                protected.append(CGRect(x: 0, y: y, width: columnWidth, height: PantryPacker.moreRow))
                y += PantryPacker.moreRow
            }
        }
        let bounds = CGRect(x: 0, y: 0, width: columnWidth, height: PantryPacker.capacity)
        let frames = rows.map(\.rect)
        var safe: [UUID: CGFloat] = [:]
        for (index, row) in rows.enumerated() {
            if let target = PantryTouch.target(for: index, rows: frames, protected: protected, bounds: bounds) {
                safe[groups[row.section].items[row.row].id] = target.height
            }
        }
        return safe
    }

    private func columnView(_ packer: PantryPacker, layouts: [[PantryRowLayout.Fit]], column: Int) -> some View {
        let blocks = column < packer.columns.count ? packer.columns[column] : []
        let signature = blocks.map { "\($0.section)-\($0.start)" }
        let safe = targets(blocks, layouts: layouts)
        let used = blocks.reduce(0) { $0 + $1.height } + CGFloat(max(0, blocks.count - 1)) * PantryPacker.gap
        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { blockIndex, block in
                    if blockIndex > 0 {
                        pagingSpace(height: PantryPacker.gap)
                    }
                    blockView(block, packer: packer, layouts: layouts, targets: safe)
                }
                pagingSpace(height: max(0, PantryPacker.capacity - used))
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

    private func pagingSpace(height: CGFloat) -> some View {
        Color.clear.frame(height: height).contentShape(Rectangle())
            .pageSwipe { step(forward: $0) }
    }

    private func blockView(_ block: PantryPacker.Block, packer: PantryPacker,
                           layouts: [[PantryRowLayout.Fit]], targets: [UUID: CGFloat]) -> some View
    {
        let group = groups[block.section]
        let end = min(block.start + block.count, group.items.count)
        let rows = Array(group.items[block.start ..< end])
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.title)
                        .font(Theme.voice(size: 14).weight(.semibold).smallCaps())
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .tracking(0.015 * 14)
                        .foregroundStyle(Theme.Colors.Accent.kitchenSection)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(group.items.count)")
                        .font(Theme.numeral(15, weight: .light))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(PantrySectionMap.urgent(group) > 0 ? Theme.Colors.Accent.kitchenWarn
                            : Theme.Colors.inkSecondary)
                }
                .frame(height: PantryPacker.header - 1, alignment: .bottom)
                Rectangle().fill(Theme.Colors.Accent.kitchenSection.opacity(0.5)).frame(height: 1)
            }
            .contentShape(Rectangle())
            .pageSwipe { step(forward: $0) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(packer.spokenHeader(block))
            .accessibilityAction(named: "Next") { step(forward: true) }
            .accessibilityAction(named: "Back") { step(forward: false) }
            ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, item in
                let fit = layouts[block.section][block.start + rowIndex]
                PantryRowControl(item: item, targetHeight: targets[item.id] ?? fit.height,
                                 direct: targets[item.id] != nil, perform: perform, openActions: {
                                     selectedID = item.id
                                     showingActions = true
                                 }, content: {
                                     rowView(item, fit: fit)
                                 })
                                 .frame(height: fit.height)
            }
            if block.more > 0 {
                Button { step(forward: true) } label: {
                    Text("\(block.more) more, swipe")
                        .font(Theme.voice(size: 8))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: PantryPacker.moreRow, alignment: .leading)
                        .accessibilityLabel("\(block.more) more")
                        .accessibilityAction(named: "Next") { step(forward: true) }
                }
                .buttonStyle(.plain)
                .pageSwipe { step(forward: $0) }
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
        .accessibilityHidden(true)
    }

    private func name(_ item: PantryRoomItem) -> some View {
        Text(KitchenText.short(item.name, limit: 18))
            .font(Theme.voice(size: PantryRowLayout.nameSize).weight(item.isLow || item.isPinned ? .medium : .regular))
            .foregroundStyle(item.isLow ? Theme.Colors.Accent.kitchenWarn : Theme.Colors.ink)
            .lineLimit(1)
    }

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
}
