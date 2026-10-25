import SwiftUI
import TesseraCore

/// One thing on Home (sheet 213): a name or number in three tiers, no card and no frame. Core ranks them
/// (`OneThings.ranked`, on the phone, at most seven); this is the host's copy of one, with its accent as a colour.
struct HomeThing: Identifiable, Equatable {
    enum Accent: Equatable {
        /// Ink: a task.
        case ink
        case app(HomeApp)
        /// The rose family, never cobalt.
        case birthday
        /// The sky: the weather.
        case sky
    }

    let id: String
    /// What kind of thing this is: the sign the mosaic builds for it (sheet 213).
    var kind: OneThing.Kind
    var big: String
    /// Outfit 200 at 60 pt for a short value (a time, a count, degrees), at 44 pt for words.
    var bigIsNumber: Bool
    var accent: Accent
    var mid: String
    /// The thing's own word in the mid line, highlighted; nil for a plain or private one.
    var keyword: String?
    var small: String
    /// The task a hold on the big line finishes (only a task can be struck through).
    var taskID: UUID?
    var target: OneThing.Target
    /// "Pack the charger, done." or "Private, done.": the one Undo line.
    var undoLine: String?

    var accentColor: Color {
        switch accent {
        case .ink: Theme.Colors.ink
        case let .app(app): app.accent
        case .birthday: Color(light: 0xB0466A, dark: 0xE07A9A)
        case .sky: Theme.Colors.Accent.skyTo
        }
    }

    var spoken: String {
        [big, mid, small].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    init(_ thing: OneThing) {
        id = thing.id
        kind = thing.kind
        big = thing.big
        bigIsNumber = thing.big.count <= 8 && thing.big.contains(where: \.isNumber)
        accent = switch thing.accent {
        case .ink: .ink
        case let .app(app): HomeApp(appID: app).map(Accent.app) ?? .ink
        case .birthday: .birthday
        case .sky: .sky
        }
        mid = thing.mid
        keyword = thing.midKeyword
        small = thing.small
        taskID = if case let .task(id)? = thing.done {
            id
        } else {
            nil
        }
        target = thing.target
        undoLine = thing.undoLine
    }
}

@MainActor
enum HomeThings {
    /// Core's ranked things for the space. The weather stays out until it is real (Apple weather is not entitled yet,
    /// and
    /// a sample would read as a fact); birthdays have no source on the phone yet.
    static func make(model: AppModel, facts: MosaicFacts, routines: HomeSentence.RoutinesPart) -> [HomeThing] {
        let unit = MassUnit(rawValue: model.displayUnits.unit(for: .weight) ?? "") ?? .kilograms
        return OneThings.ranked(engine: model.engine, facts: facts, plan: model.plan, routines: routines, unit: unit)
            .map(HomeThing.init)
    }
}

/// The 196 pt space under the mosaic. A sideways swipe past 50 pt (here or on the mosaic) only triggers the change:
/// nothing
/// follows the finger. The old tiers fold away in place with a top-down clip over 0.26 s and the new ones reveal in the
/// same spot, clipped in and staggered 200, 280 and 360 ms (Kaushik, Oct 23, 12:14 PM); one light haptic. Press and
/// hold
/// the big line of a task 180 ms and an ink strike draws through over 0.6 s; letting go once it is full finishes the
/// task (one rigid haptic and the one Undo line), letting go early retracts it. Reduce Motion: a plain swap, and the
/// strike shows once the hold completes.
struct HomeOneThing: View {
    let things: [HomeThing]
    @Binding var index: Int
    /// A page swipe of this much sideways travel (left is next): whether the page turned.
    let turn: (CGFloat) -> Bool
    /// The hold finished this task: whether it was marked done.
    let done: (HomeThing) -> Bool
    let open: (HomeThing) -> Void
    /// The sign slot's global frame, for the mosaic to build the sign in (sheet 213).
    var onSlot: (CGRect) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strike: Double = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var full = false
    /// The finger moved too far during this hold: it can no longer finish anything.
    @State private var moved = false
    @State private var turns = 0
    @State private var finishes = 0

