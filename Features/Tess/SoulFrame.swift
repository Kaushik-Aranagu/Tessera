import SwiftUI

/// Where one dab is in a frame, in points from the soul's centre (before the group scale).
struct SoulPose: Equatable {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scaleX: CGFloat = 0
    var scaleY: CGFloat = 0
    var blur: CGFloat = 4
    var opacity: CGFloat = 0

    static let hidden = SoulPose()

    static func mix(_ start: Self, _ end: Self, _ amount: CGFloat) -> Self {
        func lerp(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
            lhs * (1 - amount) + rhs * amount
        }
        return SoulPose(x: lerp(start.x, end.x), y: lerp(start.y, end.y), scaleX: lerp(start.scaleX, end.scaleX),
                        scaleY: lerp(start.scaleY, end.scaleY), blur: lerp(start.blur, end.blur),
                        opacity: lerp(start.opacity, end.opacity))
    }
}

/// The fixed geometry of the six dabs (three mains, then three satellites) and the drip.
struct SoulDab {
    let home: CGPoint
    let bloom: CGPoint
    let size: CGSize
    /// Colour and corner shape: 0 vermilion, 1 cobalt, 2 cadmium.
    let paint: Int

    static let all: [SoulDab] = [
        SoulDab(home: tightened(CGPoint(x: -14, y: -8)), bloom: CGPoint(x: 18, y: -10), size: main, paint: 0),
        SoulDab(home: tightened(CGPoint(x: 14, y: -8)), bloom: CGPoint(x: -16, y: -12), size: main, paint: 1),
        SoulDab(home: tightened(CGPoint(x: 0, y: 13)), bloom: CGPoint(x: 0, y: 18), size: main, paint: 2),
        SoulDab(home: tightened(CGPoint(x: -22, y: 10)), bloom: CGPoint(x: -20, y: 14), size: satellite, paint: 0),
        SoulDab(home: tightened(CGPoint(x: 20, y: 12)), bloom: CGPoint(x: 22, y: 10), size: satellite, paint: 1),
        SoulDab(home: tightened(CGPoint(x: 4, y: -20)), bloom: CGPoint(x: 6, y: -22), size: satellite, paint: 2),
    ]
    /// The spread (soul-explore.md, "After he picks"; Kaushik, 16 Oct): every home offset pulled toward the main
    /// dabs' centre to 65% of the original, matching the icon. Each mode's paths (bloom, carry, drip) are unchanged.
    static let spread: CGFloat = 0.65
    private static let centre = CGPoint(x: 0, y: -1)

    private static func tightened(_ home: CGPoint) -> CGPoint {
        CGPoint(x: centre.x + (home.x - centre.x) * spread, y: centre.y + (home.y - centre.y) * spread)
    }

    static let drip = SoulDab(home: .zero, bloom: .zero, size: CGSize(width: 22, height: 20), paint: 0)
    static let main = CGSize(width: 76, height: 70)
    static let satellite = CGSize(width: 46, height: 42)
    /// The splash ring's diameter at scale 1.
    static let ringDiameter: CGFloat = 100

    func pose(_ key: SoulKey, target: CGPoint) -> SoulPose {
        SoulPose(
            x: key.home * home.x + key.bloom * bloom.x + key.target * target.x + key.dx,
            y: key.home * home.y + key.bloom * bloom.y + key.target * target.y + key.dy,
            scaleX: key.scaleX, scaleY: key.scaleY, blur: key.blur, opacity: key.opacity
        )
    }
}

/// Everything the shader needs for one instant: six dabs, the drip, the ring, the halo and the group look.
struct SoulFrame: Equatable {
    var dabs: [SoulPose]
    var drip = SoulPose.hidden
    /// `scaleX` is the ring's scale.
    var ring = SoulPose.hidden
    /// `scaleX` is the halo's scale.
    var halo = SoulPose(scaleX: 0.9, scaleY: 0.9, opacity: 0.8)
    var look = SoulLook()
    /// A moment's whole-body move (a lean, a peek's rise), in the canvas's points after the look's scale. Not mixed:
    /// it belongs to the overlay that sets it, never to a mode.
    var shift = CGPoint.zero

