import Foundation
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
        #expect(line == "Tacos, 3 added")
    }

    /// Only staples: nothing new goes on, one line, no UNDO.
    @Test func onlyStaplesSaysNothingToAdd() throws {
        let seasoning = try model.engine.perform(CreateRecipe(text: "Seasoning\nsalt\nblack pepper\n\nMix them."),
                                                 by: .user).output
        #expect(send(seasoning) == .nothing("Seasoning, nothing to add"))
    }

    @Test func aRefusalSaysDidntSave() {
        let outcome = RecipeCopy.send { () throws -> (count: Int, record: OpRecord) in
            throw ActionError.invalidArguments(action: "addRecipeToGroceries", reason: "x")
        }
        #expect(outcome == .failed("Didn't save that. Try again"))
    }

    @Test func eachRowIsOneSpokenStop() throws {
        let line = try #require(IngredientLine.parse("2 cups flour, sifted"))
        #expect(RecipeCopy.spokenRow("2 cups", line) == "2 cups \(line.name)\(line.prep.map { ", \($0)" } ?? "")")
        #expect(!RecipeCopy.spokenRow("", line).hasPrefix(" "))
    }

    /// A walled title never shows or is spoken in the add's line (QA on #808).
    @Test func aPrivateRecipeSaysPrivateRecipe() throws {
        let title = "Rent 1200 stew"
        let stew = try model.engine.perform(CreateRecipe(text: "\(title)\n2 carrots\n1 onion\n\nSimmer."), by: .user)
            .output
        #expect(RecipeCopy.isPrivate(stew.title, model: model))
        let outcome = RecipeCopy.send(isPrivate: RecipeCopy.isPrivate(stew.title, model: model)) {
            let result = try model.engine.perform(AddRecipeToGroceries(recipe: stew.id), by: .user)
            return (result.output.count, result.record)
        }
        guard case let .added(line, _) = outcome else { Issue.record("expected an add"); return }
        #expect(line == "Private recipe, 2 added" && !line.contains("stew") && !line.contains("Rent"))
        let again = RecipeCopy.send(isPrivate: true) {
            let result = try model.engine.perform(AddRecipeToGroceries(recipe: stew.id), by: .user)
            return (result.output.count, result.record)
        }
        #expect(again == .nothing("Private recipe, nothing to add"))
    }

    /// G68: the add is named for what it does, the whole recipe.
    @Test func theVoiceOverActionSaysAll() {
        #expect(RecipeCopy.addAllAction == "Add all to Groceries")
    }

    /// QA on #819: a hand-off keeps what is left of the window, never a fresh 10 s.
    @Test func theHandOffKeepsWhatIsLeft() {
        let start = Date(timeIntervalSince1970: 1000)
        #expect(RecipeCopy.holdLeft(since: start, now: start.addingTimeInterval(3)) == .seconds(7))
        #expect(RecipeCopy.holdLeft(since: start, now: start.addingTimeInterval(30)) == .seconds(1))
        #expect(RecipeCopy.holdLeft(since: nil, now: start) == .seconds(10))
    }

    /// Product 11:20 (#836): a bigger-size re-add changes amounts, "Tacos, 3 updated.", with UNDO that puts them back.
    @Test func aBiggerReAddSaysUpdatedWithUndo() throws {
        let tacos = try model.engine.perform(CreateRecipe(text: """
        Tacos
        Serves 2
        1 lb ground beef
        2 limes
        8 corn tortillas

        Brown the beef.
        """), by: .user).output
        func add(_ serves: Int?) -> RecipeCopy.SendOutcome {
            RecipeCopy.send {
                let result = try model.engine.perform(AddRecipeToGroceries(recipe: tacos.id, serves: serves), by: .user)
                return (result.output.count, result.record)
            }
        }
        _ = add(nil)
        guard case let .added(line, record) = add(4) else { Issue.record("expected an update"); return }
        #expect(line.hasPrefix("Tacos, ") && line.hasSuffix("updated"))
        _ = model.engine.undo(record)
        #expect(add(2) == .nothing("Tacos, nothing to add"))
    }

    /// G70 (ER14): a private recipe's failed add prints only the kind, never a word of its title.
    @Test func aPrivateRefusalSaysOnlyTheKind() {
        let outcome = RecipeCopy.send(isPrivate: true) { () throws -> (count: Int, record: OpRecord) in
            throw ActionError.invalidArguments(action: "addRecipeToGroceries", reason: "x")
        }
        #expect(outcome == .failed("Didn't save that. Private recipe"))
    }

    /// Product and Design 12:45: one warning per failure, never twice within a second.
    @Test func theWarningPlaysOncePerFailure() {
        let start = Date(timeIntervalSince1970: 1000)
        #expect(RecipeCopy.playsNotSaved(last: nil, now: start))
        #expect(!RecipeCopy.playsNotSaved(last: start, now: start.addingTimeInterval(0.4)))
        #expect(RecipeCopy.playsNotSaved(last: start, now: start.addingTimeInterval(1.2)))
    }
}