    static let height: CGFloat = 196
    static let swipeDistance: CGFloat = 50
    /// Home 236: the 80 pt sign is centred on the big and mid tiers (4 to 150 pt), so its top sits at 37.
    static let signTop: CGFloat = 37
    /// The sign's width plus the 12 pt that every tier's text stops short of it.
    static let signRoom: CGFloat = 80 + 12

    var body: some View {
        ZStack(alignment: .topLeading) {
            if things.indices.contains(index) {
                let thing = things[index]
                page(thing)
                // A's 80 pt pixel sign sits at the top right; its slot is left clear here.
                Color.clear.frame(width: 80, height: 80)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onSlot($0) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    // Home 236: the sign is centred on the big and mid tiers and never moves with the pages.
                    .padding(.top, Self.signTop)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.height, alignment: .topLeading)
        .contentShape(Rectangle())
        // High priority: a swipe that starts on the space turns the page, and the page scrolls from anywhere else.
        .highPriorityGesture(swipe)
        .tesseraFeedback(.pageTurn, trigger: turns)
        .tesseraFeedback(.setLogged, trigger: finishes)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("One thing at a time")
        .accessibilityAdjustableAction { direction in
            if turn(direction == .increment ? -(Self.swipeDistance + 1) : Self.swipeDistance + 1) {
                turns += 1
            }
        }
    }

    // MARK: Page

    private func page(_ thing: HomeThing) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            tier(thing, delay: 0.2, height: 84) { big(thing) }
            tier(thing, delay: 0.28, height: 56) { mid(thing) }
            tier(thing, delay: 0.36, height: 22) {
                Text(thing.small)
                    .font(Theme.voice(size: 15))
                    .foregroundStyle(Theme.Colors.inkTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .padding(.trailing, Self.signRoom)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(thing.spoken)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Open") { open(thing) }
        .accessibilityActions {
            if thing.taskID != nil {
                Button("Mark done") { _ = done(thing) }
            }
        }
    }

    /// One tier in its own fixed cell, so the old and the new overlap without moving anything: the old folds away with
    /// a
    /// top-down clip (0.26 s), the new reveals from the top after its stagger.
    private func tier(_ thing: HomeThing, delay: Double, height: CGFloat,
                      @ViewBuilder content: () -> some View) -> some View
    {
        ZStack(alignment: .topLeading) {
            content()
                .id(thing.id)
                // Through the motion policy: under Reduce Motion each becomes the short crossfade.
                .transition(.asymmetric(
                    insertion: AnyTransition.modifier(active: TierClip(progress: 0, fromTop: true),
                                                      identity: TierClip(progress: 1, fromTop: true))
                        .animation(MotionPolicy.resolve(.easeOut(duration: 0.3).delay(delay),
                                                        reduceMotion: reduceMotion)),
                    removal: AnyTransition.modifier(active: TierClip(progress: 0, fromTop: false),
                                                    identity: TierClip(progress: 1, fromTop: false))
                        .animation(MotionPolicy.resolve(.easeIn(duration: 0.26), reduceMotion: reduceMotion))
                ))
        }
        // The tier sizes to its content (a two-line big line, large Dynamic Type); `height` is only its least.
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
    }

    @ViewBuilder
    private func big(_ thing: HomeThing) -> some View {
        let colour = thing.accentColor
        let text = Text(thing.bigIsNumber ? thing.big : AppsListRows.fit(thing.big, limit: 28))
            // Always Outfit 200: 60 pt for a short value, 44 pt for words (which may wrap to two lines).
            .font(Theme.numeral(thing.bigIsNumber ? 60 : 44))
            .foregroundStyle(colour)
            .textRenderer(StrikeRenderer(progress: strike, color: Theme.Colors.ink))
            .fixedSize(horizontal: false, vertical: true)
        if thing.taskID != nil {
            text.simultaneousGesture(hold(thing))
        } else {
            Button { open(thing) } label: { text }.buttonStyle(.plain)
        }
    }

    private func mid(_ thing: HomeThing) -> some View {
        Button { open(thing) } label: {
            Text(Self.midText(thing))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
    }

    /// Figtree 20 in ink with exactly one keyword, the thing's own word: 600 at 1.1x with an underline in its accent
    /// (ink
    /// for tasks).
    static func midText(_ thing: HomeThing) -> AttributedString {
        var text = AttributedString(thing.mid)
        text.font = Theme.voice(size: 20)
        text.foregroundColor = Theme.Colors.ink
        if let keyword = thing.keyword, let range = text.range(of: keyword) {
            let accent = thing.accentColor
            text[range].font = Theme.voice(size: 22).weight(.semibold)
            text[range].foregroundColor = accent
            text[range].underlineStyle = Text.LineStyle(pattern: .solid, color: accent)
        }
        return text
    }

    // MARK: Gestures

    /// A swipe in any of the four directions (sheet 220): left or up goes to the next thing, right or down to the
    /// previous. The dominant axis wins; it commits past 50 pt or on a flick faster than 300 pt/s.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart))
            .onChanged { _ in
                // A drag in any direction is a swipe, not a hold: the strike retracts.
                cancelHold()
            }
            .onEnded { value in
                let sideways = abs(value.translation.width) >= abs(value.translation.height)
                // A diagonal has no clear direction: the dominant axis must lead by 1.3x or the swipe is ignored.
                let lead = sideways
                    ? abs(value.translation.width) / max(abs(value.translation.height), 1)
                    : abs(value.translation.height) / max(abs(value.translation.width), 1)
                guard lead >= 1.3 else { return }
                // `turn` reads a negative value as next: left (negative) and up (negative) are both next.
                let across = sideways ? value.translation.width : value.translation.height
                let speed = (sideways ? value.velocity.width : value.velocity.height) * (across < 0 ? -1 : 1)
                // Past the distance, or a real flick (fast and past the flick travel); a twitch or a swipe taken back
                // at lift turns nothing.
                guard GestureTuning.commits(distance: Double(abs(across)), velocity: Double(speed),
                                            arm: Double(Self.swipeDistance)) else { return }
                // The tiers' own transitions carry the animation; this only lets them run.
                withTesseraAnimation(.linear(duration: 0.01), reduceMotion: reduceMotion) {
                    if turn(across < 0 ? -(Self.swipeDistance + 1) : Self.swipeDistance + 1) {
                        turns += 1
                    }
                }
            }
    }

    /// 180 ms of holding, then the strike draws in 0.6 s; letting go once it is full finishes the task. Any movement
    /// past about 10 pt cancels it, so a scroll or a swipe never finishes anything.
    private func hold(_ thing: HomeThing) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if hypot(value.translation.width, value.translation.height) > 10 {
                    cancelHold()
                    return
                }
                guard holdTask == nil, !full, !moved else { return }
                holdTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled else { return }
                    if reduceMotion {
                        // Reduce Motion: the strike shows once, when the hold completes.
                        try? await Task.sleep(for: .milliseconds(600))
                        guard !Task.isCancelled else { return }
                        strike = 1
                    } else {
                        withTesseraAnimation(.linear(duration: 0.6), reduceMotion: false) { strike = 1 }
                        try? await Task.sleep(for: .milliseconds(600))
                        guard !Task.isCancelled else { return }
                    }
                    full = true
                }
            }
            .onEnded { _ in
                let wasFull = full && !moved
                moved = false
                if wasFull {
                    if done(thing) {
                        finishes += 1
                    }
                    reset()
                } else {
                    cancelHold()
                }
            }
    }

    private func cancelHold() {
        moved = true
        holdTask?.cancel()
        reset(retract: true)
    }

    private func reset(retract: Bool = false) {
        holdTask = nil
        full = false
        withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion || !retract) { strike = 0 }
    }
}

/// A tier folding in or out in place: a clip that runs top-down (the new tier grows from the top, the old one shrinks
/// toward the bottom).
private struct TierClip: ViewModifier {
    var progress: CGFloat
    var fromTop: Bool

    func body(content: Content) -> some View {
        content.mask {
            Rectangle().scaleEffect(y: max(progress, 0.001), anchor: fromTop ? .top : .bottom)
        }
    }
}
