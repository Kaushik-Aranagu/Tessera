import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// G65: a kept link shows by its host alone, and Remove takes it off the shelf.
@MainActor
struct RecipesKeptTests {
    @Test func aKeptLinkShowsOnlyItsHost() throws {
        let link = try #require(URL(string: "https://www.seriouseats.com/the-best-dal-recipe?utm_source=x"))
        #expect(RecipesKeptCopy.host(link) == "seriouseats.com")
        #expect(RecipesKeptCopy.heading(1) == "1 link kept for later")
        #expect(RecipesKeptCopy.heading(3) == "3 links kept for later")
        #expect(RecipesKeptCopy.removed(link) == "seriouseats.com, removed")
        #expect(!RecipesKeptCopy.removed(link).contains("dal"))
    }

    @Test func removeTakesItOffTheShelfAndEraseEmptiesIt() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let shelf = RecipeLinkShelf(fileURL: folder.appending(path: "recipe-links.json"))
        shelf.fileProtection = []
        let dal = try #require(URL(string: "https://example.com/dal"))
        let tacos = try #require(URL(string: "https://example.com/tacos"))
        shelf.keep(dal)
        shelf.keep(tacos)
        #expect(shelf.waiting() == [dal, tacos])
        shelf.remove(dal)
        #expect(shelf.waiting() == [tacos])
        shelf.erase()
        #expect(shelf.waiting().isEmpty)
    }

    /// QA on #1031: Remove's UNDO puts the link back in its own place, and a link kept meanwhile stays behind it.
    @Test func undoingARemovePutsTheLinkBackInItsPlace() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let shelf = RecipeLinkShelf(fileURL: folder.appending(path: "recipe-links.json"))
        shelf.fileProtection = []
        let links = try ["dal", "tacos", "stew"].map { try #require(URL(string: "https://example.com/\($0)")) }
        for link in links {
            shelf.keep(link)
        }
        let takeBack = KeptLinks.remove(links[1], from: shelf)
        #expect(shelf.waiting() == [links[0], links[2]])
        let soup = try #require(URL(string: "https://example.com/soup"))
        shelf.keep(soup)
        takeBack()
        #expect(shelf.waiting() == [links[0], links[1], links[2], soup])
        // The first and the last come back in place too.
        KeptLinks.remove(links[0], from: shelf)()
        KeptLinks.remove(soup, from: shelf)()
        #expect(shelf.waiting() == [links[0], links[1], links[2], soup])
        shelf.erase()
    }

    /// QA on #913: with "Tess asks Claude" off, a kept link that needs Claude to read is a firm "Claude is off" and
    /// leaves the shelf; no call is made.
    @Test func withClaudeOffAKeptLinkLeavesTheShelf() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let shelf = RecipeLinkShelf(fileURL: folder.appending(path: "recipe-links.json"))
        shelf.fileProtection = []
        let link = try #require(URL(string: "https://example.com/no-card"))
        shelf.keep(link)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NoCardPage.self]
        let session = URLSession(configuration: config)
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext)
        var asked = false
        let claude = ClaudeRecipeReader(keys: NoKeychain(), ledger: TessUsageLedger(store: model.store,
                                                                                    classes: model.classes),
                                        session: session) { asked = true; return true }
        let outcome = await RecipePasteLink.read(link, reader: RecipeLinkReader(session: session, claude: claude),
                                                 asksClaude: false, shelf: shelf)
        #expect(!outcome.kept && shelf.waiting().isEmpty)
        #expect(!asked)
    }
}

/// A page with no recipe card and no recipe text: only Claude could read it.
private final class NoCardPage: URLProtocol {
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let html = Data("<html><body><p>A short story about a walk.</p></body></html>".utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "text/html"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: html)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// No key at all, never written.
private struct NoKeychain: TessKeychain {
    func read() -> String? {
        nil
    }

    func save(_: String) -> Bool {
        false
    }

    func delete() {}
}
