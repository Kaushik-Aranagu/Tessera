import Foundation

/// Where a cue comes from (sheet 204). Never health, calendar, body, calories or money: there is no source for them.
public enum MosaicCueSource: Int, CaseIterable, Sendable {
    case tess, app, `switch`, clock, outside
}

/// One situation that can change the mosaic. A name and a source and a key only: no text, no title, no value, so a
/// masked or private item can cue a moment and show nothing else.
public enum MosaicCueKind: String, CaseIterable, Sendable {
    /// clock
    case sunrise, afternoonIdle, beforeSunset, lateNight
    /// Tess (on-device reasoning; Claude never picks a mood or a moment)
    case suggestionReady, restDayInPlan, announcement
    /// apps
    case workoutStarts, newBest, timerEnds, reminderDue, arrived, checkedOff, lastDoneToday, backAfterAway
    /// outside (WeatherKit, inert until entitled)
    case rain, snow, fog, storm, heat, wind
    /// switches
    case featureOn, focusStarts

    public var source: MosaicCueSource {
        switch self {
        case .sunrise, .afternoonIdle, .beforeSunset, .lateNight: .clock
        case .suggestionReady, .restDayInPlan, .announcement: .tess
        case .workoutStarts, .newBest, .timerEnds, .reminderDue, .arrived, .checkedOff, .lastDoneToday,
             .backAfterAway: .app
        case .rain, .snow, .fog, .storm, .heat, .wind: .outside
        case .featureOn, .focusStarts: .switch
        }
    }
}

public struct MosaicCue: Equatable, Sendable {
    public let kind: MosaicCueKind
    public let at: Date
    /// Which event this is, so the same one never plays twice.
    public let key: String
    /// A cue that needs Claude is held back unless asksClaude is on ("Tess asks Claude").
    public let needsClaude: Bool

    public init(_ kind: MosaicCueKind, at: Date, key: String? = nil, needsClaude: Bool = false) {
        self.kind = kind
        self.at = at
        self.key = key ?? "\(kind.rawValue)-\(Int(at.timeIntervalSince1970))"
        self.needsClaude = needsClaude
    }

    public var source: MosaicCueSource {
        kind.source
    }
}

/// The twelve moments (sheet 201 and 204), by name.
public enum MosaicMomentName: String, CaseIterable, Sendable {
    case snow, fog, wind, storm, heat, announce, tess, timer, finished, best, reminder, delivery

    /// Only a timer and a reminder play in quiet hours.
    public var playsInQuietHours: Bool {
        self == .timer || self == .reminder
    }
}

public enum MosaicEffect: Equatable, Sendable {
    case mood(MosaicMood)
    case moment(MosaicMomentName)
}

/// How an effect comes in (a mood) or hands back (a moment). Not the app's `MosaicChangeover`: that one is the drawing.
public enum MosaicHandOver: String, CaseIterable, Sendable {
    case flip, wave, dissolve, wipe, fall, gather, melt
}

/// cue → effect → changeover.
public struct MosaicWire: Equatable, Sendable {
    public let cue: MosaicCueKind
    public let effect: MosaicEffect
    public let changeover: MosaicHandOver
}

