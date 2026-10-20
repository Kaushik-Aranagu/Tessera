import SwiftUI

/// One of the twelve lights while she works: the six dabs as built, plus six hidden children (two per main, the
/// parent's paint) that only show when she splits. In the dab space `SoulRenderer` draws in (before the look's
/// scale); `radiusX`/`radiusY` are the half-size of the paint shape.
struct SoulLight: Equatable {
    var x: CGFloat
    var y: CGFloat
    var radiusX: CGFloat
    var radiusY: CGFloat
    var blur: CGFloat
    var alpha: CGFloat
    var paint: Int
}

/// When the working overlay began and, once she was told to stop, when the gather began.
struct SoulWorkTimes: Equatable {
    var split: Date
    var gather: Date?

    /// Seeds the dock lights' drift, so no two working states move alike (idea 1).
    var seed: UInt64 {
        UInt64(abs(split.timeIntervalSinceReferenceDate) * 1000)
    }
}

/// Working: fade, split, process, gather (docs/design/motion/tess-motion.md §5, the lab's `tess-motion.html`).
/// Pure: every value is a function of the seconds since the split and since the gather, so a frame at any time is
/// the same frame (and testable). Positions are worked out in on-screen points round the soul's centre (the lab's
/// values), then brought into dab space by the soul's drawn scale.
enum SoulWork {
    /// Each light's parent dab: 0-5 are the dabs, 6-11 the children (6, 7 vermilion; 8, 9 cobalt; 10, 11 cadmium).
    static let parent = [0, 1, 2, 3, 4, 5, 0, 0, 1, 1, 2, 2]
    /// The gather lands every light on its dab at this point (§5: "every light lands within the same 60 ms").
    static let gatherDuration = 0.82
    /// The fade: saturation to 0.62 over 500 ms.
    static let fadeDuration = 0.5
    static let fadedSaturation: CGFloat = 0.62
    /// The constellation's centre: 10 pt left of home and 7 pt up, beside her line.
    static let centre = CGPoint(x: -10, y: -7)
    /// The lab's think scene splits at 1.4 s; its loops run on scene time, so ours start at the same phase.
    static let phase = 1.4

    /// One light's Lissajous loop: x and y amplitude, x and y period, phase, radius (the lab's `CONSTELLATION`).
    struct Orbit {
        let ampX: CGFloat, ampY: CGFloat, periodX: Double, periodY: Double, phase: Double, radius: CGFloat
    }

    static let orbits: [Int: Orbit] = {
        var result: [Int: Orbit] = [
            0: Orbit(ampX: 26, ampY: 14, periodX: 6.2, periodY: 4.4, phase: 0, radius: 15),
            2: Orbit(ampX: 20, ampY: 18, periodX: 7.4, periodY: 5.2, phase: 1.7, radius: 15),
            3: Orbit(ampX: 34, ampY: 12, periodX: 8.6, periodY: 6.1, phase: 3.1, radius: 11),
            4: Orbit(ampX: 16, ampY: 20, periodX: 5.6, periodY: 7.8, phase: 4.4, radius: 11),
            5: Orbit(ampX: 10, ampY: 8, periodX: 9.2, periodY: 6.6, phase: 2.2, radius: 11),
            7: Orbit(ampX: 30, ampY: 16, periodX: 6.8, periodY: 5.7, phase: 5.3, radius: 12),
            8: Orbit(ampX: 5, ampY: 4, periodX: 7.9, periodY: 4.9, phase: 0.9, radius: 12),
            9: Orbit(ampX: 12, ampY: 22, periodX: 8.3, periodY: 6.9, phase: 3.8, radius: 12),
            11: Orbit(ampX: 28, ampY: 20, periodX: 9.7, periodY: 7.3, phase: 2.6, radius: 12),
        ]
        // The three that read (cobalt, then a vermilion and a cadmium child) orbit with the rest until readers land.
        for index in [1, 6, 10] {
            let value = Double(index)
            result[index] = Orbit(ampX: 18 + CGFloat(index), ampY: 12 + CGFloat(index % 3) * 4,
                                  periodX: 6 + value * 0.3, periodY: 5 + value * 0.2, phase: value,
                                  radius: index == 1 ? 15 : 12)
        }
        return result
    }()

    /// The three lights that read, by index: the cobalt main and a vermilion and a cadmium child.
    static let readerNumber: [Int: Int] = [1: 0, 6: 1, 10: 2]

