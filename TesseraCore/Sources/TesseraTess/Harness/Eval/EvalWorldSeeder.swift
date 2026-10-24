import Foundation
import TesseraCore

/// Writes an `EvalWorld` into a store through the app's own actions (test-world.md part 1), `by: .system`, so the
/// rows look like real use and the op log has every one of them. Each action gets the world's own time, so nothing
/// needs the clock moved.
///
/// Walls: it refuses a store that holds anything he made (any workout, cook, spend, money in, note, belief, memory
/// line or occasion), so it can never mix into his data. The caller stamps the store as a test store (Core's part 2)
/// and never seeds the app's real store file.
///
/// Not seeded yet, and named in the report: leftovers (no class yet) and the Pulldown rename (`RenameObject` renames
/// objects, not exercise classes; the world logs "Lat Pulldown" throughout). Told lines carry the seed's time, since
/// `RememberFact` takes none.
@MainActor
public enum EvalWorldSeeder {
    public enum Refusal: Error, Equatable {
        /// The store already holds rows of this class.
        case storeHasData(String)
    }

    public struct Report: Sendable, Equatable {
        /// Rows written, by room.
        public var written: [String: Int] = [:]
        /// Actions that refused, by room, with the first reason.
        public var refused: [String: Int] = [:]
        public var firstRefusal: [String: String] = [:]
        public var notSeeded: [String] = ["leftovers", "renames"]
    }

    /// The classes whose rows mean someone already uses the store.
    static let hisClasses: [SystemCatalog.Key] = [.workout, .cook, .spend, .inflow, .note, .belief, .tessMemory,
                                                  .occasion]

    public static func seed(_ world: EvalWorld, into engine: ActionEngine) throws -> Report {
        let store = engine.store
        for key in hisClasses {
            if let classDef = engine.classes[key], store.objects(of: classDef).contains(where: { !$0.isDeleted }) {
                throw Refusal.storeHasData(key.rawValue)
            }
        }
        var seeder = Seeder(engine: engine, world: world)
        seeder.training()
        seeder.kitchen()
        seeder.money()
        seeder.notes()
        seeder.chores()
        seeder.body()
        seeder.events()
        seeder.memory()
        store.save()
        return seeder.report
    }
}

@MainActor
private struct Seeder {
    let engine: ActionEngine
    let world: EvalWorld
    var report = EvalWorldSeeder.Report()

    var store: ObjectStore {
        engine.store
    }

    var classes: [SystemCatalog.Key: ClassDef] {
        engine.classes
    }

    var calendar: Calendar {
        EvalWorld.calendar
    }

    /// Runs one action; a refusal is counted against its room and the seed goes on.
    @discardableResult
    mutating func perform<A: EngineAction>(_ action: A, room: String) -> ActionEngine.Result<A.Output>? {
        do {
            let result = try engine.perform(action, by: .system)
            report.written[room, default: 0] += 1
            return result
        } catch {
            report.refused[room, default: 0] += 1
            if report.firstRefusal[room] == nil {
                report.firstRefusal[room] = "\(A.descriptor.name): \(error)"
            }
            return nil
        }
    }

    // MARK: Training