public enum MosaicWires {
    /// The default table (sheet 204). On by default; every cue has exactly one wire.
    public static let defaults: [MosaicWire] = [
        MosaicWire(cue: .sunrise, effect: .mood(.morning), changeover: .fall),
        MosaicWire(cue: .afternoonIdle, effect: .mood(.day), changeover: .flip),
        MosaicWire(cue: .beforeSunset, effect: .mood(.golden), changeover: .flip),
        MosaicWire(cue: .lateNight, effect: .mood(.night), changeover: .flip),
        MosaicWire(cue: .suggestionReady, effect: .moment(.tess), changeover: .gather),
        MosaicWire(cue: .restDayInPlan, effect: .mood(.rest), changeover: .flip),
        MosaicWire(cue: .announcement, effect: .moment(.announce), changeover: .melt),
        MosaicWire(cue: .workoutStarts, effect: .mood(.running), changeover: .wave),
        MosaicWire(cue: .newBest, effect: .moment(.best), changeover: .melt),
        MosaicWire(cue: .timerEnds, effect: .moment(.timer), changeover: .wave),
        MosaicWire(cue: .reminderDue, effect: .moment(.reminder), changeover: .dissolve),
        MosaicWire(cue: .arrived, effect: .moment(.delivery), changeover: .wave),
        MosaicWire(cue: .checkedOff, effect: .moment(.finished), changeover: .gather),
        MosaicWire(cue: .lastDoneToday, effect: .mood(.done), changeover: .wave),
        MosaicWire(cue: .backAfterAway, effect: .mood(.back), changeover: .gather),
        MosaicWire(cue: .rain, effect: .mood(.rain), changeover: .fall),
        MosaicWire(cue: .snow, effect: .moment(.snow), changeover: .melt),
        MosaicWire(cue: .fog, effect: .moment(.fog), changeover: .dissolve),
        MosaicWire(cue: .storm, effect: .moment(.storm), changeover: .melt),
        MosaicWire(cue: .heat, effect: .moment(.heat), changeover: .wave),
        MosaicWire(cue: .wind, effect: .moment(.wind), changeover: .dissolve),
        MosaicWire(cue: .featureOn, effect: .moment(.finished), changeover: .flip),
        MosaicWire(cue: .focusStarts, effect: .mood(.rest), changeover: .dissolve),
    ]

    public static func wire(for cue: MosaicCueKind, overrides: [MosaicWire] = []) -> MosaicWire? {
        overrides.first { $0.cue == cue } ?? defaults.first { $0.cue == cue }
    }
}

/// A moment waiting its turn, or playing.
public struct MosaicQueuedMoment: Equatable, Sendable {
    public let name: MosaicMomentName
    public let handBack: MosaicHandOver
    public let key: String
    public let sourceRank: Int
}

public struct MosaicMoodChange: Equatable, Sendable {
    public let mood: MosaicMood
    public let changeover: MosaicHandOver
}

/// What the view is told to do after a step: switch the mood, start a moment, or neither. The view only plays this.
public struct MosaicDirective: Equatable, Sendable {
    public var mood: MosaicMoodChange?
    public var play: MosaicQueuedMoment?
}

public struct MosaicSwitchState: Equatable, Sendable {
    public var mood: MosaicMood?
    public var playing: MosaicQueuedMoment?
    public var queue: [MosaicQueuedMoment] = []
    public var seen: Set<String> = []

    public init(mood: MosaicMood? = nil) {
        self.mood = mood
    }
}

/// Resolves cues into one mood and a short queue of moments. On the phone only, no model call. Rules (sheet 204):
/// a moment beats a mood; Tess, then apps, then the clock, then the weather; a moment never cuts into another one,
/// the queue holds three and drops the oldest; in quiet hours only a timer and a reminder play and the queue is
/// cleared when they begin; outside cues do nothing until WeatherKit is on; a cue that needs Claude waits for
/// asksClaude.
public enum MosaicSwitchboard {
    public static let queueLimit = 3

    public static func step(_ state: MosaicSwitchState, cues: [MosaicCue], now _: Date, quiet: Bool,
                            asksClaude: Bool = false, weatherOn: Bool = false,
                            overrides: [MosaicWire] = []) -> (state: MosaicSwitchState, directive: MosaicDirective)
    {
        var next = state
        var directive = MosaicDirective()
        if quiet {
            // Only a timer and a reminder survive the night; the rest are not replayed at seven.
            next.queue.removeAll { !$0.name.playsInQuietHours }
        }
        let usable = cues
            .filter { !next.seen.contains($0.key) }
            .filter { !$0.needsClaude || asksClaude }
            .filter { $0.source != .outside || weatherOn }
            .sorted { ($0.source.rawValue, $1.at) < ($1.source.rawValue, $0.at) }
        // Moments queue in the order they arrived; the rank decides which queued one plays next.
        var moodCues: [(MosaicCue, MosaicMood, MosaicHandOver)] = []
        for cue in usable.sorted(by: { $0.at < $1.at }) {
            guard let wire = MosaicWires.wire(for: cue.kind, overrides: overrides) else { continue }
            switch wire.effect {
            case let .moment(name):
                if quiet, !name.playsInQuietHours {
                    continue
                }
                next.seen.insert(cue.key)
                let queued = MosaicQueuedMoment(name: name, handBack: wire.changeover, key: cue.key,
                                                sourceRank: cue.source.rawValue)
                next.queue.append(queued)
                if next.queue.count > queueLimit {
                    next.queue.removeFirst(next.queue.count - queueLimit)
                }
            case let .mood(mood):
                if quiet, mood != .night {
                    continue
                }
                moodCues.append((cue, mood, wire.changeover))
            }
        }
        // A moment beats a mood: with one playing or queued, the mood waits for the next step.
        if next.playing == nil, !next.queue.isEmpty {
            let first = takeNext(&next.queue)
            next.playing = first
            directive.play = first
        } else if next.playing == nil,
                  let best = moodCues.min(by: { ($0.0.source.rawValue, $1.0.at) < ($1.0.source.rawValue, $0.0.at) }),
                  best.1 != next.mood
        {
            next.mood = best.1
            next.seen.insert(best.0.key)
            directive.mood = MosaicMoodChange(mood: best.1, changeover: best.2)
        }
        return (next, directive)
    }

