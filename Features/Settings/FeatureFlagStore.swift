import Foundation
import TesseraCore

/// Where the app keeps which approved features he turned Off (sheet 203; Kaushik, Oct 23: what he approves, asks for or
/// is recommended ships On, and he asks for what he does not want turned off). Core's `FeatureFlags` is the list and
/// the rule; this is the one text field on this iPhone, never in a backup, the op log or a model. Absent means
/// "as shipped" (every flag On, the Home layout he picked by default), so a flag added later is On with no
/// migration. Reads are nonisolated so the older raw readers can ask without hopping actors.
enum FeatureFlagStore {
    static let offKey = "featureFlags.off"
    static let migratedKey = "featureFlags.migrated.oct23"

    /// What a fresh phone starts from: Core's shipped Off ids (the losing Home layout). The apps list is On.
    nonisolated static var shippedOff: Set<String> {
        FeatureChoices.shipped.off
    }

    /// The flags that are Off now.
    nonisolated static func off(defaults: UserDefaults = .standard) -> Set<String> {
        guard let stored = defaults.string(forKey: offKey) else {
            return shippedOff
        }
        return FeatureFlags.off(encoded: stored)
    }

    /// Whether a flag is On. An id that is not a flag reads nil, so the caller keeps its own rule.
    nonisolated static func isOn(_ id: String, defaults: UserDefaults = .standard) -> Bool? {
        guard FeatureFlags.flag(id) != nil else { return nil }
        return !off(defaults: defaults).contains(id)
    }

    nonisolated static func isFlag(_ id: String) -> Bool {
        FeatureFlags.flag(id) != nil
    }

    /// Turns one flag On or Off. Ids that are not flags change nothing.
    nonisolated static func set(_ id: String, on: Bool, defaults: UserDefaults = .standard) {
        guard FeatureFlags.flag(id) != nil else { return }
        let next = FeatureFlags.setting(id, on: on, off: off(defaults: defaults))
        defaults.set(next.sorted().joined(separator: ";"), forKey: offKey)
    }

    /// Once: a switch he had turned Off by hand on a flag that used to be On by default (the rest timer, Tess names
    /// training days) stays Off. An old stored On needs nothing, because every flag is On now.
    nonisolated static func migrateOnce(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: migratedKey) else { return }
        var off = off(defaults: defaults)
        for flag in FeatureFlags.all where defaults.string(forKey: "review.\(flag.id)") == "Off" {
            off.insert(flag.id)
        }
        defaults.set(off.sorted().joined(separator: ";"), forKey: offKey)
        defaults.set(true, forKey: migratedKey)
    }

    /// Whether the code is running inside a unit-test host (XCTest is loaded there).
    nonisolated static var isTestHost: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    /// The flags are in force on the real app, not in a unit-test host (which keeps the older per-switch reads).
    nonisolated static var usesFlags: Bool {
        !isTestHost
    }

    /// Not a demo and not a unit-test host.
    nonisolated static var isRealLaunch: Bool {
        !LaunchFlags.has("-demo") && !LaunchFlags.has("-resetDemo") && !isTestHost
    }
}
