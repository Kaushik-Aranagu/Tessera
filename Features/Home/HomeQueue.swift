import SwiftUI
import TesseraCore
import TesseraTess

// Today on Home (docs/design/today-on-home.md, M2 slices 8 and 9): the queue window under Now. Next, then Later,
// in one bounded surface with a heading that rolls; swipe right to finish (the strike follows the finger), swipe
// left for "not now". Tess says what happened beside her soul, with Undo.

// MARK: - Tess's voice for Home actions

/// What Tess says beside the soul after something happens on Home, and the op it can undo. One shared instance,
/// read by Home and `BottomChrome`.
@MainActor @Observable
final class TessVoice {
    static let shared = TessVoice()

    struct Note: Equatable {
        let id = UUID()
        let text: String
        let undo: OpRecord?
        /// What UNDO runs besides (or instead of) undoing the op: several ops, or state that isn't an op.
        var takeBack: (() -> Void)?

        static func == (lhs: Note, rhs: Note) -> Bool {
            lhs.id == rhs.id
        }
    }

    private(set) var note: Note?

    /// Shows `text` for 4 s (with UNDO when there's an op to undo). `holds` overrides how long it stays.
    func say(_ text: String, undo: OpRecord? = nil, holds: Duration? = nil, takeBack: (() -> Void)? = nil) {
        let note = Note(text: text, undo: undo, takeBack: takeBack)
        self.note = note
        Task { @MainActor in
            try? await Task.sleep(for: Self.hold(undo: undo != nil || takeBack != nil, holds: holds))
            if self.note?.id == note.id {
                self.note = nil
            }
        }
    }

    /// How long a line stays: a line with something to take back 10 s (M37), a plain line 4 s, or `holds`. Under
    /// VoiceOver UNDO is a flat 10 s, whatever the line asked for (UndoSlot ruling), so it can be reached.
    static func hold(undo: Bool, holds: Duration? = nil,
                     voiceOver: Bool = UIAccessibility.isVoiceOverRunning) -> Duration
    {
        if undo, voiceOver {
            return .seconds(10)
        }
        return holds ?? .seconds(undo ? 10 : 4)
    }

    func clear() {
        note = nil
    }
}

// MARK: - Queue data

/// One row in the queue: a task or tonight's workout, dated (today) or undated (Later, no time).
struct QueueEntry: Identifiable, Equatable {
    let id: UUID
    let title: String
    let time: Date?
    let isWorkout: Bool

    /// Next: up to three things after Now, in order. Later: the rest of today, then undated tasks.
    @MainActor
    static func split(model: AppModel, schedule: [ScheduleItem], current: ScheduleItem?, now: Date)
        -> (next: [QueueEntry], later: [QueueEntry])
    {
        let today = HomeData.upcoming(schedule, excluding: current, now: now)
            .map { QueueEntry(id: $0.id, title: $0.title, time: $0.start, isWorkout: $0.isWorkout) }
        let undated = TaskList(store: model.store, classes: model.classes).later()
            .filter { $0.id != current?.id }
            .map { QueueEntry(id: $0.id, title: $0.title, time: nil, isWorkout: false) }
        let next = Array(today.prefix(3))
        return (next, Array(today.dropFirst(3)) + undated)
    }
}

// MARK: - The window

/// One bounded surface: a pinned heading word, then Next (up to 3 rows at 21/500, ink stepping down) and Later
/// (21/400 at 62%). The pinned word rolls from Next to Later as the in-flow "Later" reaches it.
struct QueueWindow: View {
    let next: [QueueEntry]
    let later: [QueueEntry]

