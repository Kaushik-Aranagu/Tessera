import SwiftUI
import TesseraCore

/// The Purse as content for the standing shell (sheet 283 v5), and the one source of the Purse landing's words:
/// `MoneyLandingView` (the scaffold) reads the same `Facts`. Level 0 is the landing; level 1 a category's page (the
/// first door, This month, lists the month's spends by kind and day). Never a figure on the page outside the widget's
/// numbers; a walled kind reads "Private spend". Money stays here: nothing reaches Home, a widget, a log or Claude.
/// Pure: no views, no store reads.
struct PurseRoomContent: RoomContent {
    static let room = "purse"
    static let sceneKey = "purse.chart"

    struct Facts: Equatable {
        var wall = MoneyWall()
        var categories: [PurseCategory] = []
        var switcher: [String] = []
        var firstMonth = ""
        /// The needs for each switcher word, in `switcher` order.
        var needs: [[String]] = []
        var caption = "Nothing yet"
        var widget: [WidgetItem] = []
        var doors: [DialDoor] = []
        /// Each door's rows, for its page.
        var rows: [String: [ShellRow]] = [:]
    }

    let facts: Facts
    var accent: Color = LandingAccent.money

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? (facts.doors.first?.id ?? "this month"))
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let widget = facts.widget
        let item = widget.indices.contains(state.widgetIndex) ? widget[state.widgetIndex] : widget.first
        let doors = facts.doors
        let focused = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        let window = facts.needs.indices.contains(state.switcherIndex) ? state.switcherIndex : 0
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "purse.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "purse.switcher", kind: .switcher,
                                   payload: .switcher(across: facts.switcher, vertical: [])),
            .needs: facts.needs.isEmpty ? nil
                : SlotContent(
                    id: ContentID("purse.needs.\(window)"),
                    kind: .text,
                    payload: .lines(facts.needs[window])
                ),
            .keystone: keystone,
            .caption: caption,
            .widget: widget.isEmpty ? nil : SlotContent(id: "purse.widget", kind: .widget, payload: .widget(widget)),
            .glyph: item.map { SlotContent(id: ContentID("purse.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph($0, color: accent)) },
            .dial: doors.isEmpty ? nil : SlotContent(id: "purse.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("purse.summary.\(door.id)"), kind: .summary, payload: .summary(door))
            },
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let door = facts.doors.first { $0.id == id }
        let rows = facts.rows[id] ?? []
        let line = rows.isEmpty ? "Nothing here yet." : "\(rows.count) \(rows.count == 1 ? "spend" : "spends"), newest first."
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "purse.nav.purse", kind: .text, payload: .navWord("Purse")),
            .doorTitle: SlotContent(id: ContentID("purse.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(name: door?.name ?? "This month", line: line,
                                                        color: door?.color ?? accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("purse.door.\(id).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Shared by both levels (same ids: the chart, title, caption and action are not touched)

    private var title: SlotContent {
        SlotContent(id: "purse.title", kind: .text, payload: .title("Purse", accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(
            id: ContentID(Self.sceneKey),
            kind: .scene,
            payload: .scene(Self.sceneKey, label: "You are the stock")
        )
    }

    private var caption: SlotContent {
        SlotContent(id: "purse.caption", kind: .text, payload: .lines([facts.caption]))
    }

    private var action: SlotContent {
        SlotContent(id: "purse.action", kind: .action, payload: .action([
            ShellStep(id: "log", verb: "Log", object: "A spend"),
            ShellStep(id: "look", verb: "Look", object: "The month"),
            ShellStep(id: "plan", verb: "Plan", object: "This month"),
        ], accent: accent))
    }
}

// MARK: - The facts (one source for the scaffold landing and the shell)

extension PurseRoomContent.Facts {
    @MainActor
    static func load(model: AppModel, scheme _: ColorScheme) -> Self {
        let now = AppClock.now
        var facts = Self()
        facts.wall = wall(model: model, now: now)
        facts.categories = PurseBook(model: model, now: now).categories()
        facts.firstMonth = firstMonth(model: model, now: now)
        let month = now.formatted(Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.wide))
        facts.switcher = [month, "This year", "Since \(facts.firstMonth)"]
        facts.needs = (0 ..< facts.switcher.count).map { needs(facts.wall, firstMonth: facts.firstMonth, window: $0) }
        facts.caption = caption(facts.wall)
        facts.widget = widget(facts.categories)
        facts.doors = doors(facts.categories)
        facts.rows = rows(model: model, now: now, first: facts.doors.first?.id)
        return facts
    }

    @MainActor
    static func wall(model: AppModel, now: Date) -> MoneyWall {
        let calendar = Calendar.current
        let ledger = SpendLedger(store: model.store, classes: model.classes)
        var spends: [SpendLedger.Entry] = []
        for back in 0 ..< 3 {
            guard let month = calendar.date(byAdding: .month, value: -back, to: now) else { continue }
            spends += ledger.entries(inMonthOf: month, calendar: calendar)
        }
        let monthCount = ledger.entries(inMonthOf: now, calendar: calendar).count
        let shown = spends.sorted { $0.spentAt > $1.spentAt }.map { entry in
            MoneyWall.Spend(category: entry.category, at: entry.spentAt,
                            isPrivate: ObjectPrivacy.isPrivateWord(entry.category, in: model.store))
        }
        let monthName = now.formatted(Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.wide))
        let trend = MoneyTrend(store: model.store, classes: model.classes).compare(now: now, calendar: calendar)
        let sentence = trend.map { LandingSentences.money(nothingLate: false, due: nil, trend: $0.clause).text }
        return MoneyWall.build(spends: shown, monthCount: monthCount, monthName: monthName, trend: sentence)
    }

    @MainActor
    static func firstMonth(model: AppModel, now: Date) -> String {
        let first = model.classes[.spend].map { model.store.objects(of: $0) }?
            .compactMap { model.store.value("spentAt", of: $0)?.dateValue }.min() ?? now
        return first.formatted(Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.wide))
    }

    /// The categories are the doors too (contract v2 §12): turning the dial turns the chart, and the other way round.
    static func doors(_ categories: [PurseCategory]) -> [DialDoor] {
        categories.map { item in
            DialDoor(id: item.id, name: item.name, color: item.indices.isEmpty ? Theme.Colors.ink : LandingAccent.money,
                     label: item.indices.isEmpty ? "Not set up yet" : "Indices",
                     lines: item.indices.isEmpty ? []
                         : ["\(item.indices.count) \(item.indices.count == 1 ? "index" : "indices")"]
                         + item.indices.prefix(2).map(\.name.capitalized))
        }
    }

    /// The chart in words, never a figure: "Heading down at this pace." / "Nothing yet".
    static func caption(_ wall: MoneyWall) -> String {
        wall.monthCount == 0 ? "Nothing yet" : "The dashed line is where this pace ends the month."
    }

    /// Two lines beside the switcher: the month in words, or that the longer views come next. Never a figure.
    static func needs(_ wall: MoneyWall, firstMonth: String, window: Int) -> [String] {
        switch window {
        case 1: return ["The year view comes next", "Twelve months, payday to payday"]
        case 2: return ["Since \(firstMonth) comes next", "Every month side by side"]
        default:
            guard wall.monthCount > 0 else { return ["Nothing yet", "Log a spend to start the line"] }
            let last = wall.lastCategory.map { "Last on \($0)" } ?? (wall.lastIsPrivate ? "Last spend private" : "")
            return [wall.monthCount == 1 ? "1 spend so far" : "\(wall.monthCount) spends so far", last]
        }
    }

    /// The widget (283): still yours, spent today, spent this month. Numbers count up; no red or green; no strike.
    static func widget(_ categories: [PurseCategory]) -> [WidgetItem] {
        guard let month = categories.first?.indices.first, let spend = categories.first?.indices.dropFirst().first,
              !month.isEmpty
        else {
            return [WidgetItem(id: "nothing", header: "This month", big: "Nothing yet", middle: "Log a spend",
                               small: "It starts the line", strikeable: false)]
        }
        let today = (spend.solid.last ?? 0) - (spend.solid.dropLast().last ?? 0)
        // "Still yours" needs money in to mean anything; with no inflow logged it steps aside.
        let hasIncome = (month.solid.max() ?? 0) > 0
        return [
            WidgetItem(id: "yours", header: "Still yours", big: figure(month.solid.last ?? 0), bigIsNumber: true,
                       middle: "in minus out this month", small: "The solid line", strikeable: false),
            WidgetItem(id: "today", header: "Today", big: figure(today), bigIsNumber: true, middle: "spent today",
                       small: "Every spend a tick down", strikeable: false),
            WidgetItem(id: "month", header: "This month", big: figure(spend.solid.last ?? 0), bigIsNumber: true,
                       middle: "spent so far", small: "The dashed line is this pace", strikeable: false),
        ].filter { hasIncome || $0.id != "yours" }
    }

    /// A whole figure with grouping, no symbol and no cents: "2,125".
    static func figure(_ value: Double) -> String {
        value.rounded().formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "en_US")))
    }

    /// The first door's page: this month's spends, newest first, by kind and day. No amounts; a walled kind reads
    /// "Private spend". The other categories have no page rows yet.
    @MainActor
    static func rows(model: AppModel, now: Date, first: String?) -> [String: [ShellRow]] {
        guard let first else { return [:] }
        let ledger = SpendLedger(store: model.store, classes: model.classes)
        let spends = ledger.entries(inMonthOf: now).sorted { $0.spentAt > $1.spentAt }
        let style = Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.abbreviated).day()
        let rows = spends.map { entry -> ShellRow in
            let isPrivate = ObjectPrivacy.isPrivateWord(entry.category, in: model.store)
            let kind = entry.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = isPrivate ? "Private spend"
                : (kind.isEmpty || MoneyWall.looksLikeAmount(kind) ? "Spend" : kind.capitalized)
            return ShellRow(id: entry.object.id.uuidString, title: title, detail: entry.spentAt.formatted(style),
                            isPrivate: isPrivate)
        }
        return [first: rows]
    }
}

