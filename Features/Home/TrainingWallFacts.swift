import SwiftUI
import TesseraCore

// The facts the Training landing shows (landing contract §12, sheets 226, 230, 241): the day, the word wall of lifts
// and routines, the five doors, the one brief line and the foot's action word. Read once per revision; nothing here
// draws. Private routines read "Private workout" and never reach the wall.

/// What today is for Training.
enum TrainingDay: Equatable {
    case ready(name: String, minutes: Int, lifts: Int)
    case running(name: String, liftsDone: Int)
    case done(name: String, next: String?)
    case rest(next: String?, nextDay: Date?)
    case nothing
}

/// The brief's one line: plain words around one named thing.
struct TrainingBrief: Equatable {
    var before = ""
    let name: String
    var after = ""
    /// The split colour for a routine name (Push clay, Pull teal, Legs plum); nil draws the name in ink.
    var split: TrainingSplit?

    var text: String {
        before + name + after
    }
}

/// Sheet 241: the split a routine belongs to, by its name.
enum TrainingSplit: Equatable {
    case push, pull, legs

    init?(name: String) {
        let lower = name.lowercased()
        if lower.hasPrefix("push") {
            self = .push
        } else if lower.hasPrefix("pull") {
            self = .pull
        } else if lower.hasPrefix("leg") {
            self = .legs
        } else {
            return nil
        }
    }

    func color(dark: Bool) -> Color {
        switch self {
        case .push: Color(hex: dark ? 0xE2A07F : 0x9C4B2C)
        case .pull: Color(hex: dark ? 0x84C3C9 : 0x1E6E77)
        case .legs: Color(hex: dark ? 0xE3A3CB : 0x8A4570)
        }
    }
}

/// Where a wall word or a door goes.
enum TrainingWallTarget: Equatable {
    case exercise(UUID)
    case routine(UUID)

    var id: String {
        switch self {
        case let .exercise(id): "x:\(id.uuidString)"
        case let .routine(id): "r:\(id.uuidString)"
        }
    }

    /// Reads "x:<uuid>" or "r:<uuid>"; a "#..." suffix (a page row's own place, so two rows naming one lift keep
    /// distinct ids) is ignored.
    init?(id: String) {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let uuid = UUID(uuidString: String(parts[1].prefix { $0 != "#" })) else { return nil }
        switch parts[0] {
        case "x": self = .exercise(uuid)
        case "r": self = .routine(uuid)
        default: return nil
        }
    }
}

struct TrainingWallFacts: Equatable {
    let day: TrainingDay
    let words: [WallWord]
    let doors: [DialDoor]
    let brief: TrainingBrief?
    /// The foot's verb over its object; nil when there is nothing to do from here.
    let action: TrainingFoot?
    /// A rest day's other action: start the next routine anyway (its object is the routine).
    let restOption: String?
    /// The exercise behind each of the Today door's lines, in order (nil where a line names no lift), so a row on
    /// the Today page opens that one lift.
    var todayLiftIDs: [UUID?] = []

    var stateLine: [String] {
        Self.stateForms(day)
    }

    // MARK: Words

    /// The state line, longest form first (FitLine shows the longest that fits; the last always fits).
    static func stateForms(_ day: TrainingDay, calendar: Calendar = .current) -> [String] {
        switch day {
        case let .ready(name, minutes, lifts):
            let liftWord = lifts == 1 ? "lift" : "lifts"
            return ["\(name) today, about \(minutes) min, \(lifts) \(liftWord).",
                    "\(name) today, about \(minutes) min.", "\(name) today.", "\(name)."]
        case let .running(name, liftsDone):
            let forms = liftsDone > 0
                ? ["\(name) under way, \(liftsDone) \(liftsDone == 1 ? "lift" : "lifts") done."] : []
            return forms + ["\(name) under way.", "Under way."]
        case let .done(name, next):
            let forms = next.map { ["\(name) done today. Next is \($0).", "\(name) done. Next is \($0)."] } ?? []
            return forms + ["\(name) done today.", "Done today."]
        case let .rest(next, nextDay):
            var forms: [String] = []
            if let nextDay {
                let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: nextDay) - 1]
                forms.append("Rest today. Next is \(weekday).")
            } else if let next {
                forms.append("Rest today. Next is \(next).")
            }
            return forms + ["Rest today."]
        case .nothing:
            return ["Nothing on the plan yet.", "No plan yet."]
        }
    }

    /// The foot (283 v3): a verb over its object, never one phrase ("Start" over "Push A").
    static func actionWord(_ day: TrainingDay) -> TrainingFoot? {
        switch day {
        case let .ready(name, _, _): TrainingFoot(verb: "Start", object: name, hold: true)
        case let .running(name, _): TrainingFoot(verb: "Pick up", object: name)
        case .rest: TrainingFoot(verb: "Log", object: "A walk")
        case .done: nil
        case .nothing: TrainingFoot(verb: "Pick", object: "A routine")
        }
    }

    /// A wall word: cut on a whole word at 14 characters, the Notes rule.
    static func short(_ name: String) -> String {
        NotesLandingPage.short(name)
    }

    /// The first word of a lift ("Bench" for "Bench Press"), for the door facts' 150 pt column.
    static func lift(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// Recency (0 to 0.7, gone after 60 days) plus 0.3 when the newest session holds the best.
    static func weight(daysSince: Double, bestIsNewest: Bool) -> Double {
        let recency = max(0, 1 - daysSince / 60) * 0.7
        return min(1, recency + (bestIsNewest ? 0.3 : 0))
    }
}

