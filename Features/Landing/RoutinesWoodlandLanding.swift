import SwiftUI
import TesseraCore

/// The Routines landing on the shared kit (248 v2, landing contract): the habit woodland in the keystone slot with its
/// caption line, the groves on the dial, two update rows in the brief (tap opens, swipe right starts it, swipe left
/// Not now, Undo for 10 s) and "Plant" at the foot. Private routines read "Private routine" here and never leave the
/// phone: nothing on this page reaches Claude, a widget or a backup.
struct RoutinesWoodlandLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var selected: UUID?
    @State private var planting = false
    @State private var draft = ""
    @State private var notNowTick = 0

    /// Plum 8E4A78 light, D59AC4 dark (contract §9).
    static let accent = Color(light: 0x8E4A78, dark: 0xD59AC4)
    private var gold: Color {
        scheme == .dark ? Color(hex: 0xD9C27A) : Color(hex: 0x7E6A1E)
    }

    private var slate: Color {
        scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
    }

    var body: some View {
        let _ = model.revision
        let _ = notNowTick
        let front = RoutinesFront(model: model, now: AppClock.now)
        let today = TesseraDay().today(AppClock.now)
        let facts = RoutinesWoodlandFacts(front: front, notNow: RoutinesNotNow.ids(on: today))
        LandingFrame(title: "Routines", accent: Self.accent, stateLine: facts.stateLine,
                     onTitle: { model.open(.routinesBrowse) },
                     keystone: { keystone(facts) },
                     doors: doors(facts), focus: $focus,
                     openDoor: { _ in model.open(.routinesBrowse) },
                     brief: { brief(facts, front: front) },
                     action: LandingFootAction(word: "Plant", hint: "Plants a new routine") {
                         draft = ""
                         planting = true
                     },
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .alert("Plant a routine", isPresented: $planting) {
                TextField("Name", text: $draft)
                Button("Plant") { plant() }
                Button("Cancel", role: .cancel) {}
            }
    }

    // MARK: Keystone

    private func keystone(_ facts: RoutinesWoodlandFacts) -> some View {
        let tapped = facts.trees.first { $0.id == selected }
        let caption = RoutinesWoodlandFacts.caption(for: tapped ?? facts.oldest, selected: tapped != nil)
        return LandingKeystone(label: "Your woodland") {
            VStack(spacing: 0) {
                RoutinesWoodlandScene(trees: facts.trees, selected: selected) { id in
                    if selected == id {
                        model.open(.object(id))
                    } else {
                        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { selected = id }
                    }
                }
                .offset(x: lean)
                .tesseraAnimation(Theme.Motion.house, value: focus)
                FitLine(forms: caption, size: 15, color: Theme.Colors.inkSecondary)
                    .frame(width: RoutinesWoodlandScene.size.width, height: 30, alignment: .leading)
                    .id(caption.first)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .padding(.top, 30)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    /// The woodland leans a little toward the focused grove (Body to the left bank, Mind and Home to the right).
    private var lean: CGFloat {
        switch RoutinesWoodlandFacts.doorNames[focus % RoutinesWoodlandFacts.doorNames.count].id {
        case "body": 8
        case "mind", "home": -8
        default: 0
        }
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

    // MARK: Brief

    private func brief(_ facts: RoutinesWoodlandFacts, front: RoutinesFront) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(facts.updates) { update in
                RoutineUpdateRow(update: update,
                                 open: { model.open(.object(update.id)) },
                                 done: { start(update.id, front: front) },
                                 notNow: { notNow(update) })
                    .frame(height: 64, alignment: .top)
            }
        }
    }

    /// Swipe right on a routine row: a workout routine is kept by running it, so it starts (Pick up when it runs).
    private func start(_ id: UUID, front: RoutinesFront) {
        guard let item = front.item(id) else { return }
        RoutinesStarter.start(item, running: front.running, model: model)
    }

    private func notNow(_ update: RoutinesWoodlandFacts.Update) {
        let day = TesseraDay().today(AppClock.now)
        RoutinesNotNow.set(update.id, on: day, hidden: true)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { notNowTick += 1 }
        TessVoice.shared.say("\(update.name), not now.", takeBack: {
            RoutinesNotNow.set(update.id, on: day, hidden: false)
            notNowTick += 1
        })
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
