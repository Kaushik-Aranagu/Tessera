import SwiftUI
import TesseraCore

/// One thing on Home (sheet 213): a name or number in three tiers, no card and no frame. Core ranks them; until its
/// feed
/// lands the stand-in below reads the ranker's picks and the apps' own lines.
struct HomeThing: Identifiable, Equatable {
    enum Kind: Equatable {
        case task, app(HomeApp)
    }

    let id: String
    let kind: Kind
    /// Outfit 200 at 66 pt when a number (a time, a count), else Figtree 500 at 36 pt.
    var big: String
    var bigIsNumber: Bool
    /// The accent of the big line; ink for a task.
    var accent: HomeApp?
    var mid: String
    /// The app word in the mid line (a 205 keyword), if it names one.
    var keyword: String?
    var small: String
    /// The task a hold on the big line finishes.
    var taskID: UUID?
    var opens: HomeSentence.Opens?

    var spoken: String {
        [big, mid, small].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

@MainActor
enum HomeThings {
    static let maxThings = 7
    static let holdHint = "Hold to strike it through"

    /// The thing's own word in a line: its first one or two words, up to a connecting word, a comma or a figure
    /// ("Push day" in "Push day at 6:30 pm", "Groceries" in "Groceries, 4 to get").
    static func keyword(in text: String) -> String? {
        let stops: Set = ["at", "is", "on", "in", "turns", "to", "for", "and", "of"]
        var words: [String] = []
        for raw in text.split(separator: " ") {
            let word = String(raw)
            let bare = word.trimmingCharacters(in: .punctuationCharacters)
            if stops.contains(bare.lowercased()) || bare.contains(where: \.isNumber) {
                break
            }
            words.append(bare)
            if word.last == "," || word.last == "." || words.count == 2 {
                break
            }
        }
        let joined = words.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// The stand-in feed: the ranker's task picks first (a private one reads by its shown label), then each app's own
    /// line, up to seven.
    static func standIn(model: AppModel, lines: [AppSummaryLine], now: Date) -> [HomeThing] {
        var out: [HomeThing] = []
        let picks = NowPage.rank(model: model, now: now, incumbent: nil)
        for pick in picks where pick.item.kind == .task && out.count < 3 {
            let shown = ObjectPrivacy.shownLabel(of: pick.item.object, in: model.store, classes: model.classes)
                ?? pick.item.title
            let private_ = ObjectPrivacy
                .shownLabel(of: pick.item.object, in: model.store, classes: model.classes) != nil
            out.append(HomeThing(id: pick.item.id.uuidString, kind: .task, big: shown, bigIsNumber: false,
                                 accent: nil, mid: private_ || pick.why.isEmpty ? "Today" : pick.why,
                                 keyword: private_ || pick.why.isEmpty ? nil : keyword(in: pick.why),
                                 small: holdHint, taskID: pick.item.id, opens: .object(pick.item.id)))
        }
        for line in lines where out.count < maxThings && line.text != AppSummaryLines.nothingPlanned {
            let app = AppsListRows.home(line.app)
            let time = line.text.split(separator: " ").first { $0.contains(":") }.map(String.init)
            out.append(HomeThing(id: "app-\(app.rawValue)", kind: .app(app), big: time ?? app.rawValue,
                                 bigIsNumber: time != nil, accent: app, mid: line.text, keyword: keyword(in: line.text),
                                 small: "",
                                 taskID: nil, opens: line.opens))
        }
        return Array(out.prefix(maxThings))
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
    /// The hold finished this task.
    let done: (HomeThing) -> Void
    let open: (HomeThing) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strike: Double = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var full = false
    @State private var turns = 0
    @State private var finishes = 0

    static let height: CGFloat = 196
    static let swipeDistance: CGFloat = 50

    var body: some View {
        ZStack(alignment: .topLeading) {
            if things.indices.contains(index) {
                let thing = things[index]
                page(thing)
                // A's 72 pt pixel sign sits at the top right; its slot is left clear here.
                Color.clear.frame(width: 72, height: 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .accessibilityHidden(true)
                Text("\(index + 1) of \(things.count)")
                    .font(Theme.numeral(14, weight: .light))
                    .foregroundStyle(Theme.Colors.inkTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height, alignment: .topLeading)
        .contentShape(Rectangle())
        .simultaneousGesture(swipe)
        .tesseraFeedback(.selection, trigger: turns)
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(thing.spoken)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Open") { open(thing) }
        .accessibilityActions {
            if thing.taskID != nil {
                Button("Mark done") { done(thing) }
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
                .transition(reduceMotion ? .identity : .asymmetric(
                    insertion: AnyTransition.modifier(active: TierClip(progress: 0, fromTop: true),
                                                      identity: TierClip(progress: 1, fromTop: true))
                        .animation(.easeOut(duration: 0.3).delay(delay)),
                    removal: AnyTransition.modifier(active: TierClip(progress: 0, fromTop: false),
                                                    identity: TierClip(progress: 1, fromTop: false))
                        .animation(.easeIn(duration: 0.26))
                ))
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
    }

    @ViewBuilder
    private func big(_ thing: HomeThing) -> some View {
        let colour = thing.accent?.accent ?? Theme.Colors.ink
        let text = Text(thing.big)
            // Always Outfit 200: 60 pt for a short value, 44 pt for words (which may wrap to two lines).
            .font(Theme.numeral(thing.bigIsNumber ? 60 : 44))
            .foregroundStyle(colour)
            .textRenderer(StrikeRenderer(progress: strike, color: Theme.Colors.ink))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
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
            let accent = thing.accent?.accent ?? Theme.Colors.ink
            text[range].font = Theme.voice(size: 22).weight(.semibold)
            text[range].foregroundColor = accent
            text[range].underlineStyle = Text.LineStyle(pattern: .solid, color: accent)
        }
        return text
    }

    // MARK: Gestures

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // A sideways drag is a swipe, not a hold: the strike retracts.
                if abs(value.translation.width) > abs(value.translation.height) {
                    cancelHold()
                }
            }
            .onEnded { value in
                let across = value.translation.width
                guard abs(across) > Self.swipeDistance, abs(across) > abs(value.translation.height) else { return }
                // The tiers' own transitions carry the animation; this only lets them run.
                withTesseraAnimation(.linear(duration: 0.01), reduceMotion: reduceMotion) {
                    if turn(across) {
                        turns += 1
                    }
                }
            }
    }

    /// 180 ms of holding, then the strike draws in 0.6 s; letting go once it is full finishes the task.
    private func hold(_ thing: HomeThing) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard holdTask == nil, !full else { return }
                holdTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled else { return }
                    withAnimation(reduceMotion ? nil : .linear(duration: 0.6)) { strike = 1 }
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    full = true
                }
            }
            .onEnded { _ in
                if full {
                    finishes += 1
                    done(thing)
                    reset()
                } else {
                    cancelHold()
                }
            }
    }

    private func cancelHold() {
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
