import SwiftUI
import TesseraCore

/// The Watch landing (Routines; sheet 283 on the shared scaffold): the woodland of 268 in the keystone, spanning the
/// phone's width; the switcher across Evening, Night, Morning with the needs beside it; the widget (next, thirsty, the
/// day's tally) with a bird-and-flower glyph; the groves on the dial; "Plant" at the foot. Private routines read
/// "Private routine" here and never leave the phone: nothing on this page reaches Claude, a widget or a backup.
struct RoutinesWoodlandLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var selected: UUID?
    @State private var planting = false
    @State private var draft = ""
    @State private var switcherIndex = WatchTime.current(AppClock.now).rawValue
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0

    /// Plum 8E4A78 light, D59AC4 dark (contract §9).
    static let accent = Color(light: 0x8E4A78, dark: 0xD59AC4)
    /// Wine, for a thirsty tree (241 "needs care"): 9A2541 / EE8E9C.
    static let wine = Color(light: 0x9A2541, dark: 0xEE8E9C)

    private var gold: Color {
        scheme == .dark ? Color(hex: 0xD9C27A) : Color(hex: 0x7E6A1E)
    }

    private var slate: Color {
        scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
    }

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let front = RoutinesFront(model: model, now: now)
        let today = TesseraDay().today(now)
        let facts = RoutinesWoodlandFacts(front: front, notNow: RoutinesNotNow.ids(on: today))
        let entries = front.items.map {
            WatchWords.Entry(name: $0.name, minute: $0.usual?.startMinuteOfDay, done: $0.doneAt != nil)
        }
        let time = WatchTime(rawValue: switcherIndex) ?? .evening
        let tapped = facts.trees.first { $0.id == selected }
        LandingScaffold(title: "Watch", accent: Self.accent, navWord: "Bridge", onBack: { dismiss() },
                        onTitle: { model.open(.routinesBrowse) },
                        switcher: WatchTime.allCases.map(\.word),
                        switcherIndex: $switcherIndex, switcherVerticalIndex: $switcherVerticalIndex,
                        needs: WatchWords.needs(time, entries),
                        keystone: { keystone(facts, now: now) },
                        caption: tapped.map { RoutinesWoodlandFacts.caption(for: $0, selected: true) }
                            ?? WatchWords.restCaption(hasTrees: !facts.trees.isEmpty),
                        widget: WatchWords.widget(facts, wine: Self.wine), widgetIndex: $widgetIndex,
                        openWidget: { item in
                            if let id = UUID(uuidString: item.id) {
                                model.open(.object(id))
                            } else {
                                model.open(.routinesBrowse)
                            }
                        },
                        glyph: { _ in WatchGlyph() },
                        doors: doors(facts), focus: $focus,
                        openDoor: { _ in model.open(.routinesBrowse) },
                        action: LandingFootAction(word: "Plant", hint: "Plants a new routine") {
                            draft = ""
                            planting = true
                        })
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                        .alert("Plant a routine", isPresented: $planting) {
                            TextField("Name", text: $draft)
                            Button("Plant") { plant() }
                            Button("Cancel", role: .cancel) {}
                        }
    }

    // MARK: Keystone

    /// The woodland is wider than the slot: it spans the phone (402 pt) and dissolves into the page at both edges.
    private func keystone(_ facts: RoutinesWoodlandFacts, now: Date) -> some View {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        let hour = Double(parts.hour ?? 12) + Double(parts.minute ?? 0) / 60
        return RoutinesWoodlandScene(trees: facts.trees, selected: selected, hour: hour, tap: { id in
            if selected == id {
                model.open(.object(id))
            } else {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { selected = id }
            }
        }, water: { id in
            let name = facts.trees.first { $0.id == id }?.name ?? "It"
            TessVoice.shared.say("\(name), watered.")
        })
        .frame(width: LandingKeystone<EmptyView>.size.width, height: LandingKeystone<EmptyView>.size.height)
        .accessibilityLabel("Your woodland")
    }

    // MARK: Doors

    private func doors(_ facts: RoutinesWoodlandFacts) -> [DialDoor] {
        facts.doors.map { door in
            let color: Color = switch door.id {
            case "fruit": gold
            case "lake": slate
            default: Self.accent
            }
            return DialDoor(id: door.id, name: door.name, count: door.count > 0 ? "\(door.count)" : nil,
                            color: color, lines: door.lines)
        }
    }

    // MARK: Plant

    /// "Plant" makes the routine (and adds it to the plan), then opens it to add its first step; Undo takes both.
    private func plant() {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        guard !title.isEmpty else { return }
        if looksLikeClaudeKey(title) {
            TessVoice.shared.say(claudeKeyLine)
            return
        }
        guard let made = try? model.engine.perform(CreateRoutine(title: title), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
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
        model.open(.object(made.output.id))
    }
}

