import Foundation

/// Which picture of the day a caption is for (Home mosaic, sheet 199, switch homeMosaic).
public enum MosaicScene: CaseIterable, Sendable {
    case day, time, sky, next, done
}

/// How a laid tile is coloured: the glaze (no app) or an app's accent. The view maps an app to its colour.
public enum MosaicTone: Equatable, Sendable {
    case glaze
    case accent(AppID)
}

/// A sky colour, 0 to 255 a channel.
public struct MosaicRGB: Equatable, Sendable {
    public let red: Int
    public let green: Int
    public let blue: Int
}

/// The next thing with a start time today.
public struct MosaicNext: Equatable, Sendable {
    /// A private or walled thing is "Private task" or "Private workout", never its words.
    public let title: String
    public let start: Date
    /// The app it belongs to, for the app word's accent; nil when its title is masked.
    public let app: AppID?
}

/// One thing finished today: when, and which app. Never a title; private things count. The app is for drawing a tile in
/// the app on screen only: it never reaches the Lock Screen, a widget, a Live Activity or an intent (a test scans for
/// it).
public struct MosaicFinish: Equatable, Sendable {
    public let time: Date
    public let app: AppID?
}

/// The facts the Home mosaic draws from, worked out on the phone for one moment. No title of a private or walled thing
/// is ever in it, and none of it goes to Claude, a log, a backup or a widget. Rolled over at midnight: the day it was
/// made for is `day`, and a view lays no tile from yesterday's.
public struct MosaicFacts: Equatable, Sendable {
    public let now: Date
    /// The start of the calendar day these facts are for.
    public let day: Date
    public let sunrise: Date
    public let sunset: Date
    public let finishedToday: [MosaicFinish]
    public let nextTimed: MosaicNext?
    /// Whole minutes from now to `nextTimed`, nil with none.
    public let freeMinutes: Int?
    let calendar: Calendar

    /// The calendar these facts were made with, for the mood picker.
    var calendarForPicker: Calendar {
        calendar
    }

    // MARK: Sky

    private static let stops: [(name: String, rgb: (Int, Int, Int))] = [
        ("sunrise", (233, 185, 160)), ("sunriseHour", (240, 214, 180)), ("lateMorning", (236, 228, 206)),
        ("afternoon", (234, 214, 176)), ("beforeSunset", (214, 160, 138)), ("sunset", (176, 122, 140)),
        ("sunsetHour", (104, 98, 146)), ("ten", (58, 54, 90)), ("midnight", (36, 34, 58)),
    ]

    /// The sky at a moment of today: the nine stops in order, mixed between, from today's own sunrise and sunset.
    public func sky(at date: Date) -> MosaicRGB {
        let hour = date.timeIntervalSince(day) / 3600
        return sky(atHour: hour)
    }

    /// The sky at an hour of the day, 0 to 24.
    public func sky(atHour hour: Double) -> MosaicRGB {
        let rise = sunrise.timeIntervalSince(day) / 3600, set = sunset.timeIntervalSince(day) / 3600
        let length = max(set - rise, 1)
        let times: [Double] = [
            rise, rise + 1, rise + length * 0.30, rise + length * 0.62, set - 1, set, set + 1, 22, 24,
        ]
        let colours = Self.stops.map(\.rgb)
        let midnight = colours[8]
        // Before sunrise: the midnight colour until an hour ahead, then up to the sunrise colour.
        if hour <= rise - 1 {
            return Self.rgb(midnight)
        }
        if hour < times[0] {
            return Self.mix(midnight, colours[0], (hour - (rise - 1)) / 1)
        }
        // Keep the stops in order for a short winter day or a late sunset.
        var ordered = times
        for index in 1 ..< ordered.count where ordered[index] <= ordered[index - 1] {
            ordered[index] = ordered[index - 1] + 0.01
        }
        for index in 1 ..< ordered.count where hour <= ordered[index] {
            let span = ordered[index] - ordered[index - 1]
            return Self.mix(colours[index - 1], colours[index], span > 0 ? (hour - ordered[index - 1]) / span : 1)
        }
        return Self.rgb(midnight)
    }

    private static func rgb(_ value: (Int, Int, Int)) -> MosaicRGB {
        MosaicRGB(red: value.0, green: value.1, blue: value.2)
    }

    private static func mix(_ from: (Int, Int, Int), _ to: (Int, Int, Int), _ amount: Double) -> MosaicRGB {
        let t = min(max(amount, 0), 1)
        func channel(_ lhs: Int, _ rhs: Int) -> Int {
            Int((Double(lhs) + (Double(rhs) - Double(lhs)) * t).rounded())
        }
        return MosaicRGB(red: channel(from.0, to.0), green: channel(from.1, to.1), blue: channel(from.2, to.2))
    }

    // MARK: Captions

