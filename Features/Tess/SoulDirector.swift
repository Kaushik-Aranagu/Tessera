import Foundation
import TesseraCore

/// Who decides how Tess looks and how she changes (Kaushik, 1:22 PM): not random, not fixed rules. The burst of
/// colour (when, and which of her three colours) and the palette (which colours, and when they move toward others) are
/// decisions behind this seam. The rule-based director below is what runs today; Core's director takes its place
/// later without the drawing changing.
protocol SoulDirecting {
    /// The burst of colour under way at `time` (seconds), if any.
    func burst(at time: Double, quiet: Bool) -> SoulCloud.ActiveBurst?
    /// Her three paints for the screen she is on: it sees only the screen's one accent (nil on Home or any screen with
    /// several) and the ground. The glide between palettes is the drawing's, not the director's.
    func paints(dark: Bool, pageAccents: Set<AppID>) -> [UInt32]
}

/// The rules (a local shim with the director's signature): a seeded schedule of bursts, Ember, and a close palette from
/// a screen's one accent.
struct SoulRuleDirector: SoulDirecting {
    func burst(at time: Double, quiet: Bool) -> SoulCloud.ActiveBurst? {
        SoulCloud.burst(at: time, quiet: quiet)
    }

    func paints(dark: Bool, pageAccents _: Set<AppID>) -> [UInt32] {
        SoulPaints.ember(dark: dark)
    }
}

/// Core's director behind the seam (`TessDirection.decide`, the clamps included): her palette is Ember, or three
/// colours derived from the screen's one accent. The director sees only the screen's accents and her state. Her
/// bursts' timing keeps the seeded schedule until Core's burst choice carries a schedule.
struct CoreSoulDirector: SoulDirecting {
    var core: any TessDirector = RuleDirector()
    /// Each app's accent in OKLCH, for the palette it derives (light and dark).
    var accents: (_ dark: Bool) -> [AppID: OKLCH] = { _ in [:] }
    var reduceMotion = false
    var lowPower = false

    func burst(at time: Double, quiet: Bool) -> SoulCloud.ActiveBurst? {
        SoulCloud.burst(at: time, quiet: quiet)
    }

    func paints(dark: Bool, pageAccents: Set<AppID>) -> [UInt32] {
        let context = DirectorContext(now: .now, reduceMotion: reduceMotion, lowPower: lowPower, dark: dark,
                                      accents: accents(dark))
        let decision = TessDirection.decide(core, .tessPalette(pageAccents: pageAccents), context: context)
        guard case let .tessPalette(choice) = decision.choice, choice.accent != nil, choice.colors.count == 3 else {
            return SoulPaints.ember(dark: dark)
        }
        // The colours come back in OKLCH and may sit outside sRGB: they are brought in by reducing chroma.
        return choice.colors.map {
            SoulPaints.hex(lightness: $0.lightness, chroma: $0.chroma, hue: $0.hue * Double.pi / 180)
        }
    }
}
