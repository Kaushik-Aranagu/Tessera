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

    /// Ten seconds to take it back, then the word leaves.
    static let undoWindow: TimeInterval = 10
    private static let key = "training.triedToday"

    static func dayKey(_ now: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: TesseraDay().today(now))
    }

    static func current(now: Date = AppClock.now, defaults: UserDefaults = .standard) -> TriedToday? {
        guard let data = defaults.data(forKey: key), let tried = try? JSONDecoder().decode(TriedToday.self, from: data),
              tried.day == dayKey(now) else { return nil }
        return tried
    }

    static func set(_ tried: TriedToday?, defaults: UserDefaults = .standard) {
        if let tried, let data = try? JSONEncoder().encode(tried) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func undoIsOpen(now: Date = AppClock.now) -> Bool {
        now.timeIntervalSince(triedAt) < Self.undoWindow
    }

    /// "Trying Upper in 25 today. Push A tomorrow." The Plan's weekday for the replaced routine is the next day it
    /// rolls to; the weekday is spoken as that day's name ("Thursday").
    func line(now: Date = AppClock.now, calendar: Calendar = .current) -> String {
        let trying = "Trying \(title) in \(minutes) today."
        guard let replacedTitle else { return trying }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let weekday = tomorrow.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "en_US")))
        return "\(trying) \(replacedTitle) on \(weekday)."
    }
}

extension AppModel {
    /// Makes the workout a routine (one undo per step) and puts it in today's place. Nothing happens while a workout
    /// is running or finished today: today is already decided.
    @discardableResult
    func tryToday(_ workout: ReadyWorkout, now: Date = AppClock.now) -> Bool {
        guard canTryToday(now: now) else { return false }
        let replaced = todaysRoutine(now: now)?.title ?? tonightWorkout(around: now)?.title
        guard let routine = try? ReadyWorkouts.add(workout, using: engine) else { return false }
        TriedToday.set(TriedToday(routineID: routine.id, title: workout.title, replacedTitle: replaced,
                                  minutes: workout.minutes, day: TriedToday.dayKey(now), triedAt: now))
        touch()
        return true
    }

    /// Today can take a ready workout when nothing is running, nothing is finished, and a scheduled workout has not
    /// been
    /// started (a started one is today's).
    func canTryToday(now: Date = AppClock.now) -> Bool {
        guard session == nil, finishedToday(now: now).isEmpty else { return false }
        guard let scheduled = tonightWorkout(around: now) else { return true }
        return store.value("startedAt", of: scheduled) == nil
    }

    /// The routine "Try today" put in today's place, while it is still today's.
    func triedRoutine(now: Date = AppClock.now) -> ObjectRecord? {
        guard session == nil, finishedToday(now: now).isEmpty, let tried = TriedToday.current(now: now),
              let routine = object(tried.routineID), !routine.isDeleted else { return nil }
        return routine
    }

    /// Takes "Try today" back: the routine it made goes, and today's place is the Plan's again.
    func undoTryToday() {
        guard let tried = TriedToday.current() else { return }
        TriedToday.set(nil)
        _ = try? engine.perform(DeleteObject(object: tried.routineID), by: .user)
        touch()
    }

    /// "Save": the ready workout as one of his routines, nothing else.
    @discardableResult
    func saveReadyWorkout(_ workout: ReadyWorkout) -> Bool {
        guard (try? ReadyWorkouts.add(workout, using: engine)) != nil else { return false }
        touch()
        return true
    }
}
