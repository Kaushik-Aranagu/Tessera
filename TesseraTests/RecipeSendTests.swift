@testable import Tessera
import TesseraCore
import Testing

/// G58 (K87.8): the recipe page's add says the engine's line; nothing new is one line with no UNDO; a refusal says so.
@MainActor
struct RecipeSendTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func send(_ recipe: ObjectRecord) -> RecipeCopy.SendOutcome {
        RecipeCopy.send {
            let result = try model.engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
            return (result.output.count, result.record)
        }
    }

    @Test func anAddSaysHowMany() throws {
        let tacos = try model.engine.perform(CreateRecipe(text: """
        Tacos
        1 lb ground beef
        2 limes
        8 corn tortillas

        Brown the beef.
        """), by: .user).output
        guard case let .added(line, _) = send(tacos) else { Issue.record("expected an add"); return }
        #expect(line == "Tacos, 3 added.")
    }

    /// Only staples: nothing new goes on, one line, no UNDO.
    @Test func onlyStaplesSaysNothingToAdd() throws {
        let seasoning = try model.engine.perform(CreateRecipe(text: "Seasoning\nsalt\nblack pepper\n\nMix them."),
                                                 by: .user).output
        #expect(send(seasoning) == .nothing("Seasoning, nothing to add."))
    }

    @Test func aRefusalSaysDidntSave() {
        let outcome = RecipeCopy.send { () throws -> (count: Int, record: OpRecord) in
            throw ActionError.invalidArguments(action: "addRecipeToGroceries", reason: "x")
        }
        #expect(outcome == .failed("Didn't save that. Try again."))
    }

    @Test func eachRowIsOneSpokenStop() throws {
        let line = try #require(IngredientLine.parse("2 cups flour, sifted"))
        #expect(RecipeCopy.spokenRow("2 cups", line) == "2 cups \(line.name)\(line.prep.map { ", \($0)" } ?? "")")
        #expect(!RecipeCopy.spokenRow("", line).hasPrefix(" "))
    }
}
