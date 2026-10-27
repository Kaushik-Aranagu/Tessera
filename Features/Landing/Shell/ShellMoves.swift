import SwiftUI

/// Why a place is changing: the opening, a route change (the one clock, with each place's own delays), a change of
/// state inside a room (a swipe or a turn: no waiting), or a layout merge or split (content leaves before the places
/// flow and arrives after they settle).
enum MoveContext: Equatable {
    case opening, route, state, merge
}

/// How a place plays its next change. The shell sets it a frame before the content changes, so both the leaving
/// view (its removal) and the arriving one (its insertion) use it.
struct PlaceStyle: Equatable {
    var move: PlaceMove = .untouched
    var context: MoveContext = .state
    /// The dial reel: the old doors' names, when the dial plays its reel.
    var reelFrom: [String] = []

    static let rest = PlaceStyle()
}

/// Each place's own move as a SwiftUI transition (sheet 283 v4, "moving place by place"). Every animation goes
/// through `MotionPolicy`; Reduce Motion makes every place a 150 ms cross-fade.
enum PlaceTransition {
    static func make(_ place: Place, _ style: PlaceStyle, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else {
            return .opacity.animation(MotionPolicy.reducedMotionFade)
        }
        return .asymmetric(insertion: insertion(place, style), removal: removal(place, style))
    }

    private static func motion(_ animation: Animation) -> Animation {
        MotionPolicy.resolve(animation, reduceMotion: false)
    }

    /// The masthead's rows flap like the departure board; a row index staggers them.
    private static func row(_ place: Place) -> Double {
        switch place {
        case .title, .navWord: 0
        default: 1
        }
    }

    // MARK: Insertion

    private static func insertion(_ place: Place, _ style: PlaceStyle) -> AnyTransition {
        switch style.context {
        case .opening:
            let delay = Double(ShellTiming.arrivalOrder(place)) * ShellTiming.openingStagger
            return rise
                .animation(motion(.timingCurve(0.2, 0.8, 0.2, 1, duration: ShellTiming.openingSeconds).delay(delay)))
        case .merge:
            return arrival(place)
        case .route, .state:
            break
        }
        let route = style.context == .route
        if style.move == .collapseAndForm {
            return place == .keystone ? dissolve.animation(motion(.easeOut(duration: 0.4).delay(route ? 0.2 : 0.1)))
                : form.animation(motion(.spring(duration: 0.44, bounce: 0.3).delay(route ? 0.33 : 0.2)))
        }
        switch place {
        case .title, .navWord, .switcher, .needs, .doorTitle:
            let delay = route ? 0.18 + row(place) * 0.06 : 0.1
            return flapIn.animation(motion(.spring(duration: 0.34, bounce: 0.28).delay(delay)))
        case .caption:
            return unroll.animation(motion(.easeOut(duration: 0.32).delay(route ? 0.52 : 0.12)))
        case .widget:
            return .modifier(active: Shift(y: 64, opacity: 0), identity: Shift())
                .animation(motion(.spring(duration: 0.42, bounce: 0.1).delay(route ? 0.2 : 0.12)))
        case .glyph:
            return form.animation(motion(.spring(duration: 0.44, bounce: 0.3).delay(route ? 0.33 : 0.2)))
        case .dial:
            // The reel plays inside the dial place; without one the dial fades in.
            return style.reelFrom.isEmpty ? .opacity.animation(motion(.easeOut(duration: 0.3))) : .identity
        case .doorSummary:
            if route {
                return .modifier(active: Shift(x: 90, opacity: 0), identity: Shift())
                    .animation(motion(.spring(duration: 0.42, bounce: 0.2).delay(ShellTiming.summaryDelay)))
            }
            // Inside the room the summary rises 6 pt by a clip as the dial turns.
            return .modifier(active: Shift(y: 6, opacity: 0), identity: Shift()).animation(motion(Theme.Motion.firm))
        case .actionWord:
            // The letters stream in inside the action word.
            return .identity
        case .keystone:
            return dissolve.animation(motion(.easeOut(duration: 0.4).delay(route ? 0.2 : 0.1)))
        case .page:
            // Rows settle in from the top down inside the page.
            return .identity
        case .tess:
            return .opacity.animation(motion(.easeOut(duration: 0.3)))
        }
    }

    /// After a split (or into a merge target): each place rises into its frame, in place order, 30 ms apart.
    private static func arrival(_ place: Place) -> AnyTransition {
        switch place {
        case .page:
            return .identity
        case .doorTitle:
            return flapIn.animation(motion(.spring(duration: 0.34, bounce: 0.28)))
        case .glyph:
            return form.animation(motion(.spring(duration: 0.44, bounce: 0.3)))
        default:
            let delay = Double(ShellTiming.arrivalOrder(place)) * ShellTiming.arriveStagger
            return rise
                .animation(motion(.timingCurve(0.2, 0.8, 0.2, 1, duration: ShellTiming.arriveSeconds).delay(delay)))
        }
    }

    // MARK: Removal

