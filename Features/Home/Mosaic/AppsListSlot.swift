import SwiftUI
import TesseraCore

/// The rows of the apps list (sheet 205), pure so they test without a screen: each app in the edge order with the one
/// line it has to say today, or a quiet line when it has nothing. Core masks private things and keeps Money to a due
/// word before the clause gets here. Core's AppSummaryLine replaces the clause here when it lands.
@MainActor
enum AppsListRows {
    struct Row: Identifiable, Equatable {
        /// Bridge's dial also holds two doors that are not apps (sheet 283): the weather landing and Settings.
        enum Extra: String { case lookout, settings }

        let app: HomeApp
        let summary: String
        let opens: HomeSentence.Opens?
        var extra: Extra?

        var id: String {
            extra?.rawValue ?? app.rawValue
        }

        /// The ship name on the dial (sheet 281).
        var name: String {
            switch extra {
            case .lookout: "Lookout"
            case .settings: "Settings"
            case nil: app.shipName
            }
        }

        var accent: Color {
            switch extra {
            case .lookout: Color(light: 0xC9772E, dark: 0xE8A06A)
            case .settings: Theme.Colors.ink
            case nil: app.accent
            }
        }

        /// What opening it shows.
        var door: HomeV2Door {
            switch extra {
            case .lookout: .lookout
            case .settings: .settings
            case nil: .app(app)
            }
        }
    }

    static let quiet = "Nothing planned"

    static func home(_ app: AppSummaryApp) -> HomeApp {
        switch app {
        case .training: .training
        case .kitchen: .kitchen
        case .routines: .routines
        case .tasks: .tasks
        case .notes: .notes
        case .lists: .lists
        case .money: .money
        }
    }

    /// One row per app, in Core's order. An app whose line is missing (Core omits Money and Routines when it did not
    /// read their source) still has its row, name only, and still opens. A private top item already reads "Private".
    /// The dial's order (sheet 283): Log, Lookout, Deck, Galley, Watch, Purse, then To do and Settings. Lists folded
    /// into the Log (sheet 280), so it has no row of its own; To do stays until Tasks has another door.
    static let order: [AppSummaryApp?] = [.notes, nil, .training, .kitchen, .routines, .money, .tasks]

    static func make(_ lines: [AppSummaryLine], weather: String = "") -> [Row] {
        var rows: [Row] = order.map { app in
            guard let app else { return Row(app: .tasks, summary: weather, opens: nil, extra: .lookout) }
            let line = lines.first { $0.app == app }
            return Row(app: home(app), summary: line.map { $0.text.isEmpty ? quiet : $0.text } ?? "",
                       opens: line?.opens)
        }
        rows.append(Row(app: .tasks, summary: "", opens: nil, extra: .settings))
        return rows
    }

    /// A fact that fits one short line: cut at a word edge, never with an ellipsis.
    static func fit(_ text: String, limit: Int = 38) -> String {
        guard text.count > limit else { return text }
        let head = String(text.prefix(limit))
        // The cut lands on a space: every word in the head is whole.
        let nextIndex = text.index(text.startIndex, offsetBy: limit)
        if text[nextIndex] == " " {
            return head.trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:"))
        }
        if let space = head.lastIndex(of: " ") {
            return String(head[..<space]).trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:"))
        }
        // One long word: hard cut at the limit, no ellipsis.
        return head
    }

    /// How far row `index` sits from the middle in the ring, the nearer way round: from -(count - 1) / 2 through count
    /// / 2
    /// (an even count puts its far row on the positive side).
    static func relative(_ index: Int, middle: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var offset = ((index - middle) % count + count) % count
        if offset > count / 2 {
            offset -= count
        }
        return offset
    }

    /// The app that sits `offset` rows from `index` in a ring: the list wraps round.
    static func wrapped(_ index: Int, _ offset: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (((index + offset) % count) + count) % count
    }
}

