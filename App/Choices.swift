import Foundation
import os

/// Builder A's stand-in for Builder B's `ReviewChoices` (#1096) until it lands: the same storage (the UserDefaults key
/// `review.<id>`, string values) so swapping is one line. Off means today's behaviour, so an unset key, or a stored
/// value the choice does not know, reads its default.
enum Choice {
    static func value(_ id: String, options: [String], default fallback: String,
                      defaults: UserDefaults = .standard) -> String
    {
        // An approved feature flag reads the Off-ids store on the phone (sheet 203); a demo keeps today's defaults.
        if defaults === UserDefaults.standard, FeatureFlagStore.usesFlags, !LaunchFlags.has("-demo"),
           options.contains("On"),
           options.contains("Off"), let on = FeatureFlagStore.isOn(id)
        {
            return on ? "On" : "Off"
        }
        guard let stored = defaults.string(forKey: "review.\(id)"), options.contains(stored) else { return fallback }
        return stored
    }

    /// The type pair: "Figtree and Outfit" (default) sets words in Figtree and numbers in Outfit ExtraLight; "As
    /// before"
    /// is the Inter Tight look. Read where a face is made, so a flip shows on the next draw.
    static let fontOffered = ["Figtree and Outfit", "As before"]

    static func fontIsNew(defaults: UserDefaults = .standard) -> Bool {
        if defaults === UserDefaults.standard {
            return FontChoice.isNew
        }
        return value("font", options: fontOffered, default: "Figtree and Outfit", defaults: defaults) == "Figtree and Outfit"
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

    /// Cook timer voice: "Off" (default) ends a cook timer with its alert alone; "On" has Tess say the timer's name
    /// ("Simmer is done.") when the app is in front.
    static func cookTimerVoiceIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("cookTimerVoice", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// Hands-free cook mode: "Off" (default) moves steps on a touch; "On" adds a tap-opened listening window for
    /// "next", "back" and "timer".
    static func handsFreeCookIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("handsFreeCook", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// Steps run in parallel: "Off" (default) is one lane; "On" lets a "meanwhile" step run beside a timed one.
    static func parallelStepsIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("parallelSteps", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// Cook notes on the recipe: "Off" (default) keeps notes in COOKS; "On" asks for a note on Finish and shows the
    /// newest on the recipe page.
    static func cookNotesIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("cookNotes", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// Tess's face: "Off" (default) is the plain mark, "Eyes" gives her eyes. Only what is drawn is offered; the mouth
    /// comes back as a third option in the change that draws it. A stored "Eyes and mouth" from an earlier build still
    /// reads as eyes.
    static let tessFaceOffered = ["Off", "Eyes"]

    static func tessHasEyes(defaults: UserDefaults = .standard) -> Bool {
        value("tessFace", options: tessFaceOffered + ["Eyes and mouth"], default: "Off", defaults: defaults) != "Off"
    }

    /// The calorie line on an exercise's sheet: Off by default.
    static func caloriesBurnedIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("caloriesBurned", options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// The Lock Screen rest card's colours: "Cobalt sky" (default, Kaushik's pick of 2026-10-15) in every look, or
    /// "Follows the look", where the card takes the day or night look like the app. The Island stays Obsidian either
    /// way.
    static let lockScreenLookOffered = ["Cobalt sky", "Follows the look"]

    static func lockScreenFollowsLook(defaults: UserDefaults = .standard) -> Bool {
        value("lockScreenLook", options: lockScreenLookOffered, default: "Cobalt sky", defaults: defaults)
            == "Follows the look"
    }
}

/// The Font key, read once and kept: every face and text role asks, many times per frame. A change to the standard
/// defaults clears it, so a flip in Settings shows on the next draw.
enum FontChoice {
    private static let cache = OSAllocatedUnfairLock<Bool?>(initialState: nil)
    /// The observer lives for the whole process; it only clears the cache, under the same lock.
    private static let watcher = Watcher()

    private final class Watcher: Sendable {
        init() {
            NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil,
                                                   queue: nil)
            { _ in
                FontChoice.cache.withLock { $0 = nil }
            }
        }
    }

    static var isNew: Bool {
        _ = watcher
        if let cached = cache.withLock({ $0 }) {
            return cached
        }
        let value = Choice.value("font", options: Choice.fontOffered, default: "Figtree and Outfit") == "Figtree and Outfit"
        cache.withLock { $0 = value }
        return value
    }
}