    private static func removal(_ place: Place, _ style: PlaceStyle) -> AnyTransition {
        if style.context == .merge {
            // Content leaves before a merge starts, so text is never stretched.
            return .opacity.animation(motion(.easeOut(duration: ShellTiming.contentOut)))
        }
        let route = style.context == .route
        if style.move == .collapseAndForm {
            return place == .keystone ? dissolve.animation(motion(.easeIn(duration: 0.3)))
                : form.animation(motion(.easeIn(duration: 0.26)))
        }
        switch place {
        case .title, .navWord, .switcher, .needs, .doorTitle:
            let delay = route ? row(place) * 0.05 : 0
            return flapOut.animation(motion(.easeIn(duration: 0.2).delay(delay)))
        case .caption:
            return unroll.animation(motion(.easeIn(duration: 0.16)))
        case .widget:
            return .modifier(active: Shift(y: -48, opacity: 0), identity: Shift())
                .animation(motion(.easeIn(duration: 0.26)))
        case .glyph:
            return form.animation(motion(.easeIn(duration: 0.26)))
        case .dial:
            return .opacity.animation(motion(.easeOut(duration: 0.14)))
        case .doorSummary:
            return route ? .modifier(active: Shift(x: 80, opacity: 0), identity: Shift())
                .animation(motion(.easeIn(duration: 0.26)))
                : .opacity.animation(motion(.easeOut(duration: 0.15)))
        case .actionWord:
            return .modifier(active: Shift(x: -24, skew: 18, opacity: 0), identity: Shift())
                .animation(motion(.easeIn(duration: 0.22)))
        case .keystone:
            return dissolve.animation(motion(.easeIn(duration: 0.3)))
        case .page:
            // Content in no named place leaves softly where it stands.
            return .opacity.animation(motion(.easeOut(duration: 0.18)))
        case .tess:
            return .opacity.animation(motion(.easeOut(duration: 0.2)))
        }
    }

    // MARK: The moves

    private static var rise: AnyTransition {
        .modifier(active: Rise(shown: false), identity: Rise(shown: true))
    }

    private static var flapIn: AnyTransition {
        .modifier(active: Flap(angle: -88), identity: Flap(angle: 0))
    }

    private static var flapOut: AnyTransition {
        .modifier(active: Flap(angle: 88), identity: Flap(angle: 0))
    }

    private static var unroll: AnyTransition {
        .modifier(active: Unroll(amount: 0), identity: Unroll(amount: 1))
    }

    /// Collapse to a point, rotating 70°, and form again from it.
    private static var form: AnyTransition {
        .modifier(active: Collapse(amount: 0), identity: Collapse(amount: 1))
    }

    /// A keystone that changes kind dissolves with blur rather than collapsing.
    private static var dissolve: AnyTransition {
        .modifier(active: Dissolve(amount: 0), identity: Dissolve(amount: 1))
    }
}

/// The opening rise: up 10 pt from 95% size, revealed (sheet 283; no blur, Kaushik Oct 25).
private struct Rise: ViewModifier {
    let shown: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.95, anchor: .topLeading)
            .offset(y: shown ? 0 : 10)
    }
}

/// A board flap: the row turns about its horizontal axis and is gone past 88°.
private struct Flap: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.5)
            .opacity(max(0, 1 - abs(angle) / 88))
    }
}

/// The caption rolls up into the keystone (its top edge) and unrolls from it.
private struct Unroll: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1, y: max(amount, 0.001), anchor: .top)
            .opacity(amount)
    }
}

private struct Collapse: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(max(amount, 0.001))
            .rotationEffect(.degrees(70 * (1 - amount)))
            .opacity(amount)
    }
}

private struct Dissolve: ViewModifier {
    let amount: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: 6 * (1 - amount))
            .opacity(amount)
    }
}

/// A slide with an optional lean (the action word leaves left with a skew).
private struct Shift: ViewModifier {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var skew: Double = 0
    var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: CGFloat(tan(skew * .pi / 180)), d: 1, tx: 0, ty: 0))
            .offset(x: x, y: y)
            .opacity(opacity)
    }
}

/// The dial reel (sheet 283 v4): a 120 pt window masked at both ends shows the old doors, nine mixed names from both
/// lists, then the new doors. It runs 980 ms, fast at first with a 3 pt blur, and slows to rest on the new doors;
/// the real dial fades in under it over the last 140 ms.
struct DialReel: View {
    let from: [String]
    let to: [String]
    var color: Color = Theme.Colors.ink

    @State private var landed = false
    @State private var gone = false

    static func names(from: [String], to: [String]) -> [String] {
        let old = Array(from.prefix(3))
        let new = Array(to.prefix(3))
        let pool = from + to
        let mixed = pool.isEmpty ? [] : (0 ..< 9).map { pool[($0 * 5 + 1) % pool.count] }
        return old + mixed + new
    }

    var body: some View {
        let names = Self.names(from: from, to: to)
        let travel = CGFloat(max(names.count - 3, 0)) * 40
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(.custom("Figtree", size: 20, relativeTo: .title3).weight(.bold))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .frame(width: 160, height: 40, alignment: .leading)
            }
        }
        .offset(y: landed ? -travel : 0)
        .blur(radius: landed ? 0 : 3)
        .frame(width: 160, height: 120, alignment: .topLeading)
        .clipped()
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22),
                                   .init(color: .black, location: 0.78), .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
        .opacity(gone ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(MotionPolicy.resolve(.timingCurve(0.1, 0.7, 0.15, 1, duration: ShellTiming.reel),
                                               reduceMotion: false))
            {
                landed = true
            }
            withAnimation(MotionPolicy.resolve(
                .easeOut(duration: 0.14).delay(ShellTiming.reel - 0.14),
                reduceMotion: false
            )) {
                gone = true
            }
        }
    }
}
