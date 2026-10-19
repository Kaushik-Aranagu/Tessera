import Foundation
@testable import TesseraCore
import Testing

/// OL01, OL05, OL06, OL07 and OL59 (gap hunt 22): one public function, `ObjectPrivacy.shownLabel`, answers for the
/// object page, the export and the index, including a workout or routine.
@MainActor
struct OneLabelTests {
    let store = ObjectStore.open(inMemory: true)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test(arguments: ["Knee rehab day", "Weigh in 82.4 kg", "Lexapro day"])
    func aPrivateWorkoutOrRoutineReadsPrivateWorkout(_ raw: String) throws {
        let engine = try engine()
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(RenameObject(object: routine.id, title: raw), by: .user)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        for object in [routine, workout] {
            #expect(ObjectPrivacy.shownLabel(of: object, in: store, classes: engine.classes) == "Private workout")
            #expect(ObjectPrivacy.label(of: object, in: store, classes: engine.classes) == "Private workout")
        }
    }

    @Test func aPlainRoutineAndItsWorkoutStayPlain() throws {
        let engine = try engine()
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(RenameObject(object: routine.id, title: "Push Day Q"), by: .user)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        for object in [routine, workout] {
            #expect(ObjectPrivacy.shownLabel(of: object, in: store, classes: engine.classes) == nil)
        }
        // The running process's resume point is not words: the shared export keeps the plain routine's name.
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(json.contains("Push Day Q"))
    }

    @Test func aChildOfAPrivateRecipeReadsPrivateRecipe() throws {
        let engine = try engine()
        let recipe = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n1 pinch saffron\nMethod\n1. Bake it."), by: .user
        ).output
        let children = recipe.orderedChildren
        #expect(!children.isEmpty)
        for child in children {
            #expect(ObjectPrivacy.shownLabel(of: child, in: store, classes: engine.classes) == "Private recipe")
        }
    }

    @Test func anIngredientOnlyPrivateRecipesUseReadsPrivateItem() throws {
        let engine = try engine()
        try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n1 pinch saffron\n2 tsp cumin\nMethod\n1. Bake it."),
            by: .user
        )
        try engine.perform(
            CreateRecipe(text: "Rice\nIngredients\n1 cup rice\n1 tsp cumin\nMethod\n1. Cook it."), by: .user
        )
        let ingredientClass = try #require(engine.classes[.ingredient])
        let byName = Dictionary(uniqueKeysWithValues: store.objects(of: ingredientClass).map { ($0.title, $0) })
        let saffron = try #require(byName.first { $0.key.lowercased().contains("saffron") }?.value)
        let cumin = try #require(byName.first { $0.key.lowercased().contains("cumin") }?.value)
        #expect(ObjectPrivacy.shownLabel(of: saffron, in: store, classes: engine.classes) == "Private item")
        #expect(ObjectPrivacy.shownLabel(of: cumin, in: store, classes: engine.classes) == nil)
    }

    @Test func pageMaskAndExportMaskAgree() throws {
        let engine = try engine()
        try engine.perform(CreateNote(body: "wifi password is hunter2zebra"), by: .user)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        try engine.perform(CreateTask(title: "Weigh in 82.4 kg"), by: .user)
        try engine.perform(CreateTask(title: "Buy lemons"), by: .user)
        let list = try engine.perform(CreateList(name: "Errands"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "take melatonin"), by: .user)
        try engine.perform(AddListItem(list: list.id, text: "Pasta night"), by: .user)
        try engine.perform(CreateRecipe(text: "Melatonin lasagna\nIngredients\n1 onion\nMethod\n1. Bake."), by: .user)
        try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\n1. Fry."), by: .user)
        let wide = PrivateWords.labels(in: store.context)
        var checked = 0
        for object in store.context.all(ObjectRecord.self) where !object.isClassObject {
            // Whatever the export masks, the shared function masks, to the same label.
            let shown = ObjectPrivacy.shownLabel(of: object, in: store, classes: engine.classes)
            #expect(shown == wide[object.id] || (wide[object.id] == nil && shown != nil && ObjectPrivacy
                    .label(of: object, in: store, classes: engine.classes) != nil), "\(object.title)")
            checked += 1
        }
        #expect(checked > 10)
    }

    @Test func theDefaultSideOfAPrivateWorkoutIsCountOnly() throws {
        let engine = try engine()
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(RenameObject(object: routine.id, title: "Knee rehab day"), by: .user)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        for object in [routine, workout] {
            #expect(SideFacts.defaultFields(of: object, in: store, classes: engine.classes) == nil)
        }
    }

    @Test func aWalledWaitingOnKeepsItsProcessPrivateInTheExport() throws {
        let engine = try engine()
        let task = try engine.perform(CreateTask(title: "Follow up"), by: .user).output
        try engine.perform(
            WaitOnTask(task: task.id, waitingOn: "Waiting on wifi password hunter2zebra", checkAt: .now + 86400),
            by: .user
        )
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(!json.lowercased().contains("hunter2zebra"), "a walled waitingOn leaked into the export")
    }
}
