import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Memory spec M4: every shipped agent compiles, no agent gets a money write, Opus is never first, Body exists
/// only under lab, and an expertise pack's hash changes only when its source data changes.
@MainActor
struct AgentSpecTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]

    init() throws {
        classes = try store.prepareCatalog()
    }

    // MARK: Specs

    @Test func everyShippedAgentCompiles() {
        #expect(AgentSpec.problems().isEmpty)
        #expect(AgentSpec.shipped.map(\.name) == ["Tess", "Training", "Kitchen", "Today", "Notes", "Money", "Body"])
    }

    @Test func noAgentIsOfferedAMoneyAction() {
        for spec in AgentSpec.shipped {
            #expect(Set(spec.tools).isDisjoint(with: Door.moneyActions))
        }
        var greedy = AgentSpec.money
        greedy.tools.append("logSpend")
        #expect(greedy.problems().contains { $0.contains("money actions") })
    }

    @Test func opusIsNeverTheFirstRung() {
        for spec in AgentSpec.shipped {
            #expect(spec.plain.ladder.first != .opus && spec.open.ladder.first != .opus)
        }
        var eager = AgentSpec.training
        eager.open.ladder = [.opus, .sonnet]
        #expect(eager.problems().count == 2)
    }

    @Test func bodyIsLabOnly() {
        #expect(AgentSpec.available(under: .lab).count == 7)
        #expect(!AgentSpec.available(under: .strict).contains { $0.name == "Body" })
    }

    @Test func subAgentsStayThreeWideAndTwoDeep() {
        var deep = AgentSpec.kitchen
        deep.depth = 2
        #expect(!deep.problems().isEmpty)
        deep.maxChildren = 0
        #expect(deep.problems().isEmpty)
        var wide = AgentSpec.tess
        wide.maxChildren = 4
        #expect(!wide.problems().isEmpty)
    }

    @Test func unknownToolsAndSharedNamesAreCaught() {
        var odd = AgentSpec.notes
        odd.tools.append("deleteEverything")
        #expect(odd.problems().contains { $0.contains("unknown tools") })
        #expect(!AgentSpec.problems([AgentSpec.notes, AgentSpec.notes]).isEmpty)
        #expect(AgentSpec.named("training") == AgentSpec.training)
    }

    // MARK: Expertise packs

    func facts(bench: Double = 92.5) -> TrainingExpertise.Facts {
        TrainingExpertise.Facts(
            e1RMFormula: "weight * (1 + reps / 30)",
            library: [.init(name: "Bench Press", equipment: "barbell", pattern: "horizontalPush", primary: ["Chest"],
                            secondary: ["Triceps"], reps: 5 ... 8)],
            yours: [], plans: [.init(name: "Push Pull Legs", routines: ["Push Day"])],
            routines: [.init(name: "Push Day", slots: [(exercise: "Bench Press", sets: 4)]),
                       .init(name: "Private workout", slots: [])],
            bests: [.init(exercise: "Bench Press", e1RM: bench * 1.1667, repMaxes: [5: bench], sessions: 12)]
        )
    }

    @Test func aPackIsAPureFunctionOfItsFacts() {
        let one = TrainingExpertise.render(facts())
        #expect(one == TrainingExpertise.render(facts()))
        #expect(one.hash.count == 16)
        #expect(one.text.contains("Bench Press: e1RM 107.9; 5 reps 92.5; 12 sessions"))
        #expect(one.text.contains("Push Day: Bench Press 4 sets"))
        #expect(one.text.contains("Private workout") && !one.text.contains("Private workout:"))
        #expect(TrainingExpertise.render(facts(bench: 95)).hash != one.hash)
    }

    @Test func theTrainingPackReadsTheStore() throws {
        let bench = try #require(classes[.benchPress])
        let workoutClass = try #require(classes[.workout])
        let entryClass = try #require(classes[.exerciseEntry])
        let setClass = try #require(classes[.set])
        let engine = ActionEngine(store: store, classes: classes)
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .system).output
        _ = try engine.perform(AddSlot(routine: routine.id, exercise: bench.id), by: .system)
        let workout = store.create(workoutClass, title: "Push A")
        try store.set("startedAt", to: .date(.now.addingTimeInterval(-3600)), on: workout)
        try store.set("endedAt", to: .date(.now), on: workout)
        let entry = store.create(entryClass, parent: workout)
        try store.setClassLink("exercise", on: entry, to: bench)
        let set = store.create(setClass, parent: entry)
        try store.set("weight", to: .mass(100), on: set)
        try store.set("reps", to: .number(5), on: set)

        let facts = TrainingExpertise.facts(store: store, classes: classes)
        #expect(facts.library.count == ExerciseLibrary.seeds.count)
        #expect(facts.routines.contains { $0.name == "Push A" && $0.slots.map(\.exercise) == [bench.name] })
        #expect(facts.bests.contains { $0.exercise == bench.name && $0.repMaxes[5] == 100 })
        #expect(facts.e1RMFormula != nil)

        let pack = try #require(ExpertisePack.build(for: .training, store: store, classes: classes))
        #expect(pack == ExpertisePack.build(for: .training, store: store, classes: classes))
        try store.set("weight", to: .mass(105), on: set)
        #expect(ExpertisePack.build(for: .training, store: store, classes: classes)?.hash != pack.hash)
    }

    @Test func theKitchenPackListsAislesPlacesAndRecipes() throws {
        let recipeClass = try #require(classes[.recipe])
        _ = store.create(recipeClass, title: "Turkey Chili")
        let pack = try #require(ExpertisePack.build(for: .kitchen, store: store, classes: classes))
        #expect(pack.text.contains("Turkey Chili"))
        #expect(Aisle.allCases.allSatisfy { pack.text.contains($0.rawValue) })
        #expect(ExpertisePack.build(for: .tess, store: store, classes: classes) == nil)
    }
}
