@testable import Tessera
import TesseraCore
import Testing

/// A private recipe names nothing anywhere: its steps, lines, timers and the step its cook is on (QA on #1032).
@MainActor
struct KitchenMaskTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func recipe(_ text: String) throws -> ObjectRecord {
        try model.engine.perform(CreateRecipe(text: text), by: .user).output
    }

    private func label(_ object: ObjectRecord) -> String? {
        ObjectMask.label(of: object, in: model.store, classes: model.classes)
    }

    @Test func aPrivateRecipesStepsLinesAndTimersReadTheirLabels() throws {
        let cake = try recipe("Dentist cake\n2 cups flour\n\nSoak the dates overnight.\nBake 30 minutes.")
        let book = RecipeBook(store: model.store, classes: model.classes)
        let step = try #require(book.steps(of: cake).first)
        #expect(label(step.object) == KitchenMask.stepLabel)
        let line = try #require(cake.orderedChildren.first { $0.classDef?.id == model.classes[.recipeLine]?.id })
        #expect(label(line) == "Private item")
        let cook = try model.engine.perform(StartCooking(recipe: cake.id), by: .user).output
        #expect(label(cook) == ObjectPrivacy.recipeLabel)
        let timer = try model.engine.perform(StartKitchenTimer(label: "Soak dates", minutes: 10, cook: cook.id),
                                             by: .user).output
        #expect(label(timer) == KitchenMask.timerLabel)
    }

    @Test func anOrdinaryRecipesPartsShowTheirWords() throws {
        let dal = try recipe("Dal\n1 cup lentils\n\nSimmer 20 minutes.")
        let step = try #require(RecipeBook(store: model.store, classes: model.classes).steps(of: dal).first)
        #expect(label(step.object) == nil)
        let cook = try model.engine.perform(StartCooking(recipe: dal.id), by: .user).output
        let timer = try model.engine.perform(StartKitchenTimer(label: "Simmer", minutes: 20, cook: cook.id),
                                             by: .user).output
        #expect(label(timer) == nil)
        // A timer with no cook belongs to no recipe and keeps its label.
        let loose = try model.engine.perform(StartKitchenTimer(label: "Tea", minutes: 4), by: .user).output
        #expect(label(loose) == nil)
    }

    /// Home's ledger: the cook reads "Private recipe" and its step by number, never "Soak the dates overnight."
    @Test func homeShowsAPrivateCooksStepByNumberOnly() throws {
        let cake = try recipe("Dentist cake\n2 cups flour\n\nSoak the dates overnight.\nBake 30 minutes.")
        try model.engine.perform(StartCooking(recipe: cake.id), by: .user)
        let process = try #require(ProcessTable(engine: model.engine).running())
        #expect(process.nextStep?.contains("dates") == true)
        let shown = LedgerRow.shown(process, store: model.store, classes: model.classes, lastWeightKg: nil)
        #expect(shown.title == ObjectPrivacy.recipeLabel)
        #expect(shown.nextStep == "Step 1 of 2")
    }

    @Test func homeShowsAnOrdinaryCooksStepAsStored() throws {
        let dal = try recipe("Dal\n1 cup lentils\n\nSimmer 20 minutes.")
        try model.engine.perform(StartCooking(recipe: dal.id), by: .user)
        let process = try #require(ProcessTable(engine: model.engine).running())
        let shown = LedgerRow.shown(process, store: model.store, classes: model.classes, lastWeightKg: nil)
        #expect(shown.nextStep == process.nextStep)
    }
}
