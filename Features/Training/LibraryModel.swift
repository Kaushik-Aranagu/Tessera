import Foundation
import SwiftUI
import TesseraCore

/// The four things the Library holds (the "What" dial, sheet 230 v3). Each cell shows a count.
enum LibraryWhat: String, CaseIterable, Identifiable {
    case routines = "Routines", exercises = "Exercises", programs = "Programs", goals = "Goals"

    var id: String {
        rawValue
    }

    /// The action word at the foot for what is showing.
    var actionWord: String {
        switch self {
        case .routines: "Build a routine"
        case .exercises: "Add an exercise"
        case .programs: "Start a program"
        case .goals: "Set a goal"
        }
    }

    /// Each cell has its own colour (v3.3), for the dial's focus word, the category count and the focused row:
    /// Routines go green, Exercises gold, Programs slate, Goals the Training blue.
    var color: Color {
        switch self {
        case .routines: Theme.Colors.Go.green
        case .exercises: Theme.Colors.Gold.label
        case .programs: Theme.Colors.Slate.label
        case .goals: Theme.Colors.Accent.training
        }
    }

    /// What Tess's bar is prefilled with when the action word is tapped (the app builds things through her).
    var draft: String {
        switch self {
        case .routines: "build a routine "
        case .exercises: "add an exercise "
        case .programs: "start a program "
        case .goals: "set a goal "
        }
    }
}

/// How the category row cuts the library: by kind (the default), by length or by day. The word on the left rolls
/// the axis.
enum LibraryAxis: String, CaseIterable {
    case kind = "by kind", length = "by length", day = "by day"

    var next: LibraryAxis {
        let all = Self.allCases
        return all[(all.firstIndex(of: self).map { $0 + 1 } ?? 0) % all.count]
    }

