import Foundation
@testable import TesseraCore
import Testing

/// Each seeded routine carries a kind, so its colour does not depend on its title.
@MainActor
struct RoutineKindTests {
    @Test func theSixSeededDaysCarryTheirKind() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let plan = try #require(store.object(id: StarterContent.planID))
        let kinds = Dictionary(uniqueKeysWithValues: store.linkedObjects("routines", of: plan)
            .map { ($0.title, RoutineKind.of($0, in: store)) })
        #expect(kinds == ["Push A": .push, "Push B": .push, "Pull A": .pull, "Pull B": .pull, "Legs A": .legs,
                          "Legs B": .legs])
        _ = classes
    }

    @Test func aRenamedDayKeepsItsKind() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first { $0.title == "Push A" })
        try engine.perform(RenameObject(object: push.id, title: "Bench day"), by: .user)
        #expect(RoutineKind.of(push, in: store) == .push)
    }

    @Test func anExistingInstallWithoutKindsGetsThemOnTheNextLaunchAndHisChoiceIsKept() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let plan = try #require(store.object(id: StarterContent.planID))
        let routines = store.linkedObjects("routines", of: plan)
        let pull = try #require(routines.first { $0.title == "Pull A" })
        let push = try #require(routines.first { $0.title == "Push A" })
        try store.set("kind", to: nil, on: pull)
        try store.set("kind", to: .choice("legs"), on: push) // he chose
        StarterContent.backfillKinds(store: store, classes: classes)
        #expect(RoutineKind.of(pull, in: store) == .pull)
        #expect(RoutineKind.of(push, in: store) == .legs)
        // And the launch path does it too.
        try store.set("kind", to: nil, on: pull)
        try store.prepareCatalog()
        #expect(RoutineKind.of(pull, in: store) == .pull)
    }

    @Test func aRoutineHeBuildsKeepsAKindOnlyIfGivenOne() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let plain = try engine.perform(CreateRoutine(title: "Upper"), by: .user).output
        let made = try engine.perform(CreateRoutine(title: "Bench day", kind: "Push"), by: .user).output
        #expect(RoutineKind.of(plain, in: store) == nil && RoutineKind.of(made, in: store) == .push)
        let set = try engine.perform(SetRoutineKind(routine: plain.id, kind: "legs"), by: .user)
        #expect(RoutineKind.of(plain, in: store) == .legs)
        engine.undo(set.record)
        #expect(RoutineKind.of(plain, in: store) == nil)
    }
}