/// The apps menu under Next (sheet 205, no caption since 209): a scroller of three 40 pt rows (more at large
/// text) that snaps to the
/// middle one and wraps round, with no ticks, dots or dividers. The middle row is the pick: its name swells 1.3x in its
/// accent on the house spring and its one-line fact is revealed from the right with a clip, sliding 14 pt. The others
/// show the name only, in ink 3. One tick per change. Tap the middle row to open it; tap another to bring it to the
/// middle. Reduce Motion: no swell and no slide.
struct AppsListSlot: View {
    @Environment(AppModel.self) private var model
    @Environment(\.playDoorway) private var playDoorway
    @Environment(\.openShellDoor) private var openShellDoor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var door: HomeV2Door?
    @State private var middle = 0
    @State private var drag: CGFloat = 0
    @State private var ticks = 0
    /// Rows the wheel has already turned during this hold.
    @State private var consumed = 0
    /// Held for scrolling (the pick sits at 1.06x), a soft haptic on pick up.
    @GestureState private var held = false
    /// A hold that scrolled (it moved past the tap slop or turned a row) has just ended: its lift is not a tap. A hold
    /// that stayed put is a slow tap and still opens the row.
    @State private var holdSuppress = false
    /// Whether the wheel is held, so the page can stop scrolling under the same finger.
    var onHold: (Bool) -> Void = { _ in }
    @State private var holdBeats = 0
    /// A snap is running; flicks that arrive meanwhile wait here (at most three).
    @State private var snapping = false
    @State private var queued: [Int] = []
    /// Bumped by each settle, so an older settle's unlock never clears a newer snap.
    @State private var snapGeneration = 0
    /// Whether the list has been moved: the glance plays after a settle, not on the first draw.
    @State private var moved = false
    /// Builder A's hook (sheet 206): each pick plays that app's glance in the mosaic, 240 ms after the list settles.
    var onGlance: ((HomeApp) -> Void)?
    /// The rows, read once per change in the model and not on every drag frame.
    @State private var rows: [AppsListRows.Row] = []
    /// 40 pt at the default size; the rows grow with the text.
    /// Sheet 283: three 40 pt places; the dial's type stops growing at AX1, so the places stay 40 pt.
    private let rowHeight: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .top) {
                // Five rows are laid out so the ring has a row to bring in on each side while it moves.
                // Rows keep their identity as the ring turns, so a settle rolls instead of hopping; the ones two or
                // more away wait outside the frame.
                ForEach(rows.indices, id: \.self) { index in
                    let offset = AppsListRows.relative(index, middle: middle, count: rows.count)
                    if abs(offset) <= 2 {
                        line(rows[index], isMiddle: offset == 0, offset: offset)
                            .offset(y: (CGFloat(offset) + 1) * rowHeight + drag)
                            .transition(.identity)
                            // The rows waiting outside the three places are clipped away; VoiceOver skips them too, so
                            // nothing reads over the widget or the foot (bounds check, Oct 26).
                            .accessibilityHidden(abs(offset) > 1)
                    }
                }
            }
            .frame(height: rowHeight * 3, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            // Sheet 220. Hold 180 ms without moving more than 6 pt: a soft haptic and the pick eases to 1.06x; then a
            // vertical drag tracks 1:1 (40 pt is one row, a tick as each crosses the middle) and a release snaps to the
            // nearest row with no momentum.
            // Simultaneous, never high priority: a plain tap still reaches its row's button (QA plan G13). A hold that
            // went on to scroll does not also open the app on lift: the tap is held back for a moment after it.
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.18, maximumDistance: 6)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .updating($held) { value, state, _ in
                        if case .second(true, _) = value {
                            state = true
                        }
                    }
                    .onChanged { value in
                        if case let .second(true, drag?) = value {
                            wheel(to: drag.translation.height)
                        }
                    }
            )
            // A flick with no hold moves exactly one row (up shows the next, down the previous), with the same snap and
            // one tick. At most three wait while a snap runs.
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { value in
                        let travel = abs(value.translation.height) > 20 || abs(value.velocity.height) > 300
                        guard travel, abs(value.translation.height) >= abs(value.translation.width) else { return }
                        flick(value.translation.height < 0 ? 1 : -1)
                    }
            )
        }
        .tesseraFeedback(.selection, trigger: ticks)
        .tesseraFeedback(.made, trigger: holdBeats)
        // The hold ends however it ends (lifted or cancelled): the gesture state resets, the list snaps and the pick
        // eases back from 1.06x.
        .onChange(of: held) { _, isHeld in
            onHold(isHeld)
            if isHeld {
                holdBeats += 1
            } else {
                finishWheel()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    holdSuppress = false
                }
            }
        }
        .animation(MotionPolicy.resolve(.easeOut(duration: 0.12), reduceMotion: reduceMotion), value: held)
        .task(id: middle) {
            guard moved, rows.indices.contains(middle) else { return }
            try? await Task.sleep(for: .milliseconds(240))
            guard !Task.isCancelled else { return }
            if rows[middle].extra == nil {
                onGlance?(rows[middle].app)
            }
        }
        // Read again when the model changes and when the day turns over.
        .task(id: "\(model.revision)-\(Calendar.current.startOfDay(for: AppClock.now).timeIntervalSince1970)") {
            // The loaders run on this refresh only (a change in the model or the day), never per frame.
            let now = AppClock.now
            rows = AppsListRows.make(AppSummaryLines.lines(
                engine: model.engine, plan: model.plan, moneyDue: .next(engine: model.engine, now: now),
                routines: .make(engine: model.engine, now: now), now: now
            ))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Apps")
        .accessibilityAdjustableAction { direction in
            settle(by: direction == .increment ? 1 : -1, count: rows.count)
        }
        .fullScreenCover(item: $door) { door in
            // No visible "‹ Home" (Kaushik): the edge swipe goes back, and VoiceOver has a hidden Back to Home.
            HomeV2DoorPage(door: door)
                .background { EdgeSwipeBack() }
                // Sheet 283: Tess bottom right on the room's landing, in the room's colour.
                .overlay(alignment: .bottomTrailing) {
                    if LandingSwitch.isOn, door != .settings {
                        BottomChrome(onSoulDoubleTap: { playDoorway(door.accent, true) { self.door = nil } },
                                     room: door.roomID)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 24, coordinateSpace: .global).onEnded { value in
                        if value.startLocation.x < 28, value.translation.width > 80 {
                            playDoorway(door.accent, true) { self.door = nil }
                        }
                    }
                )
                .accessibilityAction(.escape) { playDoorway(door.accent, true) { self.door = nil } }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Button("Back to Home") { playDoorway(door.accent, true) { self.door = nil } }
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .accessibilityLabel("Back to Home")
                }
        }
    }

    private func line(_ row: AppsListRows.Row, isMiddle: Bool, offset: Int) -> some View {
        Button {
            guard !holdSuppress else { return }
            if isMiddle {
                open(row)
            } else {
                settle(by: offset, count: rows.count)
            }
        } label: {
            // Sheet 283, Kaushik Oct 26: the dial on the RIGHT (x 218-378, names right-aligned), focus 26 pt bold in
            // its
            // colour, neighbours 20 pt with a 1.6 pt depth blur; the focus's one fact on the LEFT (x 24-216), 15 pt
            // ink 2, cut on whole words.
            ZStack(alignment: .leading) {
                if isMiddle, !row.summary.isEmpty {
                    FitLine(forms: FitLine.cuts(row.summary), size: 15, color: Theme.Colors.inkSecondary)
                        .frame(width: 192, alignment: .leading)
                        .id(row.id)
                        .transition(.offset(y: reduceMotion ? 0 : 6))
                }
                Text(row.name)
                    .font(.custom("Figtree", size: isMiddle ? 26 : 20, relativeTo: .title3)
                        .weight(isMiddle ? .bold : .regular))
                    .scaleEffect(isMiddle && held && !reduceMotion ? 1.06 : 1, anchor: .trailing)
                    .foregroundStyle(isMiddle ? row.accent : Theme.Colors.inkSecondary)
                    .blur(radius: isMiddle || reduceMotion ? 0 : 1.6)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .trailing)
                    .offset(x: 194)
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMiddle && !row.summary.isEmpty ? "\(row.name), \(row.summary)" : row.name)
        .accessibilityHint(isMiddle ? "Opens \(row.name)" : "Brings it to the middle")
    }

    /// A tap on the middle row: the object its line names, else the app.
    private func open(_ row: AppsListRows.Row) {
        if row.extra == nil, case let .object(id)? = row.opens {
            model.path.append(Route.object(id))
        } else if !openShellDoor(row.door) {
            // The standing shell holds the room when it can (its places change in place); else the doorway plays
            // into the room's own page.
            playDoorway(row.accent, false) { door = row.door }
        }
    }

    /// The held finger is `translation` points from where it began: whole rows turn the ring (a tick each) and the rest
    /// follows the finger 1:1.
    private func wheel(to translation: CGFloat) {
        guard !rows.isEmpty else { return }
        moved = true
        let total = Int((-translation / rowHeight).rounded(.towardZero))
        if abs(translation) > GestureTuning.tapSlop || total != consumed {
            holdSuppress = true
        }
        if total != consumed {
            middle = AppsListRows.wrapped(middle, total - consumed, count: rows.count)
            consumed = total
            ticks += 1
        }
        drag = translation + CGFloat(consumed) * rowHeight
    }

    /// The finger lifted: spring-snap to the nearest row, no momentum.
    private func finishWheel() {
        let nearest = drag < -rowHeight / 2 ? 1 : drag > rowHeight / 2 ? -1 : 0
        consumed = 0
        settle(by: nearest, count: rows.count)
    }

    private func flick(_ direction: Int) {
        guard !rows.isEmpty else { return }
        if snapping {
            if queued.count < 3 {
                queued.append(direction)
            }
            return
        }
        settle(by: direction, count: rows.count)
    }

    private func settle(by steps: Int, count: Int) {
        snapping = true
        snapGeneration += 1
        let generation = snapGeneration
        defer {
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { drag = 0 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 20 : 350))
                guard generation == snapGeneration else { return }
                snapping = false
                if !queued.isEmpty {
                    flick(queued.removeFirst())
                }
            }
        }
        guard steps != 0, count > 0 else { return }
        moved = true
        withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
            middle = AppsListRows.wrapped(middle, steps, count: count)
            drag = 0
        }
        ticks += 1
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

/// A fact revealed from the right with a clip, sliding 14 pt (no fade).
private struct RevealRight: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: (1 - progress) * 14)
            .mask(alignment: .trailing) {
                Rectangle().scaleEffect(x: max(progress, 0.001), anchor: .trailing)
            }
    }
}

private extension AnyTransition {
    static var reveal: AnyTransition {
        .modifier(active: RevealRight(progress: 0), identity: RevealRight(progress: 1))
    }
}
