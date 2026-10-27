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

/// The one-thing swipe as a pure step: which card leaves and which comes in. Sheet 294 section 4: the widget must
/// never be left empty, so the card that leaves is read BEFORE the index changes.
enum OneThingSwipe {
    /// A swipe by `dx` (negative is next; the travel must pass 50 pt): the index of the card that leaves and the one
    /// that comes in, wrapping; nil when nothing turns.
    static func step(index: Int, count: Int, dx: CGFloat) -> (leaving: Int, entering: Int)? {
        guard count > 1, abs(dx) > 50 else { return nil }
        return (index, ((index + (dx < 0 ? 1 : -1)) % count + count) % count)
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
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var strike: Double = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var full = false
    /// The finger moved too far during this hold: it can no longer finish anything.
    @State private var moved = false
    @State private var turns = 0
    @State private var finishes = 0

    /// Sheet 283 v4: the widget place is 200 tall (412 to 612).
    static let height: CGFloat = 200
    static let swipeDistance: CGFloat = 50
    /// Home 236: the 80 pt sign is centred on the big and mid tiers (4 to 150 pt), so its top sits at 37.
    static let signTop: CGFloat = 32
    /// The sign's width plus the 12 pt that every tier's text stops short of it.
    static let signRoom: CGFloat = 80 + 12

    var body: some View {
        ZStack(alignment: .topLeading) {
            if things.indices.contains(index) {
                let thing = things[index]
                // The widget is the clipped place: the tiers roll over its top and bottom edges (sheets 294, 295).
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
        // Sheet 283 section 5, Bridge's one-thing box: header (13 pt 600 caps, tracked .12 em) at 429, the Big line in
        // a
        // 64 pt slot at 444, the Middle line (20 pt) at 522, the Small line (15 pt 500 ink 2) at 554. Fixed slots: text
        // cuts on whole words and never wraps; the type stops growing at AX1 so nothing overlaps.
        ZStack(alignment: .topLeading) {
            tier(thing, delay: 0.12, height: 20, inset: 17) {
                Text(Self.header(thing.kind).uppercased())
                    .font(.custom("Figtree", size: 13, relativeTo: .caption).weight(.semibold))
                    .tracking(13 * 0.12)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    // The header ends where the Big line starts (429 + 15 = 444): fixed size, never over it.
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .frame(height: 15, alignment: .top)
            }
            // 428: its 15.7 pt line ends before the Big line at 444 (no overlap, bounds check).
            .offset(y: 16)
            tier(thing, delay: 0.2, height: 64, inset: 32) { big(thing) }
                .frame(height: 64, alignment: .leading)
                .offset(y: 32)
            tier(thing, delay: 0.28, height: 28, inset: 110) { mid(thing) }
                .offset(y: 110)
            tier(thing, delay: 0.36, height: 22, inset: 142) {
                FitLine(forms: FitLine.cuts(thing.small), size: 15, color: Theme.Colors.inkSecondary, weight: .medium)
            }
            .offset(y: 142)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .frame(height: Self.height, alignment: .topLeading)
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

    /// One tier in its own fixed cell, so the old and the new overlap without moving anything. Sheet 294: the old tier
    /// rolls out over the top edge and the new one comes in over the bottom edge, the same roll in reverse, each after
    /// its stagger. Under Reduce Motion the roll is off and each is the short crossfade.
    private func tier(_ thing: HomeThing, delay: Double, height: CGFloat, inset: CGFloat,
                      @ViewBuilder content: () -> some View) -> some View
    {
        ZStack(alignment: .topLeading) {
            content()
                .id(thing.id)
                // Through the motion policy: under Reduce Motion each becomes the short crossfade.
                .transition(.asymmetric(
                    insertion: AnyTransition.modifier(
                        active: roll(1, side: .trailing, inset: inset),
                        identity: roll(0, side: .trailing, inset: inset)
                    )
                    .animation(MotionPolicy.resolve(.easeOut(duration: 0.3).delay(delay),
                                                    reduceMotion: reduceMotion)),
                    removal: AnyTransition.modifier(
                        active: roll(1, side: .leading, inset: inset),
                        identity: roll(0, side: .leading, inset: inset)
                    )
                    .animation(MotionPolicy.resolve(.easeIn(duration: 0.26), reduceMotion: reduceMotion))
                ))
        }
        // The tier sizes to its content (a two-line big line, large Dynamic Type); `height` is only its least.
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
    }

    private func roll(_ overflow: CGFloat, side: EdgeRoll.Side, inset: CGFloat) -> EdgeRollPass {
        EdgeRollPass(overflow: overflow, axis: .vertical, side: side, travel: Self.height, inset: inset,
                     placeLength: Self.height, preset: .card, reduceMotion: reduceMotion)
    }

    @ViewBuilder
    private func big(_ thing: HomeThing) -> some View {
        let colour = thing.accentColor
        // Sheet 283: a word at Figtree 38 700 on one line (cut on whole words), or an Outfit 56 number.
        let text = Text(thing.bigIsNumber ? thing.big : Self.cut(thing.big, size: 38, width: 262, typeSize: typeSize))
            .font(thing.bigIsNumber ? .custom("Outfit", size: 56, relativeTo: .largeTitle).weight(.light)
                : .custom("Figtree", size: 38, relativeTo: .largeTitle).weight(.bold))
            .foregroundStyle(colour)
            .lineLimit(1)
            .textRenderer(StrikeRenderer(progress: strike, color: Theme.Colors.ink))
        if thing.taskID != nil {
            text.simultaneousGesture(hold(thing))
        } else {
            Button { open(thing) } label: { text }.buttonStyle(.plain)
        }
    }

    private func mid(_ thing: HomeThing) -> some View {
        Button { open(thing) } label: {
            Text(Self.midText(thing))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    /// Figtree 20 in ink with exactly one keyword, the thing's own word: 600 at 1.1x with an underline in its accent
    /// (ink
    /// for tasks).
    static func midText(_ thing: HomeThing) -> AttributedString {
        midText(thing.mid, keyword: thing.keyword, accent: thing.accentColor)
    }

    static func midText(_ mid: String, keyword: String?, accent: Color) -> AttributedString {
        var text = AttributedString(mid)
        text.font = Theme.voice(size: 20)
        text.foregroundColor = Theme.Colors.ink
        if let keyword, let range = text.range(of: keyword) {
            // Sheet 283: no decorative underline; the key word is 600 in its accent at the line's own size.
            text[range].font = Theme.voice(size: 20).weight(.semibold)
            text[range].foregroundColor = accent
        }
        return text
    }

    /// The widget header (283): the room the thing belongs to, by its ship name.
    static func header(_ kind: OneThing.Kind) -> String {
        switch kind {
        case .training: "Deck"
        case .groceries: "Galley"
        case .birthday: "Birthday"
        case .task: "To do"
        case .list: "Log"
        case .weather: "Lookout"
        case .routine: "Watch"
        }
    }

    /// The longest whole-word cut of `text` that fits `width` at Figtree `size` 700; never an ellipsis. It measures at
    /// the size the line draws at: scaled with the reader's text size, but clamped to AX1 like the page (so a larger
    /// size never cuts words that still fit).
    static func cut(_ text: String, size: CGFloat, width: CGFloat, typeSize: DynamicTypeSize = .large) -> String {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Figtree", .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold],
        ])
        let traits = UITraitCollection(preferredContentSizeCategory: category(min(typeSize, .accessibility1)))
        let scaled = UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: size, compatibleWith: traits)
        let font = UIFont(descriptor: descriptor, size: scaled)
        for form in FitLine.cuts(text) where (form as NSString).size(withAttributes: [.font: font]).width <= width {
            return form
        }
        return FitLine.cuts(text).last ?? text
    }

    private static func category(_ size: DynamicTypeSize) -> UIContentSizeCategory {
        switch size {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
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
