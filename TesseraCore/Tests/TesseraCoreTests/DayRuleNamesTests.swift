import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Rule names fit the split they name (Kaushik, Oct 20), and a rule-made name may be improved once by a model.
@MainActor
struct DayRuleNamesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: classes)
        try StarterContent.installIfNeeded(store: store, classes: classes)
        engine = ActionEngine(store: store, classes: classes)
    }

    func starters() throws -> [String: ObjectRecord] {
        let plan = try #require(store.object(id: StarterContent.planID))
        return Dictionary(uniqueKeysWithValues: store.linkedObjects("routines", of: plan).map { ($0.title, $0) })
    }

    func routine(_ title: String, _ lifts: [String]) throws -> ObjectRecord {
        let made = try engine.perform(CreateRoutine(title: title), by: .user).output
        for lift in lifts {
            let exercise = try #require(store.allClasses().first { $0.name == lift })
            try engine.perform(AddSlot(routine: made.id, exercise: exercise.id, sets: 3), by: .user)
        }
        return made
    }

    static let contradictions: [String: [String]] = [
        "push": ["pull", "back", "leg", "lower", "upper", "full", "core"],
        "pull": ["push", "chest", "press", "leg", "lower", "upper", "full", "core"],
        "legs": ["push", "pull", "chest", "back", "press", "upper", "arms", "core"],
    ]

    func names(_ routine: ObjectRecord) -> [String] {
        DayRuleNames.choices(DayRuleNames.shape(of: routine, store: store))
    }

    @Test(arguments: [
        ("Push A", "push", "Heavy chest"), ("Push B", "push", "Press day"), ("Pull A", "pull", "Heavy pull"),
        ("Pull B", "pull", "Back and biceps"), ("Legs A", "legs", "Squat day"), ("Legs B", "legs", "Heavy legs"),
    ])
    func eachStarterDayIsNamedForItsSplit(_ title: String, _ split: String, _ first: String) throws {
        let day = try #require(starters()[title])
        let choices = names(day)
        #expect(!choices.isEmpty && choices.allSatisfy { DayNames.isUsable($0) }, "\(title) \(choices)")
        for name in choices {
            let lower = name.lowercased()
            #expect(!(Self.contradictions[split] ?? []).contains { lower.contains($0) }, "\(title): \(name)")
        }
        if !first.isEmpty {
            #expect(choices.first == first, "\(title): \(choices)")
        }
    }

    @Test func threeMoreDaysFitTheirSplitToo() throws {
        let upper = try routine("Upper", ["Bench Press", "Barbell Row", "Overhead Press", "Lat Pulldown"])
        #expect(names(upper).first == "Upper body")
        let arms = try routine("Arms", ["Dumbbell Curl", "Hammer Curl", "Rope Pushdown"])
        #expect(names(arms).first == "Arms day")
        let full = try routine("All", ["Back Squat", "Bench Press", "Barbell Row", "Romanian Deadlift"])
        #expect(["Full body", "Heavy legs", "Upper body"].contains(names(full).first ?? ""), "\(names(full))")
        #expect(!(names(full).first ?? "").contains("Push") && !(names(full).first ?? "").contains("Pull"))
    }

    @Test func noPullDayIsEverCalledPushAndPull() throws {
        for title in ["Pull A", "Pull B"] {
            let day = try #require(starters()[title])
            #expect(!names(day).contains { $0.lowercased().contains("push") }, "\(title) \(names(day))")
        }
    }

    @Test func aRuleNameIsUpgradedOnceByAModelAndNeverAfter() async throws {
        let day = try #require(starters()["Push A"])
        day.title = "New routine"
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        // No model: the rule name.
        #expect(await maker.autoName(day, engine: engine) == "Heavy chest")
        #expect(DayNames.isRuleNamed(day, store: store))
        // Still no model: nothing more happens, and the rule name is not churned.
        #expect(await maker.autoName(day, engine: engine) == nil && day.title == "Heavy chest")
        // A model arrives: one better name.
        maker.onDeviceAvailable = { true }
        maker.onDevice = { _, _ in "Bench and shoulders" }
        #expect(await maker.autoName(day, engine: engine) == "Bench and shoulders")
        #expect(!DayNames.isRuleNamed(day, store: store))
        // A model-made name is never replaced (its exercises have not changed).
        maker.onDevice = { _, _ in "Something else" }
        #expect(await maker.autoName(day, engine: engine) == nil && day.title == "Bench and shoulders")
    }

    @Test func aTypedNameIsNeverUpgraded() async throws {
        let day = try #require(starters()["Push A"])
        day.title = "Bench day"
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false }, onDevice: { _, _ in "Heavy chest" })
        maker.onDeviceAvailable = { true }
        #expect(await maker.autoName(day, engine: engine) == nil && day.title == "Bench day")
        // A rule-made name he then retypes is his.
        day.title = "New routine"
        maker.onDeviceAvailable = { false }
        _ = await maker.autoName(day, engine: engine)
        day.title = "Chest and tris"
        maker.onDeviceAvailable = { true }
        #expect(await maker.autoName(day, engine: engine) == nil && day.title == "Chest and tris")
    }

    @Test func aFailedUpgradeIsTriedOncePerDay() async throws {
        let day = try #require(starters()["Pull A"])
        day.title = "New routine"
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        maker.now = { clock }
        _ = await maker.autoName(day, engine: engine)
        var asked = 0
        maker.onDeviceAvailable = { true }
        maker.onDevice = { _, _ in
            asked += 1
            return nil
        }
        _ = await maker.autoName(day, engine: engine)
        _ = await maker.autoName(day, engine: engine)
        #expect(asked == 1)
        // The next day, one more try (and it is kept on the routine, not just in this session).
        clock = clock.addingTimeInterval(26 * 3600)
        let again = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        again.now = { clock }
        again.onDeviceAvailable = { true }
        again.onDevice = { _, _ in
            asked += 1
            return nil
        }
        _ = await again.autoName(day, engine: engine)
        _ = await again.autoName(day, engine: engine)
        #expect(asked == 2)
    }

    @Test func aDayNamedBeforeTheMarkerGetsTheNewRuleNameOnceButATypedOneDoesNot() async throws {
        let all = try starters()
        let pullB = try #require(all["Pull B"]), pushA = try #require(all["Push A"])
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        // A release-30 day: Tess's weak name, the exercises it was for, and no "named by" marker.
        let pack = try #require(DayNames.pack(of: pullB, store: store))
        pullB.title = "Push and pull"
        try store.set("autoName", to: .text("Push and pull"), on: pullB)
        try store.set("autoNameKey", to: .text(pack.key), on: pullB)
        #expect(DayNames.isUnmarked(pullB, store: store) && DayNames.needsName(pullB, store: store))
        #expect(await maker.autoName(pullB, engine: engine) == "Back and biceps")
        #expect(pullB.title == "Back and biceps" && DayNames.isRuleNamed(pullB, store: store))
        #expect(!DayNames.isUnmarked(pullB, store: store))
        // Once only: the next pass changes nothing.
        #expect(await maker.autoName(pullB, engine: engine) == nil && pullB.title == "Back and biceps")
        // His own name with no marker: untouched, even beside an old Tess mark.
        pushA.title = "Bench day"
        #expect(await maker.autoName(pushA, engine: engine) == nil && pushA.title == "Bench day")
        let pushPack = try #require(DayNames.pack(of: pushA, store: store))
        try store.set("autoName", to: .text("Push and pull"), on: pushA)
        try store.set("autoNameKey", to: .text(pushPack.key), on: pushA)
        #expect(await maker.autoName(pushA, engine: engine) == nil && pushA.title == "Bench day")
    }

    @Test func everyMuscleInTheLibraryLandsInOneOfTheFourSplits() throws {
        let known = DayRuleNames.pushMuscles.union(DayRuleNames.pullMuscles).union(DayRuleNames.legMuscles)
            .union(DayRuleNames.trunkMuscles)
        let muscleClass = try #require(engine.classes[.muscle])
        let words = store.objects(of: muscleClass).filter { !$0.isDeleted }.map { $0.title.lowercased() }
        #expect(!words.isEmpty)
        #expect(words.filter { !known.contains($0) }.isEmpty, "\(words.filter { !known.contains($0) })")
    }

    @Test func anOldModelMadeNameBeforeTheMarkerIsLeftAlone() async throws {
        let pullB = try #require(starters()["Pull B"])
        let pack = try #require(DayNames.pack(of: pullB, store: store))
        pullB.title = "Back and arms and more"
        try store.set("autoName", to: .text("Back and arms and more"), on: pullB)
        try store.set("autoNameKey", to: .text(pack.key), on: pullB)
        #expect(!DayNames.isUnmarked(pullB, store: store) && !DayNames.isRuleNamed(pullB, store: store))
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        #expect(await maker.autoName(pullB, engine: engine) == nil && pullB.title == "Back and arms and more")
    }

    @Test func aCancelledPassAppliesNothing() async throws {
        let pushA = try #require(starters()["Push A"])
        pushA.title = "New routine"
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        let work = Task { @MainActor in
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                continuation.resume()
            }
            return await maker.autoName(pushA, engine: engine)
        }
        work.cancel()
        #expect(await work.value == nil && pushA.title == "New routine")
    }

    @Test func aDayWithNothingToApplyDoesNotAskAModelOnEveryPass() async throws {
        let day = try #require(starters()["Pull A"])
        day.title = "New routine"
        let maker = DayNamer(keys: InMemoryKeychain(), ledger: TessUsageLedger(store: store, classes: engine.classes),
                             allowed: { false })
        maker.onDeviceAvailable = { true }
        var asked = 0
        maker.onDevice = { _, _ in
            asked += 1
            return nil
        }
        // Everything the rules could offer is taken by other days, so there is nothing to apply.
        for other in try starters().values where other.id != day.id {
            other.title = "Heavy pull"
        }
        _ = await maker.autoName(day, engine: engine)
        _ = await maker.autoName(day, engine: engine)
        _ = await maker.autoName(day, engine: engine)
        #expect(asked == 1)
    }
}
