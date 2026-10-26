import Foundation
import Observation
import os

/// The switches and the meter. Switches persist in `UserDefaults` (`live.switch.<id>`); the meter counts how long
/// each feature was live, which is the number the before/after reads.
@MainActor
@Observable
final class LiveRegistry {
    static let shared = LiveRegistry()

    private(set) var switches: [String: LiveSwitch] = [:]
    private(set) var liveSeconds: [String: Double] = [:]
    private(set) var flips: [String: Int] = [:]
    private var since: [String: Date] = [:]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let signposter = OSSignposter(subsystem: "com.kaushikaranagu.tessera", category: "live")
    @ObservationIgnored private var intervals: [String: OSSignpostIntervalState] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for feature in LiveFeatures.all {
            if let raw = defaults.string(forKey: Self.key(feature)), let value = LiveSwitch(rawValue: raw) {
                switches[feature.id] = value
            }
        }
    }

    func switchState(for feature: LiveFeature) -> LiveSwitch {
        switches[feature.id] ?? .auto
    }

    func set(_ state: LiveSwitch, for feature: LiveFeature) {
        switches[feature.id] = state == .auto ? nil : state
        defaults.set(state == .auto ? nil : state.rawValue, forKey: Self.key(feature))
    }

    /// Sets every feature at once. The measurement run uses `.alwaysLive` for the before and `.auto` for the after.
    func setAll(_ state: LiveSwitch) {
        for feature in LiveFeatures.all { set(state, for: feature) }
    }

    /// Called by `liveRegion` when a feature's live state flips.
    func record(_ feature: LiveFeature, live: Bool, at date: Date = .now) {
        if live {
            guard since[feature.id] == nil else { return }
            since[feature.id] = date
            flips[feature.id, default: 0] += 1
            intervals[feature.id] = signposter.beginInterval("live", id: signposter.makeSignpostID(),
                                                             "\(feature.id, privacy: .public)")
        } else if let start = since.removeValue(forKey: feature.id) {
            liveSeconds[feature.id, default: 0] += date.timeIntervalSince(start)
            if let state = intervals.removeValue(forKey: feature.id) { signposter.endInterval("live", state) }
        }
    }

    func resetMeter() {
        liveSeconds = [:]
        flips = [:]
    }

    private static func key(_ feature: LiveFeature) -> String {
        "live.switch.\(feature.id)"
    }
}