    static let rowHeight: CGFloat = 48
    static let headingHeight: CGFloat = 40
    static let gap: CGFloat = 24
    static let windowHeight: CGFloat = 156

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.homeRowGrabbed) private var rowGrabbed
    @State private var offset: CGFloat = 0
    /// Next's ids as last drawn, so a row that moves up into Next can bloom once (nil until the first draw).
    @State private var seenNext: Set<UUID>?

    /// Each Next row's height as drawn (a wrapped title makes a taller row).
    @State private var heights: [UUID: CGFloat] = [:]

    /// Where the in-flow "Later" word sits in the scroll content.
    private var laterWordY: CGFloat {
        next.isEmpty ? 0 : next.reduce(0) { $0 + (heights[$1.id] ?? Self.rowHeight) } + Self.gap
    }

    private var heading: String {
        next.isEmpty || offset >= laterWordY - 4 ? "Later" : "Next"
    }

    var body: some View {
        if next.isEmpty, later.isEmpty {
            Text("Nothing else today.")
                .textRole(.body)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                pinnedHeading
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(next.enumerated()), id: \.element.id) { index, entry in
                            QueueRow(entry: entry, isNext: true, ink: [1, 0.88, 0.76][min(index, 2)],
                                     arrives: seenNext != nil && !(seenNext ?? []).contains(entry.id))
                                .frame(minHeight: Self.rowHeight)
                                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { heights[entry.id] = $0 }
                                .transition(refill)
                        }
                        if !next.isEmpty, !later.isEmpty {
                            Text("Later")
                                .font(Theme.voice(size: 34))
                                .foregroundStyle(Theme.Colors.ink)
                                .opacity(inFlowOpacity)
                                .frame(height: Self.headingHeight, alignment: .bottomLeading)
                                .padding(.top, Self.gap - (Self.headingHeight - Self.rowHeight))
                                .accessibilityAddTraits(.isHeader)
                        }
                        ForEach(later) { entry in
                            QueueRow(entry: entry, isNext: false, ink: 0.62)
                                .frame(minHeight: Self.rowHeight)
                                .transition(refill)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollDisabled(rowGrabbed)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, new in
                    offset = new
                }
                .frame(height: Self.windowHeight)
                .mask {
                    VStack(spacing: 0) {
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 40)
                    }
                }
                .tesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), value: next.map(\.id))
                .onAppear { seenNext = Set(next.map(\.id)) }
                .onChange(of: next.map(\.id)) { _, ids in
                    Task { @MainActor in seenNext = Set(ids) }
                }
                .tesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), value: later.map(\.id))
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Next and Later, \(next.count + later.count) items")
        }
    }

    /// The pinned word rolls: the old word goes up 14 pt and fades, the new one comes up from 14 pt below.
    private var pinnedHeading: some View {
        ZStack(alignment: .bottomLeading) {
            Text(heading)
                .font(Theme.voice(size: 34))
                .foregroundStyle(Theme.Colors.ink)
                .id(heading)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .offset(y: heading == "Later" ? 14 : -14).combined(with: .opacity),
                    removal: .offset(y: heading == "Later" ? -14 : 14).combined(with: .opacity)
                ))
        }
        .frame(height: Self.headingHeight, alignment: .bottomLeading)
        .clipped()
        .tesseraAnimation(.spring(Spring(duration: 0.26, bounce: 0)), value: heading)
        .accessibilityAddTraits(.isHeader)
    }

    /// The in-flow word fades as it reaches the pinned heading, so there are never two.
    private var inFlowOpacity: Double {
        let distance = laterWordY - offset
        return Double(min(max(distance / Self.rowHeight, 0), 1))
    }

    /// The next item rises into the freed slot from 60 pt below.
    private var refill: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .offset(y: 60).combined(with: .opacity),
                                              removal: .opacity)
    }
}

// MARK: - A row

/// Dab, name and time. Press for a beat, then drag right: the strike follows the finger and past 140 pt the row
/// is done. Drag left: the row slides to reveal TOMORROW (or NEXT WEEK for an undated row); past 120 pt it moves.
/// Tap opens it.
private struct QueueRow: View {
    let entry: QueueEntry
    let isNext: Bool
    let ink: Double

    @Environment(AppModel.self) private var model
    private let voice = TessVoice.shared
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CGFloat = 0
    @State private var strike: Double = 0
    @State private var armed = false
    @State private var struck = false
    @State private var finishes = 0
    @State private var moves = 0
    @State private var away = false
    @State private var dried = false
    @State private var washing = false
    /// Set by the window when this row has just moved up into Next.
    var arrives = false
    @State private var holding = false
    @Environment(\.homePagerIdle) private var pagerIdle
    @Environment(\.homeRowGrab) private var grab

    private static let strikeSpan: CGFloat = 250
    /// Past this the row is done (and armed, with a `.selection`).
    private static let finishDistance: CGFloat = 140
    private static let moveThreshold: CGFloat = 120