/// The Purse opened through the standing shell (`-shellRoom purse` on the simulator). The dial and the chart share
/// the category (the navigator's dial focus); the chart's index is its keystone page.
struct PurseShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigator = ShellNavigator(root: .landing(PurseRoomContent.room))
    @State private var adding = false
    @State private var draft = ""

    var body: some View {
        let _ = model.revision
        let facts = PurseRoomContent.Facts.load(model: model, scheme: scheme)
        ShellView(room: PurseRoomContent(facts: facts), navigator: navigator, accent: LandingAccent.money,
                  act: handle)
            .environment(\.doorSummaryStyle, .meter)
            .environment(\.shellGlyphRoom, .purse)
            .environment(\.shellScene) { _ in
                AnyView(PurseIndexView(categories: facts.categories, category: navigator.binding(\.dialFocus),
                                       index: navigator.binding(\.keystonePage)))
            }
            .overlay {
                if navigator.route.level == 0 {
                    KeystoneHandover(kind: .purseDot, from: MoneyLandingView.lineEnd())
                }
            }
            .alert("Log a spend", isPresented: $adding) {
                TextField("12.40 lunch", text: $draft)
                    .keyboardType(.numbersAndPunctuation)
                Button("Log") { MoneyLandingView.logSpend(draft, model: model, reduceMotion: reduceMotion) }
                Button("Cancel", role: .cancel) {}
            }
        #if DEBUG
            .task { await ShellStills.walk(navigator, room: PurseRoomContent.room) }
        #endif
    }

    private func handle(_ intent: ShellIntent) {
        switch intent {
        case .back:
            navigator.pop()
        case let .openDoor(id):
            navigator.push(.door(PurseRoomContent.room, id))
        case .openItem:
            break
        case let .action(id):
            switch id {
            case "look":
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
                    navigator.binding(\.dialFocus).wrappedValue = 0
                    navigator.binding(\.keystonePage).wrappedValue = 0
                    navigator.binding(\.switcherIndex).wrappedValue = 0
                }
            case "plan":
                TessVoice.shared.say("Plans for the month come with Bills.")
            default:
                draft = ""
                adding = true
            }
        }
    }
}
