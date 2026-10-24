import SwiftUI
import TesseraCore

/// One line in the Pantry room (sheet 232).
struct PantryRoomItem: Identifiable, Equatable {
    enum Source {
        case stock(ObjectRecord)
        case toGet(ListContents.Item)
        /// Added by hand; Core stores these when its action lands.
        case added
    }

    let id: UUID
    /// The real name: a private item shows it here and nowhere outside the room.
    let name: String
    let isLow: Bool
    let isPinned: Bool
    /// A quantity on To get, or nothing.
    let amount: String?
    let source: Source

    static func == (lhs: PantryRoomItem, rhs: PantryRoomItem) -> Bool {
        lhs.id == rhs.id && lhs.isLow == rhs.isLow && lhs.isPinned == rhs.isPinned && lhs.name == rhs.name
    }

    /// What VoiceOver says: "pinned, Eggs, low".
    var spoken: String {
        let parts: [String?] = [isPinned ? "pinned" : nil, name, isLow ? "low" : amount]
        return parts.compactMap(\.self).joined(separator: ", ")
    }
}

/// The room's words and paging, pure so they test without a screen.
enum PantryRoomCopy {
    static let rowsPerPage = 5
    static let rowHeight: CGFloat = 44
    static let bodyHeight: CGFloat = 220

    /// "Low on milk and eggs." / "All good in here."
    static func brief(low: [String]) -> String {
        guard !low.isEmpty else { return "All good in here." }
        let shown = Array(low.prefix(3)).map { $0.lowercased() }
        let joined = shown.count == 1 ? shown[0]
            : shown.dropLast().joined(separator: ", ") + " and " + shown[shown.count - 1]
        return "Low on \(joined)."
    }

    /// The To get brief: "Milk and eggs, and 3 more."
    static func toGetBrief(_ names: [String]) -> String {
        guard !names.isEmpty else { return "Nothing to get." }
        let shown = Array(names.prefix(2))
        let head = shown.count == 1 ? shown[0] : shown[0] + " and " + shown[1].lowercased()
        return names.count > 2 ? "\(head), and \(names.count - 2) more." : "\(head)."
    }

    /// "2 low" / "Nothing low".
    static func section(low: Int, toUse: Int) -> String {
        var parts: [String] = []
        if low > 0 {
            parts.append("\(low) low")
        }
        if toUse > 0 {
            parts.append("\(toUse) to use soon")
        }
        return parts.isEmpty ? "Nothing low" : parts.joined(separator: ", ")
    }

    static func pageCount(_ rows: Int) -> Int {
        max(1, (rows + rowsPerPage - 1) / rowsPerPage)
    }

    /// Pinned first (in the order pinned), then low, then the rest as they came.
    static func ordered(_ items: [PantryRoomItem], pinOrder: [UUID]) -> [PantryRoomItem] {
        let pinned = pinOrder.compactMap { id in items.first { $0.id == id && $0.isPinned } }
        let rest = items.filter { item in !pinned.contains { $0.id == item.id } }
        return pinned + rest.filter(\.isLow) + rest.filter { !$0.isLow }
    }

    /// "5 to get" / "Nothing to get".
    static func toGetWord(_ count: Int) -> String {
        count == 0 ? "Nothing to get" : "\(count) to get"
    }
}

