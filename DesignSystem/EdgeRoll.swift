import SwiftUI

/// Sheets 294 and 295: things roll over edges. Nothing is cut by the edge of a clipped place: once part of a thing is
/// past the edge it rolls away like paper over the edge of a drum. The roll is driven by how much of the thing is
/// already past (position, never time): by three quarters past it has tilted up to 16 degrees away over that edge
/// (pivot on the far side), shrunk by up to 4%, blurred by at most 1.2 pt and faded to 8%, on a smoothstep. Inside the
/// place nothing changes. The moving thing carries its own soft fade, a mask 28 pt deep that ends exactly at the
/// edge, so nothing is ever sliced; there is no band, no blur and no material over the clip itself, and nothing at
/// rest is touched. Not glass, no tint, no fill. Reduce Motion: no roll and no fade mask (the crossfade applies).
/// The departure board is exempt (it flaps in place and never scrolls).
enum EdgeRoll {
    // MARK: Tuning (sheet 295, section 1)

    /// The share of the thing past the edge at which the roll is complete.
    static let fullAt: CGFloat = 0.75
    static let maxTilt: Double = 16
    static let maxShrink: CGFloat = 0.04
    static let maxBlur: CGFloat = 1.2
    static let minOpacity: Double = 0.08
    /// The moving thing's own fade: clear at the clip edge, opaque this far inside.
    static let fadeDepth: CGFloat = 28

    // MARK: Pure pieces

    /// What a thing looks like at a given overflow.
    struct Look: Equatable {
        var tilt: Double
        var scale: CGFloat
        var blur: CGFloat
        var opacity: Double

        static let rest = Look(tilt: 0, scale: 1, blur: 0, opacity: 1)
    }

    /// Which side of the place a thing is past.
    enum Side: Equatable {
        /// The top of a vertical place, the left of a sideways one.
        case leading
        case trailing
    }

    /// How much of a thing is past the edge of its place, along one axis (`0` fully inside, `1` fully past).
    struct Overflow: Equatable {
        var fraction: CGFloat
        var side: Side

        static let none = Overflow(fraction: 0, side: .leading)
    }

    /// The share of the thing (`childMin ... childMax`) past the clip (`clipMin ... clipMax`) on its worse side.
    static func overflow(childMin: CGFloat, childMax: CGFloat, clipMin: CGFloat, clipMax: CGFloat) -> Overflow {
        let size = childMax - childMin
        guard size > 0 else { return .none }
        let before = min(max((clipMin - childMin) / size, 0), 1)
        let after = min(max((childMax - clipMax) / size, 0), 1)
        if before == 0, after == 0 {
            return .none
        }
        return before >= after ? Overflow(fraction: before, side: .leading) : Overflow(fraction: after, side: .trailing)
    }

    /// The smoothstep from nothing at the edge to the full roll at `fullAt` past it.
    static func look(overflow: CGFloat) -> Look {
        let progress = min(max(overflow / fullAt, 0), 1)
        let eased = progress * progress * (3 - 2 * progress)
        return Look(tilt: maxTilt * Double(eased), scale: 1 - maxShrink * eased, blur: maxBlur * eased,
                    opacity: 1 - (1 - minOpacity) * Double(eased))
    }

    /// Reduce Motion: no roll, no tilt, no shrink, no blur; the crossfade stays (opacity follows the overflow).
    static func look(overflow: CGFloat, reduceMotion: Bool) -> Look {
        guard reduceMotion else { return look(overflow: overflow) }
        return Look(tilt: 0, scale: 1, blur: 0, opacity: 1 - Double(min(max(overflow, 0), 1)))
    }

    /// One stop of the thing's own fade: `opacity` at `location` (0 to 1 along the thing).
    struct FadeStop: Equatable {
        var location: CGFloat
        var opacity: Double
    }

    /// The thing's own fade mask along one axis: clear at each clip edge it is past, opaque `fadeDepth` inside, and
    /// nil when it is fully inside (nothing at rest is touched).
    static func fade(childMin: CGFloat, childMax: CGFloat, clipMin: CGFloat, clipMax: CGFloat,
                     depth: CGFloat = fadeDepth) -> [FadeStop]?
    {
        let size = childMax - childMin
        guard size > 0, childMin < clipMin || childMax > clipMax else { return nil }
        func place(_ position: CGFloat) -> CGFloat {
            min(max((position - childMin) / size, 0), 1)
        }
        var stops: [FadeStop] = []
        let opaqueFrom = place(clipMin + depth)
        let opaqueTo = max(place(clipMax - depth), opaqueFrom)
        if childMin < clipMin {
            stops += [FadeStop(location: 0, opacity: 0), FadeStop(location: place(clipMin), opacity: 0),
                      FadeStop(location: opaqueFrom, opacity: 1)]
        } else {
            stops.append(FadeStop(location: 0, opacity: 1))
        }
        if childMax > clipMax {
            stops += [FadeStop(location: opaqueTo, opacity: 1), FadeStop(location: place(clipMax), opacity: 0),
                      FadeStop(location: 1, opacity: 0)]
        } else {
            stops.append(FadeStop(location: 1, opacity: 1))
        }
        return stops
    }

    /// The tilt's sign: the thing falls away from the viewer over the edge it is leaving by.
    static func tiltSign(side: Side, axis: Axis) -> Double {
        switch (axis, side) {
        case (.vertical, .leading): -1
        case (.vertical, .trailing): 1
        case (.horizontal, .leading): 1
        case (.horizontal, .trailing): -1
        }
    }
}

// MARK: - The roll itself

