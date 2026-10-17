@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// #86 R3: tap-to-fix always cycles ingredient → step → ignore → ingredient, even for a line that won't read as an
/// ingredient, and never touches the title.
@MainActor
struct PasteCycleTests {
    @Test func aLineThatWontParseStillReachesStep() {
        // "Serve hot" marked ingredient reads back as ignored (it won't parse), but the next tap is still step.
        #expect(PasteCopy.nextReading(after: "ingredient", current: .ignored) == "step")
        #expect(PasteCopy.nextReading(after: "step", current: .step(text: "x", timers: [])) == "ignore")
        #expect(PasteCopy.nextReading(after: "ignore", current: .ignored) == "ingredient")
        #expect(PasteCopy.nextReading(after: nil, current: .ignored) == "ingredient")
        #expect(PasteCopy.nextReading(after: nil, current: .title) == nil)
        #expect(PasteCopy.nextReading(after: nil, current: .heading) == nil)
    }

    /// G54: a bare link reads as nothing to keep, so Save isn't drawn; a read recipe can be saved.
    @Test func saveIsDrawnOnlyWhenSomethingWasRead() {
        #expect(!PasteCopy.canSave(CreateRecipe.lines(of: "https://example.com/shakshuka", corrections: [:])))
        #expect(PasteCopy.canSave(CreateRecipe.lines(of: "Dal\n1 cup lentils\nSimmer 20 minutes", corrections: [:])))
        #expect(PasteCopy.didntSave == "Didn't save that. Try again.")
    }

    /// G54: a bare link gets the link nudge and a Read it key; text with a link in it reads as a recipe.
    @Test func aBareLinkIsALinkNotATitle() {
        let link = "https://example.com/shakshuka"
        #expect(RecipePasteLink.bareLink(link) != nil)
        #expect(RecipePasteLink.bareLink("Dal\nfrom \(link)") == nil)
        #expect(PasteCopy.idleLine(link: true, reading: true, read: true, lines: []) ==
            "A link. Tap Read it and I'll read the page.")
        #expect(!PasteCopy.idleLine(link: true, reading: true, read: true, lines: []).contains("example.com"))
        #expect(PasteCopy.idleLine(link: false, reading: false, read: false, lines: []) ==
            "Paste a recipe and I'll read it.")
    }

    /// #810: a link with a password is refused whole, and a longer paste holding one never reaches the miss log.
    @Test func aLinkWithAPasswordIsNeverKept() {
        let link = "https://name:" + "hunter" + "2@example.com/dal"
        #expect(RecipePasteLink.isSecretLink(link))
        #expect(PasteCopy.hasSecretLink("Dal\nfrom \(link)\n1 cup lentils"))
        #expect(!PasteCopy.hasSecretLink("Dal\nfrom https://example.com/dal\n1 cup lentils"))
        #expect(RecipeLinkLine.secretLink == "That link has a password in it. Paste the text instead.")
    }

    /// QA on #821: a credential link wrapped in punctuation inside a longer paste is still caught.
    @Test func aWrappedPasswordLinkIsCaught() {
        let link = "https://name:" + "hunter" + "2@example.com/dal"
        #expect(PasteCopy.hasSecretLink("Dal (\(link)).\n1 cup lentils"))
        #expect(PasteCopy.hasSecretLink("from \"\(link)\","))
        #expect(!PasteCopy.hasSecretLink("Dal (https://example.com/dal)."))
    }
}
