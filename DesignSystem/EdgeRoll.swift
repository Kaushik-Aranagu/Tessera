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
    // MARK: Tuning (sheets 295 and 297)

    /// The share of the thing past the edge at which the roll is complete.
    static let fullAt: CGFloat = 0.75

    /// One roll's strengths: its own fade depth (clear at the clip edge, opaque this far inside), the lean away over
    /// the edge in degrees, the shrink, and whether it also softens (a 1.2 pt blur and a fade of the thing's own
    /// opacity to 8%). A fade with no lean and no shrink is the whole preset for the switcher word.
    struct Preset: Equatable {
        var depth: CGFloat
        var lean: Double
        var shrink: CGFloat
        var softens: Bool

        /// The widget card (sheet 295): 28 pt fade, 16 degrees, 4%, blur and fade yes.
        static let card = Preset(depth: 28, lean: 16, shrink: 0.04, softens: true)
        /// List rows (297): 18 pt fade, 10 degrees, 3%; the mask is the fade, the row's own opacity stays.
        static let row = Preset(depth: 18, lean: 10, shrink: 0.03, softens: false)
        /// The switcher word on every landing (297): a 22 pt fade only, no lean, no shrink.
        static let word = Preset(depth: 22, lean: 0, shrink: 0, softens: false)
    }

    static let maxBlur: CGFloat = 1.2
    static let minOpacity: Double = 0.08
    /// The card's fade depth.
    static let fadeDepth: CGFloat = Preset.card.depth

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
    static func look(overflow: CGFloat, preset: Preset = .card) -> Look {
        let progress = min(max(overflow / fullAt, 0), 1)
        let eased = progress * progress * (3 - 2 * progress)
        return Look(tilt: preset.lean * Double(eased), scale: 1 - preset.shrink * eased,
                    blur: preset.softens ? maxBlur * eased : 0,
                    opacity: preset.softens ? 1 - (1 - minOpacity) * Double(eased) : 1)
    }

    /// Reduce Motion: no roll, no tilt, no shrink, no blur; the crossfade stays (opacity follows the overflow).
    static func look(overflow: CGFloat, preset: Preset = .card, reduceMotion: Bool) -> Look {
        guard reduceMotion else { return look(overflow: overflow, preset: preset) }
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

    /// What to apply to a scrolled child right now.
    struct State {
        var look: Look
        var tilt: Double
        var pivot: UnitPoint
        var axisVector: (x: CGFloat, y: CGFloat, z: CGFloat)
    }

    /// Reads the child's frame against the scroll view and gives the roll to apply (rest when inside or Reduce Motion).
    static func state(proxy: GeometryProxy, axis: Axis, preset: Preset, reduceMotion: Bool) -> State {
        let vector: (x: CGFloat, y: CGFloat, z: CGFloat) = axis == .vertical ? (1, 0, 0) : (0, 1, 0)
        guard !reduceMotion, let clip = proxy.bounds(of: .scrollView) else {
            return State(look: .rest, tilt: 0, pivot: .center, axisVector: vector)
        }
        let frame = proxy.frame(in: .scrollView)
        let vertical = axis == .vertical
        let over = overflow(childMin: vertical ? frame.minY : frame.minX, childMax: vertical ? frame.maxY : frame.maxX,
                            clipMin: vertical ? clip.minY : clip.minX, clipMax: vertical ? clip.maxY : clip.maxX)
        let look = look(overflow: over.fraction, preset: preset)
        return State(look: look, tilt: look.tilt * tiltSign(side: over.side, axis: axis),
                     pivot: pivot(axis: axis, side: over.side), axisVector: vector)
    }

    /// The far side of the thing, where it pivots.
    static func pivot(axis: Axis, side: Side) -> UnitPoint {
        switch (axis, side) {
        case (.vertical, .leading): .bottom
        case (.vertical, .trailing): .top
        case (.horizontal, .leading): .trailing
        case (.horizontal, .trailing): .leading
        }
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
        let pivot = EdgeRoll.pivot(axis: axis, side: side)
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
    let preset: EdgeRoll.Preset
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fade: [EdgeRoll.FadeStop]?

    func body(content: Content) -> some View {
        let reduce = reduceMotion
        let axis = axis
        let preset = preset
        content
            .visualEffect { view, proxy in
                let state = EdgeRoll.state(proxy: proxy, axis: axis, preset: preset, reduceMotion: reduce)
                return view
                    .rotation3DEffect(.degrees(state.tilt), axis: state.axisVector, anchor: state.pivot,
                                      perspective: 0.5)
                    .scaleEffect(state.look.scale, anchor: state.pivot)
                    .blur(radius: state.look.blur)
                    .opacity(state.look.opacity)
            }
            .edgeFaded(fade, axis: axis)
            .onGeometryChange(for: [EdgeRoll.FadeStop]?.self) { proxy in
                guard !reduce, let clip = proxy.bounds(of: .scrollView) else { return nil }
                let frame = proxy.frame(in: .scrollView)
                return EdgeRoll.fade(
                    childMin: axis == .vertical ? frame.minY : frame.minX,
                    childMax: axis == .vertical ? frame.maxY : frame.maxX,
                    clipMin: axis == .vertical ? clip.minY : clip.minX,
                    clipMax: axis == .vertical ? clip.maxY : clip.maxX,
                    depth: preset.depth
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
    var preset = EdgeRoll.Preset.card
    var reduceMotion = false

    nonisolated var animatableData: CGFloat {
        get { overflow }
        set { overflow = newValue }
    }

    func body(content: Content) -> some View {
        let look = EdgeRoll.look(overflow: overflow, preset: preset, reduceMotion: reduceMotion)
        let shift = (side == .leading ? -1 : 1) * overflow * travel * (reduceMotion ? 0 : 1)
        return content
            .rolled(look, axis: axis, side: side)
            .edgeFaded(axis: axis, shift: shift, inset: inset, placeLength: placeLength, depth: preset.depth,
                       active: overflow > 0 && !reduceMotion)
            .offset(x: axis == .horizontal ? shift : 0, y: axis == .vertical ? shift : 0)
    }
}

private extension View {
    // The fade for a thing moving by `shift` inside a place, sized from the thing's own length.
    // swiftlint:disable:next function_parameter_count
    func edgeFaded(axis: Axis, shift: CGFloat, inset: CGFloat, placeLength: CGFloat, depth: CGFloat,
                   active: Bool) -> some View
    {
        modifier(InPlaceFade(axis: axis, shift: shift, inset: inset, placeLength: placeLength, depth: depth,
                             active: active))
    }
}

private struct InPlaceFade: ViewModifier {
    let axis: Axis
    let shift: CGFloat
    let inset: CGFloat
    let placeLength: CGFloat
    let depth: CGFloat
    let active: Bool

    func body(content: Content) -> some View {
        content.mask {
            GeometryReader { proxy in
                let length = axis == .vertical ? proxy.size.height : proxy.size.width
                let low = inset + shift
                let stops = active && placeLength > 0
                    ? EdgeRoll.fade(
                        childMin: low,
                        childMax: low + length,
                        clipMin: 0,
                        clipMax: placeLength,
                        depth: depth
                    )
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
    /// Sheets 295, 297: a thing in a scrolled place that rolls over the scroll view's edge as it crosses, fading
    /// through the edge on its own mask (never a blur or a material over the clip). Put it on each child of a
    /// `ScrollView` (a row, a day, an hour column); nothing changes while the child is fully inside. The defaults
    /// are the card; `edgeRoll(axis:preset:)` names the three presets.
    func edgeRoll(axis: Axis, depth: CGFloat = EdgeRoll.Preset.card.depth, lean: Double = EdgeRoll.Preset.card.lean,
                  shrink: CGFloat = EdgeRoll.Preset.card.shrink, softens: Bool = true) -> some View
    {
        modifier(EdgeRollScroll(axis: axis, preset: .init(depth: depth, lean: lean, shrink: shrink,
                                                          softens: softens)))
    }

    func edgeRoll(axis: Axis, preset: EdgeRoll.Preset) -> some View {
        modifier(EdgeRollScroll(axis: axis, preset: preset))
    }

    /// The fade alone, for a thing the caller moves itself by `shift` inside a place `placeLength` long (the
    /// switcher word under his finger): no lean, no shrink, nothing at rest touched. Off under Reduce Motion.
    func edgeFade(axis: Axis, shift: CGFloat, placeLength: CGFloat, depth: CGFloat = EdgeRoll.Preset.word.depth,
                  inset: CGFloat = 0, reduceMotion: Bool) -> some View
    {
        edgeFaded(axis: axis, shift: shift, inset: inset, placeLength: placeLength, depth: depth,
                  active: !reduceMotion && shift != 0)
    }
}