    var categories: [String] {
        switch self {
        case .kind: ["Everything", "Push", "Pull", "Legs", "Full body", "Cardio", "Mobility"]
        case .length: ["Everything", "Under 30 min", "30 to 45 min", "45 to 60 min", "Over an hour"]
        case .day: ["Everything", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
    }
}

/// One thing in the Library, whichever cell it belongs to.
struct LibraryEntry: Identifiable, Equatable {
    let id: String
    let what: LibraryWhat
    let title: String
    /// The two lines of the brief while it is in front.
    let lines: [String]
    /// "Push", "Pull", "Legs", "Full body", "Cardio" or "Mobility".
    let kind: String
    let minutes: Int?
    /// Weekday (1 is Sunday) the plan puts it on, when it does.
    let weekday: Int?
    var routineID: UUID?
    var classID: UUID?
    var planID: UUID?
}

enum LibraryFilter {
    /// Whether an item belongs under a category of an axis. "Everything" is always true; a thing with no length or day
    /// (an exercise) is only found under Everything on those axes.
    static func matches(_ item: LibraryEntry, axis: LibraryAxis, category: String) -> Bool {
        guard category != "Everything" else { return true }
        switch axis {
        case .kind:
            return item.kind == category
        case .length:
            guard let minutes = item.minutes else { return false }
            return switch category {
            case "Under 30 min": minutes < 30
            case "30 to 45 min": (30 ..< 45).contains(minutes)
            case "45 to 60 min": (45 ..< 60).contains(minutes)
            case "Over an hour": minutes >= 60
            default: false
            }
        case .day:
            guard let weekday = item.weekday, let index = axis.categories.firstIndex(of: category) else { return false }
            // Monday is category 1, and weekday 2.
            return weekday == (index % 7) + 1
        }
    }

    /// Items under each category of the axis, in order, for the counts.
    static func counts(_ items: [LibraryEntry], axis: LibraryAxis) -> [Int] {
        axis.categories.map { category in items.count { matches($0, axis: axis, category: category) } }
    }
}

enum LibraryKinds {
    /// The kind of a routine or an exercise from its name: Push, Pull, Legs, Full body, Cardio or Mobility.
    static func kind(ofName name: String) -> String {
        let lowered = name.lowercased()
        func has(_ words: [String]) -> Bool {
            words.contains { lowered.contains($0) }
        }
        if has(["full body", "full-body", "total body"]) {
            return "Full body"
        }
        if has(["mobility", "stretch", "yoga", "warm-up", "warm up"]) {
            return "Mobility"
        }
        if has(["cardio", "run", "bike", "cycle", "rower", "rowing", "swim", "jump rope", "treadmill"]) {
            return "Cardio"
        }
        if has(["leg", "squat", "lunge", "calf", "hip thrust", "glute", "deadlift", "hamstring"]) {
            return "Legs"
        }
        if has(["pull", "row", "curl", "chin", "lat ", "face pull", "shrug", "back "]) {
            return "Pull"
        }
        if has(["push", "press", "bench", "dip", "fly", "raise", "triceps", "pushdown", "push-up"]) {
            return "Push"
        }
        return "Full body"
    }
}

/// Goals are not in Core yet; this seam answers until they are (listed as a Core need).
struct LibraryGoal: Equatable {
    let title: String
    let line: String
}

protocol LibraryGoalsSource {
    func goals() -> [LibraryGoal]
}

struct NoGoalsYet: LibraryGoalsSource {
    func goals() -> [LibraryGoal] {
        []
    }
}

enum LibraryData {
    @MainActor
    static func items(model: AppModel, goals: LibraryGoalsSource = NoGoalsYet()) -> [LibraryEntry] {
        var items: [LibraryEntry] = []
        let todayWeek = model.ledger.week(containing: AppClock.now, plan: model.plan, now: AppClock.now)
        for routine in model.objects(of: .routine) where !routine.isDeleted {
            let slots = routine.orderedChildren
            let sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
            let minutes = sets > 0 ? TrainingPage.estimatedMinutes(sets: sets) : nil
            let title = ObjectPrivacy.routineTitle(routine.title, in: model.store)
            let day = todayWeek.first { $0.planned?.id == routine.id && !$0.isRest }
                .map { Calendar.current.component(.weekday, from: $0.day) }
            items.append(LibraryEntry(
                id: routine.id.uuidString, what: .routines, title: title,
                lines: [
                    "\(slots.count) \(slots.count == 1 ? "lift" : "lifts")\(minutes.map { ", about \($0) min" } ?? "").",
                    day.map { "On \(weekdayName($0))." } ?? "Not on a day this week.",
                ],
                kind: LibraryKinds.kind(ofName: routine.title), minutes: minutes, weekday: day, routineID: routine.id
            ))
        }
        if let root = model.classDef(.exercise) {
            for exercise in ClassResolver.descendants(of: root)
                where ExerciseRouting.isExercise(exercise, classes: model.classes)
            {
                let last = model.ledger.sessions(of: exercise).first?.sets.first
                items.append(LibraryEntry(
                    id: exercise.id.uuidString, what: .exercises, title: exercise.name,
                    lines: [last.map { "Last time \(Format.shown($0.weight)) for \(Int($0.reps.rounded()))." }
                        ?? "Not done yet.", ""],
                    kind: LibraryKinds.kind(ofName: exercise.name), minutes: nil, weekday: nil, classID: exercise.id
                ))
            }
        }
        for plan in model.objects(of: .plan) where !plan.isDeleted {
            let count = model.store.linkedObjects("routines", of: plan).count
            let fixed = PlanSchedule.mode(of: plan, store: model.store) == .fixed
            items.append(LibraryEntry(
                id: plan.id.uuidString, what: .programs, title: plan.title,
                lines: ["\(count) \(count == 1 ? "routine" : "routines").", fixed ? "On fixed days." : "Rolls on."],
                kind: "Full body", minutes: nil, weekday: nil, planID: plan.id
            ))
        }
        for goal in goals.goals() {
            items.append(LibraryEntry(id: "goal-\(goal.title)", what: .goals, title: goal.title, lines: [goal.line, ""],
                                      kind: "Full body", minutes: nil, weekday: nil))
        }
        return items
    }

    private static func weekdayName(_ weekday: Int) -> String {
        Calendar.current.weekdaySymbols[(weekday - 1) % 7]
    }
}

extension AppModel {
    /// "Do it today" for a routine of his: it takes today's place (the plan is never rewritten, so the routine it
    /// replaced is still next tomorrow). Returns its Undo, or nil when today is already decided.
    @discardableResult
    func doRoutineToday(_ routine: ObjectRecord, now: Date = AppClock.now) -> (() -> Void)? {
        guard canTryToday(now: now) else { return nil }
        purgeStaleTried(now: now)
        let replaced = todaysRoutine(now: now)?.title ?? tonightWorkout(around: now)?.title
        let previous = TriedToday.current(scope: triedScope)
        let sets = routine.orderedChildren.reduce(0) { $0 + Int(store.number("sets", of: $1) ?? 3) }
        TriedToday.set(
            TriedToday(routineID: routine.id, title: routine.title, replacedTitle: replaced,
                       minutes: TrainingPage.estimatedMinutes(sets: sets), day: TriedToday.dayKey(now), triedAt: now,
                       kept: true),
            scope: triedScope
        )
        touch()
        let scope = triedScope
        return { [weak self] in
            TriedToday.set(previous, scope: scope)
            self?.touch()
        }
    }
}