// MARK: - Words

/// The switcher's three parts of the day (283): Evening (noon to 9 pm), Night (9 pm to 4 am), Morning (4 am to noon).
enum WatchTime: Int, CaseIterable {
    case evening, night, morning

    var word: String {
        switch self {
        case .evening: "Evening"
        case .night: "Night"
        case .morning: "Morning"
        }
    }

    /// "this evening", "tonight", "this morning".
    var phrase: String {
        switch self {
        case .evening: "this evening"
        case .night: "tonight"
        case .morning: "this morning"
        }
    }

    static func of(minute: Int) -> WatchTime {
        switch minute {
        case 240 ..< 720: .morning
        case 720 ..< 1260: .evening
        default: .night
        }
    }

    static func current(_ now: Date, calendar: Calendar = .current) -> WatchTime {
        let parts = calendar.dateComponents([.hour, .minute], from: now)
        return of(minute: (parts.hour ?? 12) * 60 + (parts.minute ?? 0))
    }
}

enum WatchWords {
    struct Entry: Equatable {
        let name: String
        /// Its usual start, minutes after midnight; nil when it has no usual time (it counts as evening).
        let minute: Int?
        let done: Bool
    }

    /// The two needs lines beside the switcher (283): the next one in that part of the day, then how it stands.
    /// Never "N of M".
    static func needs(_ time: WatchTime, _ entries: [Entry]) -> [String] {
        let mine = entries.filter { WatchTime.of(minute: $0.minute ?? 1080) == time }
        let open = mine.filter { !$0.done }.sorted { ($0.minute ?? 1080) < ($1.minute ?? 1080) }
        let done = mine.count - open.count
        let first: String = if let next = open.first {
            next.minute.map { "\(next.name), \(RoutinesLandingWords.clock($0))" } ?? next.name
        } else if done > 0 {
            "All kept \(time.phrase)"
        } else {
            "Nothing \(time.phrase)"
        }
        var parts: [String] = []
        if !open.isEmpty {
            parts.append("\(open.count) to tend")
        }
        if done > 0 {
            parts.append("\(done) done")
        }
        let second = parts.isEmpty ? "A quiet \(time.word.lowercased())" : parts.joined(separator: ", ")
        return [first, second]
    }

    /// The caption at rest: how to touch the woodland, longest first.
    static func restCaption(hasTrees: Bool) -> [String] {
        hasTrees ? ["Tap a tree to name it, hold it to water.", "Tap a tree, hold to water.", "Tap a tree."]
            : ["Plant a routine and it grows here.", "Nothing planted yet."]
    }

