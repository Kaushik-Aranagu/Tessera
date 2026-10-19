import Foundation

/// Builder A's stand-in for Builder B's `ReviewChoices` (#1096) until it lands: the same storage (the UserDefaults key
/// `review.<id>`, string values) so swapping is one line. Off means today's behaviour, so an unset key reads its
/// default.
enum Choice {
    static func value(_ id: String, default fallback: String, defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: "review.\(id)") ?? fallback
    }

    /// The rest timer: "On" rings one local notification when a rest ends; "Off" keeps today's Live Activity alert.
    static func restTimerIsOn(defaults: UserDefaults = .standard) -> Bool {
        value("restTimer", default: "On", defaults: defaults) == "On"
    }
}
