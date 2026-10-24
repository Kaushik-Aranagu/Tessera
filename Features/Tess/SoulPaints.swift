import Foundation

/// Her palette (sheet 215 rev 20). Ember is her base: vermilion into gold. When a screen has one clear accent she takes
/// a close palette from it: the accent in the middle, and its hue turned 18 degrees each way at the sides. Home, or any
/// screen with several accents, keeps Ember; accents are never averaged. A change of palette glides over 1.2 s in
/// OKLCH, turning hue the short way so she never passes through grey, with a small catch at the end.
enum SoulPaints {
    static let glideSeconds = 1.2

    static func ember(dark: Bool) -> [UInt32] {
        dark ? SoulCloud.paintsDark : SoulCloud.paintsLight
    }

    /// The accent at L 0.64 (light) or 0.74 (dark) with chroma of at least 0.15 in the middle, ±18 degrees of hue at
    /// the sides. Order: middle, then the two sides (the middle field sits nearest her centre).
    static func close(to accent: UInt32, dark: Bool) -> [UInt32] {
        let lab = SoulCloud.oklab(accent)
        let chroma = max(hypot(lab.greenRed, lab.blueYellow), 0.15)
        let hue = atan2(lab.blueYellow, lab.greenRed)
        let lightness = dark ? 0.74 : 0.64
        let spread = 18 * Double.pi / 180
        return [hue, hue - spread, hue + spread].map { hex(lightness: lightness, chroma: chroma, hue: $0) }
    }

    /// The palette for a screen: a close palette from its one accent, else Ember.
    static func palette(dark: Bool, pageAccent: UInt32?) -> [UInt32] {
        pageAccent.map { close(to: $0, dark: dark) } ?? ember(dark: dark)
    }

    // MARK: Glide

    /// `from` toward `to` at `progress` (0 ... 1) in OKLCH, hue the short way, with a small catch at the end (a 3%
    /// overshoot that settles).
    static func glide(from: [UInt32], to: [UInt32], progress: Double) -> [UInt32] {
        guard from.count == to.count else { return to }
        let unit = min(max(progress, 0), 1)
        // Ease-out with a small catch (back-ease at 0.8).
        let overshoot = 0.8, back = overshoot + 1
        let eased = 1 + back * pow(unit - 1, 3) + overshoot * pow(unit - 1, 2)
        return zip(from, to).map { start, end in
            let first = lch(start), last = lch(end)
            var turn = last.hue - first.hue
            while turn > Double.pi {
                turn -= 2 * Double.pi
            }
            while turn < -Double.pi {
                turn += 2 * Double.pi
            }
            return hex(lightness: first.lightness + (last.lightness - first.lightness) * eased,
                       chroma: max(first.chroma + (last.chroma - first.chroma) * eased, 0),
                       hue: first.hue + turn * eased)
        }
    }

    static func lch(_ hex: UInt32) -> (lightness: Double, chroma: Double, hue: Double) {
        let lab = SoulCloud.oklab(hex)
        return (lab.lightness, hypot(lab.greenRed, lab.blueYellow), atan2(lab.blueYellow, lab.greenRed))
    }

    static func hex(lightness: Double, chroma: Double, hue: Double) -> UInt32 {
        let tone = SoulCloud.rgbInGamut(
            lightness: lightness,
            greenRed: chroma * cos(hue),
            blueYellow: chroma * sin(hue)
        )
        func byte(_ value: Double) -> UInt32 {
            UInt32((min(max(value, 0), 1) * 255).rounded())
        }
        return byte(tone.red) << 16 | byte(tone.green) << 8 | byte(tone.blue)
    }
}

/// Keeps the palette she is wearing and glides to a new one when her director chooses another (a reference type, so the
/// drawing can advance it without state updates).
final class SoulPaletteGlider {
    private var from: [UInt32]?
    private var target: [UInt32]?
    private var start = 0.0

    /// The paints to draw at `time` for the director's `target`; a change begins a glide from what is on screen now.
    func paints(target new: [UInt32], at time: Double, instant: Bool) -> [UInt32] {
        guard let target else {
            target = new
            from = new
            return new
        }
        if new != target {
            from = instant ? new : shown(at: time)
            self.target = new
            start = time
        }
        guard let from, !instant else { return new }
        return SoulPaints.glide(from: from, to: new, progress: (time - start) / SoulPaints.glideSeconds)
    }

    private func shown(at time: Double) -> [UInt32] {
        guard let from, let target else { return target ?? [] }
        return SoulPaints.glide(from: from, to: target, progress: (time - start) / SoulPaints.glideSeconds)
    }
}
