import Foundation
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
        // QA on #830: an email, an @handle or a bare "@" is ordinary recipe text.
        #expect(!PasteCopy.hasSecretLink("Questions to chef@bakery.com"))
        #expect(!PasteCopy.hasSecretLink("Recipe by @dalqueen"))
        #expect(!PasteCopy.hasSecretLink("Bake 4 @ 350 for 20 minutes"))
    }

    @Test func waitingLinksReadAsACount() {
        #expect(PasteCopy.readWaiting(1) == "Read 1 waiting")
        #expect(PasteCopy.readWaiting(3) == "Read 3 waiting")
    }

    /// G59 (#854): a paste already saved says which, never "Didn't save that", and a walled title stays masked.
    @Test func aDuplicatePasteNamesTheRecipe() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        let dal = "Weeknight dal\n1 cup red lentils\nSimmer 20 minutes."
        #expect(PasteCopy.duplicateLine(dal, store: model.store, classes: model.classes) == nil)
        try model.engine.perform(CreateRecipe(text: dal), by: .user)
        let line = try #require(PasteCopy.duplicateLine(dal, store: model.store, classes: model.classes))
        #expect(line == "Weeknight dal is already on Recipes." && PasteCopy.isRefusal(line))
        let stew = "Rent 1200 stew\n2 carrots\n1 onion\n\nSimmer."
        try model.engine.perform(CreateRecipe(text: stew), by: .user)
        #expect(PasteCopy.duplicateLine(stew, store: model.store, classes: model.classes) ==
            "Private recipe is already on Recipes.")
    }

    /// #854 release condition: a private duplicate is refused by name ("Private recipe") and never reaches the miss
    /// log; a plain refusal still does.
    @Test func aPrivateDuplicateNeverReachesTheMissLog() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let log = CaptureMissLog(url: folder.appending(path: "misses.jsonl"))
        let stew = "Rent 1200 stew\n2 carrots\n1 onion\n\nSimmer."
        func save(_ text: String) -> PasteCopy.SaveOutcome {
            PasteCopy.save(text, corrections: [:], engine: model.engine, store: model.store, classes: model.classes,
                           missLog: log)
        }
        guard case .saved = save(stew) else { Issue.record("expected the first paste to save"); return }
        guard case let .duplicate(line) = save(stew) else { Issue.record("expected a duplicate"); return }
        #expect(line == "Private recipe is already on Recipes." && !line.contains("stew"))
        #expect(log.all().isEmpty)
        guard case .failed = save("https://example.com/dal") else { Issue.record("a bare link writes nothing"); return }
        #expect(log.all().count == 1)
    }

    /// QA on #865: a made-up medicine-titled recipe pasted twice reads "Private recipe" and the miss log stays empty.
    @Test func aMedicineTitledDuplicateIsPrivateAndNeverLogged() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let log = CaptureMissLog(url: folder.appending(path: "misses.jsonl"))
        let tea = "Ibuprofen tea\n1 cup water\n\nSteep it."
        func save() -> PasteCopy.SaveOutcome {
            PasteCopy.save(tea, corrections: [:], engine: model.engine, store: model.store, classes: model.classes,
                           missLog: log)
        }
        guard case .saved = save() else { Issue.record("expected the first paste to save"); return }
        guard case let .duplicate(line) = save() else { Issue.record("expected a duplicate"); return }
        #expect(line == PasteCopy.duplicate("Private recipe") && !line.lowercased().contains("ibuprofen"))
        #expect(log.all().isEmpty)
    }
}