    private var destination: String {
        entry.time == nil ? "NEXT WEEK" : "TOMORROW"
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // The destination word waits in the track and rises in once the row has slid clear of it.
            Text(destination)
                .textRole(.labelStrong)
                .foregroundStyle(Theme.Colors.ink)
                .opacity(Double(min(max((-drag - 110) / 20, 0), 1)))
                .offset(y: drag < -110 ? 0 : 6)
                .accessibilityHidden(true)
            content
                .offset(x: drag < 0 ? leftOffset : 0)
                // Lifted while held: a soft shadow on the text itself and a slight scale, no highlight shape.
                .scaleEffect(holding && !struck ? 1.03 : 1, anchor: .leading)
                // The shadow lifts on light looks only; on dark ones ink would glow (B14). Scale and haptic carry it
                // there.
                .shadow(color: Theme.Colors.ink.opacity(holding && !struck && !Theme.Colors.halo ? 0.18 : 0),
                        radius: 6, y: 3)
                .tesseraAnimation(.spring(Spring(duration: 0.25, bounce: 0.2)), value: holding)
        }
        .contentShape(Rectangle())
        // A UIKit press-then-drag: it never claims a moving finger, so a flick always pages Home; once the press
        // lands, Home and the queue stop scrolling (below) and the drag belongs to the row.
        .gesture(RowPressDrag(
            isEnabled: !entry.isWorkout && pagerIdle && !struck,
            began: { holding = true },
            changed: { track($0) },
            ended: { commit($0) },
            cancelled: { holding = false }
        ))
        .onTapGesture { model.open(.object(entry.id)) }
        .modifier(ZoomSource(id: Route.object(entry.id), namespace: namespace))
        .tesseraFeedback(trigger: armed) { _, now in now ? .selection : nil }
        .tesseraFeedback(trigger: holding) { _, now in now ? .pickedUp : nil }
        // A held row that leaves the tree (it finished, or the page changed) must give the pager back.
        .onDisappear {
            if holding {
                grab(false)
            }
        }
        .onChange(of: holding) { _, now in
            grab(now)
            if !now {
                settle()
            }
        }
        .tesseraFeedback(.done, trigger: finishes)
        .tesseraFeedback(.notNow, trigger: moves)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.time.map { "\(entry.title), \(Format.clock($0))" } ?? entry.title)
        .accessibilityHint("Opens \(entry.title)")
        .accessibilityAction(named: "Done") {
            if !entry.isWorkout {
                finish()
            }
        }
        .accessibilityAction(named: "Not now") {
            if !entry.isWorkout {
                move()
            }
        }
        .onAppear {
            if arrives {
                bloom()
            }
        }
        .onChange(of: arrives) { _, now in
            if now {
                bloom()
            }
        }
        #if DEBUG
        .task { await playScript() }
        #endif
    }

    #if DEBUG
        /// `-queueScript`: the first undone task row strikes itself as if dragged right; a row that is dated later
        /// in the evening then slides left to Tomorrow. Lets the motion be recorded without touch automation.
        private func playScript() async {
            guard LaunchFlags.has("-queueScript"), !entry.isWorkout,
                  !QueueRow.scripted.contains(entry.id), QueueRow.scripted.count < 2 else { return }
            QueueRow.scripted.insert(entry.id)
            let first = QueueRow.scripted.count == 1
            try? await Task.sleep(for: .seconds(first ? 2.5 : 8))
            if first {
                for step in 1 ... 38 {
                    drag = CGFloat(step) * 4
                    strike = min(Double(drag / Self.strikeSpan), 1)
                    armed = drag >= Self.finishDistance
                    try? await Task.sleep(for: .milliseconds(16))
                }
                finish()
            } else {
                for step in 1 ... 34 {
                    drag = -CGFloat(step) * 4
                    armed = -drag >= Self.moveThreshold
                    try? await Task.sleep(for: .milliseconds(16))
                }
                try? await Task.sleep(for: .milliseconds(250))
                move()
            }
        }

        @MainActor private static var scripted: Set<UUID> = []
    #endif

    /// The row's class pigment, for its moments only (no dot ever sits beside the name: no-dots.md).
    private var pigment: Color {
        entry.isWorkout ? Theme.Colors.live : Theme.Colors.context
    }

    private var content: some View {
        // The time sits on the title's first baseline at its own width, so a long title takes the rest of the row and
        // wraps beside it: nothing cut, nothing under it (Design on #507).
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Text(entry.title)
                .font(Theme.Typography.font(Theme.concept.scale.body, weight: isNext ? .medium : .regular))
                .foregroundStyle(Theme.Colors.ink.opacity(struck ? 0.45 : ink))
                // A long title wraps; it never ends in "…" (41.2).
                .fixedSize(horizontal: false, vertical: true)
                // Finishing paints the strike wet in the row's pigment, then it dries to ink with the name.
                .textRenderer(StrikeRenderer(progress: strike, color: dried ? Theme.Colors.ink.opacity(0.45)
                        : pigment))
                .background(alignment: .leading) {
                    // Becoming next: one faint wash of the pigment blooms behind the name, then rests in ink.
                    RadialGradient(colors: [pigment.opacity(0.16), .clear], center: .center, startRadius: 0,
                                   endRadius: 90)
                        .frame(width: 180, height: 60)
                        .scaleEffect(washing ? 1.08 : 0.7)
                        .opacity(washing ? 1 : 0)
                        .allowsHitTesting(false)
                }
            Spacer(minLength: Theme.Spacing.s)
            if let time = entry.time {
                // Lowercase like the sentences and the hero: "8:30 pm" (Design picked .data over .label).
                Text(Format.clock(time))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
                    .fixedSize()
                    .opacity(struck ? 0 : Double(max(0, 1 - abs(drag) / 40)))
            }
        }
        .frame(maxHeight: .infinity)
    }

    /// The time stays put while the title travels, and fades out over the first 40 pt of a drag.
    /// 1:1 to 150 pt, then rubber-banded at 35%.
    private var leftOffset: CGFloat {
        let pull = -drag
        return -(pull <= 150 ? pull : 150 + (pull - 150) * 0.35)
    }

    private func commit(_ distance: CGFloat) {
        holding = false
        if distance >= Self.finishDistance {
            finish()
        } else if -distance >= Self.moveThreshold {
            move()
        } else {
            settle()
        }
    }

    private func track(_ distance: CGFloat) {
        drag = distance
        if distance > 0 {
            strike = min(Double(distance / Self.strikeSpan), 1)
            armed = distance >= Self.finishDistance
        } else {
            strike = 0
            armed = -distance >= Self.moveThreshold
        }
    }

    /// Back to rest: the strike retracts (220 ms ease-out). Also runs when the gesture is cancelled.
    private func settle() {
        armed = false
        guard !struck, !away else { return }
        withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion) {
            drag = 0
            strike = 0
        }
    }

    /// Becoming next: one faint wash of the row's pigment blooms behind the name, then dries back to ink (QA N1).
    private func bloom() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.5)) { washing = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(Theme.Motion.dry(reduceMotion: reduceMotion)) { washing = false }
        }
    }

    /// The strike runs out, the name dims, the finish haptic fires; the row holds 600 ms, then the op lands and
    /// the queue closes up.
    private func finish() {
        finishes += 1
        // Reduce Motion: the strike draws in ink, no wet phase.
        dried = reduceMotion
        withTesseraAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.42), reduceMotion: reduceMotion) {
            strike = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 420))
            if let dry = Theme.Motion.dry(reduceMotion: reduceMotion) {
                withAnimation(dry) {
                    dried = true
                    struck = true
                }
            } else {
                dried = true
                struck = true
            }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 900))
            let record = try? model.engine.perform(SetTaskDone(task: entry.id, done: true), by: .user).record
            withTesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), reduceMotion: reduceMotion) {
                model.touch()
            }
            voice.say("\(entry.title), done.", undo: record)
        }
    }

    /// Tomorrow (a dated row) or next week (an undated one); the row slides away and the queue closes up.
    private func move() {
        moves += 1
        // Next week at 09:00 of his day seven days on (B1), so 01:00 Saturday still counts as Friday.
        let tesseraDay = TesseraDay()
        let target: Date? = entry.time == nil
            ? tesseraDay.adding(days: 7, to: tesseraDay.start(of: AppClock.now)).addingTimeInterval(5 * 3600)
            : nil
        away = true
        withTesseraAnimation(.easeIn(duration: 0.2), reduceMotion: reduceMotion) { drag = -420 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            let record = try? model.engine.perform(MoveTask(task: entry.id, to: target, time: AppClock.now), by: .user)
                .record
            withTesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), reduceMotion: reduceMotion) {
                model.touch()
            }
            // Thing first with where it went, the way Tess says it (Design on #553): "Stretch, tomorrow 7 am."
            let moved = model.store.object(id: entry.id).flatMap { model.store.value("startsAt", of: $0)?.dateValue }
            let when = entry.time == nil ? "next week"
                : moved.map { TessCaptureEngine.when($0, context: TessContext(now: AppClock.now)) } ?? "tomorrow"
            voice.say("\(entry.title), \(when).", undo: record)
        }
    }
}

