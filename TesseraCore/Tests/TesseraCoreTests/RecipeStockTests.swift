import Foundation
@testable import TesseraCore
import Testing

/// Have and short for a recipe against the pantry (rows H1-H7). Pure: the stock table is handed in.
struct RecipeStockTests {
    func lines(_ texts: [String]) -> [IngredientLine] {
        texts.compactMap { IngredientLine.parse($0) }
    }

    func rows(_ texts: [String], serves: Int = 4, at target: Int = 4, stock: [String: RecipeStock.Entry])
        -> [RecipeStock.Row]
    {
        RecipeStock.rows(lines: lines(texts), recipeServes: serves, serves: target, stock: stock)
    }

    func verdicts(_ rows: [RecipeStock.Row]) -> [RecipeStock.Verdict] {
        rows.map(\.verdict)
    }

    @Test func chickenInLemonOutRiceIn() {
        let result = rows(["1 lb chicken thighs", "1 lemon", "1 cup rice"], stock: [
            "chicken thigh": .init(.inStock), "lemon": .init(.out), "rice": .init(.inStock),
        ])
        #expect(verdicts(result) == [.have, .short(.init(amount: nil, unit: nil)), .have])
        #expect(RecipeStock.shortNames(result) == ["lemon"])
        #expect(RecipeStock.speech(result, recipeIsPrivate: false) == "Short on lemon.")
    }

    @Test func belowTheAmountIsShortByTheDifference() {
        let result = rows(["2 cups rice"], stock: ["rice": .init(.inStock, amount: 1, unit: .cup)])
        #expect(verdicts(result) == [.short(.init(amount: 1, unit: .cup))])
        // Enough of it, and the same amount, are have.
        #expect(verdicts(rows(["2 cups rice"], stock: ["rice": .init(.inStock, amount: 2, unit: .cup)])) == [.have])
        // Units of one dimension compare: 400 ml in the jar is under 2 cups (480 ml) by a quarter cup.
        let mixed = rows(["2 cups milk"], stock: ["milk": .init(.inStock, amount: 400, unit: .millilitre)])
        guard case let .short(gap) = mixed[0].verdict else {
            Issue.record("not short")
            return
        }
        #expect(gap.unit == .cup && (0.25 ... 0.5).contains(gap.count))
        // Mass against count is not compared: in stock is have.
        let apples = rows(["3 apples"], stock: ["apple": .init(.inStock, amount: 200, unit: .gram)])
        #expect(verdicts(apples) == [.have])
    }

    @Test func oneKeyAcrossPluralsAndPrep() {
        let eggs = rows(["3 eggs"], stock: ["egg": .init(.inStock)])
        #expect(verdicts(eggs) == [.have] && eggs[0].key == "egg")
        let cilantro = rows(["2 tbsp chopped fresh cilantro"], stock: ["cilantro": .init(.out)])
        #expect(cilantro[0].key == "cilantro" && RecipeStock.shortNames(cilantro).count == 1)
    }

    @Test func noStateIsCheckNeverShort() {
        let result = rows(["1 tsp paprika", "1 lemon"], stock: ["lemon": .init(.inStock)])
        #expect(verdicts(result) == [.check, .have])
        #expect(RecipeStock.shortNames(result).isEmpty)
        #expect(RecipeStock.speech(result, recipeIsPrivate: false) == "Nothing is short.")
    }

    @Test func staplesTasteAndServingLinesAreNotJudged() {
        let result = rows(
            ["1 tbsp kosher salt", "hot sauce, for serving", "50 g cheddar, optional", "pepper, to taste"],
            stock: ["kosher salt": .init(.out), "hot sauce": .init(.out), "cheddar": .init(.out)]
        )
        #expect(verdicts(result).allSatisfy { $0 == .skipped })
        #expect(RecipeStock.shortNames(result).isEmpty)
    }

    @Test func servesRescalesTheAmountsNeeded() {
        let stock = ["rice": RecipeStock.Entry(.inStock, amount: 2, unit: .cup)]
        #expect(verdicts(rows(["2 cups rice"], serves: 4, at: 4, stock: stock)) == [.have])
        // At 8 the recipe needs 4 cups: short by 2.
        #expect(verdicts(rows(["2 cups rice"], serves: 4, at: 8, stock: stock)) == [.short(.init(
            amount: 2,
            unit: .cup
        ))])
        // At 2 it needs 1 cup: have.
        #expect(verdicts(rows(["2 cups rice"], serves: 4, at: 2, stock: stock)) == [.have])
    }

    @Test func aPrivateRecipeSaysOnlyPrivateRecipe() {
        let result = rows(["1 lemon", "2 cups rice"], stock: ["lemon": .init(.out), "rice": .init(.out)])
        let speech = RecipeStock.speech(result, recipeIsPrivate: true)
        #expect(speech == "Private recipe" && !speech.lowercased().contains("lemon") && !speech.contains("short"))
    }

    @Test func manyShortNamesFold() {
        let result = rows(["1 lemon", "1 lime", "2 cups rice", "1 onion", "1 carrot"], stock: [
            "lemon": .init(.out), "lime": .init(.out), "rice": .init(.out), "onion": .init(.out), "carrot": .init(.out),
        ])
        #expect(RecipeStock.speech(result, recipeIsPrivate: false) == "Short on lemon, lime and 3 more.")
    }

    @MainActor
    @Test func aWalledLineInAPlainRecipeIsNeverNamed() {
        let store = ObjectStore.open(inMemory: true)
        let result = rows(["1 lemon", "1 Ozempic dose"], stock: ["lemon": .init(.out), "ozempic dose": .init(.out)])
        let speech = RecipeStock.speech(result, recipeIsPrivate: false, in: store)
        #expect(speech == "Short on lemon and Private item." && !speech.lowercased().contains("ozempic"))
        // The names alone carry the mask too.
        #expect(RecipeStock.shortNames(result).contains("ozempic dose"))
        #expect(RecipeStock.shortNames(result) { ObjectPrivacy.isPrivateWord($0, in: store) }.contains("Private item"))
    }

    @Test func aCountWithNoUnitIsAlwaysHave() {
        let result = rows(["3 apples", "2 onions"], stock: [
            "apple": .init(.inStock, amount: 1), "onion": .init(.inStock, amount: 1, unit: .piece),
        ])
        #expect(verdicts(result) == [.have, .have])
    }

    @Test func nothingHereIsEverAClaudeJob() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        for file in try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            #expect(try !String(contentsOf: file, encoding: .utf8).contains("RecipeStock"), "\(file.lastPathComponent)")
        }
    }
}
