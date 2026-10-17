import Foundation
@testable import TesseraCore
import Testing

/// Home's done-pack wall (board 0al): Research's home-pack-walls W1 to W16. A walled title or best name means no
/// pack, so no call; the rules line still shows.
@MainActor
struct HomeDonePackTests {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    static let ended = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 19, minute: 40))!

    static func done(_ title: String, bests: [String] = ["Bench"], sets: Int = 12,
                     sinceLastDays: Int? = nil) -> HomeFact
    {
        HomeFact(id: UUID(), kind: .workout, title: title, state: .done, sets: sets, exercisesDone: 4,
                 exercisesPlanned: 5, records: bests, sinceLastDays: sinceLastDays,
                 startedAt: ended.addingTimeInterval(-3600), endedAt: ended)
    }

    static func pack(_ fact: HomeFact, lastWeightKg: Double? = nil) -> Result<HomeDonePack, HomeDonePack.Skip> {
        HomeDonePack.build(fact, dayLabel: "Thursday night", calendar: calendar, lastWeightKg: lastWeightKg)
    }

    struct Row: Sendable, CustomStringConvertible {
        let id: String
        let title: String
        let bests: [String]
        var sets = 12
        var lastWeightKg: Double?
        let walled: Bool
        let hardFail: [String]

        var description: String {
            id
        }
    }

    nonisolated static let rows: [Row] = [
        Row(id: "W1", title: "Weigh in 182.4 lb", bests: ["Bench"], walled: true, hardFail: ["182.4"]),
        Row(id: "W2", title: "Push B", bests: ["Locker code 0000"], walled: true, hardFail: ["Locker code", "0000"]),
        Row(id: "W4", title: "Gym pin 1234 day", bests: ["Squat"], walled: true, hardFail: ["1234"]),
        Row(id: "W5", title: "Legs", bests: ["Pin press"], walled: true, hardFail: ["Pin press"]),
        Row(id: "W6", title: "Rent 1850 day", bests: ["Press"], walled: true, hardFail: ["1850"]),
        Row(id: "W7", title: "Push B $40 club", bests: ["Bench"], walled: true, hardFail: ["$40"]),
        Row(id: "W8", title: "Morning 82.2", bests: ["Row"], walled: true, hardFail: ["82.2"]),
        Row(id: "W8b", title: "Morning 82.2", bests: ["Row"], lastWeightKg: 82.2, walled: true, hardFail: ["82.2"]),
        Row(id: "W9", title: "Bench 182.4", bests: ["Bench"], walled: true, hardFail: ["182.4"]),
        Row(id: "W9b", title: "Push B", bests: ["Bench 182.4"], walled: true, hardFail: ["182.4"]),
        Row(id: "W12b", title: "Door code 4417", bests: ["Bench"], walled: true, hardFail: ["4417"]),
        Row(id: "W13", title: "Heart rate day 5x5", bests: ["Row"], walled: true, hardFail: ["heart rate day"]),
        Row(id: "W14", title: "Push B 5x5 80 for 8", bests: ["Bench"], walled: false, hardFail: []),
        Row(id: "W10", title: "Push B", bests: ["Press"], walled: false, hardFail: []),
    ]

    @Test(arguments: rows)
    func homeDonePackWallCoversFixturesW1ToW16(_ row: Row) {
        let result = Self.pack(Self.done(row.title, bests: row.bests, sets: row.sets), lastWeightKg: row.lastWeightKg)
        if row.walled {
            #expect(result == .failure(.walled), "\(row.id)")
        } else {
            #expect((try? result.get()) != nil, "\(row.id)")
        }
        let body = (try? result.get())?.json ?? ""
        for token in row.hardFail {
            #expect(!body.lowercased().contains(token.lowercased()), "\(row.id): \(token)")
        }
        // The rules line still shows whatever the wall says.
        let line = HomeLines.workoutText(for: Self.done(row.title, bests: row.bests), now: Self.ended,
                                         calendar: Self.calendar)
        #expect(line.hasPrefix("\(row.title) done."), "\(row.id)")
    }

    @Test func homeDonePackControlCaseSendsTitleAndBests() throws {
        // W10: the wall must not be over-eager; the pack is the title, the bests and counts only.
        let pack = try Self.pack(Self.done("Push B", bests: ["Press"], sinceLastDays: 3)).get()
        #expect(pack.json == #"{"bests":["Press"],"dayLabel":"Thursday night","finish":"7:40 pm","item":"h1","#
            + #""names":["Push B","Press"],"numbers":[1,3,4,5,7,12,40],"rules":"Push B done. Press best.","#
            + #""sinceLastDays":3,"title":"Push B"}"#, "\(pack.json)")
    }

    @Test func aPassingTitleLicensesNoNumbersOfItsOwn() throws {
        // W14: the title may carry its notation; `numbers` is the counts and the clock, never 5, 80 or 8 from it.
        let pack = try Self.pack(Self.done("Push B 5x5 80 for 8", bests: ["Bench"])).get()
        #expect(pack.json.contains("Push B 5x5 80 for 8"))
        #expect(!pack.numbers.contains(80) && !pack.numbers.contains(8) && pack.numbers.contains(40))
    }

    @Test func homeDonePackSkipsBeforeWallWhenWorkoutHasNoSets() {
        // W12a: no sets is skipped before the wall runs.
        #expect(Self.pack(Self.done("Door code 4417", bests: [], sets: 0)) == .failure(.noSets))
        #expect(Self.pack(Self.done("Push B", bests: [], sinceLastDays: 2)) == .failure(.nothingToAdd))
        #expect((try? Self.pack(Self.done("Push B", bests: [], sinceLastDays: 4)).get()) != nil)
    }

    @Test func aKeyShapedTitleIsNeverPacked() {
        // W15: built from pieces, never a literal.
        let key = "sk" + "-" + "ant" + "-" + "TESTFAKE" + String(repeating: "x", count: 20)
        #expect(Self.pack(Self.done("Push \(key)")) == .failure(.walled))
        #expect(Self.pack(Self.done("Push B", bests: [key])) == .failure(.walled))
    }

    @Test func homeDonePackNeverIncludesWorkoutNote() throws {
        // W3, W11: a done workout's notes are not a fact; the pack has no field for them.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let (workout, summary) = try finish(routineTitle: nil, engine: engine, store: store, classes: classes)
        for note in ["wifi is tacocat", "sick, bp 120/80"] {
            try store.set("notes", to: .richText(note), on: workout)
            let fact = HomeFacts(engine: engine, calendar: Self.calendar).fact(done: summary)
            let body = (try? Self.pack(fact).get())?.json ?? ""
            #expect(!body.contains("tacocat") && !body.contains("120/80") && !body.contains("sick"))
        }
    }

    @Test func renameObjectOnRoutineStillReachesPackWallWhenSourceUnwalled() throws {
        // W16: renamed after it was made clean (RenameObject is exempt at the engine); the pack wall still holds.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let (_, summary) = try finish(routineTitle: "Gym pin 1234 day", engine: engine, store: store, classes: classes)
        let fact = HomeFacts(engine: engine, calendar: Self.calendar).fact(done: summary)
        #expect(fact.title.contains("1234"))
        // A first session has no best to beat, so give it one: the wall, not the gate, must stop it.
        #expect(Self.pack(Self.done(fact.title, bests: ["Squat"])) == .failure(.walled))
    }

    /// Starts and finishes the starter plan's first routine with one set; renames the routine first when asked.
    func finish(routineTitle: String?, engine: ActionEngine, store: ObjectStore,
                classes: [SystemCatalog.Key: ClassDef]) throws -> (ObjectRecord, WorkoutSummary)
    {
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        if let routineTitle {
            try engine.perform(RenameObject(object: routine.id, title: routineTitle), by: .user)
        }
        let start = Self.ended.addingTimeInterval(-3600)
        let workout = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 5, time: start), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: Self.ended), by: .user)
        let ledger = TrainingLedger(store: store, classes: classes)
        let summary = try #require(ledger.finishedWorkouts(on: Self.ended, calendar: Self.calendar).first)
        return (workout, summary)
    }
}