    mutating func training() {
        let exercises: [ClassDef] = store.exerciseGroups(root: classes[.exercise]).flatMap(\.exercises)
        var byName: [String: ClassDef] = [:]
        for exercise in exercises where byName[exercise.name] == nil {
            byName[exercise.name] = exercise
        }

        // Routines with their slots, in the order each first appears.
        var routines: [String: ObjectRecord] = [:]
        for workout in world.workouts where routines[workout.routine] == nil {
            guard let routine = perform(CreateRoutine(title: workout.routine), room: "training")?.output else {
                continue
            }
            var slotted: [String] = []
            for lift in workout.sets where !slotted.contains(lift.exercise) {
                slotted.append(lift.exercise)
            }
            for name in slotted {
                guard let exercise = byName[name] else { continue }
                let sets = Double(workout.sets.filter { $0.exercise == name }.count)
                perform(AddSlot(routine: routine.id, exercise: exercise.id, sets: sets), room: "training")
            }
            routines[workout.routine] = routine
        }

        // A plan per phase: upper and lower until Sep 1, then push, pull and legs.
        let phases: [(title: String, names: [String])] = [
            ("Upper Lower", ["Upper Day", "Lower Day"]), ("Push Pull Legs", ["Push Day", "Pull Day", "Leg Day"]),
        ]
        for phase in phases {
            let ids: [UUID] = phase.names.compactMap { routines[$0]?.id }
            let first: Date? = world.workouts.filter { phase.names.contains($0.routine) }.map(\.start).min()
            if !ids.isEmpty, let first {
                perform(CreatePlan(title: phase.title, routines: ids, startsOn: first), room: "training")
            }
        }

        for workout in world.workouts {
            guard let routine = routines[workout.routine],
                  let started = perform(StartRoutine(routine: routine.id, time: workout.start), room: "training")?
                  .output
            else { continue }
            var time = workout.start
            for lift in workout.sets {
                guard let exercise = byName[lift.exercise], let entry = entry(for: exercise, in: started) else {
                    continue
                }
                time = time.addingTimeInterval(150)
                perform(LogSet(entry: entry.id, weight: lift.weight, reps: Double(lift.reps), time: time),
                        room: "training")
            }
            perform(FinishWorkout(workout: started.id, time: time.addingTimeInterval(300)), room: "training")
            if workout.isDeleted {
                perform(DeleteObject(object: started.id), room: "training")
            }
        }
    }

    /// The workout's entry for an exercise, added when its routine had no slot for it.
    mutating func entry(for exercise: ClassDef, in workout: ObjectRecord) -> ObjectRecord? {
        let existing = workout.orderedChildren.first { child in
            !child.isDeleted && store.linkedClass("exercise", of: child)?.id == exercise.id
        }
        if let existing {
            return existing
        }
        return perform(AddExercise(workout: workout.id, exercise: exercise.id), room: "training")?.output
    }

    // MARK: Kitchen

    mutating func kitchen() {
        var recipes: [String: ObjectRecord] = [:]
        for name in world.recipes {
            let text = """
            \(name)
            Serves 4
            1 tbsp olive oil
            1 tsp kosher salt
            2 cups water
            Method
            1. Heat the oil in a large pot.
            2. Cook the \(name.lowercased()) for 30 minutes, then season with the salt.
            """
            if let recipe = perform(CreateRecipe(text: text, title: name), room: "kitchen")?.output {
                recipes[name] = recipe
            }
        }
        for cook in world.cooks {
            guard let recipe = recipes[cook.recipe],
                  let made = perform(StartCooking(recipe: recipe.id, time: cook.day), room: "kitchen")?.output
            else { continue }
            perform(FinishCooking(cook: made.id, time: cook.day.addingTimeInterval(40 * 60)), room: "kitchen")
        }
    }

    // MARK: Money

    mutating func money() {
        var pools: [String: UUID] = [:]
        for spend in world.spends {
            let key = "\(spend.category)|\(spend.currency)"
            if pools[key] == nil {
                let name = spend.currency == "USD" ? spend.category.capitalized
                    : "\(spend.category.capitalized) \(spend.currency)"
                pools[key] = perform(CreatePool(name: name, currency: spend.currency, kind: "account"),
                                     room: "money")?.output.id
            }
            let amount = Double(spend.cents) / 100
            guard let logged = perform(LogSpend(amount: amount, currency: spend.currency, note: spend.note,
                                                spentAt: spend.at, pool: pools[key], autoPool: false),
                                       room: "money")
            else { continue }
            if spend.isReversed {
                // His Undo, as the app does it: the spend reads "Reversed".
                if engine.undo(logged.record) == .nothingToDo {
                    report.refused["money", default: 0] += 1
                }
            }
        }
        for inflow in world.inflows {
            let amount = String(format: "%.2f", Double(inflow.cents) / 100)
            perform(LogInflow(amount: amount, currency: "USD", source: "paycheck", note: inflow.note, at: inflow.at),
                    room: "money")
        }
    }

    // MARK: Notes