private extension View {
    /// The look applied: a tilt about the far side, a shrink toward it, a blur and a fade.
    func rolled(_ look: EdgeRoll.Look, axis: Axis, side: EdgeRoll.Side) -> some View {
        let pivot: UnitPoint = switch (axis, side) {
        case (.vertical, .leading): .bottom
        case (.vertical, .trailing): .top
        case (.horizontal, .leading): .trailing
        case (.horizontal, .trailing): .leading
        }
        let tilt = look.tilt * EdgeRoll.tiltSign(side: side, axis: axis)
        return rotation3DEffect(.degrees(tilt), axis: axis == .vertical ? (1, 0, 0) : (0, 1, 0), anchor: pivot,
                                perspective: 0.5)
            .scaleEffect(look.scale, anchor: pivot)
            .blur(radius: look.blur)
            .opacity(look.opacity)
    }

    /// The thing's own fade as a mask; nothing at all when `stops` is nil.
    @ViewBuilder
    func edgeFaded(_ stops: [EdgeRoll.FadeStop]?, axis: Axis) -> some View {
        if let stops {
            mask {
                LinearGradient(stops: stops.map { .init(color: .black.opacity($0.opacity), location: $0.location) },
                               startPoint: axis == .vertical ? .top : .leading,
                               endPoint: axis == .vertical ? .bottom : .trailing)
            }
        } else {
            self
        }
    }
}

private struct EdgeRollScroll: ViewModifier {
    let axis: Axis
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fade: [EdgeRoll.FadeStop]?

    func body(content: Content) -> some View {
        let reduce = reduceMotion
        let axis = axis
        content
            .visualEffect { view, proxy in
                guard !reduce, let clip = proxy.bounds(of: .scrollView) else { return view.opacity(1) }
                let frame = proxy.frame(in: .scrollView)
                let over = EdgeRoll.overflow(
                    childMin: axis == .vertical ? frame.minY : frame.minX,
                    childMax: axis == .vertical ? frame.maxY : frame.maxX,
                    clipMin: axis == .vertical ? clip.minY : clip.minX,
                    clipMax: axis == .vertical ? clip.maxY : clip.maxX
                )
                return view.rolled(EdgeRoll.look(overflow: over.fraction), axis: axis, side: over.side)
            }
            .edgeFaded(fade, axis: axis)
            .onGeometryChange(for: [EdgeRoll.FadeStop]?.self) { proxy in
                guard !reduce, let clip = proxy.bounds(of: .scrollView) else { return nil }
                let frame = proxy.frame(in: .scrollView)
                return EdgeRoll.fade(
                    childMin: axis == .vertical ? frame.minY : frame.minX,
                    childMax: axis == .vertical ? frame.maxY : frame.maxX,
                    clipMin: axis == .vertical ? clip.minY : clip.minX,
                    clipMax: axis == .vertical ? clip.maxY : clip.maxX
                )
            } action: { fade = $0 }
    }
}

/// The roll driven by an explicit overflow (a thing animating across the edge of a widget). `overflow` is `0` inside
/// and `1` fully past; coming in is the same roll in reverse. It also carries the thing across: `travel` points along
/// the axis toward `side` at full overflow. `inset` is where the thing sits inside the place (along the axis) and
/// `placeLength` the place's length, so its own fade ends exactly at the place's edge.
struct EdgeRollPass: ViewModifier, Animatable {
    var overflow: CGFloat
    var axis: Axis = .vertical
    var side: EdgeRoll.Side = .leading
    var travel: CGFloat = 0
    var inset: CGFloat = 0
    var placeLength: CGFloat = 0
    var reduceMotion = false

    var animatableData: CGFloat {
        get { overflow }
        set { overflow = newValue }
    }

    func body(content: Content) -> some View {
        let look = EdgeRoll.look(overflow: overflow, reduceMotion: reduceMotion)
        let shift = (side == .leading ? -1 : 1) * overflow * travel * (reduceMotion ? 0 : 1)
        return content
            .rolled(look, axis: axis, side: side)
            .edgeFadedInPlace(axis: axis, shift: shift, inset: inset, placeLength: placeLength,
                              active: overflow > 0 && !reduceMotion)
            .offset(x: axis == .horizontal ? shift : 0, y: axis == .vertical ? shift : 0)
    }
}

private extension View {
    /// The fade for a thing moving by `shift` inside a place: sized from the thing's own length.
    func edgeFadedInPlace(axis: Axis, shift: CGFloat, inset: CGFloat, placeLength: CGFloat,
                          active: Bool) -> some View
    {
        modifier(InPlaceFade(axis: axis, shift: shift, inset: inset, placeLength: placeLength, active: active))
    }
}

private struct InPlaceFade: ViewModifier {
    let axis: Axis
    let shift: CGFloat
    let inset: CGFloat
    let placeLength: CGFloat
    let active: Bool

    func body(content: Content) -> some View {
        content.mask {
            GeometryReader { proxy in
                let length = axis == .vertical ? proxy.size.height : proxy.size.width
                let low = inset + shift
                let stops = active && placeLength > 0
                    ? EdgeRoll.fade(childMin: low, childMax: low + length, clipMin: 0, clipMax: placeLength)
                    : nil
                if let stops {
                    LinearGradient(stops: stops.map { .init(color: .black.opacity($0.opacity), location: $0.location) },
                                   startPoint: axis == .vertical ? .top : .leading,
                                   endPoint: axis == .vertical ? .bottom : .trailing)
                } else {
                    Color.black
                }
            }
        }
    }
}

extension View {
    /// Sheet 295: a thing in a scrolled place that rolls over the scroll view's edge as it crosses, fading through the
    /// edge on its own mask. Put it on each child of a `ScrollView` (a row, a day, an hour column); nothing changes
    /// while the child is fully inside.
    func edgeRoll(axis: Axis) -> some View {
        modifier(EdgeRollScroll(axis: axis))
    }
}
