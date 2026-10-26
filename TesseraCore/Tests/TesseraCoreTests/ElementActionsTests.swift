import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The six actions behind Tess's element calls (docs/ai/harness/element-actions.md).
@MainActor
struct ElementActionsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { TimeZone(identifier: "America/Los_Angeles")! }
        engine.now = { Date(timeIntervalSince1970: 1_792_000_000) }
    }

    func routine(_ title: String) throws -> ObjectRecord {
        try engine.perform(CreateRoutine(title: title), by: .user).output
    }

    // MARK: pinNote

    @Test func pinningToggleAndPrivateNotesStayPrivate() throws {
        let note = try engine.perform(CreateNote(body: "Trip packing"), by: .user).output
        let pin = try engine.perform(SetPinned(object: note.id), by: .tess)
        #expect(store.value("pinned", of: note) == .bool(true) && store.value("pinnedAt", of: note) != nil)
        #expect(pin.record.receipt == "Trip packing, pinned.")
        let unpin = try engine.perform(SetPinned(object: note.id), by: .tess)
        #expect(unpin.record.receipt == "Trip packing, unpinned." && store.value("pinnedAt", of: note) == nil)
        engine.undo(unpin.record)
        #expect(store.value("pinned", of: note) == .bool(true))
        // A list can be pinned; a task cannot.
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(SetPinned(object: list.id, pinned: true), by: .user)
        #expect(store.value("pinned", of: list) == .bool(true))
        let task = try engine.perform(CreateTask(title: "Call the bank"), by: .user).output
        #expect(throws: ActionError.self) { try engine.perform(SetPinned(object: task.id), by: .user) }
        // A private note is pinned and still read as "Private note".
        let secret = try engine.perform(CreateNote(body: "my PIN is 0420 do not tell"), by: .user).output
        let said = try engine.perform(SetPinned(object: secret.id, pinned: true), by: .tess)
        #expect(said.record.receipt?.contains("0420") == false)
    }

    // MARK: rainAlert

    @Test func theRainAlertIsOnOffAndHasALead() throws {
        let on = try engine.perform(SetRainAlert(), by: .tess)
        #expect(on.record.receipt == "You'll hear 30 minutes before rain.")
        let settings = SettingsStore(engine: engine).read()
        #expect(settings.rainAlert == true && settings.rainAlertMinutes == 30)
        let hour = try engine.perform(SetRainAlert(on: true, leadMinutes: 60), by: .tess)
        #expect(hour.record.receipt == "You'll hear an hour before rain.")
        #expect(SettingsStore(engine: engine).read().rainAlertMinutes == 60)
        let off = try engine.perform(SetRainAlert(on: false), by: .tess)
        #expect(off.record.receipt == "Rain alert off." && SettingsStore(engine: engine).read().rainAlert == false)
        engine.undo(off.record)
        #expect(SettingsStore(engine: engine).read().rainAlert == true)
        // The lead stays inside 5 minutes to a day.
        try engine.perform(SetRainAlert(leadMinutes: 1), by: .user)
        #expect(SettingsStore(engine: engine).read().rainAlertMinutes == 5)
        // Other settings are not touched by a write of settings.
        try SettingsStore(engine: engine).update { $0.restWeekday = 3 }
        #expect(SettingsStore(engine: engine).read().rainAlert == true)
    }

    // MARK: restDay

    @Test func restTodayRefusesAGoingWorkoutAndMarksTheRest() throws {
        let book = RestBook(store: store, classes: classes)
        let rest = try engine.perform(TakeRest(scope: .training, from: at(20), until: at(20)), by: .tess)
        #expect(rest.record.receipt?.hasPrefix("Rest today.") == true)
        #expect(book.isTrainingRest(on: at(20, 18), calendar: calendar))
        #expect(!book.isTrainingRest(on: at(21), calendar: calendar))
        // Again the same day changes nothing: the same row.
        let again = try engine.perform(TakeRest(scope: .training, from: at(20), until: at(20)), by: .tess)
        #expect(again.output.id == rest.output.id)
        // A workout going refuses.
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(StartRoutine(routine: routine.id, time: at(22)), by: .user)
        let error = #expect(throws: ActionError.self) {
            try engine.perform(TakeRest(scope: .training, from: at(22), until: at(22)), by: .tess)
        }
        #expect(error.flatMap(TakeRest.refusalLine) == "A workout is already going.")
    }

    @Test func aRestTodayMakesTheLedgerReadARestDay() throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let ledger = TrainingLedger(store: store, classes: classes)
        let day = at(20)
        let before = ledger.restDay(plan: plan, now: day, calendar: calendar)
        try engine.perform(TakeRest(scope: .training, from: day, until: day), by: .user)
        let after = try #require(ledger.restDay(plan: plan, now: day, calendar: calendar))
        // On a day that already read as a rest day nothing changes; on a training day it now reads as one.
        #expect(before == nil || before?.next.id == after.next.id)
        #expect(after.next.id == ledger.nextRoutine(in: plan, now: day, calendar: calendar)?.id)
    }

    // MARK: tend, plant, pause

    @Test func tendingOnceADayEndsAPauseAndTheLedgerNeverSeesIt() throws {
        let journal = try routine("Journal")
        let book = RestBook(store: store, classes: classes)
        let pause = try engine.perform(TakeRest(scope: .routine, routine: journal.id, from: at(20)), by: .tess)
        #expect(pause.record.receipt == "Journal, resting.")
        #expect(book.pause(of: journal.id, on: at(23), calendar: calendar) != nil)
        let tend = try engine.perform(TendRoutine(routine: journal.id, at: at(23)), by: .tess)
        #expect(tend.output && tend.record.receipt == "Journal, done for today.")
        #expect(book.tendedDays(of: journal.id, calendar: calendar).count == 1)
        #expect(book.pause(of: journal.id, on: at(23), calendar: calendar) == nil)
        // The second tend the same day writes nothing.
        let second = try engine.perform(TendRoutine(routine: journal.id, at: at(23, 20)), by: .tess)
        #expect(!second.output && second.record.receipt == "Journal is done for today.")
        #expect(book.tendedDays(of: journal.id, calendar: calendar).count == 1)
        // A run is not a workout.
        let ledger = TrainingLedger(store: store, classes: classes)
        #expect(try ledger.sessions(of: #require(classes[.benchPress])).isEmpty)
    }

    @Test func plantingPicksTheGroveFromTheNameAndTheCadenceFromTheWords() throws {
        let cases: [(String, String)] = [("Journal", "mind"), ("Stretch", "body"), ("Tidy the desk", "home"),
                                         ("Water plants", "home"), ("Something odd", "body")]
        for (name, grove) in cases {
            let made = try engine.perform(PlantRoutine(name: name), by: .tess)
            #expect(store.value("grove", of: made.output) == .choice(grove), "\(name)")
            #expect(store.value("cadence", of: made.output) == .choice("day"))
            #expect(made.record.receipt == "\(name), planted.")
        }
        let twice = try engine.perform(PlantRoutine(name: "Swim", cadence: "day", weekdays: "5, 2, 2"), by: .tess)
        #expect(store.value("fixedWeekdays", of: twice.output) == .text("2,5"))
        #expect(store.value("cadence", of: twice.output) == .choice("week"))
        #expect(throws: ActionError.self) { try engine.perform(PlantRoutine(name: "  "), by: .tess) }
    }

    @Test func aPrivateRoutineNameIsPlantedAsPrivateRoutine() throws {
        let made = try engine.perform(PlantRoutine(name: "weigh in at 82 kg"), by: .tess)
        // The real name stays on the device; the shown label and the receipt say "Private routine".
        #expect(made.output.title == "weigh in at 82 kg" && made.record.receipt == "Private routine, planted.")
    }

    @Test func aSessionPlannedForTodayRefusesTheRestInHisWords() throws {
        let workout = try store.create(#require(classes[.workout]), title: "Push A")
        try store.set("scheduledFor", to: .date(at(24)), on: workout)
        let error = #expect(throws: ActionError.self) {
            try engine.perform(TakeRest(scope: .training, from: at(24, 9), until: at(24, 9)), by: .tess)
        }
        #expect(error.flatMap(TakeRest.refusalLine) == "There's a session planned today.")
        // Through the tool, that line is what he hears.
        let spoken = #expect(throws: TessToolError.self) {
            try TessTools.run("restDay", arguments: Data("{}".utf8), engine: engine, now: at(24, 9), calendar: calendar)
        }
        #expect(spoken?.description == "There's a session planned today.")
    }

    @Test func anErrorWithNoSpokenLineIsNeverSpokenRaw() throws {
        try engine.perform(SetRainAlert(on: false), by: .user)
        let settings = try #require(store.object(id: SettingsStore.objectID))
        store.softDelete(settings)
        let spoken = #expect(throws: TessToolError.self) {
            try TessTools.run("rainAlert", arguments: Data(#"{"on":true,"leadMinutes":null}"#.utf8), engine: engine)
        }
        #expect(spoken?.description == "That didn't work.")
    }

    @Test func anIdOfTheWrongClassIsNoNoteOrList() throws {
        let journal = try routine("Journal")
        let spoken = #expect(throws: TessToolError.self) {
            try TessTools.run("pinNote", arguments: Data(#"{"note":"\#(journal.id.uuidString)","pinned":null}"#.utf8),
                              engine: engine)
        }
        #expect(spoken != nil)
        #expect(store.value("pinned", of: journal) == nil)
    }

    @Test func pausingForDaysEndsByItselfAndResumeEndsItEarly() throws {
        let journal = try routine("Journal")
        let book = RestBook(store: store, classes: classes)
        let week = try engine.perform(TakeRest(scope: .routine, routine: journal.id, from: at(20), until: at(26)),
                                      by: .tess)
        #expect(week.record.receipt == "Journal, resting until Monday.")
        #expect(book.pause(of: journal.id, on: at(26, 23), calendar: calendar) != nil)
        #expect(book.pause(of: journal.id, on: at(27), calendar: calendar) == nil)
        let resumed = try engine.perform(ResumeRoutine(routine: journal.id, at: at(22)), by: .tess)
        _ = resumed
        #expect(throws: ActionError.self) {
            try engine.perform(ResumeRoutine(routine: journal.id, at: at(22)), by: .tess)
        }
    }

    // MARK: Tools

    @Test func theSixToolsExistAndTheProposedListIsEmpty() throws {
        for name in ["pinNote", "rainAlert", "restDay", "tendRoutine", "plantRoutine", "pauseRoutine"] {
            #expect(TessTools.tool(named: name) != nil, "\(name)")
        }
        #expect(ElementCatalog.proposed.isEmpty)
        let note = try engine.perform(CreateNote(body: "Trip packing"), by: .user).output
        let records = try TessTools.run("pinNote", arguments: Data(#"{"note":"trip packing","pinned":null}"#.utf8),
                                        engine: engine)
        #expect(records.count == 1 && store.value("pinned", of: note) == .bool(true))
        let journal = try routine("Journal")
        _ = try TessTools.run("pauseRoutine", arguments: Data(#"{"routine":"journal","days":7,"resume":null}"#.utf8),
                              engine: engine, now: at(20), calendar: calendar)
        let pause = try #require(RestBook(store: store, classes: classes).pause(
            of: journal.id,
            on: at(20),
            calendar: calendar
        ))
        // Seven days is today plus six.
        #expect(store.value("until", of: pause)?.dateValue == TesseraDay(calendar: calendar).start(of: at(26)))
        _ = try TessTools.run("pauseRoutine", arguments: Data(#"{"routine":"journal","days":null,"resume":true}"#.utf8),
                              engine: engine, now: at(21), calendar: calendar)
        #expect(RestBook(store: store, classes: classes).pause(of: journal.id, on: at(21), calendar: calendar) == nil)
    }

    /// The strict scan reads every tool's name, description and schema words; none of them may trip it.
    @Test func noToolTextTripsTheStrictScan() throws {
        let lastKg = BodyWeight.lastKg(in: store)
        for tool in TessTools.claudeTools {
            var texts = [tool.name, tool.description]
            try texts += Door.jsonStrings(Data(JSONSerialization.data(withJSONObject: tool.input.json)))
            for text in texts {
                #expect(!SecretWords.mentions(text), "\(tool.name): \(text)")
                #expect(!PrivateFacts.isWalled(text, lastWeightKg: lastKg), "\(tool.name): \(text)")
                #expect(!PrivateFacts.isCalorieShaped(text), "\(tool.name): \(text)")
                #expect(!looksLikeClaudeKey(text), "\(tool.name): \(text)")
            }
        }
    }

    @Test func everyActionDecodesFromItsName() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let id = UUID()
        func check<A: EngineAction>(_ action: A) throws {
            let decoded = try ActionRegistry.decode(name: A.descriptor.name, arguments: encoder.encode(action))
            #expect(decoded is A, "\(A.descriptor.name)")
        }
        try check(SetPinned(object: id))
        try check(SetRainAlert())
        try check(TakeRest(scope: .training))
        try check(ResumeRoutine(routine: id))
        try check(TendRoutine(routine: id))
        try check(PlantRoutine(name: "Journal"))
    }
}
