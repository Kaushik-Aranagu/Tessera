import Foundation
import TesseraCore

/// Everything the Exercise page shows, read once from Core's ledger and store (docs/design/exercise-page.md,
/// docs/product/workouts.md §4 and §6). The view only lays it out.
@MainActor
struct ExerciseDigest {
    struct PathPart: Identifiable, Hashable {
        let id: UUID
        let title: String
    }

    struct HistoryRow: Identifiable, Hashable {
        /// The exercise entry's id.
        let id: UUID
        let workoutID: UUID
        let date: Date
        let setCount: Int
        let topSet: String
        /// Holds the best e1RM set.
        let isRecord: Bool
    }

    enum Role: Hashable {
        case primary, secondary
    }

    struct MuscleRow: Identifiable, Hashable {
        let id: UUID
        let name: String
        let role: Role
    }

    struct Trend: Hashable {
        /// Unit-space points, x by date (0 = first session, 1 = today), y up (0 = lowest, 1 = highest).
        let points: [CGPoint]
        /// "14 DAYS", or "90 DAYS" once the window is full.
        let span: String
        /// "+6.5 SINCE JULY", "−2.5 SINCE OCT 1".
        let change: String?
        let isRise: Bool
    }

    let exercise: ClassDef
    let name: String
    let path: [PathPart]
    let context: String?
    let bestE1RM: Double?
    let bestSet: String?
    let trend: Trend?
    let history: [HistoryRow]
    let repMaxes: [Int: Double]
    let muscles: [MuscleRow]
    let nextTime: String?

    init(exercise: ClassDef, ledger: TrainingLedger, store: ObjectStore, now: Date, calendar: Calendar = .current) {
        self.exercise = exercise
        name = exercise.name
        path = Self.path(of: exercise, root: ledger.classes[.exercise])

        let primary = store.linkedObjects("primaryMuscles", ofClass: exercise)
        let primaryIDs = Set(primary.map(\.id))
        let secondary = store.linkedObjects("secondaryMuscles", ofClass: exercise)
            .filter { !primaryIDs.contains($0.id) }
        muscles = primary.map { MuscleRow(id: $0.id, name: $0.title, role: .primary) }
            + secondary.map { MuscleRow(id: $0.id, name: $0.title, role: .secondary) }
        context = ExerciseWords.musclePhrase(primary: primary.map(\.title), secondary: secondary.map(\.title))

        // One call to Core: best set and e1RM, rep maxes, the last 5 sessions and the 90-day trend.
        let overview = ledger.overview(of: exercise, recent: 5, now: now)
        let best = overview.bestSet
        bestE1RM = best.map { ($0.e1RM * 10).rounded() / 10 }
        bestSet = best.map { ExerciseWords.set(weight: $0.weight, reps: $0.reps) }
        repMaxes = overview.repMaxes

        history = overview.recentSessions.map { session in
            let top = session.sets.max { ($0.weight, $0.reps) < ($1.weight, $1.reps) }
            return HistoryRow(
                id: session.id,
                workoutID: session.workout.id,
                date: session.date,
                setCount: session.sets.count,
                topSet: top.map { ExerciseWords.set(weight: $0.weight, reps: $0.reps) } ?? "",
                isRecord: best.map { record in session.sets.contains { $0.id == record.id } } ?? false
            )
        }

        trend = Self.trend(overview.trend.map { ($0.date, $0.bestE1RM) }, now: now, calendar: calendar)
        nextTime = Self.nextTime(for: exercise, ledger: ledger, store: store)
    }

    // MARK: Pieces (static so they can be tested)

    /// The class path one level up at a time, from Exercise down to the parent: "Exercises › Barbell Lifts".
    /// Long chains keep the first and the last step, so the path stays one line.
    static func path(of exercise: ClassDef, root: ClassDef?) -> [PathPart] {
        let lineage = ClassResolver.lineage(of: exercise).dropLast()
        let start = root.flatMap { root in lineage.firstIndex { $0.id == root.id } } ?? lineage.startIndex
        let ancestors = Array(lineage[start...])
        let shown = ancestors.count > 2 ? [ancestors[0], ancestors[ancestors.count - 1]] : ancestors
        return shown.map { PathPart(id: $0.id, title: ExerciseWords.plural($0.name)) }
    }

    static func trend(_ values: [(Date, Double)], now: Date, calendar: Calendar) -> Trend? {
        guard let first = values.first, let last = values.last else { return nil }
        let days = max(Int((now.timeIntervalSince(first.0) / 86400).rounded(.up)), 1)
        let span = days >= 85 ? "90 days" : "\(days) \(days == 1 ? "day" : "days")"
        let delta = ((last.1 - first.1) * 10).rounded() / 10
        let change: String? = values.count > 1
            ? "\(ExerciseWords.signed(delta)) since \(ExerciseWords.since(first.0, now: now, calendar: calendar))"
            : nil
        return Trend(points: TrendGeometry.points(values, until: now), span: span, change: change,
                     isRise: delta >= 0)
    }

