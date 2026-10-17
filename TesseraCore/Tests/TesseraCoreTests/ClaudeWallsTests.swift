import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The walls the A4 bypass check and the injection audit asked for on the Claude paths (docs/ai/a4-bypass-check.md,
/// docs/ai/injection-audit.md). Test keys are built at run time from pieces, never written out.
@Suite(.serialized) @MainActor
struct ClaudeWallsTests {
    static let key = "sk-" + "ant-" + "TEST-" + UUID().uuidString
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let flags: ClaudeMissFlags
    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        flags = try ClaudeMissFlags(defaults: #require(UserDefaults(suiteName: "claude-walls-\(UUID().uuidString)")))
        RouteStub.reply = (200, ClaudeRouteTests.answer("Nothing."))
        RouteStub.queue = []
        RouteStub.failure = nil
        RouteStub.requests = []
        RouteStub.redirect = nil
        RouteStub.bodies = []
    }

    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)

    func claude(sends: @escaping () -> Bool = { true }, key: String? = ClaudeWallsTests.key) -> ClaudeTessModel {
        var model = ClaudeTessModel(keys: InMemoryKeychain(key), ledger: ledger, flags: flags,
                                    session: RouteStub.session(), sendsMisses: sends)
        model.now = { TesseraDayTests.at(10, 15, 18, 10) }
        model.calendar = TesseraDayTests.calendar
        return model
    }

    /// A workout entry in focus on an exercise with this name, holding one set.
    func focus(on name: String, weight: Double = 80, reps: Double = 8) throws -> TessContext {
        let exercise = try ClassDef(name: name, parent: #require(classes[.exercise]))
        store.context.insert(exercise)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: exercise.id), by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
        var focused = context
        focused.entry = entry.id
        return focused
    }

    func prompt(_ focused: TessContext, lastKg: Double? = nil) -> String {
        claude().system(focused, engine: engine, lastWeightKg: lastKg)
    }

    // MARK: a4-1

    @Test func claudeCapturePackOmitsWalledExerciseNameAndLastSet() throws {
        for name in ["Weigh in 182.4", "Locker code lift", "Rent day press", "Knee rehab", "Bench $40"] {
            let system = try prompt(focus(on: name))
            #expect(system.contains("no workout in focus") && system.contains("no last set"), "\(name)")
            #expect(!system.contains(name) && !system.contains("80 kg x 8"), "\(name)")
        }
        let pasted = try prompt(focus(on: "Squat " + Self.key))
        #expect(!pasted.contains(Self.key))
    }

    @Test func claudeCapturePackKeepsAnOrdinaryExerciseAndSet() throws {
        let system = try prompt(focus(on: "Bench Press"))
        #expect(system.contains("current exercise Bench Press") && system.contains("last set 80 kg x 8"))
    }

    @Test func aWalledExerciseNameNeverReachesTheRequest() async throws {
        let focused = try focus(on: "Weigh in 182.4")
        RouteStub.reply = (200, ClaudeRouteTests.answer("Nothing."))
        let result = await claude().run(TessRequest(text: "could you log bench 80 for 8 from earlier?",
                                                    context: focused, use: .capture), engine: engine)
        _ = result
        #expect(RouteStub.bodies.count == 1)
        let body = try #require(String(data: RouteStub.bodies[0], encoding: .utf8))
        #expect(!body.contains("182.4") && body.contains("no workout in focus"))
    }

    // MARK: a4-3

    @Test func claudeRunRefusesWhenSwitchOffOrTextIsKeyShaped() async throws {
        let phrase = "could you log bench 80 for 8 from earlier?"
        let off = await claude(sends: { false }).run(TessRequest(text: phrase, context: context, use: .capture),
                                                     engine: engine)
        #expect(off.isMissed)
        let shaped = "log this " + "sk-" + "ant-" + "api03-" + String(repeating: "a1B2c3", count: 6)
        let pasted = await claude().run(TessRequest(text: shaped, context: context, use: .capture), engine: engine)
        #expect(pasted.isMissed)
        #expect(RouteStub.requests.isEmpty && ledger.calls().isEmpty)
        // With the switch on and an ordinary phrase the same call does go out.
        _ = await claude().run(TessRequest(text: phrase, context: context, use: .capture), engine: engine)
        #expect(RouteStub.requests.count == 1)
    }
}

extension TessResult {
    var isMissed: Bool {
        if case .missed = self { true } else { false }
    }
}
