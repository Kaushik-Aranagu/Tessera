import SwiftUI
import TesseraCore

/// The Watch (Routines) as content for the standing shell (sheet 283 v5): level 0 is the landing, the same content as
/// `RoutinesWoodlandLandingPage` (both read `Facts`, the one source); level 1 is a grove's door page, the Door title
/// and a Page of its routines. The woodland is a scene keystone ("watch.woods") the host draws, so it is untouched
/// when a door opens. Private routines read "Private routine" everywhere. Pure: no views, no store reads.
struct WatchRoomContent: RoomContent {
    static let room = "watch"
    static let accent = Color(light: 0x8E4A78, dark: 0xD59AC4)
    /// Wine, for a thirsty tree (241 "needs care"): 9A2541 / EE8E9C.
    static let wine = Color(light: 0x9A2541, dark: 0xEE8E9C)

    /// Everything the Watch says, read once from the store; the scaffold landing and the shell both use it.
    struct Facts: Equatable {
        var woodland = RoutinesWoodlandFacts(trees: [])
        var entries: [WatchWords.Entry] = []
        var doors: [DialDoor] = []
        var widget: [WidgetItem] = []
        /// The routines behind each door, in the woodland's order.
        var rows: [String: [ShellRow]] = [:]
        var paused = false
        var now = Date.now
        /// The tree named in the caption (the host's first tap); nil at rest.
        var selected: UUID?

        var trees: [WoodlandTree] {
            woodland.trees
        }

        /// The two needs lines for one part of the day.
        func needs(_ time: WatchTime) -> [String] {
            WatchWords.needs(time, entries)
        }

        /// The caption: the tapped tree's name and state, else how to touch the woodland.
        var caption: [String] {
            trees.first { $0.id == selected }.map { RoutinesWoodlandFacts.caption(for: $0, selected: true) }
                ?? WatchWords.restCaption(hasTrees: !trees.isEmpty)
        }

        /// What the foot's Water waters (the named tree, the thirstiest, the first due).
        var waterTarget: WoodlandTree? {
            WatchWords.waterTarget(woodland, selected: selected)
        }

        /// The foot as data (283 v3): Plant a routine; across, Water the target and Pause (or Resume) today.
        var steps: [ShellStep] {
            var steps = [ShellStep(id: "plant", verb: "Plant", object: "a routine")]
            if let target = waterTarget {
                steps.append(ShellStep(id: "water", verb: "Water", object: target.name))
            }
            steps.append(ShellStep(id: "pause", verb: paused ? "Resume" : "Pause", object: "today"))
            return steps
        }

        /// The grove's rows: today's routines, every routine (Body), the ones with fruit; the rest are empty until
        /// those routines arrive. A private routine's row reads "Private routine".
        static func rows(_ woodland: RoutinesWoodlandFacts) -> [String: [ShellRow]] {
            func row(_ tree: WoodlandTree) -> ShellRow {
                let detail = tree.doneToday ? "Done today"
                    : tree.health.isBare ? "Could begin again"
                    : tree.health.isWithering ? "Needs a little care"
                    : tree.dueToday ? "To tend today" : "Resting today"
                return ShellRow(id: tree.id.uuidString, title: tree.name, detail: detail, isPrivate: tree.isPrivate,
                                swipe: tree.dueToday && !tree.doneToday)
            }
            let trees = woodland.trees
            return [
                "today": trees.filter { $0.dueToday || $0.doneToday }.map(row),
                "body": trees.map(row),
                "fruit": trees.filter(\.hasFruit).map(row),
                "mind": [], "home": [], "lake": [],
            ]
        }

        /// The dial's doors in their meaning colours: Fruit gold, Across the lake slate, the groves plum.
        static func doors(_ woodland: RoutinesWoodlandFacts, scheme: ColorScheme) -> [DialDoor] {
            let gold = scheme == .dark ? Color(hex: 0xD9C27A) : Color(hex: 0x7E6A1E)
            let slate = scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
            return woodland.doors.map { door in
                let color: Color = switch door.id {
                case "fruit": gold
                case "lake": slate
                default: WatchRoomContent.accent
                }
                return DialDoor(id: door.id, name: door.name, count: door.count > 0 ? "\(door.count)" : nil,
                                color: color, lines: door.lines, rows: door.rows, more: door.more)
            }
        }

