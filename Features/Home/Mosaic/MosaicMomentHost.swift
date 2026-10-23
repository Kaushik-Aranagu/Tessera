import SwiftUI
import TesseraCore

/// What has played this run, in memory only: never UserDefaults, which gets backed up. An event never plays twice and
/// a moment waits ten minutes after the last (a timer and a finish excepted); a new launch starts clean.
@MainActor
enum MomentMemory {
    static var played: Set<String> = []
    static var last: (kind: MosaicMomentKind, at: Date)?
}

/// Core's pick, turned into what A's view plays and what the host feels (sheet 201).
enum MosaicMomentMapping {
    /// The haptic family of a moment's entrance: soft for most, a tick for an announcement, rigid for a timer.
    enum Beat: Equatable {
        case soft, tick, rigid
    }

    static func beat(_ kind: MosaicMomentKind) -> Beat {
        switch kind {
        case .announcement: .tick
        case .timer: .rigid
        default: .soft
        }
    }

    static func moment(for pick: MosaicMomentPick) -> MosaicMoment {
        switch pick.kind {
        case let .weather(weather):
            switch weather {
            case .snow: .snow
            case .fog: .fog
            case .wind: .wind
            case .storm: .storm
            case .heat: .heat
            }
        case .announcement: .announce(words: announceWords(pick.clause))
        case .tess: .tess
        case .timer: .timer
        case .finished: .finished(tone: pick.tone)
        case .best: .best
        case .reminder: .reminder(app: pick.clause.app)
        case .delivery: .delivery(app: pick.clause.app)
        }
    }

    /// The announcement's words: the key word in its app's accent, the rest in ink (a masked line has no key word).
    static func announceWords(_ clause: HomeSentence.Clause) -> [MosaicAnnounceWord] {
        DaySentence.words([clause]).map { MosaicAnnounceWord(text: $0.text, app: $0.app == nil ? nil : clause.app) }
    }

    /// Quiet hours until the Quiet hours page exists: the same night the mood picker uses.
    static func isQuiet(_ now: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: now)
        return hour >= 22 || hour < TesseraDay.startHour
    }
}
