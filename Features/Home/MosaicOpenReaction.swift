import Foundation

// The mosaic reacts on every open (sheet 209, part B), chosen by how long he was away. Only one reaction per open,
// never stacked, and a moment that is already playing wins. No haptic. Reduce Motion: no reaction.

enum MosaicOpenReaction: Equatable {
    /// Under 2 minutes: a ripple from the middle, 0.9 s.
    case ripple
    /// 2 minutes to 3 hours: tiles flip row by row from the last scene to now, 1.4 s.
    case flipRows
    /// The first open after 4 AM: night falls into day, 2.2 s.
    case nightIntoDay
    /// Two days or more: dusty pixels gather into today with the "back" mood, 2.4 s.
    case dustyGather
    /// A cold launch: gather from night after 500 ms, 1.8 s.
    case coldLaunch

    /// How long it takes (the sheet's seconds).
    var seconds: TimeInterval {
        switch self {
        case .ripple: 0.9
        case .flipRows: 1.4
        case .nightIntoDay: 2.2
        case .dustyGather: 2.4
        case .coldLaunch: 1.8
        }
    }

    /// A wait before it starts (a cold launch's 500 ms).
    var delay: TimeInterval {
        self == .coldLaunch ? 0.5 : 0
    }

    static let twoMinutes: TimeInterval = 120
    static let threeHours: TimeInterval = 3 * 3600
    static let twoDays: TimeInterval = 2 * 86400

    /// Which reaction an open gets, or nil for none. `lastActive` is when the app last went to the background.
    static func choose(
        now: Date,
        lastActive: Date?,
        coldLaunch: Bool,
        calendar: Calendar = .current
    ) -> MosaicOpenReaction? {
        if coldLaunch {
            return .coldLaunch
        }
        guard let lastActive else { return nil }
        let away = now.timeIntervalSince(lastActive)
        if away >= twoDays {
            return .dustyGather
        }
        if crossedFourAM(from: lastActive, to: now, calendar: calendar) {
            return .nightIntoDay
        }
        if away < twoMinutes {
            return .ripple
        }
        if away <= threeHours {
            return .flipRows
        }
        return nil
    }

    /// Whether 4 AM passed between the two moments (this is the first open of the new day).
    static func crossedFourAM(from: Date, to: Date, calendar: Calendar = .current) -> Bool {
        guard to > from else { return false }
        var parts = calendar.dateComponents([.year, .month, .day], from: to)
        parts.hour = 4
        parts.minute = 0
        guard let four = calendar.date(from: parts) else { return false }
        // 4 AM of the day `to` falls on, or the one before it when `to` is before 4 AM.
        let boundary = to >= four ? four : (calendar.date(byAdding: .day, value: -1, to: four) ?? four)
        return from < boundary && to >= boundary
    }
}

/// When the app last went to the background, kept in memory and in the standard defaults (a time, never anything else).
@MainActor
final class MosaicOpenTracker {
    static let key = "mosaic.lastActive"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordBackground(at date: Date = AppClock.now) {
        defaults.set(date.timeIntervalSince1970, forKey: Self.key)
    }

    var lastActive: Date? {
        defaults.object(forKey: Self.key) == nil ? nil : Date(timeIntervalSince1970: defaults.double(forKey: Self.key))
    }
}