    /// The widget items (283): what is next, the thirstiest tree in wine, and the day's tally in words. Routines here
    /// are kept by running them, so nothing is struck from the widget (a strike would log a run that never happened).
    static func widget(_ facts: RoutinesWoodlandFacts, wine: Color) -> [WidgetItem] {
        var items: [WidgetItem] = []
        if let next = facts.updates.first(where: { $0.kind == .next }) {
            let when = next.rest.components(separatedBy: ", ").dropFirst().first
            items.append(WidgetItem(id: next.id.uuidString, header: "Next", big: next.name,
                                    middle: when.map { "Starts \($0)" } ?? "Any time today",
                                    small: "Tap to open it", strikeable: false))
        }
        let thirsty = facts.trees.filter { $0.health.isWithering || $0.health.isBare }
            .max { $0.health.consecutive < $1.health.consecutive }
        if let thirsty {
            items.append(WidgetItem(id: thirsty.id.uuidString, header: "Thirsty", big: thirsty.name,
                                    middle: thirsty.health.isBare ? "Could begin again" : "Needs a little care",
                                    small: "Hold its tree to water it", bigColor: wine, strikeable: false))
        }
        let due = facts.trees.filter { $0.dueToday || $0.doneToday }
        if !due.isEmpty {
            let done = due.filter(\.doneToday).count
            let left = due.count - done
            items.append(WidgetItem(id: "tally", header: "Today", big: "\(done)", bigIsNumber: true,
                                    middle: "kept today",
                                    small: left > 0 ? "\(left) still to tend" : "All kept", strikeable: false))
        }
        if items.isEmpty {
            items.append(WidgetItem(id: "quiet", header: "Watch", big: "Quiet day", middle: "Plant the first one",
                                    small: "Plant is at the foot", strikeable: false))
        }
        return items
    }
}

// MARK: - The widget glyph

// swiftlint:disable identifier_name -- short drawing names, as in the painter

/// The widget's glyph (283, Watch): a little bird hops onto a branch and the flower under it opens. It moves once on
/// arrival and every 7 s after; under Reduce Motion it is shown finished and still.
struct WatchGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var appeared = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(appeared).truncatingRemainder(dividingBy: 7)
            let p = reduceMotion ? 1 : min(1, elapsed / 1.8)
            Canvas { c, size in
                WatchGlyph.draw(&c, size: size, p: p, dark: scheme == .dark)
            }
        }
        .onAppear { appeared = Date() }
        .accessibilityHidden(true)
    }

    static func draw(_ c: inout GraphicsContext, size _: CGSize, p: Double, dark: Bool) {
        let ink = Color(hex: dark ? 0xCBBFAE : 0x6B5B45)
        // The branch.
        var branch = Path()
        branch.move(to: CGPoint(x: 6, y: 30))
        branch.addQuadCurve(to: CGPoint(x: 70, y: 24), control: CGPoint(x: 40, y: 36))
        c.stroke(branch, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        for (x, y, a) in [(24.0, 31.0, -0.5), (52.0, 28.0, 0.6)] {
            c.fill(Path(ellipseIn: CGRect(x: -5, y: -2.2, width: 10, height: 4.4))
                .applying(CGAffineTransform(rotationAngle: a).concatenating(CGAffineTransform(translationX: x, y: y))),
                with: .color(Color(hex: dark ? 0x9DB98A : 0x6F8A4E)))
        }
        // The bird: in from the right in two hops, then it settles on the branch.
        let hop = min(1, p / 0.7)
        let bx = 76 - 34 * hop
        let by = 24 - abs(sin(hop * .pi * 2)) * 10 * (1 - hop * 0.3)
        let bird = Color(hex: dark ? 0xD59AC4 : 0x8E4A78)
        c.fill(Path(ellipseIn: CGRect(x: bx - 6, y: by - 7, width: 12, height: 8)), with: .color(bird))
        c.fill(Path(ellipseIn: CGRect(x: bx - 9, y: by - 10, width: 6, height: 6)), with: .color(bird))
        var beak = Path()
        beak.move(to: CGPoint(x: bx - 9, y: by - 7.5))
        beak.addLine(to: CGPoint(x: bx - 12, y: by - 6.5))
        beak.addLine(to: CGPoint(x: bx - 9, y: by - 6))
        c.fill(beak, with: .color(Color(hex: 0xD9A24A)))
        var tail = Path()
        tail.move(to: CGPoint(x: bx + 5, y: by - 4))
        tail.addLine(to: CGPoint(x: bx + 11, y: by - 7))
        c.stroke(tail, with: .color(bird), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        // The flower under it opens once the bird has landed.
        let open = max(0, min(1, (p - 0.6) / 0.4))
        var stem = Path()
        stem.move(to: CGPoint(x: 40, y: 78))
        stem.addQuadCurve(to: CGPoint(x: 40, y: 54), control: CGPoint(x: 37, y: 66))
        c.stroke(stem, with: .color(Color(hex: dark ? 0x9DB98A : 0x6F8A4E)), lineWidth: 1.6)
        let petal = Color(hex: dark ? 0xF0BED5 : 0xD77FA1)
        for k in 0 ..< 6 {
            let a = Double(k) / 6 * .pi * 2
            let r = 2 + 5 * open
            let x = 40 + cos(a) * r, y = 52 + sin(a) * r
            c.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 2.2, width: 6, height: 4.4)),
                   with: .color(petal.opacity(0.5 + 0.5 * open)))
        }
        c.fill(Path(ellipseIn: CGRect(x: 37.5, y: 49.5, width: 5, height: 5)), with: .color(Color(hex: 0xE2B84E)))
    }
}