    private static let splitCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.4, y: 0),
                                                     endControlPoint: UnitPoint(x: 0.2, y: 1))
    private static let gatherCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.55, y: 0),
                                                      endControlPoint: UnitPoint(x: 0.15, y: 1))

    private static func ramp(_ time: Double, from start: Double, over duration: Double,
                             _ curve: UnitCurve = .easeInOut) -> CGFloat
    {
        CGFloat(curve.value(at: min(max((time - start) / duration, 0), 1)))
    }

    /// 0…1: how far light `index` is out in the constellation. Satellites leave first, children last, 30 to 80 ms
    /// apart; on the gather they start home 25 ms apart and all land at `gatherDuration`.
    static func weight(_ index: Int, sinceSplit: Double, sinceGather: Double?) -> CGFloat {
        let delay = 0.25 + (index >= 6 ? 0.08 * Double(index - 5) : 0.03 * Double(index))
        let out = ramp(sinceSplit, from: delay, over: 0.9, splitCurve)
        guard let sinceGather else { return out }
        let start = 0.14 + 0.025 * Double(index % 6)
        return out * (1 - ramp(sinceGather, from: start, over: gatherDuration - start, gatherCurve))
    }

    /// 0…1: her colour drained. Out over 500 ms from the split; back from 300 ms into the gather over 550 ms.
    static func fade(sinceSplit: Double, sinceGather: Double?) -> CGFloat {
        let out = ramp(sinceSplit, from: 0, over: fadeDuration)
        guard let sinceGather else { return out }
        return out * (1 - ramp(sinceGather, from: 0.3, over: 0.55))
    }

    /// The look while she works: saturation to 0.62, contrast to 1, opacity to 90%, the halo gone.
    static func grade(_ frame: SoulFrame, fade: CGFloat) -> SoulFrame {
        var result = frame
        result.look.saturation += (fadedSaturation - frame.look.saturation) * fade
        result.look.contrast += (1 - frame.look.contrast) * fade
        result.look.opacity *= 1 - 0.1 * fade
        result.halo.opacity *= 1 - fade
        return result
    }

    /// A light at its place in the constellation, in on-screen points round the soul's centre.
    static func constellation(_ index: Int, time: Double) -> SoulLight {
        let orbit = orbits[index] ?? orbits[0]!
        let breathe = 1 + 0.14 * sin(2 * .pi * time / (3.1 + Double(index) * 0.37) + orbit.phase)
        return SoulLight(
            x: centre.x + orbit.ampX * CGFloat(sin(2 * .pi * time / orbit.periodX + orbit.phase)),
            y: centre.y + orbit.ampY * CGFloat(sin(2 * .pi * time / orbit.periodY + orbit.phase * 1.3)),
            radiusX: orbit.radius * CGFloat(breathe), radiusY: orbit.radius * 0.9 * CGFloat(breathe), blur: 5,
            alpha: 0.55, paint: SoulDab.all[parent[index]].paint
        )
    }

    /// The twelve lights for one frame, in dab space. `scale` is the soul's on-screen scale per dab-space point
    /// (the look's scale times whatever the host scales her by). Low Power keeps the children home: six lights.
    static func lights(_ frame: SoulFrame, scale: CGFloat, sinceSplit: Double, sinceGather: Double?,
                       lowPower: Bool = false, readers: [CGRect] = [], seed: UInt64? = nil) -> [SoulLight]
    {
        let time = sinceSplit + phase
        return parent.indices.map { index in
            let dab = SoulDab.all[parent[index]]
            let pose = frame.dabs[parent[index]]
            let satellites = parent[index] >= 3 ? frame.look.satellites : 1
            let formed = SoulLight(x: pose.x, y: pose.y, radiusX: dab.size.width / 2 * pose.scaleX,
                                   radiusY: dab.size.height / 2 * pose.scaleY, blur: pose.blur,
                                   alpha: index < 6 ? pose.opacity * satellites : 0, paint: dab.paint)
            let amount = lowPower && index >= 6 ? 0 : weight(index, sinceSplit: sinceSplit, sinceGather: sinceGather)
            guard amount > 0 else { return formed }
            var out = constellation(index, time: time)
            // The three that read go to the words the ask touches (idea 1); Low Power has no readers.
            if !lowPower, let reader = readerNumber[index],
               let point = SoulReaders.position(words: readers, reader: reader, time: max(sinceSplit - 0.9, 0))
            {
                out.x = point.x
                out.y = point.y
            }
            if let seed {
                let drift = SoulNoise.offset(light: index, time: lowPower ? 0 : sinceSplit, seed: seed)
                out.x += drift.x
                out.y += drift.y
            }
            out.x /= scale
            out.y /= scale
            out.radiusX /= scale
            out.radiusY /= scale
            out.blur /= scale
            return travel(formed, out, amount, index: index)
        }
    }

    /// From formed to out along an arc (never a straight slide); a child fades up as it leaves its parent and
    /// back into it in the last 40% of its way home.
    static func travel(_ start: SoulLight, _ end: SoulLight, _ amount: CGFloat, index: Int) -> SoulLight {
        let midX = (start.x + end.x) / 2, midY = (start.y + end.y) / 2
        let deltaX = end.x - start.x, deltaY = end.y - start.y
        let distance = max(hypot(deltaX, deltaY), 0.0001)
        let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
        let controlX = midX - deltaY / distance * distance * 0.22 * side
        let controlY = midY + deltaX / distance * distance * 0.22 * side
        let rest = 1 - amount
        func lerp(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
            lhs + (rhs - lhs) * amount
        }
        return SoulLight(
            x: rest * rest * start.x + 2 * rest * amount * controlX + amount * amount * end.x,
            y: rest * rest * start.y + 2 * rest * amount * controlY + amount * amount * end.y,
            radiusX: lerp(start.radiusX, end.radiusX), radiusY: lerp(start.radiusY, end.radiusY),
            blur: lerp(start.blur, end.blur),
            alpha: index < 6 ? lerp(start.alpha, end.alpha) : end.alpha * min(amount * 1.6, 1),
            paint: start.paint
        )
    }

    /// Reduce Motion (§13): no travel, and never a faded Tess (Kaushik 12:46 PM; Product G-soul): she keeps full
    /// opacity, saturation and halo, and shows "working" by position only (no swell, §13). The mains move apart in
    /// place to 1.5x their offset; the satellites stay as they are. `amount` is the 200 ms crossfade.
    static func reduced(_ frame: SoulFrame, amount: CGFloat) -> SoulFrame {
        var result = frame
        for index in result.dabs.indices where index < 3 {
            result.dabs[index].x *= 1 + 0.5 * amount
            result.dabs[index].y *= 1 + 0.5 * amount
        }
        return result
    }
}