// MARK: - Loading

@MainActor
extension TrainingWallFacts {
    private struct Lift {
        let exercise: ClassDef
        let last: Date
        let best: TrainingLedger.LoggedSet?
        let bestIsNewest: Bool
    }

    @MainActor
    static func load(_ model: AppModel, now: Date = AppClock.now, dark: Bool = false) -> TrainingWallFacts {
        let store = model.store
        let plan = model.plan
        let calendar = Calendar.current
        func shown(_ title: String) -> String {
            ObjectPrivacy.routineTitle(title, in: store)
        }
        let routines = plan.map { store.linkedObjects("routines", of: $0) }?.filter { !$0.isDeleted } ?? []
        let day = day(model, now: now, shown: shown)

        // Lifts with history, newest first. Private words never reach the wall or the doors.
        let lifts: [Lift] = ExerciseLibraryList.groups(model).flatMap(\.exercises)
            .compactMap { exercise -> Lift? in
                guard !ObjectPrivacy.isPrivateWord(exercise.name, in: store) else { return nil }
                let sessions = model.ledger.sessions(of: exercise)
                guard let newest = sessions.first else { return nil }
                let best = model.ledger.bestSet(of: exercise)
                let newestHolds = best.map { best in newest.sets.contains { $0.id == best.id } } ?? false
                return Lift(exercise: exercise, last: newest.date, best: best, bestIsNewest: newestHolds)
            }
            .sorted { $0.last > $1.last }

        var words: [WallWord] = lifts.prefix(18).map { lift in
            let days = max(0, now.timeIntervalSince(lift.last) / 86400)
            return WallWord(id: TrainingWallTarget.exercise(lift.exercise.id).id, text: short(lift.exercise.name),
                            weight: weight(daysSince: days, bestIsNewest: lift.bestIsNewest))
        }
        let todayName: String? = switch day {
        case let .ready(name, _, _), let .running(name, _): name
        default: nil
        }
        for routine in routines where shown(routine.title) != ObjectPrivacy.routineLabel
            && !words.contains(where: { $0.text == short(routine.title) })
        {
            let isToday = routine.title == todayName
            words.append(WallWord(id: TrainingWallTarget.routine(routine.id).id, text: short(routine.title),
                                  weight: isToday ? 0.95 : 0.4))
        }

        let (doors, todayLiftIDs) = doors(model, day: day, lifts: lifts, routines: routines, shown: shown, now: now,
                                          calendar: calendar, dark: dark)
        let brief = brief(model, day: day, lifts: lifts, calendar: calendar)
        var restOption: String?
        if case let .rest(next, _) = day, let next {
            restOption = next
        }
        return TrainingWallFacts(day: day, words: words, doors: doors, brief: brief, action: actionWord(day),
                                 restOption: restOption, todayLiftIDs: todayLiftIDs)
    }