    mutating func notes() {
        for note in world.notes {
            var body = note.body
            for title in note.links where !body.contains("@\(title)") {
                body += " @\(title)"
            }
            perform(CreateNote(body: body, on: note.at, isPrivate: note.isPrivate ? true : nil), room: "notes")
        }
    }

    // MARK: Chores and habits

    /// Each time a chore or habit was done is a task done at that time.
    mutating func chores() {
        for chore in world.chores {
            for day in chore.done {
                taskDone(chore.title, at: day)
            }
        }
        for habit in world.habits {
            for day in habit.done {
                taskDone(habit.name, at: day)
            }
        }
    }

    mutating func taskDone(_ title: String, at start: Date) {
        guard let task = perform(CreateTask(title: title, startsAt: start, minutes: 20), room: "today")?.output else {
            return
        }
        perform(SetTaskDone(task: task.id, time: start.addingTimeInterval(20 * 60)), room: "today")
    }

    // MARK: Body

    /// Sleep through the Health sync, one night at a time; a weigh-in is a private note, as the app keeps one today.
    mutating func body() {
        for night in world.nights {
            let wake = calendar.date(byAdding: .hour, value: 7, to: calendar.startOfDay(for: night.day)) ?? night.day
            let sample = SleepSample(value: .asleepUnspecified, start: wake.addingTimeInterval(-night.hours * 3600),
                                     end: wake)
            perform(SyncHealth(inputs: HealthInputs(sleep: [sample]), now: wake.addingTimeInterval(3600),
                               zone: "America/Los_Angeles"), room: "body")
        }
        for weighIn in world.weighIns {
            perform(CreateNote(body: "\(MemoryEval.plain(weighIn.kg)) kg this morning", on: weighIn.at,
                               isPrivate: true), room: "body")
        }
    }

    // MARK: Calendar

    mutating func events() {
        for event in world.events {
            perform(CreateOccasion(title: event.title, start: event.start,
                                   end: event.start.addingTimeInterval(Double(event.minutes) * 60)), room: "calendar")
        }
    }

    // MARK: Tess's memory

    /// Told lines through `RememberFact`, the forgotten one through the real forget; beliefs with their windows, each
    /// resting on the told line it came from.
    mutating func memory() {
        // Each belief rests on the line he told it in, which has the same time.
        var lineAt: [Date: UUID] = [:]
        for told in world.told {
            guard let line = perform(RememberFact(text: told.text), room: "memory")?.output else { continue }
            if told.forgotten != nil {
                perform(ForgetMemory(memory: line.id), room: "memory")
            } else {
                lineAt[told.at] = line.id
            }
        }
        var open: [String: UUID] = [:]
        for belief in world.beliefs.sorted(by: { $0.from < $1.from }) {
            let (key, value, words) = Self.belief(belief)
            let backing: [UUID] = lineAt[belief.from].map { [$0] } ?? []
            if let previous = open[belief.key] {
                let revised = perform(ReviseBelief(belief: previous, words: words, value: value, evidence: backing,
                                                   at: belief.from), room: "memory")
                open[belief.key] = revised?.output.id
            } else {
                let subject: UUID? = key == .usualTime ? classes[.workout]?.id : nil
                let made = perform(RecordBelief(words: words, key: key, source: .told, value: value,
                                                subjectClass: subject, evidence: backing, validFrom: belief.from),
                                   room: "memory")
                open[belief.key] = made?.output.id
            }
        }
    }

    /// The world's belief rows as typed beliefs.
    static func belief(_ belief: EvalWorld.Belief) -> (TessBelief.Key, String, String) {
        switch (belief.key, belief.value) {
        case ("trainTime", "6 am"): (.usualTime, "{\"hour\":6}", "You train at 6 am, before work.")
        case ("trainTime", _): (.usualTime, "{\"hour\":18.5}", "You train in the evening, after work.")
        case ("coffeeMilk", _): (.prefers, "{\"text\":\"\(belief.value)\"}", "You take \(belief.value) in your coffee.")
        case ("benchGoal", _): (.goal, "{\"text\":\"\(belief.value) bench\"}", "Your goal is a \(belief.value) bench.")
        default: (.fact, "{\"text\":\"\(belief.value)\"}", belief.value)
        }
    }
}