    /// Tess's forward line: "Next time: 82.5 for 9, then 85." Follows the same rule Core prefills the set with.
    static func nextTime(for exercise: ClassDef, ledger: TrainingLedger, store: ObjectStore) -> String? {
        let target = ledger.nextTarget(for: exercise)
        guard let weight = target.weight else {
            return ledger.sessions(of: exercise).isEmpty ? "First time: start light, \(target.reps) reps." : nil
        }
        let ruleText = store.classObject(of: exercise).flatMap { store.value("progression", of: $0)?.stringValue }
            ?? ClassResolver.field("progression", of: exercise)?.defaultValue?.stringValue
        var then: Double?
        if case let .doubleProgression(increment, _, _)? = ruleText.flatMap(ProgressionRule.init(parsing:)) {
            let profile = store.loadProfile(for: exercise)
            let raised = profile.nearest(to: weight + increment)
            then = raised > weight + 0.001 ? raised : profile.next(above: weight)
        }
        return ExerciseWords.nextTime(weight: weight, reps: target.reps, then: then)
    }
}

// MARK: - Words

/// How the Exercise page says things. Plain words, numbers as lifters write them.
enum ExerciseWords {
    /// "85 × 6"
    static func set(weight: Double, reps: Double) -> String {
        "\(Format.kilograms(weight)) × \(Int(reps.rounded()))"
    }

    /// "chest, with triceps and front delts": what it works, in words.
    static func musclePhrase(primary: [String], secondary: [String]) -> String? {
        let lead = list(primary.map { $0.lowercased() })
        let rest = list(secondary.map { $0.lowercased() })
        switch (lead, rest) {
        case let (lead?, rest?): return "\(lead), with \(rest)"
        case let (lead?, nil): return lead
        case let (nil, rest?): return "mostly \(rest)"
        default: return nil
        }
    }

    /// "a", "a and b", "a, b and c"
    static func list(_ items: [String]) -> String? {
        switch items.count {
        case 0: nil
        case 1: items[0]
        default: items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1]
        }
    }

    /// "Barbell Lift" → "Barbell Lifts". Names that already end in s stay as they are.
    static func plural(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.hasSuffix("s") {
            return name
        }
        // Movement patterns ("Horizontal Push", "Hip Hinge") read as categories; keep them as they are.
        if ["sh", "ch", "x", "z"].contains(where: lower.hasSuffix) || lower.hasSuffix("hinge") {
            return name
        }
        return name + "s"
    }

    /// "+6.5", "−2.5", "+0"
    static func signed(_ value: Double) -> String {
        value < 0 ? "−\(Format.kilograms(-value))" : "+\(Format.kilograms(value))"
    }

    /// "July" when the first session is in an earlier month, else "Oct 1".
    static func since(_ date: Date, now: Date, calendar: Calendar) -> String {
        let sameMonth = calendar.isDate(date, equalTo: now, toGranularity: .month)
        var style = Date.FormatStyle.dateTime
        style.timeZone = calendar.timeZone
        return sameMonth ? date.formatted(style.month(.abbreviated).day()) : date.formatted(style.month(.wide))
    }

    /// History dates: "Today", "Mon 12" this month, "Sep 27" before.
    static func historyDate(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = TesseraDay(calendar: calendar)
        if day.isSameDay(date, now) {
            return "Today"
        }
        if day.isSameDay(date, day.adding(days: -1, to: now)) {
            return "Yesterday"
        }
        var style = Date.FormatStyle.dateTime
        style.timeZone = calendar.timeZone
        return calendar.isDate(date, equalTo: now, toGranularity: .month)
            ? date.formatted(style.weekday(.abbreviated).day())
            : date.formatted(style.month(.abbreviated).day())
    }

    /// "Next time: 82.5 for 9, then 85."
    static func nextTime(weight: Double, reps: Int, then: Double?) -> String {
        let base = "Next time: \(Format.kilograms(weight)) for \(reps)"
        return then.map { "\(base), then \(Format.kilograms($0))." } ?? "\(base)."
    }

    /// "primary", "half a set each"
    static func role(_ role: ExerciseDigest.Role) -> String {
        role == .primary ? "primary" : "half a set each"
    }
}

// MARK: - Trend geometry

enum TrendGeometry {
    /// Unit-space points for a trend: x by date from the first session to `end`, y scaled to the values with a
    /// floor of 5 kg on the range, so a 1 kg wobble never looks like a cliff.
    static func points(_ values: [(Date, Double)], until end: Date, minimumRange: Double = 5) -> [CGPoint] {
        guard let first = values.first else { return [] }
        let start = first.0
        let duration = max(end.timeIntervalSince(start), 1)
        let low = values.map(\.1).min() ?? 0, high = values.map(\.1).max() ?? 0
        let range = max(high - low, minimumRange)
        let floor = low - (range - (high - low)) / 2
        return values.map { date, value in
            CGPoint(x: min(max(date.timeIntervalSince(start) / duration, 0), 1), y: (value - floor) / range)
        }
    }
}
