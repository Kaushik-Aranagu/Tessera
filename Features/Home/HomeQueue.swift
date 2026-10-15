import SwiftUI
import TesseraCore

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

        static func == (lhs: Note, rhs: Note) -> Bool {
            lhs.id == rhs.id
        }
    }

    private(set) var note: Note?

    /// Shows `text` for 4 s (with UNDO when there's an op to undo).
    func say(_ text: String, undo: OpRecord? = nil) {
        let note = Note(text: text, undo: undo)
        self.note = note
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if self.note?.id == note.id {
                self.note = nil
            }
        }
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
    @State private var offset: CGFloat = 0

    /// Where the in-flow "Later" word sits in the scroll content.
    private var laterWordY: CGFloat {
        next.isEmpty ? 0 : CGFloat(next.count) * Self.rowHeight + Self.gap
    }

    private var heading: String {
        next.isEmpty || offset >= laterWordY - 4 ? "Later" : "Next"
    }

    var body: some View {
        if next.isEmpty, later.isEmpty {
            Text("Nothing else today.")
                .textRole(.body)
                .foregroundStyle(Theme.Colors.context)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                pinnedHeading
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(next.enumerated()), id: \.element.id) { index, entry in
                            QueueRow(entry: entry, isNext: true, ink: [1, 0.88, 0.76][min(index, 2)])
                                .frame(height: Self.rowHeight)
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
                                .frame(height: Self.rowHeight)
                                .transition(refill)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
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

/// Dab, name and time. Swipe right: the strike follows the finger and past 40% the row is done. Swipe left: the
/// row slides to reveal TOMORROW (or NEXT WEEK for an undated row); past 120 pt it moves. Tap opens it.
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

    private static let strikeSpan: CGFloat = 250
    private static let doneThreshold = 0.4
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
                .offset(x: drag < 0 ? leftOffset : drag * 0.04)
        }
        .contentShape(Rectangle())
        .gesture(entry.isWorkout ? nil : swipe)
        .onTapGesture { model.open(.object(entry.id)) }
        .modifier(ZoomSource(id: Route.object(entry.id), namespace: namespace))
        .sensoryFeedback(.selection, trigger: armed) { _, now in now }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: finishes)
        .sensoryFeedback(.impact(weight: .light), trigger: moves)
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
        #if DEBUG
        .task { await playScript() }
        #endif
    }

    #if DEBUG
        /// `-queueScript`: the first undone task row strikes itself as if dragged right; a row that is dated later
        /// in the evening then slides left to Tomorrow. Lets the motion be recorded without touch automation.
        private func playScript() async {
            guard ProcessInfo.processInfo.arguments.contains("-queueScript"), !entry.isWorkout,
                  !QueueRow.scripted.contains(entry.id), QueueRow.scripted.count < 2 else { return }
            QueueRow.scripted.insert(entry.id)
            let first = QueueRow.scripted.count == 1
            try? await Task.sleep(for: .seconds(first ? 2.5 : 8))
            if first {
                for step in 1 ... 30 {
                    drag = CGFloat(step) * 4
                    strike = min(Double(drag / Self.strikeSpan), 1)
                    armed = strike >= Self.doneThreshold
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

    private var content: some View {
        HStack(spacing: Theme.Spacing.m) {
            PaintDab(color: entry.isWorkout ? Theme.Colors.live : Theme.Colors.context, seed: entry.title.count)
            Text(entry.title)
                .font(Theme.Typography.font(Theme.concept.scale.body, weight: isNext ? .medium : .regular))
                .foregroundStyle(Theme.Colors.ink.opacity(struck ? 0.45 : ink))
                .lineLimit(1)
                .textRenderer(StrikeRenderer(progress: strike, color: Theme.Colors.ink.opacity(0.85)))
            Spacer(minLength: Theme.Spacing.s)
            if let time = entry.time {
                Text(Format.clock(time))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
            }
        }
        .frame(maxHeight: .infinity)
    }

    /// 1:1 to 150 pt, then rubber-banded at 35%.
    private var leftOffset: CGFloat {
        let pull = -drag
        return -(pull <= 150 ? pull : 150 + (pull - 150) * 0.35)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                guard !struck else { return }
                // Edge swipes page Home: a row gesture starts 24 pt in from either edge, mostly horizontal.
                let width = value.startLocation.x
                guard width > 24, abs(value.translation.width) > abs(value.translation.height) * 1.4 else { return }
                drag = value.translation.width
                if drag > 0 {
                    strike = min(Double(drag / Self.strikeSpan), 1)
                    armed = strike >= Self.doneThreshold
                } else {
                    strike = 0
                    armed = -drag >= Self.moveThreshold
                }
            }
            .onEnded { _ in
                if drag > 0, strike >= Self.doneThreshold {
                    finish()
                } else if drag < 0, -drag >= Self.moveThreshold {
                    move()
                } else {
                    withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion) {
                        drag = 0
                        strike = 0
                    }
                }
                armed = false
            }
    }

    /// The strike runs out, the name dims, the finish haptic fires; the row holds 600 ms, then the op lands and
    /// the queue closes up.
    private func finish() {
        finishes += 1
        withTesseraAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.18), reduceMotion: reduceMotion) {
            strike = 1
            struck = true
            drag = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 600))
            let record = try? model.engine.perform(SetTaskDone(task: entry.id, done: true), by: .user).record
            withTesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), reduceMotion: reduceMotion) {
                model.touch()
            }
            voice.say("Done. \(entry.title).", undo: record)
        }
    }

    /// Tomorrow (a dated row) or next week (an undated one); the row slides away and the queue closes up.
    private func move() {
        moves += 1
        let target: Date? = entry.time == nil
            ? Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: AppClock.now))?
            .addingTimeInterval(9 * 3600)
            : nil
        withTesseraAnimation(.easeIn(duration: 0.2), reduceMotion: reduceMotion) { drag = -420 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            let record = try? model.engine.perform(MoveTask(task: entry.id, to: target), by: .user).record
            withTesseraAnimation(.spring(Spring(duration: 0.42, bounce: 0.12)), reduceMotion: reduceMotion) {
                model.touch()
            }
            voice.say(entry.time == nil ? "Moved to next week." : "Moved to tomorrow.", undo: record)
        }
    }
}
