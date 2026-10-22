import SwiftUI

/// How a page of rows gives way to the next (docs/design/motion/tess-page-turn-motion.md, sheets 90 and 93): the
/// Review switch "Page turn" picks one, and Today (the default) is the app as it was. Shared: Settings' preview now,
/// Plans and Exercise pagers next. No haptic on a turn. Reduce Motion: every style is one 150 ms crossfade.
enum PageTurnStyle: String, CaseIterable, Sendable {
    case today = "Today"
    case slide = "Slide"
    case turn = "Turn"
    case soften = "Soften"
    case rotate = "Rotate"

    /// The style he picked in Settings › Review.
    @MainActor
    static var current: PageTurnStyle {
        PageTurnStyle(rawValue: ReviewChoices.shared.value(of: "pageTurn") ?? "") ?? .today
    }

    /// Whether the whole page moves as one (Today, Slide, Soften) or row by row (Turn, Rotate).
    var isWholePage: Bool {
        switch self {
        case .today, .slide, .soften: true
        case .turn, .rotate: false
        }
    }
}

/// The spec's timings, in one place, so the shared pagers and the preview can't drift.
enum PageTurnTiming {
    /// The page-turn curve, (.22, .8, .2, 1).
    static func curve(_ duration: Double) -> Animation {
        .timingCurve(0.22, 0.8, 0.2, 1, duration: duration)
    }

    static let reduced = Animation.easeInOut(duration: 0.15)

    /// Turn: rows leave 260 ms, 24 ms apart; arrive 440 ms, 38 ms apart from 190 ms.
    static func turnLeave(_ order: Int) -> Animation {
        curve(0.26).delay(Double(order) * 0.024)
    }

    static func turnArrive(_ order: Int) -> Animation {
        curve(0.44).delay(0.19 + Double(order) * 0.038)
    }

    /// Rotate: slot k leaves at 24k ms over 160 ms and arrives at 80 + 24k ms over 260 ms.
    static func rotateLeave(_ order: Int) -> Animation {
        curve(0.16).delay(Double(order) * 0.024)
    }

    static func rotateArrive(_ order: Int) -> Animation {
        curve(0.26).delay(0.08 + Double(order) * 0.024)
    }

    /// The whole turn, for a caller that waits on it: Turn 190 + 38(N-1) + 440, Rotate 80 + 24(N-1) + 260.
    static func total(_ style: PageTurnStyle, rows: Int, reduceMotion: Bool) -> Double {
        if reduceMotion {
            return 0.15
        }
        let last = Double(max(rows, 1) - 1)
        return switch style {
        case .today: 0
        case .slide: 0.52
        case .turn: 0.19 + 0.038 * last + 0.44
        case .soften: 0.59
        case .rotate: 0.08 + 0.024 * last + 0.26
        }
    }
}

/// A blur that comes and goes as a transition (Soften).
private struct BlurFade: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.blur(radius: radius).opacity(radius == 0 ? 1 : 0)
    }
}

extension AnyTransition {
    /// The whole page's transition for a style (Slide, Soften; Today swaps with none).
    @MainActor
    static func pageTurn(_ style: PageTurnStyle, reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity.animation(PageTurnTiming.reduced)
        }
        switch style {
        case .today, .turn, .rotate:
            return .identity
        case .slide:
            return .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
                .animation(PageTurnTiming.curve(0.52))
        case .soften:
            return .asymmetric(
                insertion: .modifier(active: BlurFade(radius: 14), identity: BlurFade(radius: 0))
                    .animation(PageTurnTiming.curve(0.40).delay(0.19)),
                removal: .modifier(active: BlurFade(radius: 14), identity: BlurFade(radius: 0))
                    .animation(PageTurnTiming.curve(0.34))
            )
        }
    }

    /// One row's transition for a row-by-row style (Turn, Rotate), `order` counted in the direction of travel.
    @MainActor
    static func pageTurnRow(_ style: PageTurnStyle, order: Int, reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity.animation(PageTurnTiming.reduced)
        }
        switch style {
        case .turn:
            return .asymmetric(
                insertion: .offset(y: 34).combined(with: .opacity).animation(PageTurnTiming.turnArrive(order)),
                removal: .offset(y: -18).combined(with: .opacity).animation(PageTurnTiming.turnLeave(order))
            )
        case .rotate:
            return .asymmetric(
                insertion: .offset(y: 40).combined(with: .opacity).animation(PageTurnTiming.rotateArrive(order)),
                removal: .offset(y: -14).combined(with: .opacity).animation(PageTurnTiming.rotateLeave(order))
            )
        case .today, .slide, .soften:
            return .identity
        }
    }
}