        /// The Watch's facts from the store (the same reads the scaffold landing made).
        @MainActor
        static func load(model: AppModel, scheme: ColorScheme, selected: UUID? = nil) -> Self {
            let now = AppClock.now
            let front = RoutinesFront(model: model, now: now)
            let today = TesseraDay().today(now)
            let woodland = RoutinesWoodlandFacts(front: front, notNow: RoutinesNotNow.ids(on: today))
            var facts = Self()
            facts.woodland = woodland
            facts.entries = front.items.map { item in
                WatchWords.Entry(name: item.name, minute: item.usual?.startMinuteOfDay, done: item.doneAt != nil,
                                 due: front.todayIDs.contains(item.id)
                                     || WoodlandLog.isDue(today: today, daily: item.daily, weekdays: item.weekdays))
            }
            facts.doors = doors(woodland, scheme: scheme)
            facts.widget = WatchWords.widget(woodland, wine: WatchRoomContent.wine)
            facts.rows = rows(woodland)
            facts.paused = WatchPause.isPaused(on: today)
            facts.now = now
            facts.selected = selected
            return facts
        }
    }

    let facts: Facts

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? "today")
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let time = WatchTime(rawValue: state.switcherIndex) ?? .evening
        let widget = facts.widget
        let item = widget.indices.contains(state.widgetIndex) ? widget[state.widgetIndex] : widget.first
        let doors = facts.doors
        let focused = doors.isEmpty ? nil : doors[((state.dialFocus % doors.count) + doors.count) % doors.count]
        return Screen(layout: .landing, slots: [
            .title: title,
            .navWord: SlotContent(id: "watch.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "watch.switcher", kind: .switcher,
                                   payload: .switcher(across: WatchTime.allCases.map(\.word), vertical: [])),
            .needs: SlotContent(id: ContentID("watch.needs.\(time.rawValue)"), kind: .text,
                                payload: .lines(facts.needs(time))),
            .keystone: keystone,
            .caption: caption,
            .widget: widget.isEmpty ? nil : SlotContent(id: "watch.widget", kind: .widget, payload: .widget(widget)),
            .glyph: item.map { SlotContent(id: ContentID("watch.glyph.\($0.id)"), kind: .glyph,
                                           payload: .glyph($0, color: $0.bigColor ?? Self.accent)) },
            .dial: doors.isEmpty ? nil : SlotContent(id: "watch.dial", kind: .dial, payload: .dial(doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("watch.summary.\(door.id)"), kind: .summary, payload: .summary(door))
            },
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let door = facts.doors.first { $0.id == id }
        let rows = facts.rows[id] ?? []
        let line = rows.isEmpty ? "Nothing planted here yet."
            : "\(rows.count) \(rows.count == 1 ? "routine" : "routines") growing here."
        return Screen(layout: .door, slots: [
            .title: title,
            .navWord: SlotContent(id: "watch.nav.watch", kind: .text, payload: .navWord("Watch")),
            .doorTitle: SlotContent(id: ContentID("watch.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(name: door?.name ?? "Today", line: line,
                                                        color: door?.color ?? Self.accent)),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("watch.door.\(id).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Shared by both levels (same ids: the woodland, title, caption and foot are not touched)

    private var title: SlotContent {
        SlotContent(id: "watch.title", kind: .text, payload: .title("Watch", accent: Self.accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: "watch.woods", kind: .scene, payload: .scene("watch.woods", label: "Your woodland"))
    }

    /// The caption's id follows the tapped tree, so naming a tree plays the caption's own move.
    private var caption: SlotContent {
        SlotContent(id: ContentID("watch.caption.\(facts.selected?.uuidString ?? "rest")"), kind: .text,
                    payload: .lines(facts.caption))
    }

    private var action: SlotContent {
        SlotContent(id: "watch.action", kind: .action, payload: .action(facts.steps, accent: Self.accent))
    }
}

/// The Watch's foot actions, shared by the scaffold landing and the shell host. Nothing here writes a run: routines
/// are kept by running them, so Water is a gesture of care and Pause is a day marker on this phone only.
@MainActor
enum WatchActions {
    /// "Plant" makes the routine (and adds it to the plan), with one Undo for both; returns the new routine's id.
    static func plant(_ draft: String, model: AppModel) -> UUID? {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        if looksLikeClaudeKey(title) {
            TessVoice.shared.say(claudeKeyLine)
            return nil
        }
        guard let made = try? model.engine.perform(CreateRoutine(title: title), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return nil
        }
        var records = [made.record]
        if let plan = model.plan,
           let added = try? model.engine.perform(AddRoutineToPlan(plan: plan.id, routine: made.output.id), by: .user)
        {
            records.append(added.record)
        }
        model.touch()
        TessVoice.shared.say("\(title) planted.", takeBack: { [model] in
            for record in records.reversed() {
                model.engine.undo(record)
            }
            model.touch()
        })
        return made.output.id
    }

    static func watered(_ name: String) {
        TessVoice.shared.say("\(name), watered.")
    }

    /// Pause (or resume) today, on this phone only, with a take-back.
    static func togglePause(model: AppModel) {
        let day = TesseraDay().today(AppClock.now)
        let was = WatchPause.isPaused(on: day)
        WatchPause.set(!was, on: day)
        model.touch()
        TessVoice.shared.say(was ? "Watch back on for today." : "Watch paused for today. Nothing is marked missed.",
                             takeBack: { [model] in
                                 WatchPause.set(was, on: day)
                                 model.touch()
                             })
    }

    /// The woodland's hour, for its light.
    static func hour(_ now: Date) -> Double {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        return Double(parts.hour ?? 12) + Double(parts.minute ?? 0) / 60
    }
}

/// The Watch opened through the standing shell (`-shellRoom watch` on the simulator). The woodland is drawn through
/// `shellScene`; a first tap on a tree names it in the caption, a second opens it; holding waters it. Doors push their
/// grove's page, back pops (restoring every place).
struct WatchShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var navigator = ShellNavigator(root: .landing(WatchRoomContent.room))
    @State private var selected: UUID?
    @State private var waterRequest: WoodlandWaterRequest?
    @State private var opened: Opened?
    @State private var planting = false
    @State private var draft = ""
    @State private var handOver = WatchHandOver.Moment(kind: .bird, at: Date())

    private struct Opened: Identifiable {
        let id: UUID
    }

    var body: some View {
        let _ = model.revision
        let facts = WatchRoomContent.Facts.load(model: model, scheme: scheme, selected: selected)
        ShellView(room: WatchRoomContent(facts: facts), navigator: navigator, accent: WatchRoomContent.accent,
                  act: { handle($0, facts) })
            .environment(\.shellScene) { _ in AnyView(woods(facts)) }
            .environment(\.doorSummaryStyle, .grow)
            .environment(\.shellGlyphRoom, .watch)
            .overlay { WatchHandOver(moment: handOver) }
            .onAppear {
                navigator.state.switcherIndex = WatchTime.current(AppClock.now).rawValue
                handOver = .init(kind: .bird, at: Date())
            }
            .onChange(of: navigator.state.widgetIndex) { _, index in
                handOver = .init(kind: index == 0 ? .bird : .petals, at: Date())
            }
            .sheet(item: $opened) { item in
                NavigationStack { ObjectPage(route: .object(item.id)) }
            }
            .alert("Plant a routine", isPresented: $planting) {
                TextField("Name", text: $draft)
                Button("Plant") {
                    if let id = WatchActions.plant(draft, model: model) {
                        opened = Opened(id: id)
                    }
                    draft = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        #if DEBUG
            .task { await walkForStills() }
        #endif
    }

    private func woods(_ facts: WatchRoomContent.Facts) -> some View {
        RoutinesWoodlandScene(trees: facts.trees, selected: selected, hour: WatchActions.hour(facts.now), tap: { id in
            if selected == id {
                opened = Opened(id: id)
            } else {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { selected = id }
            }
        }, water: { id in
            WatchActions.watered(facts.trees.first { $0.id == id }?.name ?? "It")
        }, waterRequest: waterRequest)
            .frame(width: LandingKeystone<EmptyView>.size.width, height: LandingKeystone<EmptyView>.size.height)
    }

    #if DEBUG
        /// `-shellDoor today` (simulator only, LaunchFlags): opens that grove 2 s after launch; `-shellBack` comes
        /// back.
        private func walkForStills() async {
            guard let door = LaunchFlags.value(after: "-shellDoor") else { return }
            try? await Task.sleep(for: .seconds(2))
            navigator.push(.door(WatchRoomContent.room, door))
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(3))
            navigator.pop()
        }
    #endif

    private func handle(_ intent: ShellIntent, _ facts: WatchRoomContent.Facts) {
        switch intent {
        case .done, .notNow:
            break
        case .back:
            navigator.pop()
        case let .openDoor(id):
            navigator.push(.door(WatchRoomContent.room, id))
        case let .openItem(id):
            if let uuid = UUID(uuidString: id) {
                opened = Opened(id: uuid)
            } else {
                navigator.push(.door(WatchRoomContent.room, "today"))
            }
        case .action("water"):
            if let target = facts.waterTarget {
                waterRequest = WoodlandWaterRequest(id: target.id, at: Date())
                WatchActions.watered(target.name)
            }
        case .action("pause"):
            WatchActions.togglePause(model: model)
        case .action:
            draft = ""
            planting = true
        }
    }
}
