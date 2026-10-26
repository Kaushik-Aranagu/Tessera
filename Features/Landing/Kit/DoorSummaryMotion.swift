import SwiftUI

/// How a room's door summary changes when the dial turns (sheet 283 v6). All under 1 s, all through MotionPolicy;
/// Reduce Motion is a plain swap (the policy's 150 ms cross-fade, nothing moves).
enum DoorSummaryStyle: Equatable {
    /// The kit's plain rise (Settings, Log until it has its own).
    case rise
    /// Deck: lines chalked on left to right (0.3 s each, 0.15 s apart) in Barlow Condensed; old ones wiped off with a
    /// small puff of chalk dust falling toward the foot.
    case chalk
    /// Lookout: new lines condense out of fog (blur 8 to 0, letter spacing .22 em to normal, 0.62 s); old lines
    /// evaporate upward.
    case fog
    /// Watch: new lines grow up from their baseline with a small sway (0.56 s); old lines fall like leaves.
    case grow

    var family: String {
        self == .chalk ? "BarlowCondensed-SemiBold" : "Figtree"
    }

    /// Barlow Condensed is narrow; 17 pt keeps it the same optical size as Figtree 16.
    var lineSize: CGFloat {
        self == .chalk ? 17 : 16
    }

    /// Total length of a change for `rows` rows.
    func duration(rows: Int) -> Double {
        switch self {
        case .rise: 0.35
        case .chalk: 0.3 + 0.15 * Double(max(rows - 1, 0))
        case .fog: 0.62
        case .grow: 0.56
        }
    }

    func animation(rows: Int) -> Animation {
        switch self {
        case .rise: Theme.Motion.firm
        case .chalk, .fog: .timingCurve(0.2, 0.8, 0.2, 1, duration: duration(rows: rows))
        case .grow: .spring(duration: 0.56, bounce: 0.3)
        }
    }

    func transition(index: Int, count: Int, reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        switch self {
        case .rise:
            return .offset(y: 6)
        case .chalk:
            let window = ChalkWindow(index: index, count: count)
            return .asymmetric(insertion: .modifier(active: ChalkOn(progress: 0, window: window),
                                                    identity: ChalkOn(progress: 1, window: window)),
                               removal: .modifier(active: ChalkOff(progress: 1, seed: index),
                                                  identity: ChalkOff(progress: 0, seed: index)))
        case .fog:
            return .asymmetric(insertion: .modifier(active: FogIn(progress: 0), identity: FogIn(progress: 1)),
                               removal: .modifier(active: FogOut(progress: 1), identity: FogOut(progress: 0)))
        case .grow:
            return .asymmetric(insertion: .modifier(active: GrowIn(progress: 0, index: index),
                                                    identity: GrowIn(progress: 1, index: index)),
                               removal: .modifier(active: LeafFall(progress: 1, index: index),
                                                  identity: LeafFall(progress: 0, index: index)))
        }
    }
}

/// The share of the whole change one chalked row takes, and where it starts: 0.3 s each, 0.15 s apart.
struct ChalkWindow: Equatable {
    let index: Int
    let count: Int

    /// The row's own progress (0 to 1) inside the whole change's `progress`.
    func local(_ progress: Double) -> Double {
        let total = 0.3 + 0.15 * Double(max(count - 1, 0))
        let start = 0.15 * Double(index) / total
        let length = 0.3 / total
        return min(max((progress - start) / length, 0), 1)
    }
}

private struct ChalkOn: ViewModifier, Animatable {
    var progress: Double
    let window: ChalkWindow

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let local = window.local(progress)
        content.mask(alignment: .leading) {
            Rectangle().frame(width: 196 * local)
        }
    }
}

private struct ChalkOff: ViewModifier, Animatable {
    var progress: Double
    let seed: Int

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        // The towel goes left to right; the dust it lifts falls toward the foot.
        content
            .mask(alignment: .trailing) { Rectangle().frame(width: 196 * (1 - progress)) }
            .overlay(alignment: .topLeading) {
                Canvas { context, _ in
                    guard progress > 0, progress < 1 else { return }
                    for grain in 0 ..< 12 {
                        let hash = Double((grain * 37 + seed * 11) % 23) / 23
                        let x = 196 * progress - 10 + hash * 18
                        let y = 6 + hash * 14 + progress * progress * 34
                        let side = 1 + hash * 1.4
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                                     with: .color(Theme.Colors.inkSecondary.opacity(0.55 * (1 - progress))))
                    }
                }
                .frame(width: 210, height: 64)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

private struct FogIn: ViewModifier, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .tracking(0.22 * 16 * (1 - progress))
            .blur(radius: 8 * (1 - progress))
            .opacity(progress)
    }
}

private struct FogOut: ViewModifier, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: 6 * progress)
            .offset(y: -12 * progress)
            .opacity(1 - progress)
    }
}

private struct GrowIn: ViewModifier, Animatable {
    var progress: Double
    let index: Int

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        // Up from the baseline; the spring's overshoot is the sway.
        let lean = (1 - progress) * (index.isMultiple(of: 2) ? -6 : 5)
        content
            .scaleEffect(x: 1, y: max(progress, 0.01), anchor: .bottomLeading)
            .rotationEffect(.degrees(lean), anchor: .bottomLeading)
    }
}

private struct LeafFall: ViewModifier, Animatable {
    var progress: Double
    let index: Int

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let side: Double = index.isMultiple(of: 2) ? 1 : -1
        content
            .rotationEffect(.degrees(16 * progress * side), anchor: .center)
            .offset(x: 14 * sin(progress * .pi * 1.5) * side, y: 40 * progress * progress)
            .opacity(1 - progress)
    }
}
