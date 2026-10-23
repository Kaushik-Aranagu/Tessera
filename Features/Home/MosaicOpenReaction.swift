import Foundation

// The mosaic reacts on every open (sheet 209 B). Core decides which reaction (`MosaicFacts.openCue`); the host keeps
// when the app last went to the background and when it was last opened, in memory and in the standard defaults (two
// times, never anything else).

@MainActor
final class MosaicOpenTracker {
    static let backgroundKey = "mosaic.lastBackground"
    static let openKey = "mosaic.lastOpen"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordBackground(at date: Date = AppClock.now) {
        defaults.set(date.timeIntervalSince1970, forKey: Self.backgroundKey)
    }

    func recordOpen(at date: Date = AppClock.now) {
        defaults.set(date.timeIntervalSince1970, forKey: Self.openKey)
    }

    var lastBackground: Date? {
        time(Self.backgroundKey)
    }

    var lastOpen: Date? {
        time(Self.openKey)
    }

    private func time(_ key: String) -> Date? {
        defaults.object(forKey: key) == nil ? nil : Date(timeIntervalSince1970: defaults.double(forKey: key))
    }
}
