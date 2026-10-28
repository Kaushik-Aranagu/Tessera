import SwiftUI
import TesseraCore
import UIKit

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
    @State private var waterRequest: WoodlandWaterRequest?
    /// The keystone hands the widget its item: the bird on arrival, petals when the item changes.
    @State private var handOver = WatchHandOver.Moment(kind: .bird, at: Date())

    static let accent = WatchRoomContent.accent
    static let wine = WatchRoomContent.wine

    var body: some View {
        let _ = model.revision
        let facts = WatchRoomContent.Facts.load(model: model, scheme: scheme, selected: selected)
        let time = WatchTime(rawValue: switcherIndex) ?? .evening
        LandingScaffold(title: "Watch", accent: Self.accent, navWord: "Bridge", onBack: { dismiss() },
                        onTitle: { model.open(.routinesBrowse) },
                        switcher: WatchTime.allCases.map(\.word),
                        switcherIndex: $switcherIndex, switcherVerticalIndex: $switcherVerticalIndex,
                        needs: facts.needs(time),
                        keystone: { keystone(facts) },
                        caption: facts.caption,
                        widget: facts.widget, widgetIndex: $widgetIndex,
                        openWidget: { item in
                            if let id = UUID(uuidString: item.id) {
                                model.open(.object(id))
                            } else {
                                model.open(.routinesBrowse)
                            }
                        },
                        glyph: { item in LandingGlyph(item: item, color: item.bigColor ?? Self.accent, room: .watch) },
                        doors: facts.doors, focus: $focus,
                        openDoor: { _ in model.open(.routinesBrowse) },
                        action: footAction(facts), summaryStyle: .grow)
            .overlay { WatchHandOver(moment: handOver) }
            .onAppear { handOver = .init(kind: .bird, at: Date()) }
            .onChange(of: widgetIndex) { _, index in
                handOver = .init(kind: index == 0 ? .bird : .petals, at: Date())
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .alert("Plant a routine", isPresented: $planting) {
                TextField("Name", text: $draft)
                Button("Plant") {
                    if let id = WatchActions.plant(draft, model: model) {
                        model.open(.object(id))
                    }
                    draft = ""
                }
                Button("Cancel", role: .cancel) {}
            }
    }

    // MARK: Keystone

    /// The woodland is wider than the slot: it spans the phone (402 pt) and dissolves into the page at both edges.
    private func keystone(_ facts: WatchRoomContent.Facts) -> some View {
        RoutinesWoodlandScene(trees: facts.trees, selected: selected, hour: WatchActions.hour(facts.now), tap: { id in
            if selected == id {
                model.open(.object(id))
            } else {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { selected = id }
            }
        }, water: { id in
            WatchActions.watered(facts.trees.first { $0.id == id }?.name ?? "It")
        }, waterRequest: waterRequest)
            .frame(width: LandingKeystone<EmptyView>.size.width, height: LandingKeystone<EmptyView>.size.height)
            .accessibilityLabel("Your woodland")
    }

    // MARK: Foot

    /// Verb over object (283 v3), from the shared steps: Plant a routine; across, Water and Pause.
    private func footAction(_ facts: WatchRoomContent.Facts) -> LandingFootAction {
        let target = facts.waterTarget
        let alternates: [LandingFootAction.Step] = facts.steps.dropFirst().map { step in
            .init(verb: step.verb, object: step.object) {
                if step.id == "water", let target {
                    waterRequest = WoodlandWaterRequest(id: target.id, at: Date())
                    WatchActions.watered(target.name)
                } else if step.id == "pause" {
                    WatchActions.togglePause(model: model)
                }
            }
        }
        return LandingFootAction(word: "Plant", object: "a routine", hint: "Plants a new routine",
                                 alternates: alternates)
        {
            draft = ""
            planting = true
        }
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
        /// Due today (only today's routines count in the needs).
        var due = true
    }

    /// The two needs lines beside the switcher (283): the next one in that part of the day, then how it stands.
    /// Never "N of M".
    static func needs(_ time: WatchTime, _ entries: [Entry]) -> [String] {
        let mine = entries.filter { ($0.due || $0.done) && WatchTime.of(minute: $0.minute ?? 1080) == time }
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

    /// The widget's Big line holds 262 pt of Figtree 700 38: the longest whole-word cut of the name that fits, never
    /// "..." (the kit draws the Big line on one line).
    static func bigFit(_ name: String, width: CGFloat = 262) -> String {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Figtree", .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold],
        ])
        let font = UIFont(descriptor: descriptor, size: 38)
        let forms = FitLine.cuts(name)
        return forms.first { ($0 as NSString).size(withAttributes: [.font: font]).width <= width } ?? forms.last ?? name
    }

    /// What the foot's Water waters: the tree named in the caption, else the thirstiest, else the first due today.
    static func waterTarget(_ facts: RoutinesWoodlandFacts, selected: UUID?) -> WoodlandTree? {
        if let selected, let tree = facts.trees.first(where: { $0.id == selected }) {
            return tree
        }
        let thirsty = facts.trees.filter { $0.health.isWithering || $0.health.isBare }
            .max { $0.health.consecutive < $1.health.consecutive }
        return thirsty ?? facts.trees.first { $0.dueToday && !$0.doneToday } ?? facts.trees.first
    }

    /// The caption at rest: how to touch the woodland, longest first.
    static func restCaption(hasTrees: Bool) -> [String] {
        hasTrees ? ["Tap a tree to name it, hold it to water", "Tap a tree, hold to water", "Tap a tree"]
            : ["Plant a routine and it grows here", "Nothing planted yet"]
    }

    /// The widget items (283): what is next, the thirstiest tree in wine, and the day's tally in words. Routines here
    /// are kept by running them, so nothing is struck from the widget (a strike would log a run that never happened).
    static func widget(_ facts: RoutinesWoodlandFacts, wine: Color) -> [WidgetItem] {
        var items: [WidgetItem] = []
        if let next = facts.updates.first(where: { $0.kind == .next }) {
            let when = next.rest.components(separatedBy: ", ").dropFirst().first
            items.append(WidgetItem(id: next.id.uuidString, header: "Next", big: bigFit(next.name),
                                    middle: when.map { "Starts \($0)" } ?? "Any time today",
                                    small: "Tap to open it", strikeable: false))
        }
        let thirsty = facts.trees.filter { $0.health.isWithering || $0.health.isBare }
            .max { $0.health.consecutive < $1.health.consecutive }
        if let thirsty {
            items.append(WidgetItem(id: thirsty.id.uuidString, header: "Thirsty", big: bigFit(thirsty.name),
                                    middle: thirsty.health.isBare ? "Could begin again" : "Needs a little care",
                                    small: "Hold its tree to water it", bigColor: wine, strikeable: false))
        }
        let due = facts.trees.filter { $0.dueToday || $0.doneToday }
        if !due.isEmpty {
            let done = due.filter(\.doneToday).count
            let left = due.count - done
            items.append(WidgetItem(id: "tally", header: "Today", big: "\(done)", bigIsNumber: true,
                                    middle: "tended today",
                                    small: left > 0 ? "\(left) still to tend" : "All kept", strikeable: false))
        }
        if items.isEmpty {
            items.append(WidgetItem(id: "quiet", header: "Grove", big: "Quiet day", middle: "Nothing growing yet",
                                    small: "Plant is at the foot", strikeable: false))
        }
        return items
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