extension EnvironmentValues {
    /// False while Home's pager is scrolling or settling; rows ignore their own gestures then.
    @Entry var homePagerIdle = true
    /// A row reports when it has the finger (after its press), so Home's pager and the queue stop scrolling.
    @Entry var homeRowGrab: (Bool) -> Void = { _ in }
    @Entry var homeRowGrabbed = false
}

/// Press for 0.2 s without moving, then drag: reports the horizontal travel since the press landed. Built on
/// `UILongPressGestureRecognizer`, which fails as soon as the finger moves before the press, so it never competes
/// with a scroll view's pan.
struct RowPressDrag: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    var began: () -> Void
    var changed: (CGFloat) -> Void
    var ended: (CGFloat) -> Void
    var cancelled: () -> Void

    final class Coordinator {
        var startX: CGFloat = 0
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context _: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.2
        recognizer.allowableMovement = 8
        recognizer.cancelsTouchesInView = false
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UILongPressGestureRecognizer, context _: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let x = recognizer.location(in: nil).x
        switch recognizer.state {
        case .began:
            context.coordinator.startX = x
            began()
        case .changed:
            changed(x - context.coordinator.startX)
        case .ended:
            ended(x - context.coordinator.startX)
        case .cancelled, .failed:
            cancelled()
        default:
            break
        }
    }
}
