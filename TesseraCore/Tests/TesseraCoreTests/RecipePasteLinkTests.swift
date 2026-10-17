import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G54 (Kitchen gap hunt 8, K87.4, K86.7): the Paste screen's link path. In RecipeLinkTests' serialized suite, since
/// both drive LinkStub.
extension RecipeLinkTests {
    func shelf() -> RecipeLinkShelf {
        let shelf = RecipeLinkShelf(fileURL: FileManager.default.temporaryDirectory
            .appending(path: "recipe-links-\(UUID().uuidString)/recipe-links.json"))
        shelf.fileProtection = []
        return shelf
    }

    @Test(arguments: ["https://budgetbytes.com/chili-mac/", "  http://budgetbytes.com/x\n", "www.budgetbytes.com/x"])
    func aBarePasteIsALink(_ text: String) {
        #expect(RecipePasteLink.bareLink(text)?.scheme == "https", "\(text)")
    }

    @Test(arguments: [
        "Chili mac",
        "budgetbytes.com/x",
        "https://budgetbytes.com/x and more",
        "Chili mac\nhttps://a.com/x",
        "https://192.168.1.1/admin",
        "https://printer.local/",
        ""
    ])
    func anythingElseIsNot(_ text: String) {
        #expect(RecipePasteLink.bareLink(text) == nil, "\(text)")
    }

    @Test func aKeyIsNeverALink() {
        #expect(RecipePasteLink.bareLink("https://" + Self.fakeKey + ".example.com/") == nil)
    }

    @Test func aPastedLinkReadsAsARecipe() async throws {
        LinkStub.pages["budgetbytes.com"] = .init(body: Self.page(Self.chiliMac))
        let link = try #require(RecipePasteLink.bareLink("https://budgetbytes.com/chili-mac/"))
        let outcome = await RecipePasteLink.read(link, reader: reader(), asksClaude: true, shelf: shelf())
        #expect(outcome.result.kind == .read && !outcome.kept && outcome.line == "7 ingredients, 3 steps, 2 timers.")
        #expect(!outcome.line.contains("budgetbytes")) // never the URL in her line
    }

    @Test func offlineKeepsTheLinkUntilHisTap() async throws {
        let shelf = shelf()
        let link = try #require(RecipePasteLink.bareLink("https://budgetbytes.com/chili-mac/?utm_source=pin"))
        LinkStub.failure = .notConnectedToInternet
        let offline = await RecipePasteLink.read(link, reader: reader(), asksClaude: true, shelf: shelf)
        #expect(offline.kept && offline.line == "Recipe link, kept for later.")
        #expect(shelf.waiting().map(\.absoluteString) == ["https://budgetbytes.com/chili-mac/"])
        // Kept once, not twice; and nothing reads it by itself.
        _ = await RecipePasteLink.read(link, reader: reader(), asksClaude: true, shelf: shelf)
        #expect(shelf.waiting().count == 1)
        let requests = LinkStub.requests.count
        LinkStub.failure = nil
        #expect(LinkStub.requests.count == requests)
        // His tap, back online: read, and off the shelf.
        LinkStub.pages["budgetbytes.com"] = .init(body: Self.page(Self.chiliMac))
        let read = try await RecipePasteLink.read(#require(shelf.waiting().first), reader: reader(), asksClaude: true,
                                                  shelf: shelf)
        #expect(read.result.kind == .read && shelf.waiting().isEmpty)
    }

    @Test func claudeOffNeverAsksClaude() async throws {
        LinkStub.pages["blog.example.com"] = .init(body: Self.prose)
        let link = try #require(RecipePasteLink.bareLink("https://blog.example.com/beans"))
        let outcome = await RecipePasteLink.read(link, reader: reader(claude: true), asksClaude: false, shelf: nil)
        #expect(outcome.line == RecipeLinkLine.claudeOff && !outcome.kept)
        #expect(!LinkStub.requests.contains { $0.url?.host() == "api.anthropic.com" })
    }

    @Test func anUnreadableShelfIsNeverWrittenOver() throws {
        let shelf = shelf()
        try FileManager.default.createDirectory(at: shelf.fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data("not json yet".utf8).write(to: shelf.fileURL)
        try shelf.keep(#require(URL(string: "https://budgetbytes.com/x")))
        #expect(try String(contentsOf: shelf.fileURL, encoding: .utf8) == "not json yet")
        #expect(shelf.waiting().isEmpty)
    }
}
