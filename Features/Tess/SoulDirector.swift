import Foundation

/// Who decides how Tess looks and how she changes (Kaushik, 1:22 PM): not random, not fixed rules. The burst of
/// colour (when, and which of her three colours) and the palette (which colours, and when they move toward others) are
/// decisions behind this seam. The rule-based director below is what runs today; Core's director takes its place
/// later without the drawing changing.
protocol SoulDirecting {
    /// The burst of colour under way at `time` (seconds), if any.
    func burst(at time: Double, quiet: Bool) -> SoulCloud.ActiveBurst?
    /// Her three paints for the screen she is on: it sees only the screen's one accent (nil on Home or any screen with
    /// several) and the ground. The glide between palettes is the drawing's, not the director's.
    func paints(dark: Bool, pageAccent: UInt32?) -> [UInt32]
}

/// The rules (a local shim with the director's signature): a seeded schedule of bursts, Ember, and a close palette from
/// a screen's one accent.
struct SoulRuleDirector: SoulDirecting {
    func burst(at time: Double, quiet: Bool) -> SoulCloud.ActiveBurst? {
        SoulCloud.burst(at: time, quiet: quiet)
    }

    func paints(dark: Bool, pageAccent: UInt32?) -> [UInt32] {
        SoulPaints.palette(dark: dark, pageAccent: pageAccent)
    }
}