    /// What today is, from the same sources the old page reads: running, tried, tonight's, the plan's, done, rest.
    @MainActor
    private static func day(_ model: AppModel, now: Date, shown: (String) -> String) -> TrainingDay {
        let store = model.store
        if let session = model.session {
            let done = session.entries.filter { !session.setRows(of: $0).isEmpty }.count
            return .running(name: shown(session.workout.title), liftsDone: done)
        }
        if let workout = model.tonightWorkout(around: now) {
            let entries = workout.orderedChildren.filter { !$0.isDeleted }
            let sets = NowPage.plannedSets(entries, store: store)
            return .ready(name: shown(workout.title), minutes: TrainingPage.estimatedMinutes(sets: sets),
                          lifts: entries.count)
        }
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        if let finished = model.finishedToday(now: now).first {
            let next = plan.flatMap { model.ledger.nextRoutine(in: $0, now: now) }.map { shown($0.title) }
            return .done(name: shown(finished.title), next: next)
        }
        if model.triedRoutine() == nil,
           let rest = NowPicker(engine: model.engine).restDay(plan: plan, at: now, sessionsPerWeek: perWeek)
        {
            return .rest(next: shown(rest.next.title), nextDay: rest.nextDay)
        }
        if let routine = model.triedRoutine() ?? model.todaysRoutine(now: now) {
            let slots = routine.orderedChildren.filter { !$0.isDeleted }
            let sets = slots.reduce(0) { $0 + max(Int(store.number("sets", of: $1) ?? 3), 1) }
            return .ready(name: shown(routine.title), minutes: TrainingPage.estimatedMinutes(sets: sets),
                          lifts: slots.count)
        }
        return .nothing
    }

    // MARK: Doors

    @MainActor
    private static func doors(_ model: AppModel, day: TrainingDay, lifts: [Lift], routines: [ObjectRecord],
                              shown: (String) -> String, now: Date, calendar: Calendar,
                              dark: Bool) -> (doors: [DialDoor], todayLiftIDs: [UUID?])
    {
        let store = model.store
        let blue = Theme.Colors.Accent.training
        let gold = Color(hex: dark ? 0xD9C27A : 0x7E6A1E)
        let slate = Color(hex: dark ? 0xA7BCD6 : 0x34506F)
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan) ?? 0
        // Days trained this week (a day with two sessions is one day trained).
        let done = model.ledger.week(
            containing: now,
            plan: plan,
            now: now,
            sessionsPerWeek: perWeek > 0 ? perWeek : nil,
            calendar: calendar
        ).filter { !$0.done.isEmpty }.count
        let left = max(perWeek - done, 0)

