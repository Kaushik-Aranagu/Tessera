import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Memory spec M4: every shipped agent compiles, no agent gets a money write, Opus is never first, Body and Money exist
/// only under lab, and an expertise pack's hash changes only when its source data changes (never for a private
/// workout).
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
        #expect(AgentSpec.shipped.map(\.name)
            == ["Tess", "Training", "Kitchen", "Today", "Notes", "Money", "Body", "Watch", "Lookout"])
        // Each has the room name he sees and its own personality.
        #expect(AgentSpec.shipped.map(\.title)
            == ["Tess", "Deck", "Galley", "Bridge", "Log", "Purse", "Body", "Watch", "Lookout"])
        #expect(Set(AgentSpec.shipped.map(\.persona)).count == AgentSpec.shipped.count)
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

    @Test func bodyAndMoneyAreLabOnly() {
        #expect(AgentSpec.available(under: .lab).count == 9)
        #expect(AgentSpec.available(under: .strict).map(\.name)
            == ["Tess", "Training", "Kitchen", "Today", "Notes", "Watch", "Lookout"])
    }

    @Test func strictDropsCalendarBeliefs() {
        #expect(AgentSpec.today.beliefClasses(under: .lab).contains(.occasion))
        #expect(!AgentSpec.today.beliefClasses(under: .strict).contains(.occasion))
        #expect(AgentSpec.today.beliefClasses(under: .strict).contains(.task))
        for spec in AgentSpec.shipped {
            #expect(AgentSpec.labOnlyBeliefs.isDisjoint(with: spec.beliefClasses(under: .strict)))
        }
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
        #expect(AgentSpec.named("Deck") == AgentSpec.training)
        var blank = AgentSpec.watch
        blank.persona = ""
        #expect(blank.problems().contains { $0.contains("personality") })
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

    func routine(_ title: String) throws -> ObjectRecord {
        try ActionEngine(store: store, classes: classes).perform(CreateRoutine(title: title), by: .system).output
    }

    /// Logs one set of an exercise in a new workout made from this routine.
    func log(_ exercise: ClassDef, kg: Double, reps: Double, from routine: ObjectRecord) throws {
        let workoutClass = try #require(classes[.workout])
        let entryClass = try #require(classes[.exerciseEntry])
        let setClass = try #require(classes[.set])
        let workout = store.create(workoutClass, title: routine.title)
        try store.setLinks("routine", on: workout, to: [routine])
        try store.set("startedAt", to: .date(.now.addingTimeInterval(-3600)), on: workout)
        try store.set("endedAt", to: .date(.now), on: workout)
        let entry = store.create(entryClass, parent: workout)
        try store.setClassLink("exercise", on: entry, to: exercise)
        let set = store.create(setClass, parent: entry)
        try store.set("weight", to: .mass(kg), on: set)
        try store.set("reps", to: .number(reps), on: set)
    }

    @Test func aPrivateWorkoutMovesNoBestAndNoHash() throws {
        let bench = try #require(classes[.benchPress])
        let rehab = try routine("Shoulder rehab")
        try log(bench, kg: 80, reps: 5, from: routine("Push B"))
        let before = TrainingExpertise.facts(store: store, classes: classes)
        let pack = try #require(ExpertisePack.build(for: .training, store: store, classes: classes))
        try log(bench, kg: 120, reps: 5, from: rehab)
        let after = TrainingExpertise.facts(store: store, classes: classes)
        #expect(after == before)
        #expect(after.bests.first { $0.exercise == bench.name }?.sessions == 1)
        #expect(ExpertisePack.build(for: .training, store: store, classes: classes) == pack)
        // The routine shows only as its label, with no slots.
        #expect(after.routines.contains { $0.name == ObjectPrivacy.routineLabel && $0.slots.isEmpty })
        #expect(!pack.text.contains("rehab"))
    }

    @Test func aPrivatePlanListsNoRoutines() throws {
        let planClass = try #require(classes[.plan])
        let plan = store.create(planClass, title: "Knee rehab block")
        // Not a starter name: the starter plan lists "Legs A" and is plain.
        try store.setLinks("routines", on: plan, to: [routine("Squat Focus")])
        let facts = TrainingExpertise.facts(store: store, classes: classes)
        #expect(!facts.plans.contains { $0.name.contains("rehab") })
        let label = try #require(ObjectPrivacy.shownLabel(of: plan, in: store, classes: classes))
        #expect(facts.plans.contains { $0.name == label && $0.routines.isEmpty })
        #expect(!facts.plans.contains { $0.routines.contains("Squat Focus") })
    }

    @Test func theKitchenPackListsAislesPlacesAndRecipes() throws {
        let recipeClass = try #require(classes[.recipe])
        _ = store.create(recipeClass, title: "Turkey Chili")
        if let placeClass = classes[.place] {
            _ = store.create(placeClass, title: "Clinic fridge")
        }
        let pack = try #require(ExpertisePack.build(for: .kitchen, store: store, classes: classes))
        #expect(pack.text.contains("Turkey Chili"))
        #expect(!pack.text.contains("Clinic") && pack.text.contains(ObjectPrivacy.placeLabel))
        #expect(Aisle.allCases.allSatisfy { pack.text.contains($0.rawValue) })
        #expect(ExpertisePack.build(for: .tess, store: store, classes: classes) == nil)
    }
}