    /// The one line under a scene. Masked titles stay masked here too.
    public func caption(for scene: MosaicScene) -> String {
        switch scene {
        case .day:
            guard let next = nextTimed, let free = freeMinutes else { return "Nothing else is timed today." }
            return free <= 0 ? "\(next.title), now." : "Free \(HouseTime.minutes(free)), then \(next.title)."
        case .time:
            return "\(HouseTime.clock(now, calendar: calendar)). \(TesseraDay.weekdayName(of: now, calendar: calendar))."
        case .sky:
            if now < sunrise {
                return "Sunrise at \(HouseTime.clock(sunrise, calendar: calendar))."
            }
            return now < sunset ? "Sunset at \(HouseTime.clock(sunset, calendar: calendar))."
                : "Sunset was at \(HouseTime.clock(sunset, calendar: calendar))."
        case .next:
            guard let next = nextTimed, let free = freeMinutes else { return "Nothing timed next." }
            return free <= 0 ? "\(next.title), now." : "\(HouseTime.minutes(free)) until \(next.title)."
        case .done:
            let count = finishedToday.count
            return count == 0 ? "Nothing done yet today." : "Done today: \(count) \(count == 1 ? "thing" : "things")."
        }
    }

    /// Whether the day has rolled over since `earlier` was made, so a view clears its laid tiles.
    public func rolledOver(since earlier: MosaicFacts) -> Bool {
        day != earlier.day
    }
}

@MainActor
public extension MosaicFacts {
    /// What Home knows at `now`. `place` is a coarse latitude and longitude (rounded again inside), nil to use the time
    /// zone. `events` are the day's hands events (workout, cook, routines) so they count as timed.
    static func make(engine: ActionEngine, now: Date, calendar: Calendar = .current,
                     place: (latitude: Double, longitude: Double)? = nil, events: [HandsEvent] = []) -> MosaicFacts
    {
        let day = calendar.startOfDay(for: now)
        let sun = place.flatMap { SunTimes.day(
            latitude: $0.latitude,
            longitude: $0.longitude,
            on: now,
            calendar: calendar
        ) }
            ?? SunTimes.approximate(on: now, calendar: calendar)
        let next = nextTimed(engine: engine, now: now, day: day, calendar: calendar, events: events)
        let free = next.map { max(0, Int($0.start.timeIntervalSince(now) / 60)) }
        return MosaicFacts(now: now, day: day, sunrise: sun.sunrise, sunset: sun.sunset,
                           finishedToday: finished(engine: engine, since: day), nextTimed: next, freeMinutes: free,
                           calendar: calendar)
    }

    /// Actions that finish something. The app is read from what the action touched, else from the action's own area.
    private static let finishApps: [String: AppID?] = [
        "setTaskDone": nil, "finishWorkout": .training, "finishWorkoutEarly": .training, "finishShop": .kitchen,
        "finishCookSession": .kitchen, "finishCooking": .kitchen, "finishListRun": .lists, "endProcess": nil,
        "finishBook": .notes,
    ]

    /// Things finished since the start of the day, from the op log: when and which app, never a title. A task marked
    /// done counts only while it is still done.
    private static func finished(engine: ActionEngine, since start: Date) -> [MosaicFinish] {
        let store = engine.store
        var found: [MosaicFinish] = []
        for record in engine.history(from: start, to: start.addingTimeInterval(36 * 3600)).reversed()
            where record.state == .committed && record.actor != .system
        {
            guard let fixed = finishApps[record.action] else { continue }
            let touched = record.objectIDs.compactMap { store.object(id: $0) }
            if record.action == "setTaskDone",
               !touched.contains(where: { store.value("isDone", of: $0) == .bool(true) })
            {
                continue
            }
            let app = fixed ?? touched.lazy.compactMap { $0.classDef.flatMap { ClassResolver.app(for: $0) } }.first
            found.append(MosaicFinish(time: record.createdAt, app: app))
        }
        return found
    }

    private static func nextTimed(engine: ActionEngine, now: Date, day: Date, calendar: Calendar,
                                  events: [HandsEvent]) -> MosaicNext?
    {
        let store = engine.store, classes = engine.classes
        let end = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86400)
        // An event label gets the same check as a task's title: a cook's dish names especially. Anything private,
        // walled
        // or secret reads its app's private label instead.
        let weight = BodyWeight.lastKg(in: store)
        func masked(_ event: HandsEvent) -> String {
            guard !event.isPrivate else { return event.label }
            let hidden = ObjectPrivacy.isPrivateWord(event.label, in: store) || SecretWords.mentions(event.label)
                || PrivateFacts.isWalled(event.label, lastWeightKg: weight)
            guard hidden else { return event.label }
            switch event.app {
            case .kitchen: return ObjectPrivacy.recipeLabel
            case .routines: return RoutinesLanding.privateRoutine
            default: return ObjectPrivacy.routineLabel
            }
        }
        var candidates: [MosaicNext] = events.filter { $0.start > now && $0.start < end }
            .map { event in
                let title = masked(event)
                return MosaicNext(title: title, start: event.start, app: title == event.label ? event.app : nil)
            }
        if let taskClass = classes[.task] {
            for task in store.objects(of: taskClass) where !task.isDeleted {
                guard store.value("isDone", of: task) != .bool(true),
                      let start = store.value("startsAt", of: task)?.dateValue, start > now,
                      start < end else { continue }
                let masked = ObjectPrivacy.shownLabel(of: task, in: store, classes: classes)
                    ?? (PrivateFacts.isWalled(task.title, lastWeightKg: BodyWeight.lastKg(in: store))
                        || SecretWords.mentions(task.title) ? ObjectPrivacy.taskLabel : nil)
                candidates.append(MosaicNext(title: masked ?? task.title, start: start,
                                             app: masked == nil ? task.classDef
                                                 .flatMap { ClassResolver.app(for: $0) } : nil))
            }
        }
        return candidates.min { $0.start < $1.start }
    }
}
