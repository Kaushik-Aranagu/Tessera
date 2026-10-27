import Foundation
import TesseraCore

/// "Try today" (Design 129): today's workout is a ready one, in place of the Plan's next. The Plan is never rewritten:
/// the routine it replaced is still next tomorrow. Kept in the defaults for the day it was tried, then it is gone.
struct TriedToday: Codable, Equatable {
    var routineID: UUID
    var title: String
    /// The Plan's routine it stands in for today, if there was one.
    var replacedTitle: String?
    var minutes: Int
    var day: String
    var triedAt: Date
    /// Saved to his routines: it stays after the day. Otherwise it is cleaned away when the day ends.
    var kept = false

    /// Ten seconds to take it back, then the word leaves.
    static let undoWindow: TimeInterval = 10
    private static let baseKey = "training.triedToday"

    /// One key per store: Sample mode keeps its own, so a try there never overwrites a real one.
    private static func key(_ scope: String) -> String {
        scope.isEmpty ? baseKey : "\(baseKey).\(scope)"
    }

    static func dayKey(_ now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: TesseraDay().today(now))
    }

    /// What is stored, whatever day it is for.
    static func stored(scope: String = "", defaults: UserDefaults = .standard) -> TriedToday? {
        defaults.data(forKey: key(scope)).flatMap { try? JSONDecoder().decode(TriedToday.self, from: $0) }
    }

    static func current(now: Date = AppClock.now, scope: String = "",
                        defaults: UserDefaults = .standard) -> TriedToday?
    {
        guard let tried = stored(scope: scope, defaults: defaults), tried.day == dayKey(now) else { return nil }
        return tried
    }

    static func set(_ tried: TriedToday?, scope: String = "", defaults: UserDefaults = .standard) {
        if let tried, let data = try? JSONEncoder().encode(tried) {
            defaults.set(data, forKey: key(scope))
        } else {
            defaults.removeObject(forKey: key(scope))
        }
    }

    func undoIsOpen(now: Date = AppClock.now) -> Bool {
        now.timeIntervalSince(triedAt) < Self.undoWindow
    }

    /// "Trying Upper in 25 today. Push A tomorrow." The Plan's weekday for the replaced routine is the next day it
    /// rolls to; the weekday is spoken as that day's name ("Thursday").
    func line(now: Date = AppClock.now, calendar: Calendar = .current) -> String {
        let trying = "Trying \(title) in \(minutes) today"
        guard let replacedTitle else { return trying }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let weekday = tomorrow.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "en_US")))
        return "\(trying). \(replacedTitle) on \(weekday)"
    }
}

/// The ready workouts he has tried, newest first: the "Tried" word in the library.
enum TriedHistory {
    private static let key = "training.triedHistory"

    static func ids(defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    static func add(_ id: String, defaults: UserDefaults = .standard) {
        let kept = ([id] + ids(defaults: defaults).filter { $0 != id }).prefix(20)
        defaults.set(Array(kept), forKey: key)
    }
}

extension AppModel {
    /// One record per store (its file name; "memory" when there is no file): Sample mode and a restored copy keep their
    /// own try and never overwrite the real one.
    var triedScope: String {
        context.url?.lastPathComponent ?? "memory"
    }

    /// Today's tried workout, only while its routine is still in this store (a Sample store, or another phone's, has
    /// none, so its "Trying ..." never shows on the real page).
    func triedToday(now: Date = AppClock.now) -> TriedToday? {
        guard let tried = TriedToday.current(now: now, scope: triedScope), let routine = object(tried.routineID),
              !routine.isDeleted
        else { return nil }
        return tried
    }

    /// The routine "Try today" put in today's place, while it is still today's.
    func triedRoutine(now: Date = AppClock.now) -> ObjectRecord? {
        guard session == nil, finishedToday(now: now).isEmpty, let tried = triedToday(now: now) else { return nil }
        return object(tried.routineID)
    }

    /// Today can take a ready workout when nothing is running, nothing is finished, and a scheduled workout has not
    /// been
    /// started (a started one is today's).
    func canTryToday(now: Date = AppClock.now) -> Bool {
        guard session == nil, finishedToday(now: now).isEmpty else { return false }
        guard let scheduled = tonightWorkout(around: now) else { return true }
        return store.value("startedAt", of: scheduled) == nil
    }

    /// Makes the workout a routine (one undo per step) and puts it in today's place. A second try the same day takes
    /// the first one's place, and the line still names what the Plan had for today. Nothing happens while a workout
    /// is running or finished today: today is already decided.
    @discardableResult
    func tryToday(_ workout: ReadyWorkout, now: Date = AppClock.now) -> Bool {
        guard canTryToday(now: now) else { return false }
        purgeStaleTried(now: now)
        var replaced = todaysRoutine(now: now)?.title ?? tonightWorkout(around: now)?.title
        var earlier: TriedToday?
        if let existing = triedToday(now: now) {
            earlier = existing
            replaced = existing.replacedTitle
        }
        guard let routine = try? ReadyWorkouts.add(workout, using: engine) else { return false }
        if let earlier, !earlier.kept {
            _ = try? engine.perform(DeleteObject(object: earlier.routineID), by: .user)
        }
        TriedToday.set(TriedToday(routineID: routine.id, title: workout.title, replacedTitle: replaced,
                                  minutes: workout.minutes, day: TriedToday.dayKey(now), triedAt: now),
                       scope: triedScope)
        TriedHistory.add(workout.id)
        touch()
        return true
    }

    /// Takes "Try today" back: the routine it made goes (unless he saved it), and today's place is the Plan's again.
    func undoTryToday() {
        guard let tried = TriedToday.current(scope: triedScope) else { return }
        TriedToday.set(nil, scope: triedScope)
        if !tried.kept {
            _ = try? engine.perform(DeleteObject(object: tried.routineID), by: .user)
        }
        touch()
    }

    /// A tried routine nobody saved goes when its day is over, so Routines never fills with them.
    func purgeStaleTried(now: Date = AppClock.now) {
        guard let stored = TriedToday.stored(scope: triedScope), stored.day != TriedToday.dayKey(now) else { return }
        TriedToday.set(nil, scope: triedScope)
        if !stored.kept, let routine = object(stored.routineID), !routine.isDeleted {
            _ = try? engine.perform(DeleteObject(object: stored.routineID), by: .user)
            touch()
        }
    }

    /// "Save": the ready workout as one of his routines. Saving what he is trying today keeps that routine instead
    /// of making a second one.
    @discardableResult
    func saveReadyWorkout(_ workout: ReadyWorkout) -> Bool {
        if var tried = triedToday(), tried.title == workout.title {
            tried.kept = true
            TriedToday.set(tried, scope: triedScope)
            touch()
            return true
        }
        guard (try? ReadyWorkouts.add(workout, using: engine)) != nil else { return false }
        touch()
        return true
    }
}
