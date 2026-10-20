import Foundation

/// Builder A's stand-in for Builder B's `ReviewChoices` (#1096) until it lands: the same storage (the UserDefaults key
/// `review.<id>`, string values) so swapping is one line. Off means today's behaviour, so an unset key, or a stored
/// value the choice does not know, reads its default.
enum Choice {
    static func value(_ id: String, options: [String], default fallback: String,
                      defaults: UserDefaults = .standard) -> String
    {
        guard let stored = defaults.string(forKey: "review.\(id)"), options.contains(stored) else { return fallback }
        return stored
    }

    /// The easy swap: "One tap" adds a small Swap word under the exercise name that applies the top alternative at
    /// once (10 s UNDO); "Two taps" (default) is today's pull-down panel.
    static func swapIsOneTap(defaults: UserDefaults = .standard) -> Bool {
        value("swapExercise", options: ["Two taps", "One tap"], default: "Two taps", defaults: defaults) == "One tap"
    }

    /// The forgot-Finish nudge: Off by default.
    static func finishNudgeIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("finishNudge", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// The rest timer: "On" (default) runs the rest countdown, its Live Activity and one local notification "Rest is
    /// up"; "Off" drops the countdown and its Lock Screen keys (a flip takes effect at the next set).
    static func restTimerIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("restTimer", options: ["On", "Off"], default: "On", defaults: defaults) == "On"
    }

    /// Tess's face: "Off" (default) is the plain mark, "Eyes" gives her eyes, "Eyes and mouth" adds a small mouth, one
    /// short line that turns with the moment (docs/design/motion/tess-picks.md 18c).
    static let tessFaceOffered = ["Off", "Eyes", "Eyes and mouth"]

    static func tessFace(defaults: UserDefaults = .standard) -> String {
        value("tessFace", options: tessFaceOffered, default: "Off", defaults: defaults)
    }

    static func tessHasEyes(defaults: UserDefaults = .standard) -> Bool {
        tessFace(defaults: defaults) != "Off"
    }

    /// The mouth is only drawn when that value is chosen (no mouth without eyes).
    static func tessHasMouth(defaults: UserDefaults = .standard) -> Bool {
        tessFace(defaults: defaults) == "Eyes and mouth"
    }
}
