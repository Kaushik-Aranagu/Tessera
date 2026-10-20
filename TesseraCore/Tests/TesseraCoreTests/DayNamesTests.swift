import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Naming training days: the rule names, the checks, who may rename what, and the namer's order.
@MainActor
struct DayNamesTests {
    func seeded() throws -> (ObjectStore, ActionEngine, [String: ObjectRecord]) {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: classes)
        try StarterContent.installIfNeeded(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = Dictionary(uniqueKeysWithValues: store.linkedObjects("routines", of: plan)
            .map { ($0.title, $0) })
        return (store, ActionEngine(store: store, classes: classes), routines)
    }

    func namer(_ engine: ActionEngine, onDevice: DayNamer.OnDevice? = nil, available: Bool = false,
               claude: Bool = false) -> DayNamer
    {
        let result = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: engine.store,
                                                                                classes: engine.classes),
                              allowed: { claude }, onDevice: onDevice)
        result.onDeviceAvailable = { available }
        return result
    }

    @Test(arguments: [
        (["chest", "shoulders", "triceps"], "Push day"), (["back", "shoulders", "biceps"], "Upper body"),
        (["back", "biceps"], "Pull day"), (["quads", "glutes", "hamstrings"], "Leg day"),
        (["quads", "glutes", "calves"], "Leg day"), (["chest", "back", "quads"], "Full body"),
        (["abs"], "Core day"),
    ])
    func theRuleNameComesFromTheMuscles(_ muscles: [String], _ expected: String) {
        #expect(DayNames.localName(muscles: muscles) == expected)
        #expect(DayNames.localName(muscles: []) == nil)
        #expect(DayNames.localChoices(muscles: muscles).count >= 2)
    }

    @Test(arguments: ["Leg day", "Heavy pull", "Squat and sweat", "Carry and core"])
    func plainNamesPass(_ name: String) {
        #expect(DayNames.isUsable(name))
    }

    @Test(arguments: ["", "Leg Day Domination!", "Chest Day 2", "The upper body", "Iron therapy", "Monday grind",
                      "A very long name for one day", "Legs 💪", "\"Legs\"", "Push, heavy", "Workout"])
    func badNamesFail(_ name: String) {
        #expect(!DayNames.isUsable(name))
    }

    @Test func aPrivateRoutineHasNoPackAndIsNeverNamed() throws {
        let (store, engine, routines) = try seeded()
        let push = try #require(routines["Push A"])
        #expect(DayNames.pack(of: push, store: store)?.exercises.isEmpty == false)
        push.title = "Knee rehab day"
        #expect(DayNames.pack(of: push, store: store) == nil && !DayNames.mayAutoName(push, store: store))
        #expect(throws: (any Error).self) { try engine.perform(
            ApplyDayName(routine: push.id, name: "Leg day"),
            by: .tess
        ) }
    }

    @Test func packCarriesOnlyExerciseNamesAndMuscles() throws {
        let (store, _, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        let pack = try #require(DayNames.pack(of: routine, store: store))
        let json = String(describing: pack)
        #expect(!pack.exercises.isEmpty && !pack.muscles.isEmpty)
        #expect(!json.contains("kg") && !json.contains("Push A"))
    }

    @Test func onlyAPlaceholderOrTessOwnNameIsRenamed() throws {
        let (store, engine, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        // His own title: never.
        #expect(!DayNames.mayAutoName(routine, store: store))
        routine.title = "New routine"
        #expect(DayNames.mayAutoName(routine, store: store) && DayNames.needsName(routine, store: store))
        try engine.perform(ApplyDayName(routine: routine.id, name: "Push day"), by: .tess)
        #expect(routine.title == "Push day" && !DayNames.needsName(routine, store: store))
        // The exercises change: time again.
        let slot = try #require(routine.orderedChildren.last)
        try engine.perform(DeleteObject(object: slot.id), by: .user)
        #expect(DayNames.needsName(routine, store: store))
        // He renames it: auto-naming stops for good.
        try engine.perform(RenameObject(object: routine.id, title: "Bench day"), by: .user)
        #expect(!DayNames.mayAutoName(routine, store: store))
        #expect(throws: (any Error).self) { try engine.perform(
            ApplyDayName(routine: routine.id, name: "Upper body"),
            by: .tess
        ) }
    }

    @Test func aTakenSuggestionIsHisChoiceAndStopsAutoNaming() throws {
        let (store, engine, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "New routine"
        try engine.perform(ApplyDayName(routine: routine.id, name: "Push day"), by: .tess)
        try engine.perform(ApplyDayName(routine: routine.id, name: "Press day", force: true), by: .user)
        #expect(routine.title == "Press day" && !DayNames.mayAutoName(routine, store: store))
    }

    @Test func aNameIsNeverReusedByAnotherDay() throws {
        let (_, engine, routines) = try seeded()
        let push = try #require(routines["Push A"]), other = try #require(routines["Push B"])
        push.title = "New routine"
        other.title = "Push day"
        #expect(throws: (any Error).self) { try engine.perform(
            ApplyDayName(routine: push.id, name: "push day"),
            by: .tess
        ) }
    }

    @Test func onDeviceFirstThenRulesAndClaudeStaysOutOfIt() async throws {
        let (_, engine, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "New routine"
        let device = namer(engine, onDevice: { _, _ in "Press day" }, available: true, claude: true)
        #expect(await device.suggest(for: routine, engine: engine) == .init(name: "Press day", source: .onDevice))
        // A bad on-device name falls to the rule name, never to Claude while the phone's model is there.
        let bad = namer(engine, onDevice: { _, _ in "Chest Day 2!" }, available: true, claude: true)
        #expect(await bad.suggest(for: routine, engine: engine)?.source == .rules)
        // Nothing on the phone, no key: the rule name.
        let rules = namer(engine, claude: true)
        #expect(await rules.suggest(for: routine, engine: engine) == .init(name: "Push day", source: .rules))
    }

    @Test func suggestAgainOffersADifferentNameAndAPrivateDayGetsNone() async throws {
        let (_, engine, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "New routine"
        let maker = namer(engine)
        let first = try #require(await maker.suggest(for: routine, engine: engine))
        let second = try #require(await maker.suggest(for: routine, engine: engine, avoiding: [first.name]))
        #expect(first.name != second.name)
        routine.title = "Therapy day"
        #expect(await maker.suggest(for: routine, engine: engine) == nil)
    }

    @Test func autoNameAppliesOnceAndRespectsTheSwitch() async throws {
        let (store, engine, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "New routine"
        let maker = namer(engine)
        maker.enabled = { false }
        #expect(await maker.autoName(routine, engine: engine) == nil && routine.title == "New routine")
        maker.enabled = { true }
        #expect(await maker.autoName(routine, engine: engine) == "Push day")
        #expect(await maker.autoName(routine, engine: engine) == nil)
        #expect(!DayNames.needsName(routine, store: store))
    }
}

/// What leaves the phone: the request body of a Claude naming call.
final class NamingStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var bodies: [String] = []
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        var data = request.httpBody ?? Data()
        if data.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 8192)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 {
                    break
                }
                data.append(buffer, count: count)
            }
            stream.close()
        }
        Self.bodies.append(String(decoding: data, as: UTF8.self))
        let reply = #"{"content":[{"type":"text","text":"Press day"}],"usage":{"input_tokens":50,"output_tokens":4}}"#
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(reply.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
@Suite(.serialized)
struct DayNamerPayloadTests {
    @Test func noRoutineTitleEverLeavesThePhone() async throws {
        let (store, engine, routines) = try DayNamesTests().seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "New routine"
        let secret = try #require(routines["Pull A"])
        secret.title = "Knee rehab day"
        let typed = try #require(routines["Legs A"])
        typed.title = "Zebra Mondays"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NamingStub.self]
        let keychain = InMemoryKeychain()
        _ = keychain.save("sk-ant-" + String(repeating: "a", count: 20))
        let namer = DayNamer(keys: keychain, ledger: TessUsageLedger(store: store, classes: engine.classes),
                             session: URLSession(configuration: configuration), allowed: { true })
        NamingStub.bodies = []
        let result = await namer.suggest(for: routine, engine: engine, avoiding: ["Heavy push"])
        #expect(result?.source == .claude)
        let body = try #require(NamingStub.bodies.first)
        for hidden in ["Knee rehab", "Zebra", "New routine", "Pull A", "Legs A", "Push A"] {
            #expect(!body.contains(hidden), "\(hidden)")
        }
        #expect(body.lowercased().contains("heavy push"))
    }
}
