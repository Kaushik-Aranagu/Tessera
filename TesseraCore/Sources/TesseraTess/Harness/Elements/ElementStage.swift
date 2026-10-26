import Foundation
import TesseraCore

// The quiet stage (Design sheet 287 section 5, sheet 288 section 5; docs/ai/harness/rehearsal.md). The shell draws a
// screen with no window and no clock (`ShellStage.render(screen:looks:)`, Builder A) and answers with flags only.
// Tess stages a look she picked before she applies it, and applies it only if it passes. The picture stays in memory
// on the phone; only these flags reach a model, and they never carry an item's name.

/// One place's flags from a stage render.
public struct StageFlags: Sendable, Equatable {
    public var place: ElementPlace
    /// No clipped text, lines within their count, items within the frame.
    public var fits: Bool
    /// No type under the room's floor (10 pt units, 13 pt lines).
    public var floor: Bool
    /// Text against its ground at AA or better, in both looks.
    public var contrast: Bool
    /// The look rules: at most 4 colours, the three biggest words never share one, nothing within ΔE 10 of Ember,
    /// money never red or green and always "about".
    public var rules: Bool
    /// Every target at least 44 pt.
    public var touch: Bool
    /// The move ends within 1 s, and a Reduce Motion version exists.
    public var calm: Bool

    public init(place: ElementPlace, fits: Bool = true, floor: Bool = true, contrast: Bool = true, rules: Bool = true,
                touch: Bool = true, calm: Bool = true)
    {
        self.place = place
        self.fits = fits
        self.floor = floor
        self.contrast = contrast
        self.rules = rules
        self.touch = touch
        self.calm = calm
    }

    /// The checks it failed, by name.
    public var failed: [String] {
        [("fits", fits), ("floor", floor), ("contrast", contrast), ("rules", rules), ("touch", touch),
         ("calm", calm)].filter { !$0.1 }.map { $0.0 }
    }
}

/// What the stage found, place by place.
public struct StageReport: Sendable, Equatable {
    public var places: [StageFlags]

    public init(places: [StageFlags]) {
        self.places = places
    }

    public var passed: Bool {
        places.allSatisfy(\.failed.isEmpty)
    }

    /// One line for Tess: the places and the checks that failed, never what they show.
    public var line: String {
        let failing = places.filter { !$0.failed.isEmpty }
        guard !failing.isEmpty else { return "It passes every check." }
        return failing.map { "The \($0.place.rawValue) fails \($0.failed.joined(separator: ", "))" }
            .joined(separator: "; ") + "."
    }
}

/// The host's stage: draws the screen he is on with one look change, off screen, and reports. Nil in tests and on a
/// host with no stage yet, where a look Tess picks goes straight to the shell's own check.
public typealias LookStage = @MainActor (_ place: ElementPlace, _ change: LookChange) async -> StageReport
