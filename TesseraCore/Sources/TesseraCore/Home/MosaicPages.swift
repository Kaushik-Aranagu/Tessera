import Foundation

/// How the mosaic reacts when the app opens (sheet 209 section 3). One per open, never stacked; a moment already
/// playing wins, and Reduce Motion shows no reaction (the host's job).
public enum MosaicOpenReaction: String, CaseIterable, Sendable {
    /// Under 2 minutes away: a ripple from the middle.
    case ripple
    /// 2 minutes to 3 hours, and any longer same-day absence that is not the first open of his day: the tiles flip
    /// row by row from the last scene the mosaic showed (the host remembers it) to the one for now.
    case flip
    /// The first open after 4 am: night falls away into the day.
    case nightToDay
    /// 2 days or more: dusty pixels gather into today (the back mood).
    case back
    /// A cold launch: a gather from night, after 500 ms.
    case gather

    public var duration: TimeInterval {
        switch self {
        case .ripple: 0.9
        case .flip: 1.4
        case .nightToDay: 2.2
        case .back: 2.4
        case .gather: 1.8
        }
    }

    /// Seconds to wait before it starts.
    public var delay: TimeInterval {
        self == .gather ? 0.5 : 0
    }
}

/// What the host needs to react to an open, worked out from times alone: nothing here reads his data.
public struct MosaicOpenCue: Equatable, Sendable {
    /// Time since the last background, nil on a first ever launch.
    public let away: TimeInterval?
    public let isColdLaunch: Bool
    /// The last open was on an earlier day of his (the 4 am edge), so this is the first open of the day.
    public let isFirstOpenAfterFour: Bool
    public let reaction: MosaicOpenReaction

    /// Priority, so exactly one reaction plays: 2 days away (back), a cold launch (gather), the first open of the day
    /// (night to day), under 2 minutes (ripple), else a flip.
    public static func make(now: Date, lastBackground: Date?, lastOpen: Date?, coldLaunch: Bool,
                            calendar: Calendar = .current) -> MosaicOpenCue
    {
        let away = lastBackground.map { max(0, now.timeIntervalSince($0)) }
        let day = TesseraDay(calendar: calendar)
        let firstOfDay = lastOpen.map { !day.isSameDay($0, now) } ?? true
        let reaction: MosaicOpenReaction = if let away, away >= 2 * 86400 {
            .back
        } else if coldLaunch {
            .gather
        } else if firstOfDay {
            .nightToDay
        } else if let away, away < 120 {
            .ripple
        } else {
            .flip
        }
        return MosaicOpenCue(away: away, isColdLaunch: coldLaunch, isFirstOpenAfterFour: firstOfDay, reaction: reaction)
    }
}

/// What the Next and Week pages of the mosaic show (sheet 209 section 4). The next thing comes from tasks, training and
/// routines only, never a calendar event or a cook; its name is masked ("Private task", "Private workout") and its
/// accent is its app's, or none for a masked item or a task. No money, health, body, calories or calendar title.
public struct MosaicPageFacts: Equatable, Sendable {
    public let nextTitle: String?
    /// The accent: nil for a task, a masked item, or nothing next.
    public let nextApp: AppID?
    public let nextIn: TimeInterval?
    /// "2:10": hours and minutes to the next thing.
    public let nextClock: String?
    /// "Push day in 2 hr 10 min".
    public let nextCaption: String?
    /// The week's seven days, Monday first, as marks: done, today, open or rest.
    public let weekMarks: [TrainingStats.LandingFacts.Mark]
    public let weekDone: Int
    public let weekPlanned: Int
    /// "This week, 3 of 5 training days"; nil with no training days planned.
    public let weekCaption: String?
}

@MainActor
public extension MosaicFacts {
    /// The open cue for this moment: see `MosaicOpenCue.make`.
    func openCue(lastBackground: Date?, lastOpen: Date?, coldLaunch: Bool) -> MosaicOpenCue {
        MosaicOpenCue.make(now: now, lastBackground: lastBackground, lastOpen: lastOpen, coldLaunch: coldLaunch,
                           calendar: calendarForPicker)
    }

    func pageFacts(engine: ActionEngine, plan: ObjectRecord?) -> MosaicPageFacts {
        var title: String?, app: AppID?, clock: String?, caption: String?
        var interval: TimeInterval?
        if let next = pageNext {
            let gap = max(0, next.start.timeIntervalSince(now))
            let whole = Int(gap / 60)
            title = next.title
            app = next.app
            interval = gap
            clock = "\(whole / 60):\(String(format: "%02d", whole % 60))"
            caption = whole <= 0 ? "\(next.title), now" : "\(next.title) in \(HouseTime.minutes(whole))"
        }
        let stats = TrainingStats(store: engine.store, classes: engine.classes)
        let marks = stats.landingFacts(plan: plan, now: now, calendar: calendarForPicker).marks
        let planned = marks.count { $0 != .rest }
        let done = marks.count { $0 == .done }
        return MosaicPageFacts(
            nextTitle: title, nextApp: app, nextIn: interval, nextClock: clock, nextCaption: caption,
            weekMarks: marks, weekDone: done, weekPlanned: planned,
            weekCaption: planned > 0 ? (done >= planned ? "This week's training is done"
                : "This week, \(planned - done) training \(planned - done == 1 ? "day" : "days") to go") : nil
        )
    }
}
