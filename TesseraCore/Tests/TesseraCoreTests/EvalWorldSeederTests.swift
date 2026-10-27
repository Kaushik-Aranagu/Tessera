import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// test-world.md part 1: the small world goes into a fresh in-memory store through the app's actions, the planted
/// facts read back from the store as the key says, and a store with anything in it is refused.
@MainActor
struct EvalWorldSeederTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let world = EvalWorld.make(.small)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func live(_ key: SystemCatalog.Key) -> [ObjectRecord] {
        classes[key].map { store.objects(of: $0).filter { !$0.isDeleted } } ?? []
    }

    @Test func theSmallWorldSeedsThroughActionsAndReadsBack() throws {
        let report = try EvalWorldSeeder.seed(world, into: engine)
        #expect(report.refused.isEmpty, "\(report.firstRefusal)")
        #expect(SettingsStore.isTestStore(in: store) && TestStore.allowsClaude(store))
        #expect(report.notSeeded == ["leftovers", "renames"])

        // Training: the deleted 95 kg bench never counts, so the best for 5 is the planted 92.5 kg.
        let bench = try #require(classes[.benchPress])
        let ledger = TrainingLedger(store: store, classes: classes)
        #expect(ledger.records(for: bench).bestWeightByReps[5] == 92.5)
        #expect(live(.workout).count == world.workouts.filter { !$0.isDeleted }.count)
        // The rehab workouts are there, behind their label.
        let rehab = live(.workout).filter { $0.title == "Shoulder rehab" }
        #expect(rehab.count == 3)
        #expect(rehab.allSatisfy {
            ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) == ObjectPrivacy.routineLabel
        })

        // Kitchen, notes, calendar and the body.
        #expect(live(.recipe).count == world.recipes.count)
        #expect(live(.cook).count == world.cooks.count)
        #expect(live(.note).count == world.notes.count + world.weighIns.count)
        #expect(live(.occasion).count == world.events.count)
        #expect(BodyWeight.lastKg(in: store) == world.weighIns.last?.kg)
        #expect(!live(.sleepNight).isEmpty)

        // Money: the reversed headphones are gone, everything else is there.
        let spends = live(.spend)
        #expect(spends.count == world.spends.filter { !$0.isReversed }.count)
        #expect(!spends.contains { store.value("note", of: $0)?.stringValue == "headphones" })

        // Tess's memory: the locker line was forgotten for real, and training moved to the evening.
        #expect(!live(.tessMemory).contains { $0.title.lowercased().contains("locker") })
        // The scrub ran too: no op, summary or receipt still says it.
        // (A private note may hold the number itself: it is the note's own words, not the forgotten memory line.)
        for record in store.context.operations.values where !record.action.lowercased().contains("note") {
            let ops = record.opsData.map { String(decoding: $0, as: UTF8.self) } ?? ""
            #expect(!(ops + record.summary + (record.receipt ?? "")).lowercased().contains("locker"))
        }
        let beliefs = TessBeliefStore(engine: engine)
        let times = beliefs.all().filter { $0.key == .usualTime }
        #expect(times.count == 2)
        #expect(beliefs.open().first { $0.key == .usualTime }?.value == "{\"hour\":18.5}")
    }

    @Test func aStoreWithAnythingInItIsRefused() throws {
        let noteClass = try #require(classes[.note])
        _ = store.create(noteClass, title: "His note")
        #expect(throws: EvalWorldSeeder.Refusal.storeHasData(noteClass.name)) {
            try EvalWorldSeeder.seed(world, into: engine)
        }
        #expect(live(.workout).isEmpty)
    }

    @Test func aStoreHoldingOnlyOneTaskIsRefused() throws {
        let taskClass = try #require(classes[.task])
        _ = store.create(taskClass, title: "Call the bank")
        #expect(throws: EvalWorldSeeder.Refusal.storeHasData(taskClass.name)) {
            try EvalWorldSeeder.seed(world, into: engine)
        }
        #expect(live(.note).isEmpty && live(.workout).isEmpty)
    }

    @Test func aFreshCatalogIsEmptyAndInMemoryIsATestStore() throws {
        #expect(try TestStore.firstRowOfHis(in: store) == nil)
        #expect(!TestStore.isHisStore(store.context))
        // A starter routine he renamed is his.
        let routine = try #require(live(.routine).first)
        routine.title = "My push day"
        #expect(try TestStore.firstRowOfHis(in: store) != nil)
    }

    @Test func seedingTwiceIsRefused() throws {
        _ = try EvalWorldSeeder.seed(world, into: engine)
        #expect(throws: EvalWorldSeeder.Refusal.self) {
            try EvalWorldSeeder.seed(world, into: engine)
        }
    }
}