    static func mix(_ start: Self, _ end: Self, _ amount: CGFloat) -> Self {
        SoulFrame(
            dabs: zip(start.dabs, end.dabs).map { SoulPose.mix($0, $1, amount) },
            drip: .mix(start.drip, end.drip, amount), ring: .mix(start.ring, end.ring, amount),
            halo: .mix(start.halo, end.halo, amount), look: .mix(start.look, end.look, amount)
        )
    }

    /// Samples one mode. `time` drives looping tracks (so loops stay continuous across mode changes); `elapsed`
    /// (seconds since the mode began) drives one-shots. `still` freezes every track at the mode's still phase.
    static func sample(_ mode: TessSoul.Mode, time: Double, elapsed: Double, loops: Bool = false,
                       still: Bool = false) -> SoulFrame
    {
        let parameters = SoulParameters.table(mode)
        let target: CGPoint = if case let .handOff(point) = mode {
            point
        } else {
            .zero
        }

        func progress(_ track: SoulTrack) -> Double {
            if still {
                return parameters.stillPhase
            }
            guard parameters.isOneShot else {
                return TessSoul.phase(time, period: track.period, delay: track.delay)
            }
            var local = elapsed - track.delay
            if loops {
                let cycle = track.period + 0.8
                local = local.truncatingRemainder(dividingBy: cycle)
                if local < 0 {
                    local += cycle
                }
            }
            return local / track.period
        }
        func pose(_ track: SoulTrack, _ dab: SoulDab) -> SoulPose {
            dab.pose(track.key(at: progress(track)), target: target)
        }

        let tracks = parameters.mains + parameters.satellites
        var frame = SoulFrame(dabs: zip(tracks, SoulDab.all).map { pose($0, $1) }, look: parameters.look)
        if let drip = parameters.drip {
            frame.drip = pose(drip, SoulDab.drip)
        }
        if let ring = parameters.ring {
            frame.ring = pose(ring, SoulDab.drip)
        }
        if !still {
            // CSS `halo`: 7 s breath, scale .8 → 1, opacity .6 → 1.
            let breath = CGFloat(UnitCurve.easeInOut.value(at: 1 - abs(2 * TessSoul.phase(time, period: 7) - 1)))
            frame.halo = SoulPose(scaleX: 0.8 + 0.2 * breath, scaleY: 0.8 + 0.2 * breath, opacity: 0.6 + 0.4 * breath)
        }
        return frame
    }
}

/// One mode on screen, from `start`. A new mode fades in over `SoulBlend.duration`, on top of whatever was there.
struct SoulLayer: Equatable {
    var mode: TessSoul.Mode
    var start: Date
}

enum SoulBlend {
    static let duration: Double = 0.4

    /// 0…1, eased, for a layer that began `elapsed` seconds ago.
    static func weight(_ elapsed: Double) -> CGFloat {
        let linear = min(max(elapsed / duration, 0), 1)
        return CGFloat(UnitCurve.easeInOut.value(at: linear))
    }

    /// Folds the stack oldest-first, so a change that interrupts a blend carries on from what is on screen.
    static func frame(_ layers: [SoulLayer], at date: Date, loops: Bool) -> SoulFrame? {
        let time = date.timeIntervalSinceReferenceDate
        // Start from the newest layer that has fully blended in; anything older is invisible.
        let base = layers.lastIndex { date.timeIntervalSince($0.start) >= duration } ?? 0
        guard base < layers.count else { return nil }
        var result: SoulFrame?
        for layer in layers[base...] {
            let elapsed = date.timeIntervalSince(layer.start)
            let next = SoulFrame.sample(layer.mode, time: time, elapsed: elapsed, loops: loops)
            if let current = result {
                result = SoulFrame.mix(current, next, weight(elapsed))
            } else {
                result = next
            }
        }
        return result
    }

    /// Adds a layer for `mode`, dropping layers that the newest fully-blended one already hides.
    static func push(_ mode: TessSoul.Mode, onto layers: [SoulLayer], at date: Date) -> [SoulLayer] {
        var stack = layers
        if let base = stack.lastIndex(where: { date.timeIntervalSince($0.start) >= duration }) {
            stack.removeFirst(base)
        }
        stack.append(SoulLayer(mode: mode, start: date))
        return Array(stack.suffix(4))
    }
}