    /// The playing moment has handed back; the next queued one (if any, and allowed now) starts.
    public static func handedBack(_ state: MosaicSwitchState, quiet: Bool) -> (state: MosaicSwitchState,
                                                                               directive: MosaicDirective)
    {
        var next = state
        next.playing = nil
        if quiet {
            next.queue.removeAll { !$0.name.playsInQuietHours }
        }
        var directive = MosaicDirective()
        if !next.queue.isEmpty {
            let first = takeNext(&next.queue)
            next.playing = first
            directive.play = first
        }
        return (next, directive)
    }

    /// The best-ranked waiting moment (Tess, then apps, then the clock, then the weather), earliest first on a tie.
    private static func takeNext(_ queue: inout [MosaicQueuedMoment]) -> MosaicQueuedMoment {
        let index = queue.indices.min { (queue[$0].sourceRank, $0) < (queue[$1].sourceRank, $1) } ?? 0
        return queue.remove(at: index)
    }

    /// The clock's own cues for now, read from the facts alone (never from his data).
    public static func clockCues(facts: MosaicFacts, nothingRunning: Bool, calendar: Calendar) -> [MosaicCue] {
        let now = facts.now
        let hour = calendar.component(.hour, from: now)
        var cues: [MosaicCue] = []
        let day = Int(calendar.startOfDay(for: now).timeIntervalSince1970)
        let sinceSunrise = now.timeIntervalSince(facts.sunrise)
        if sinceSunrise >= 0, sinceSunrise <= 3600 {
            cues.append(MosaicCue(.sunrise, at: facts.sunrise, key: "sunrise-\(day)"))
        }
        let untilSunset = facts.sunset.timeIntervalSince(now)
        if untilSunset >= 0, untilSunset <= 20 * 60 {
            cues.append(MosaicCue(.beforeSunset, at: now, key: "golden-\(day)"))
        }
        if hour >= 22 || hour < 4 {
            cues.append(MosaicCue(.lateNight, at: now, key: "night-\(day)-\(hour >= 22 ? 1 : 0)"))
        }
        if nothingRunning, hour >= 12, hour < 17, untilSunset > 20 * 60 {
            cues.append(MosaicCue(.afternoonIdle, at: now, key: "afternoon-\(day)"))
        }
        return cues
    }

    /// An existing moment candidate as a cue, so the app's current sources feed the switchboard unchanged.
    public static func cue(for kind: MosaicMomentKind, at date: Date, key: String) -> MosaicCue? {
        let cueKind: MosaicCueKind? = switch kind {
        case .announcement: .announcement
        case .tess: .suggestionReady
        case .timer: .timerEnds
        case .finished: .checkedOff
        case .best: .newBest
        case .reminder: .reminderDue
        case .delivery: .arrived
        case let .weather(weather):
            switch weather {
            case .snow: .snow
            case .fog: .fog
            case .wind: .wind
            case .storm: .storm
            case .heat: .heat
            }
        }
        return cueKind.map { MosaicCue($0, at: date, key: key) }
    }
}
