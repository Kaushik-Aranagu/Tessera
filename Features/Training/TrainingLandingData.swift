import Foundation
import Observation
import SwiftUI
import TesseraCore

// MARK: - The stats seam

/// The three stat lines under "Training" (sheet 230). They come from Core's TrainingLedger API, which Core is adding;
/// until it lands the headline comes through this seam, with sample values for what the ledger cannot say yet.
struct TrainingHeadline: Equatable {
    struct Gain: Equatable {
        let lift: String
        let classID: UUID?
        let kilograms: Double
        let since: Date
    }

    var done: Int
    var planned: Int
    var weeksInARow: Int
    var gain: Gain?
    /// A new thing to try, shown in green ("New: hill sprints"); nil when there is none. Sample until Core says.
    var newThing: String?
}

protocol TrainingStatsSource {
    @MainActor func headline(model: AppModel, now: Date) -> TrainingHeadline
}

/// The sheet's own example: "3 of 6 this week", "5 weeks in a row on plan", "+10 lb on bench since Oct 1".
struct SampleTrainingStats: TrainingStatsSource {
    func headline(model _: AppModel, now: Date) -> TrainingHeadline {
        let since = Calendar.current.date(from: DateComponents(
            year: Calendar.current.component(.year, from: now), month: 10, day: 1
        )) ?? now
        return TrainingHeadline(done: 3, planned: 6, weeksInARow: 5,
                                gain: .init(lift: "Bench press", classID: nil,
                                            kilograms: 10 / MassUnit.poundsPerKilogram, since: since),
                                newThing: "hill sprints")
    }
}

/// What the ledger can say today (the week's count from the plan's own week), with the sample for the two Core has not
/// added (weeks in a row on plan, the gain on a lift). One line to change when Core's API lands.
struct LedgerTrainingStats: TrainingStatsSource {
    var fallback: TrainingStatsSource = SampleTrainingStats()

    @MainActor
    func headline(model: AppModel, now: Date) -> TrainingHeadline {
        var headline = fallback.headline(model: model, now: now)
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: model.plan) ?? 0
        headline.done = TrainingWeek.doneThisWeek(model, now: now)
        headline.planned = max(perWeek, headline.done)
        if let bench = model.classDef(.exercise).flatMap({ root in
            ClassResolver.descendants(of: root).first { $0.name.lowercased().hasPrefix("bench") }
        }), headline.gain != nil {
            headline.gain = TrainingHeadline.Gain(lift: bench.name, classID: bench.id,
                                                  kilograms: headline.gain?.kilograms ?? 0,
                                                  since: headline.gain?.since ?? now)
        }
        return headline
    }
}

extension TrainingHeadline {
    var doneLine: String {
        "\(done) of \(planned) this week"
    }

    var streakLine: String {
        "\(weeksInARow) \(weeksInARow == 1 ? "week" : "weeks") in a row on plan"
    }

    /// "+10 lb on bench since Oct 1": the lift in lower case after "on", the gain in the display unit.
    func gainParts(unit: MassUnit) -> (gain: String, rest: String)? {
        guard let gain, gain.kilograms > 0 else { return nil }
        let shown = unit.fromKilograms(gain.kilograms)
        let number = shown.rounded() == shown ? String(Int(shown)) : String(format: "%g", shown)
        let name = gain.lift.split(separator: " ").first.map { String($0).lowercased() } ?? gain.lift.lowercased()
        let day = gain.since.formatted(.dateTime.month(.abbreviated).day())
        return ("+\(number) \(unit.symbol)", " on \(name) since \(day)")
    }
}

// MARK: - Today's slot

/// The 118 pt slot on the landing and what it says (sheet 230).
enum TodaySlot: Equatable {
    case notStarted(name: String)
    case inProgress(name: String, whereLine: String)
    case paused(name: String, whereLine: String)
    case done(name: String)
    case skipped(name: String)
    case nothing

    /// The green header over the clock while it runs.
    var header: String? {
        switch self {
        case .inProgress, .paused: "In progress"
        default: nil
        }
    }

    /// The word beside the clock: "Pause", and "Go on" while paused.
    var clockWord: String? {
        switch self {
        case .inProgress: "Pause"
        case .paused: "Go on"
        default: nil
        }
    }

    /// The action word at the foot.
    var actionWord: String? {
        switch self {
        case let .notStarted(name): TrainingWords.foot(startName: name)
        case let .inProgress(name, _), let .paused(name, _): TrainingWords.footResume(name: name, verb: "Resume")
        case .done, .skipped, .nothing: nil
        }
    }

    var isStruck: Bool {
        switch self {
        case .done, .skipped: true
        default: false
        }
    }
}

/// Today's clock can be paused on the landing: the minutes stop, turn ink 3, and the word reads "Go on". A display of
/// the workout's time only; the workout itself keeps its place.
@MainActor
@Observable
final class TodayClock {
    static let shared = TodayClock()
    private(set) var pausedAt: Date?
    private(set) var pausedTotal: TimeInterval = 0

    var isPaused: Bool {
        pausedAt != nil
    }

    func pause(at now: Date = AppClock.now) {
        guard pausedAt == nil else { return }
        pausedAt = now
    }

    func resume(at now: Date = AppClock.now) {
        guard let pausedAt else { return }
        pausedTotal += now.timeIntervalSince(pausedAt)
        self.pausedAt = nil
    }

    func reset() {
        pausedAt = nil
        pausedTotal = 0
    }

    /// The elapsed time shown: stops growing while paused.
    func elapsed(since start: Date, now: Date) -> TimeInterval {
        let end = pausedAt ?? now
        return max(end.timeIntervalSince(start) - pausedTotal, 0)
    }
}

/// "Skip today": a day marked skipped on this phone (nothing is written to the plan), with a true Undo.
enum SkippedToday {
    private static let key = "training.skippedDay"

    @MainActor static var isSet: Bool {
        UserDefaults.standard.string(forKey: key) == dayKey(AppClock.now)
    }

    @MainActor static func set(_ on: Bool) {
        if on {
            UserDefaults.standard.set(dayKey(AppClock.now), forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @MainActor private static func dayKey(_ date: Date) -> String {
        TesseraDay().today(date).formatted(.iso8601.year().month().day())
    }
}