        var weekLines: [String] = []
        weekLines.append(done == 0 ? "Nothing yet" : "\(done) done")
        if left > 0 {
            weekLines.append("\(left) to go")
        }
        if case let .rest(next, nextDay) = day, let next, let nextDay {
            let weekday = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: nextDay) - 1]
            weekLines.append("\(lift(next)) \(weekday)")
        }

        var routineNames: [String] = []
        for routine in routines {
            let name = shown(routine.title)
            if !routineNames.contains(name) {
                routineNames.append(name)
            }
        }

        let plans = model.objects(of: .plan)
        var programLines: [String] = []
        if let plan {
            programLines.append(short(shown(plan.title)))
            let fixed = PlanSchedule.mode(of: plan, store: store) == .fixed
            programLines.append(fixed ? "Fixed days" : "Rolls on")
            if perWeek > 0 {
                programLines.append("\(perWeek) a week")
            }
        }

        let bests = lifts.compactMap { lift in lift.best.map { (lift.exercise.name, $0) } }.prefix(3)

        // Today (board r66): the routine and its lifts, the opening weight where one is known.
        var todayLabel: String?
        var todayLines: [String] = []
        var todayLiftIDs: [UUID?] = []
        switch day {
        case let .ready(name, _, count):
            todayLabel = name == ObjectPrivacy.routineLabel ? name : "\(short(name)), \(count) \(count == 1 ? "lift" : "lifts")"
            // The same source the day was read from: tonight's workout first, else the tried or planned routine.
            if name != ObjectPrivacy.routineLabel,
               let source = model.tonightWorkout(around: now) ?? model.triedRoutine() ?? model.todaysRoutine(now: now)
            {
                for slot in source.orderedChildren.filter({ !$0.isDeleted }).prefix(3) {
                    guard let exercise = store.linkedClass("exercise", of: slot) else { continue }
                    let weight = model.ledger.sessions(of: exercise).first?.sets.first?.weight ?? 0
                    todayLines
                        .append(weight > 0 ? "\(lift(exercise.name)) \(Format.mass(weight))" : lift(exercise.name))
                    todayLiftIDs.append(exercise.id)
                }
            }
        case let .running(name, done):
            todayLabel = "\(short(name)) under way"
            todayLines = [done > 0 ? "\(done) \(done == 1 ? "lift" : "lifts") done" : "Just started"]
        case let .done(name, next):
            todayLabel = "\(short(name)) done"
            todayLines = next.map { ["Next is \(short($0))"] } ?? []
        case let .rest(next, _):
            todayLabel = "Rest today"
            todayLines = next.map { ["Next is \(short($0))"] } ?? ["A rest day counts too"]
        case .nothing:
            todayLabel = "Nothing on the plan"
        }

        // Library: the exercises he can pick from, by kind.
        let groups = ExerciseLibraryList.groups(model).filter { !$0.exercises.isEmpty }
        let exerciseCount = groups.reduce(0) { $0 + $1.exercises.count }
        let libraryLabel = exerciseCount == 0 ? nil
            : "\(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises") in \(groups.count) \(groups.count == 1 ? "kind" : "kinds")"
        var libraryLines = Array(routineNames.prefix(1).map { $0 == ObjectPrivacy.routineLabel ? $0 : short($0) })
        libraryLines += groups.prefix(3 - libraryLines.count).map { short($0.pattern.name) }

        let first = calendar.weekdaySymbols[(calendar.firstWeekday - 1) % 7]
        let last = calendar.weekdaySymbols[(calendar.firstWeekday + 5) % 7]
        let doors = [
            DialDoor(id: "today", name: "Today", color: blue, label: todayLabel, lines: todayLines),
            DialDoor(id: "week", name: "This week", count: done > 0 ? "\(done)" : nil, color: blue,
                     label: "\(first) to \(last)", lines: weekLines),
            DialDoor(id: "library", name: "Library", count: exerciseCount > 0 ? "\(exerciseCount)" : nil, color: gold,
                     label: libraryLabel, lines: libraryLines),
            DialDoor(id: "bests", name: "Bests", color: gold, label: bests.isEmpty ? "None yet" : "Lately",
                     lines: bests.map { "\(lift($0.0)) \(Format.mass($0.1.weight))" }),
            DialDoor(id: "plan", name: "Plan", count: plans.count > 1 ? "\(plans.count)" : nil, color: slate,
                     label: plan.map { short(shown($0.title)) }, lines: Array(programLines.dropFirst())),
        ]
        return (doors, todayLiftIDs)
    }

    // MARK: Brief

    @MainActor
    private static func brief(_ model: AppModel, day: TrainingDay, lifts: [Lift], calendar _: Calendar)
        -> TrainingBrief?
    {
        switch day {
        case let .ready(name, _, _):
            // A private workout says nothing about what it works.
            guard name != ObjectPrivacy.routineLabel else {
                return TrainingBrief(before: "", name: name, after: " is ready when you are.")
            }
            if let opener = opener(model), !ObjectPrivacy.isPrivateWord(opener.name, in: model.store) {
                if let weight = opener.weight {
                    return TrainingBrief(name: opener.name, after: " opens at \(Format.mass(weight)).")
                }
                return TrainingBrief(name: opener.name, after: " comes first.")
            }
            return TrainingBrief(name: name, after: " is ready when you are.", split: TrainingSplit(name: name))
        case let .running(name, _):
            return TrainingBrief(name: name, after: " is waiting where you left it.", split: TrainingSplit(name: name))
        case let .rest(next, _):
            if let next {
                return TrainingBrief(before: "Next is ", name: next, after: ".", split: TrainingSplit(name: next))
            }
            return bestLine(lifts)
        case .done, .nothing:
            return bestLine(lifts)
        }
    }

    /// "Bench Press best 100 kg, Oct 12." from the newest lift with a best.
    private static func bestLine(_ lifts: [Lift]) -> TrainingBrief? {
        guard let lift = lifts.first(where: { $0.best != nil }), let best = lift.best else { return nil }
        let day = lift.last.formatted(.dateTime.month(.abbreviated).day())
        let when = lift.bestIsNewest ? ", \(day)" : ""
        return TrainingBrief(name: lift.exercise.name, after: " best \(Format.mass(best.weight))\(when).")
    }

    /// Today's first lift and the weight it opened at last time.
    @MainActor
    private static func opener(_ model: AppModel) -> (name: String, weight: Double?)? {
        let store = model.store
        let first: ObjectRecord? = if let workout = model.tonightWorkout() {
            workout.orderedChildren.first { !$0.isDeleted }
        } else {
            (model.triedRoutine() ?? model.todaysRoutine())?.orderedChildren.first { !$0.isDeleted }
        }
        guard let first, let exercise = store.linkedClass("exercise", of: first) else { return nil }
        let weight = model.ledger.sessions(of: exercise).first?.sets.first?.weight
        return (exercise.name, weight.flatMap { $0 > 0 ? $0 : nil })
    }
}

/// The foot's action as sheet 283 v3 draws it: the verb in the room color over its object in ink 2.
struct TrainingFoot: Equatable {
    let verb: String
    var object = ""
    /// A start needs a 500 ms hold.
    var hold = false
}
