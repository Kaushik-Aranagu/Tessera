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

/// The body of a Pantry place (sheet 234 v4): two columns, each 232 pt tall, 16 pt apart. A section is a 26 pt header
/// and 44 pt rows; a section too tall for a column carries on in the next step. The step swipe starts only on a header
/// or in the space under the last thing, never within 20 pt of the left edge; a row swipe is used up or not now at
/// 70 pt, held to its column's clip. A tap flips in and low, a hold of 0.5 s pins. From the first accessibility size
/// there is one column with the same rules.
struct PantryColumnsView: View {
    let place: String
    let groups: [PantrySectionMap.Group]
    let perform: (PantryMove, PantryRoomItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// What each place was last packed as, kept for the visit.
    @State private var packers: [String: PantryPacker] = [:]
    @State private var touch: Touch?
    @State private var rowOffset: CGFloat = 0
    @State private var nudge: CGFloat = 0
    @State private var steps = 0
    @State private var bumps = 0
    @ScaledMetric(relativeTo: .caption) private var valueSize: CGFloat = 9

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

    private var packer: PantryPacker {
        packers[place] ?? PantryPacker(sections: sectionInfo, columnCount: columnCount)
    }

    private var sectionInfo: [PantryPacker.Section] {
        groups.map { .init(title: $0.title, rows: $0.items.count, urgent: PantrySectionMap.urgent($0)) }
    }

    /// The shape of the sections; the packing is rebuilt when it changes (a thing leaves, a thing arrives).
    private var signature: String {
        "\(columnCount)|" + groups.map { "\($0.title):\($0.items.count)" }.joined(separator: ",")
    }

    var body: some View {
        let current = packer
        VStack(alignment: .leading, spacing: 0) {
            nextLine(current)
            GeometryReader { geo in
                let width = (geo.size.width - Self.gap * CGFloat(columnCount - 1)) / CGFloat(columnCount)
                HStack(alignment: .top, spacing: Self.gap) {
                    ForEach(0 ..< columnCount, id: \.self) { column in
                        columnView(current, column: column)
                            .frame(width: width, height: PantryPacker.capacity, alignment: .top)
                            .clipped()
                    }
                }
                .offset(x: nudge)
                .contentShape(Rectangle())
                .gesture(gesture(current, width: width))
            }
            .frame(height: PantryPacker.capacity)
        }
        .onAppear { rebuild() }
        .onChange(of: signature) { rebuild() }
        .tesseraFeedback(.dialStep, trigger: steps)
        .tesseraFeedback(.notNow, trigger: bumps)
    }

    private func rebuild() {
        packers[place] = PantryPacker(sections: sectionInfo, columnCount: columnCount)
    }

    // MARK: Drawing

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

    private func columnView(_ packer: PantryPacker, column: Int) -> some View {
        let blocks = column < packer.columns.count ? packer.columns[column] : []
        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { blockIndex, block in
                    blockView(block, blockIndex: blockIndex, column: column, packer: packer)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .id(blocks.map { "\($0.section)-\($0.start)" }.joined())
            .transition(reduceMotion ? .identity : .asymmetric(insertion: .move(edge: .trailing),
                                                               removal: .move(edge: .leading)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(MotionPolicy.resolve(Theme.Motion.firm.delay(0.06 * Double(column)), reduceMotion: reduceMotion),
                   value: blocks.map { "\($0.section)-\($0.start)" })
    }

    private func blockView(_ block: PantryPacker.Block, blockIndex: Int, column: Int,
                           packer: PantryPacker) -> some View
    {
        let group = groups[block.section]
        let rows = Array(group.items[block.start ..< min(block.start + block.count, group.items.count)])
        return VStack(alignment: .leading, spacing: 0) {
            // The name in small caps in slate, a hairline under it, the count at the right (wine when something in the
            // section needs attention).
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.title)
                        .font(Theme.voice(size: 16).weight(.semibold).smallCaps())
                        .tracking(0.06 * 16)
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
                rowView(item)
                    .offset(x: swiping(column: column, block: blockIndex, row: rowIndex) ? rowOffset : 0)
            }
            if block.more > 0 {
                Text("\(block.more) more, swipe")
                    .font(Theme.voice(size: 13))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: PantryPacker.row, alignment: .leading)
                    .accessibilityLabel("\(block.more) more")
                    .accessibilityAction(named: "Next") { step(forward: true) }
            }
        }
    }

    private func rowView(_ item: PantryRoomItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(KitchenText.short(item.name, limit: 18))
                .font(Theme.voice(size: 17).weight(item.isPinned ? .semibold : .regular))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
                .frame(height: 22, alignment: .leading)
            Group {
                if item.isLow {
                    Text("low").font(Theme.voice(size: valueSize).weight(.semibold))
                        .foregroundStyle(Theme.Colors.Accent.kitchenWarn)
                } else if let amount = item.amount {
                    Text(amount).font(Theme.voice(size: valueSize)).foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    Text(" ").font(Theme.voice(size: valueSize))
                }
            }
            .tracking(0.02 * valueSize)
            .lineLimit(1)
            .frame(height: 13, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: PantryPacker.row, maxHeight: PantryPacker.row, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spoken)
        .accessibilityAction(named: "Used up") { perform(.usedUp, item) }
        .accessibilityAction(named: "Not now") { perform(.notNow, item) }
        .accessibilityAction(named: item.isPinned ? "Unpin" : "Pin") { perform(.pin, item) }
        .accessibilityAction(named: item.isLow ? "Back in" : "Running low") { perform(.toggle, item) }
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

    /// Where a touch landed, from the columns' own geometry.
    private func hit(_ point: CGPoint, packer: PantryPacker, width: CGFloat) -> Hit {
        let column = Int(point.x / (width + Self.gap))
        guard column < columnCount, point.x - CGFloat(column) * (width + Self.gap) <= width,
              column < packer.columns.count else { return .space }
        var y: CGFloat = 0
        for (blockIndex, block) in packer.columns[column].enumerated() {
            if point.y < y + PantryPacker.header {
                return .header
            }
            y += PantryPacker.header
            let rows = block.count
            let end = y + CGFloat(rows) * PantryPacker.row
            if point.y < end {
                return .row(column: column, block: blockIndex, row: Int((point.y - y) / PantryPacker.row))
            }
            y = end
            if block.more > 0 {
                if point.y < y + PantryPacker.row {
                    return .more
                }
                y += PantryPacker.row
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

    private func gesture(_ packer: PantryPacker, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pantryColumns"))
            .onChanged { value in
                if touch == nil {
                    let landed = hit(value.location, packer: packer, width: width)
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