/// A page of rows that turns with the chosen style when `page` changes. Rows keep their slots (at most six on a
/// page); forward turns stagger top to bottom, back turns bottom to top. The container clips, so nothing travels
/// over the page's title or pinned things.
struct PageTurnRows<Item: Identifiable, Row: View>: View {
    let items: [Item]
    let page: Int
    var style: PageTurnStyle = .current
    @ViewBuilder var row: (Item) -> Row

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownPage = 0
    @State private var forward = true

    private var reduced: Bool {
        reduceMotion || PowerState.isLowPower
    }

    var body: some View {
        Group {
            if style.isWholePage || reduced {
                rows(stagger: false)
                    .id(shownPage)
                    .transition(.pageTurn(style, reduceMotion: reduced))
            } else {
                rows(stagger: true)
            }
        }
        .clipped()
        .onAppear { shownPage = page }
        .onChange(of: page) { old, new in
            forward = new >= old
            // Today keeps the swap as it was: no motion of its own.
            if style == .today, !reduced {
                shownPage = new
            } else {
                // Through MotionPolicy; Low Power counts as Reduce Motion: the 150 ms crossfade (QA on #1184).
                withTesseraAnimation(PageTurnTiming.curve(0.52), reduceMotion: reduced) {
                    shownPage = new
                }
            }
        }
    }

    private func rows(stagger: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let order = forward ? index : items.count - 1 - index
                row(item)
                    .id(stagger ? AnyHashable("\(shownPage)-\(index)") : AnyHashable(item.id))
                    .transition(stagger ? .pageTurnRow(style, order: order, reduceMotion: reduced) : .identity)
            }
        }
    }
}

/// Settings' Page turn preview (sheet 93): picking a word plays that turn once on a two-line mini page, holds 1 s,
/// then settles back; re-picking the same word doesn't replay. No haptic beyond the picker's own.
struct PageTurnPreview: View {
    let style: PageTurnStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var playing: Task<Void, Never>?

    private struct Line: Identifiable {
        let id: Int
        let text: String
    }

    var body: some View {
        PageTurnRows(items: PageTurnPreviewCopy.pages[page].enumerated().map { Line(id: $0.offset, text: $0.element) },
                     page: page, style: style)
        { line in
            // Two steps under the rows, label size, so it reads as a swatch and never as his own lists (Design on
            // #1184).
            Text(line.text)
                .font(Theme.Typography.font(PageTurnPreviewCopy.swatchSpec))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityHidden(true)
        .onChange(of: style) { _, _ in play() }
    }

    private func play() {
        // Today has no turn of its own: nothing to play (QA on #1184). A quick second pick cancels the first.
        playing?.cancel()
        guard style != .today else {
            page = 0
            return
        }
        page = 1
        playing = Task { @MainActor in
            let turn = PageTurnTiming.total(style, rows: 2, reduceMotion: reduceMotion || PowerState.isLowPower)
            try? await Task.sleep(for: .seconds(turn + 1))
            guard !Task.isCancelled else { return }
            page = 0
        }
    }
}

enum PageTurnPreviewCopy {
    /// The swatch's type: the rows' face at 14 pt, case kept (Design on #1184).
    static var swatchSpec: ThemeConcept.TypeSpec {
        var spec = Theme.concept.scale.body
        spec.size = 14
        spec.weight = .regular
        return spec
    }

    /// The mini page and the next one (sheet 93's sample).
    static let pages = [["Groceries, 24 to get.", "Lists, 3 open."],
                        ["Recipes, 12 kept.", "Pantry, 9 running low."]]
}
