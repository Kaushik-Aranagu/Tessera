import AppIntents
import Foundation
import FoundationModels
@testable import TesseraCore
@testable import TesseraIntents
@testable import TesseraTess
import Testing

@MainActor
struct TessTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine
    let tess: TessCaptureEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    /// Wednesday 14 October 2026, 18:00 London.
    let now = Date(timeIntervalSince1970: 1_791_997_200)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        tess = TessCaptureEngine(engine: engine)
        // A few user exercises, as the library will provide.
        for (name, parent) in [("Overhead Press", SystemCatalog.Key.barbellLift), ("Romanian Deadlift", .barbellLift),
                               ("Incline Dumbbell Press", .strengthExercise)]
        {
            container.mainContext.insert(ClassDef(name: name, parent: classes[parent]))
        }
    }

    func context(entry: ObjectRecord? = nil) -> TessContext {
        TessContext(now: now, calendar: calendar, entry: entry?.id)
    }

    // MARK: Grammar

    @Test func gymShorthandParses() {
        let grammar = TessGrammar(store: store, classes: classes)
        func lift(_ phrase: String) -> String? {
            guard case let .lift(exercise, sets, reps, weight, unit)? = grammar.parse(phrase, context: context())
            else { return nil }
            let suffix = unit == .kilograms ? "" : unit.symbol
            return "\(exercise.name) \(sets)x\(TessVoice.number(reps))@\(TessVoice.number(weight))\(suffix)"
        }
        #expect(lift("3x10 bench 80") == "Bench Press 3x10@80")
        #expect(lift("bench 80x8") == "Bench Press 1x8@80")
        #expect(lift("Bench 80 x 8") == "Bench Press 1x8@80")
        #expect(lift("bench 82.5 for 6") == "Bench Press 1x6@82.5")
        #expect(lift("ohp 3x8 at 45") == "Overhead Press 3x8@45")
        #expect(lift("RDL 100 × 8") == "Romanian Deadlift 1x8@100")
        #expect(lift("incline press 3x10 30") == "Incline Dumbbell Press 3x10@30")
        #expect(lift("bench 180lbs x 5") == "Bench Press 1x5@180lb")
        #expect(lift("ohp 3x5 95 lb") == "Overhead Press 3x5@95lb")
        #expect(lift("bench") == nil)
        #expect(lift("teleport 80x8") == nil)
        #expect(grammar.parse("asdf qwer", context: context()) == nil)
    }

    @Test func relativePhrasesUseTheEntryInFocus() throws {
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let grammar = TessGrammar(store: store, classes: classes)
        func set(_ phrase: String) -> String? {
            guard case let .set(_, weight, reps, kind, how, _, _, _)? = grammar.parse(
                phrase,
                context: context(entry: entry)
            )
            else { return nil }
            return "\(TessVoice.number(weight))x\(TessVoice.number(reps)) \(kind) \(how)"
        }
        #expect(set("same") == "80x8 working same")
        #expect(set("Same again") == "80x8 working same")
        #expect(set("7") == "80x7 working repsOnly")
        #expect(set("82.5 x 6") == "82.5x6 working full")
        #expect(set("drop to 70 for 10") == "70x10 drop drop")
        // Naming the same exercise also lands in the entry in focus.
        #expect(set("bench 85 x 5") == "85x5 working full")
    }

    @Test func datedTasksParse() throws {
        let grammar = TessGrammar(store: store, classes: classes)
        func task(_ phrase: String) -> (String, Date?)? {
            guard case let .task(title, date)? = grammar.parse(phrase, context: context()) else { return nil }
            return (title, date)
        }
        let dentist = try #require(task("dentist thu 3pm"))
        #expect(dentist.0 == "Dentist")
        #expect(dentist.1.map { calendar.dateComponents([.weekday, .hour, .minute], from: $0) } ==
            DateComponents(hour: 15, minute: 0, weekday: 5))
        let call = try #require(task("call mum tomorrow at 9:30am"))
        #expect(call.0 == "Call mum")
        #expect(call.1.map { calendar.component(.day, from: $0) } == 15)
        #expect(call.1.map { calendar.component(.minute, from: $0) } == 30)
        // 5pm has passed at 18:00, so "5pm" with no day means tomorrow.
        #expect(task("stretch 5pm")?.1.map { calendar.component(.day, from: $0) } == 15)
        #expect(task("todo buy chalk")?.0 == "Buy chalk")
        #expect(task("todo buy chalk")?.1 == nil)
        #expect(task("remind me to book physio")?.0 == "Book physio")
        #expect(task("buy chalk") == nil) // no cue: the model decides
    }

    // MARK: Capture

    @Test func captureLogsAPendingGhostAndSpeaksInTessVoice() async throws {
        let capture = await tess.capture("3x10 bench 80", context: context())
        #expect(capture.source == .grammar)
        #expect(capture.line == "Bench 3 × 10 at 80. Added to today.")
        #expect(TessVoice.violations(in: capture.line).isEmpty)
        let record = try #require(capture.records.first)
        #expect(record.state == .pending && record.actor == .tess)
        let workouts = try store.objects(of: #require(classes[.workout]))
        #expect(workouts.first?.orderedChildren.first?.orderedChildren.count == 3)
        #expect(try engine.isPending(#require(workouts.first).id))

        // Dismissing the ghost removes everything it created.
        try engine.discard(record)
        #expect(try store.objects(of: #require(classes[.workout])).isEmpty)
    }

    @Test func captureLinesForSetsAndTasks() async throws {
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        var lines = await [
            tess.capture("same", context: context(entry: entry)).line,
            tess.capture("7", context: context(entry: entry)).line,
            tess.capture("drop to 70 for 10", context: context(entry: entry)).line,
            tess.capture("dentist thu 3pm", context: context()).line, // it is Wednesday
        ]
        #expect(lines == [
            "Set 2 logged, same again.", "Set 3 logged. 80 × 7.", "Drop set logged. 70 × 10.",
            "Dentist, tomorrow 3 pm.",
        ])
        await lines.append(tess.capture("blorp", context: context()).line)
        #expect(lines.last?.hasPrefix("Didn't catch that.") == true)
        #expect(lines.allSatisfy { TessVoice.violations(in: $0).isEmpty })
        #expect(entry.orderedChildren.count == 4)
    }

    @Test func invalidCapturesWriteNothing() async throws {
        let capture = await tess.capture("bench 80x0", context: context())
        #expect(!capture.understood)
        #expect(try store.objects(of: #require(classes[.workout])).isEmpty)
    }

    @Test func shortcutsCommitImmediately() async {
        var shortcut = context()
        shortcut.commitImmediately = true
        let capture = await tess.capture("bench 80x8", context: shortcut)
        #expect(capture.records.first?.state == .committed)
    }

    @Test func theModelStepRunsOnlyWhenTheGrammarCant() async {
        final class FakeModel: TessModelCapturing {
            var phrases: [String] = []
            var isAvailable: Bool {
                true
            }

            func capture(_ phrase: String, context _: TessContext, engine _: ActionEngine) async -> TessCapture {
                phrases.append(phrase)
                return TessCapture(records: [], line: "Didn't catch that.", source: .none)
            }
        }
        let model = FakeModel()
        tess.model = model
        _ = await tess.capture("bench 80x8", context: context())
        _ = await tess.capture("ring the gym about chalk", context: context())
        #expect(model.phrases == ["ring the gym about chalk"])
    }

    // MARK: Voice

    @Test func voiceChecksCatchOffToneLines() {
        #expect(TessVoice.violations(in: "Logged 80 x 8.").isEmpty)
        #expect(!TessVoice.violations(in: "Awesome! You crushed it!").isEmpty)
        #expect(!TessVoice.violations(in: "You missed Pull Day again").isEmpty)
        #expect(!TessVoice.violations(in: "This line has far too many words in it to be one of Tess's lines.").isEmpty)
        #expect(TessVoice.instructions(today: "Wed", currentWorkout: "none", lastSet: "none")
            .contains("Act only through"))
    }

    // MARK: One registry, three faces

    @Test func everyModelToolHasAValidSchema() throws {
        let names = TessTools.all.map(\.name)
        #expect(Set(names).isSuperset(of: ["logSet", "createTask", "addGroceries"]))
        #expect(!names.contains("deleteObject") && !names.contains("rollForwardTasks"))
        for tool in TessTools.all {
            _ = try GenerationSchemaCheck.make(tool)
        }
    }

    @Test func modelToolCallsResolveNamesAndRunAsPendingTess() async throws {
        let recorder = TessToolRecorder()
        let tool = try CatalogTool(tool: #require(TessTools.tool(named: "logSet")), engine: engine, pending: true,
                                   now: .now, calendar: .current, recorder: recorder)
        let output = try await tool.call(arguments: GeneratedContent(
            json: #"{"exercise":"bench","weight":80,"reps":8,"sets":2,"unit":"kg"}"#
        ))
        #expect(output.hasPrefix("Done: Logged bench press 2×8"))
        #expect(recorder.records.first?.state == .pending)
        #expect(recorder.records.first?.actor == .tess)
        let bad = try await tool.call(arguments: GeneratedContent(
            json: #"{"exercise":"levitation","weight":80,"reps":8,"sets":1,"unit":"kg"}"#
        ))
        #expect(bad == "Error: no exercise called levitation")
        #expect(recorder.records.count == 1)
    }

    @Test func everyRegistryActionHasAnIntentOrAReason() {
        let covered = Set(TesseraIntentsCatalog.coverage.keys)
        let actions = Set(ActionRegistry.descriptors.map(\.name))
        #expect(actions.subtracting(covered).isEmpty, "Missing: \(actions.subtracting(covered))")
        #expect(covered.subtracting(actions).isEmpty, "Stale: \(covered.subtracting(actions))")
    }

    @Test func siriAddATaskKeepsKeysOutAndSecretsPrivate() throws {
        // QA I3 (#428): Siri's Add a Task never saves a Claude key and files a secret with a value as a private note.
        #expect(try CreateTaskIntent.add("sk-ant-api03-TEST", startsAt: nil, engine: engine) == TessRouter.keyLine)
        #expect(try CreateTaskIntent.add("door code 4417", startsAt: nil, engine: engine) == "Private note, kept.")
        let objects = store.context.objects.values
        #expect(!objects.contains { $0.title.contains("sk-ant") || $0.title.contains("4417") })
        #expect(objects.contains { $0.title == SecretWords.title })
        // A task that only names a secret word stays a task.
        _ = try CreateTaskIntent.add("reset my PIN", startsAt: nil, engine: engine)
        #expect(store.context.objects.values.contains { $0.title.lowercased() == "reset my pin" })
    }

    @Test func siriFilesPrivateThingsTheWayTheBarDoes() throws {
        // Product P14 (board 0l): one rule for the Bar and Siri; nothing private is read back in his words.
        #expect(try CreateTaskIntent.add("took advil 400mg", startsAt: nil, engine: engine) == "Private note, kept.")
        #expect(try CreateTaskIntent.add("$212.37 at Costco", startsAt: nil, engine: engine) == "Private note, kept.")
        #expect(try CreateTaskIntent.add("headache since tuesday", startsAt: nil, engine: engine)
            == "Private note, kept.")
        #expect(try CreateTaskIntent.add("remember my rent is 2100", startsAt: nil, engine: engine)
            == "I don't keep sums of money.")
        // Something to do stays a task (W4), read back without its amount.
        #expect(try CreateTaskIntent.add("pay rent 2100 friday", startsAt: nil, engine: engine) == "Task added.")
        let titles = store.context.objects.values.map(\.title)
        #expect(titles.contains { $0.lowercased().hasPrefix("pay rent 2100") })
        #expect(!titles.contains { $0.contains("advil") || $0.contains("212.37") || $0.contains("headache") })
        #expect(try CreateTaskIntent.add("call mom", startsAt: nil, engine: engine).lowercased().contains("call mom"))
        // Every write needs Face ID.
        for policy in [LogSetIntent.authenticationPolicy, LogNextSetIntent.authenticationPolicy,
                       UndoLastSetIntent.authenticationPolicy, StartRoutineIntent.authenticationPolicy,
                       FinishWorkoutIntent.authenticationPolicy, CreateTaskIntent.authenticationPolicy,
                       TellTessIntent.authenticationPolicy]
        {
            guard case .requiresAuthentication = policy else {
                Issue.record("a write intent doesn't need Face ID")
                continue
            }
        }
    }

    @Test func intentsRunTheSameTypedActions() throws {
        let runtime = TesseraRuntime(engine: engine, tess: tess)
        let routine = try engine.perform(CreateRoutine(title: "Push Day A"), by: .user).output
        try engine.perform(AddSlot(routine: routine.id, exercise: #require(classes[.benchPress]).id), by: .user)
        #expect(RoutineQuery.all(runtime).map(\.title) == ["Push Day A"])
        #expect(ExerciseQuery.all(runtime).map(\.name).contains("Bench Press"))
        #expect(!ExerciseQuery.all(runtime).map(\.name).contains("Barbell Lift")) // only leaf exercises

        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .intent).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, source: .lockScreen), by: .intent)
        #expect(engine.undoLatest(action: LogSet.descriptor.name) != nil)
        #expect(entry.orderedChildren.isEmpty)
    }
}