// swiftlint:enable identifier_name

/// One update row in the brief (contract §5, 64 pt slot, 17 pt light with the name in 600): tap opens, swipe right
/// starts it, swipe left is Not now. Both swipes go through the one gesture policy (`rowSwipe`).
struct RoutineUpdateRow: View {
    let update: RoutinesWoodlandFacts.Update
    let open: () -> Void
    let done: () -> Void
    let notNow: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var handled = false
    @State private var cue = HapticCue()

    var body: some View {
        Button {
            guard !handled else { return }
            open()
        } label: {
            line
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: pull)
        .rowSwipe(.both, limit: 150, onEvent: swiped)
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(update.text)
        .accessibilityHint("Opens it")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Start") { done() }
        .accessibilityAction(named: "Not now") { notNow() }
    }

    private var line: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(Self.forms(name: update.name, rest: update.rest).enumerated()), id: \.offset) { _, form in
                words(form.name, form.rest)
            }
        }
    }

    /// Longest first: the whole sentence, its short form, the name alone, then the name cut on whole words. Never
    /// wrapped, never "...".
    static func forms(name: String, rest: String) -> [(name: String, rest: String)] {
        var forms: [(name: String, rest: String)] = [(name, rest), (name, short(rest)), (name, "")]
        let parts = name.split(separator: " ")
        if parts.count > 1 {
            let small: Set = ["and", "the", "a", "an", "of", "to", "in", "on", "or", "for", "with", "at"]
            for count in stride(from: parts.count - 1, through: 1, by: -1)
                where !small.contains(parts[count - 1].lowercased())
            {
                forms.append((parts.prefix(count).joined(separator: " "), ""))
            }
        }
        return forms
    }

    private func words(_ name: String, _ rest: String) -> some View {
        (Text(name).fontWeight(.semibold).foregroundStyle(Theme.Colors.ink)
            + Text(rest).foregroundStyle(Theme.Colors.inkSecondary))
            .font(.custom("Figtree", size: 17, relativeTo: .body).weight(.light))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    /// " is next, around 5:30 pm" to " is next"; " needs a little care" to " needs care".
    static func short(_ rest: String) -> String {
        if let comma = rest.firstIndex(of: ",") {
            return String(rest[..<comma])
        }
        return rest.replacingOccurrences(of: " a little", with: "")
    }

    private func swiped(_ event: RowSwipeEvent) {
        switch event {
        case let .pulled(value):
            handled = true
            pull = value
        case let .committed(side):
            cue.play(side == .leading ? .done : .selection)
            if side == .leading {
                done()
            } else {
                notNow()
            }
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
        case .cancelled:
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
        case .ended:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                handled = false
            }
        case .armed, .disarmed:
            break
        }
    }
}
