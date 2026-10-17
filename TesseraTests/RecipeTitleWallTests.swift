@testable import Tessera
import TesseraCore
import Testing

/// G53: a private recipe's title reads "Private recipe" on the recipe page, the original page and the saved line.
@MainActor
struct RecipeTitleWallTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aPrivateTitleIsMaskedUntilShown() {
        for title in ["Rent 1200 stew", "Wifi code lasagna"] {
            let isPrivate = RecipeCopy.isPrivate(title, model: model)
            #expect(isPrivate, "\(title)")
            #expect(RecipeCopy.shownTitle(title, isPrivate: isPrivate, shown: false) == "Private recipe")
            #expect(RecipeCopy.shownTitle(title, isPrivate: isPrivate, shown: true) == title)
        }
    }

    @Test func aPlainTitleShowsAsIs() {
        #expect(!RecipeCopy.isPrivate("Weeknight dal", model: model))
        #expect(RecipeCopy.shownTitle("Weeknight dal", isPrivate: false, shown: false) == "Weeknight dal")
    }

    @Test func thePastedTitleLineStaysMaskedWhileTheTitleIs() {
        let source = "Rent 1200 stew\n2 cups lentils\n\nSimmer."
        #expect(RecipeCopy.maskedSource(source, title: "Rent 1200 stew", masked: true)
            == "Private recipe\n2 cups lentils\n\nSimmer.")
        #expect(RecipeCopy.maskedSource("  rent 1200 STEW  \nSimmer.", title: "Rent 1200 stew", masked: true)
            == "Private recipe\nSimmer.")
        #expect(RecipeCopy.maskedSource(source, title: "Rent 1200 stew", masked: false) == source)
    }
}