/// Pantry (sheet 232): the place dial over To get, Fridge, Freezer, Shelf and Counter, two brief lines, a section line,
/// five 44 pt rows a page in a fixed 220 pt slot that turns vertically, and the foot "Add a thing". Swipe right is
/// used up (got it on To get), swipe left is not now, a tap flips in and low, and a hold of 0.5 s pins (three at most).
/// Every change is a receipt with the one Undo. A drag belongs to the region it starts in: the body never moves the
/// dial. Behind the Kitchen rooms switch; the older pages stay under Off.
struct PantryRoomPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var actions: PantryEngineActions?
    @State private var receipts = KitchenReceipts()
    @State private var focus = 0
    @State private var page = 0
    @State private var adding = false
    @State private var draft = ""
    @State private var trip = ShopTrip()
    @FocusState private var typing: Bool
    // The body gesture.
    @State private var touch: Touch?
    @State private var rowOffset: CGFloat = 0
    @State private var pageDrag: CGFloat = 0
    @State private var slide = 0

    private struct Touch {
        var start: CGPoint
        var row: Int?
        var axis: Axis?
        var held = false
        var holdTask: Task<Void, Never>?
    }

    private enum Axis { case horizontal, vertical }

    var body: some View {
        let _ = model.revision
        let board = PantryBoard(store: model.store, classes: model.classes) { GroceriesCopy.name($0) }
        let places = dialPlaces(board)
        let index = min(focus, max(places.count - 1, 0))
        let items = items(board, place: places.indices.contains(index) ? places[index].id : PantryPlaces.toGet)
        let pages = PantryRoomCopy.pageCount(items.count)
        let current = min(page, pages - 1)
        VStack(alignment: .leading, spacing: 0) {
            header(toGet: board.toGetCount, places: places)
            PlaceDial(places: places, focus: $focus)
                .padding(.horizontal, Theme.Spacing.gutter)
                .onChange(of: focus) { page = 0 }
            briefLines(board: board, place: places.indices.contains(index) ? places[index].id : PantryPlaces.toGet,
                       items: items)
            sectionLine(items: items, page: current, pages: pages)
            bodySlot(items: items, page: current, place: places.indices.contains(index) ? places[index] : nil)
            Spacer(minLength: 0)
            ReceiptLine(receipts: receipts).padding(.horizontal, Theme.Spacing.gutter)
            foot(place: places.indices.contains(index) ? places[index] : nil)
        }
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if actions == nil {
                actions = PantryEngineActions(engine: model.engine) { model.touch() }
            }
        }
    }

    // MARK: Body

    /// Five rows a page in a fixed 220 pt slot; the pages are stacked and turn vertically, one per gesture.
    private func bodySlot(items: [PantryRoomItem], page: Int, place: PlaceDial.Place?) -> some View {
        let pages = PantryRoomCopy.pageCount(items.count)
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(0 ..< pages, id: \.self) { number in
                    VStack(spacing: 0) {
                        ForEach(rows(items, page: number), id: \.element.id) { row in
                            rowView(row.element, index: row.offset, page: number == page)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(height: PantryRoomCopy.bodyHeight, alignment: .top)
                }
            }
            .offset(y: -CGFloat(page) * PantryRoomCopy.bodyHeight + pageDrag)
            // A row that leaves slides away and the ones under it close up.
            .animation(MotionPolicy.resolve(Theme.Motion.firm, reduceMotion: reduceMotion), value: items.map(\.id))
        }
        .frame(maxWidth: .infinity, minHeight: PantryRoomCopy.bodyHeight, maxHeight: PantryRoomCopy.bodyHeight,
               alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .gesture(bodyGesture(items: items, page: page, pages: pages, place: place))
        .tesseraFeedback(.dialStep, trigger: slide)
        .accessibilityElement(children: .contain)
    }

    private func rows(_ items: [PantryRoomItem], page: Int) -> [EnumeratedSequence<[PantryRoomItem]>.Element] {
        let start = page * PantryRoomCopy.rowsPerPage
        let end = min(start + PantryRoomCopy.rowsPerPage, items.count)
        return start < end ? Array(items[start ..< end].enumerated()) : []
    }

    private func rowView(_ item: PantryRoomItem, index: Int, page: Bool) -> some View {
        let swiping = touch?.row == index && touch?.axis == .horizontal && page
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(item.name)
                .font(Theme.voice(size: 17).weight(item.isPinned ? .semibold : .regular))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
            Spacer(minLength: Theme.Spacing.s)
            if item.isLow {
                Text("low")
                    .font(Theme.voice(size: 15).weight(.semibold))
                    .foregroundStyle(Theme.Colors.Accent.kitchenText)
            } else if let amount = item.amount {
                Text(amount)
                    .font(Theme.voice(size: 15))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(height: PantryRoomCopy.rowHeight)
        .offset(x: swiping ? rowOffset * 0.9 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spoken)
        .accessibilityAction(named: "Used up") { perform(.usedUp, on: item) }
        .accessibilityAction(named: "Not now") { perform(.notNow, on: item) }
        .accessibilityAction(named: item.isPinned ? "Unpin" : "Pin") { perform(.pin, on: item) }
        .accessibilityAction(named: item.isLow ? "Back in" : "Running low") { perform(.toggle, on: item) }
    }

    private enum Move { case usedUp, notNow, pin, toggle }

    private func perform(_ move: Move, on item: PantryRoomItem, place _: PlaceDial.Place? = nil) {
        guard let actions else { return }
        switch (move, item.source) {
        case let (.usedUp, .toGet(line)):
            guard let ingredient = Groceries(store: model.store, classes: model.classes).ingredient(of: line.object)
            else { return }
            say(actions.gotIt(ingredient, name: item.name))
        case let (.usedUp, .stock(record)):
            say(actions.usedUp(record, name: item.name))
        case let (.notNow, .stock(record)):
            say(actions.notNow(record, name: item.name))
        case let (.pin, .stock(record)):
            say(actions.pin(record, on: !item.isPinned, name: item.name))
        case let (.toggle, .stock(record)):
            say(actions.setStock(record, low: !item.isLow, name: item.name))
        default:
            break
        }
    }

    // MARK: Gesture

    /// One gesture for the whole body, so a drag belongs to the region it starts in: a sideways drag moves the row it
    /// started on, a vertical one turns the page, a touch held 0.5 s without moving 3 pt pins, and a touch that goes
    /// nowhere is a tap.
    private func bodyGesture(items: [PantryRoomItem], page: Int, pages: Int, place: PlaceDial.Place?) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if touch == nil {
                    let row = Int(value.location.y / PantryRoomCopy.rowHeight)
                    var next = Touch(start: value.location, row: row)
                    next.holdTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        guard !Task.isCancelled, touch?.axis == nil, let index = touch?.row else { return }
                        touch?.held = true
                        if let item = rows(items, page: page).first(where: { $0.offset == index })?.element {
                            perform(.pin, on: item, place: place)
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
                switch touch?.axis {
                case .horizontal: rowOffset = dx
                case .vertical: pageDrag = max(-60, min(60, dy))
                case nil: break
                }
            }
            .onEnded { value in
                defer {
                    touch?.holdTask?.cancel()
                    touch = nil
                    withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
                        rowOffset = 0
                        pageDrag = 0
                    }
                }
                guard let touch, !touch.held else { return }
                let dx = value.translation.width, dy = value.translation.height
                switch touch.axis {
                case .horizontal?:
                    guard abs(dx) >= 90, let index = touch.row,
                          let item = rows(items, page: page).first(where: { $0.offset == index })?.element
                    else { return }
                    perform(dx > 0 ? .usedUp : .notNow, on: item, place: place)
                case .vertical?:
                    let step = (dy < 0 ? 1 : -1)
                    guard abs(dy) > 40 || abs(value.velocity.height) > 300 else { return }
                    let target = min(max(self.page + step, 0), pages - 1)
                    if target != self.page {
                        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { self.page = target }
                        slide += 1
                    }
                case nil:
                    guard let index = touch.row,
                          let item = rows(items, page: page).first(where: { $0.offset == index })?.element
                    else { return }
                    perform(.toggle, on: item, place: place)
                }
            }
    }

    // MARK: Parts

    private func dialPlaces(_ board: PantryBoard) -> [PlaceDial.Place] {
        let pinned = PlaceDial.Place(id: PantryPlaces.toGet, name: PantryPlaces.toGet, count: board.toGetCount)
        return [pinned] + board.places.map { PlaceDial.Place(id: $0.id.uuidString, name: $0.name, count: $0.count) }
    }

    private func header(toGet: Int, places _: [PlaceDial.Place]) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Pantry")
                .font(Theme.voice(size: 17).weight(.semibold))
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { focus = 0 }
            } label: {
                Text(PantryRoomCopy.toGetWord(toGet))
                    .font(Theme.voice(size: 15))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .contentTransition(.numericText())
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows what to get")
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(minHeight: 44)
    }

    private func briefLines(board _: PantryBoard, place: String, items: [PantryRoomItem]) -> some View {
        let line = place == PantryPlaces.toGet
            ? PantryRoomCopy.toGetBrief(items.map(\.name))
            : PantryRoomCopy.brief(low: items.filter(\.isLow).map(\.name))
        return Text(line)
            .font(Theme.voice(size: 17))
            .foregroundStyle(Theme.Colors.ink)
            .contentTransition(.opacity)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func sectionLine(items: [PantryRoomItem], page: Int, pages: Int) -> some View {
        HStack {
            Text(PantryRoomCopy.section(low: items.filter(\.isLow).count, toUse: 0))
            Spacer(minLength: 0)
            if pages > 1 {
                Text("\(page + 1) of \(pages)")
            }
        }
        .font(Theme.voice(size: 13))
        .foregroundStyle(Theme.Colors.inkSecondary)
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(minHeight: 28)
    }

    private func foot(place: PlaceDial.Place?) -> some View {
        Group {
            if adding {
                TextField("Say it or type it. Tess puts it in the right place.", text: $draft)
                    .font(Theme.voice(size: 17))
                    .foregroundStyle(Theme.Colors.ink)
                    .focused($typing)
                    .submitLabel(.done)
                    .onSubmit { commitAdd(place: place) }
                    .padding(.horizontal, Theme.Spacing.gutter)
                    .frame(minHeight: 44)
            } else {
                KitchenFoot(action: "Add a thing", hint: "Say it or type it. Tess puts it in the right place.") {
                    adding = true
                    typing = true
                }
            }
        }
        .padding(.bottom, HomeMosaic.tessRoom / 2)
    }

    private func commitAdd(place: PlaceDial.Place?) {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        adding = false
        draft = ""
        guard !name.isEmpty, let actions, let place else { return }
        // To get is not a place: a new thing goes to the fridge unless a place is showing.
        let target = place.id == PantryPlaces.toGet ? PantryPlaces.defaultID("fridge") : UUID(uuidString: place.id)
        let placeName = place.id == PantryPlaces.toGet ? "Fridge" : place.name
        say(actions.add(name, to: target ?? PantryPlaces.defaultID("fridge"), placeName: placeName))
    }

    private func say(_ outcome: KitchenOutcome) {
        receipts.say(outcome.receipt, undo: outcome.undo)
    }

    // MARK: Data

    private func items(_ board: PantryBoard, place: String) -> [PantryRoomItem] {
        let now = AppClock.now
        if place == PantryPlaces.toGet {
            return board.toGet.flatMap(\.rows).compactMap { row -> PantryRoomItem? in
                guard case let .toGet(item, label) = row else { return nil }
                return PantryRoomItem(id: item.id, name: label, isLow: false, isPinned: false,
                                      amount: item.quantity, source: .toGet(item))
            }
        }
        guard let id = UUID(uuidString: place),
              let found = board.places.first(where: { $0.id == id }) else { return [] }
        let stock = PantryStock(store: model.store, classes: model.classes)
        let list: [PantryRoomItem] = found.groups.flatMap(\.rows).compactMap { row in
            guard case let .stock(entry) = row, !stock.isSnoozed(entry.ingredient, at: now) else { return nil }
            // Used up by hand: it left for To get.
            if let set = stock.level(of: entry.ingredient), set.level == .out {
                return nil
            }
            return PantryRoomItem(id: entry.id, name: model.store.displayTitle(of: entry.ingredient),
                                  isLow: entry.state == .low || entry.state == .out,
                                  isPinned: stock.isPinned(entry.ingredient), amount: nil,
                                  source: .stock(entry.ingredient))
        }
        let place = model.store.object(id: id)
        return PantryRoomCopy.ordered(list, pinOrder: stock.pinned(in: place).map(\.id))
    }
}
