import Foundation

/// Builder A's stand-in for Builder B's `ReviewChoices` (#1096) until it lands: the same storage (the UserDefaults key
/// `review.<id>`, string values) so swapping is one line. Off means today's behaviour, so an unset key reads its
/// default.
enum Choice {
    static func value(_ id: String, default fallback: String, defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: "review.\(id)") ?? fallback
    }

    /// The easy swap: "One tap" adds a small Swap word under the exercise name that applies the top alternative at
    /// once (10 s UNDO); "Two taps" (default) is today's pull-down panel.
    static func swapIsOneTap(defaults: UserDefaults = .standard) -> Bool {
        value("swapExercise", default: "Two taps", defaults: defaults) == "One tap"
    }

    /// The forgot-Finish nudge: Off by default.
    static func finishNudgeIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("finishNudge", default: "Off", defaults: defaults) == "On"
    }

    /// The rest timer: "On" (default) runs the rest countdown, its Live Activity and one local notification "Rest is
    /// up"; "Off" drops the countdown and its Lock Screen keys (a flip takes effect at the next set).
    static func restTimerIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("restTimer", default: "On", defaults: defaults) == "On"
    }
}
