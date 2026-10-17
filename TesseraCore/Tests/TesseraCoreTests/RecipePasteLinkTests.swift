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

    @Test(arguments: ["https://name:hunter2@budgetbytes.com/chili-mac/", "http://name@budgetbytes.com/x",
                      "www.name:hunter2@budgetbytes.com", "https://name:hunter%202@budgetbytes.com/"])
    func aLinkWithAPasswordIsNeverReadOrKept(_ text: String) async throws {
        // QA on #807: a user or password in the link is refused whole, never fetched or written down.
        let shelf = shelf()
        #expect(RecipePasteLink.bareLink(text) == nil && RecipePasteLink.isSecretLink(text), "\(text)")
        #expect(RecipeLinkReader.safeURL(text) == nil)
        LinkStub.failure = .notConnectedToInternet
        let result = await reader().read(text)
        #expect(result.line == RecipeLinkLine.secretLink && !result.isOffline && LinkStub.requests.isEmpty)
        try shelf.keep(#require(URL(string: "https://name:hunter2@budgetbytes.com/x")))
        #expect(!FileManager.default.fileExists(atPath: shelf.fileURL.path(percentEncoded: false)))
        #expect(!RecipeLinkLine.secretLink.contains("hunter2"))
    }

    @Test func offlineIsTypedNotWorded() async {
        LinkStub.failure = .notConnectedToInternet
        let result = await reader().read("https://budgetbytes.com/")
        #expect(result.isOffline && result.kind == .failed)
        LinkStub.failure = .badServerResponse
        #expect(await !reader().read("https://budgetbytes.com/").isOffline)
    }

    @Test(arguments: [URLError.Code.timedOut, .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost])
    func aBadNetworkKeepsTheLink(_ code: URLError.Code) async throws {
        // G63, ER5: a timeout or DNS failure is the network, never "won't let me read it", and the link stays.
        let shelf = shelf()
        let link = try #require(RecipePasteLink.bareLink("https://budgetbytes.com/chili-mac/"))
        shelf.keep(link)
        LinkStub.failure = code
        let outcome = await RecipePasteLink.read(link, reader: reader(), asksClaude: true, shelf: shelf)
        #expect(outcome.kept && outcome.line == "Recipe link, kept for later.", "\(code)")
        #expect(shelf.waiting().count == 1)
    }

    @Test func aKeptLinkLosesItsFragmentAndSensitiveItems() throws {
        // G64: nothing the link's owner meant to hide is written beside the store.
        let shelf = shelf()
        let token = String(repeating: "a1B2", count: 8)
        let raw = "https://budgetbytes.com/chili-mac/?p=42&email=me%40example.com&x_signature=abc&id_token=\(token)"
            + "&ref=\(token)&utm_source=pin#access=\(token)"
        try shelf.keep(#require(URL(string: raw)))
        let saved = try String(contentsOf: shelf.fileURL, encoding: .utf8)
        #expect(shelf.waiting().map(\.absoluteString) == ["https://budgetbytes.com/chili-mac/?p=42"], "\(saved)")
        #expect(!saved.contains(token) && !saved.contains("example.com") && !saved.contains("#"))
    }

    @Test func theShelfHoldsFiftyAndErases() throws {
        let shelf = shelf()
        for index in 0 ..< 55 {
            try shelf.keep(#require(URL(string: "https://budgetbytes.com/r\(index)")))
        }
        #expect(shelf.waiting().count == RecipeLinkShelf.limit)
        #expect(shelf.waiting().first?.absoluteString == "https://budgetbytes.com/r5") // the oldest went first
        #expect(shelf.fileURL.lastPathComponent == RecipeLinkShelf.fileName)
        shelf.erase()
        #expect(shelf.waiting().isEmpty && !FileManager.default
            .fileExists(atPath: shelf.fileURL.path(percentEncoded: false)))
    }

    // MARK: - The 15 s cap, a busy site, old links, "@" in a path, the saved source

    @Test func aPageThatNeverAnswersReadsAsOfflineAtTheCap() async throws {
        let shelf = shelf()
        LinkStub.hangs = ["slow.example.com"]
        var reader = reader()
        reader.pageLimit = .milliseconds(200)
        let link = try #require(RecipePasteLink.bareLink("https://slow.example.com/chili"))
        let outcome = await RecipePasteLink.read(link, reader: reader, asksClaude: false, shelf: shelf)
        #expect(outcome.result.isOffline && outcome.kept && outcome.line == RecipeLinkLine.offline)
        #expect(shelf.waiting().map(\.absoluteString) == ["https://slow.example.com/chili"])
    }

    @Test func aPageThatStallsMidStreamReadsAsOfflineAtTheCap() async throws {
        let shelf = shelf()
        LinkStub.stalls = ["stall.example.com"]
        LinkStub.pages["stall.example.com"] = .init(body: "<html>")
        var reader = reader()
        reader.pageLimit = .milliseconds(200)
        let link = try #require(RecipePasteLink.bareLink("https://stall.example.com/chili"))
        let outcome = await RecipePasteLink.read(link, reader: reader, asksClaude: false, shelf: shelf)
        #expect(outcome.result.isOffline && outcome.kept)
    }

    @Test func aBusySiteKeepsTheLinkAndAFirmRefusalDropsIt() async throws {
        let shelf = shelf()
        let link = try #require(RecipePasteLink.bareLink("https://busy.example.com/chili"))
        // 503: may pass, so it waits on the shelf for another tap.
        LinkStub.pages["busy.example.com"] = .init(status: 503, body: "")
        let busy = await RecipePasteLink.read(link, reader: reader(), asksClaude: false, shelf: shelf)
        #expect(busy.result.isRetryable && busy.kept && shelf.waiting().count == 1)
        // A page with no recipe is a firm refusal: it leaves the shelf.
        LinkStub.pages["busy.example.com"] = .init(body: "<html><body>Hello</body></html>")
        let none = await RecipePasteLink.read(link, reader: reader(), asksClaude: false, shelf: shelf)
        #expect(!none.result.isRetryable && !none.kept && shelf.waiting().isEmpty)
    }

    @Test func aLinkKeptBeforeTrackingWasStrippedCanStillBeRemoved() throws {
        let shelf = shelf()
        try FileManager.default.createDirectory(at: shelf.fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let old = "https://budgetbytes.com/chili-mac/?utm_source=pin&fbclid=abc"
        try JSONEncoder().encode([old, "https://other.com/x"]).write(to: shelf.fileURL)
        #expect(shelf.waiting().count == 2)
        try shelf.remove(#require(URL(string: "https://budgetbytes.com/chili-mac/")))
        #expect(shelf.waiting().map(\.absoluteString) == ["https://other.com/x"])
        // And keeping it again does not double it.
        try shelf.keep(#require(URL(string: "https://other.com/x?utm_source=a")))
        #expect(shelf.waiting().count == 1)
        shelf.erase()
        #expect(shelf.waiting().isEmpty)
    }

    @Test func anAtSignOnlyInThePathOrQueryIsNotACredential() throws {
        let medium = "https://medium.com/@chef/pie"
        #expect(!RecipeLinkReader.hasCredentials(medium))
        #expect(!RecipeLinkReader.hasCredentials("www.medium.com/@chef/pie"))
        #expect(!RecipeLinkReader.hasCredentials("https://site.com/r?by=@chef"))
        #expect(!RecipeLinkReader.hasCredentials("https://site.com/r#@chef"))
        #expect(RecipePasteLink.bareLink(medium)?.absoluteString == medium)
        #expect(!RecipePasteLink.isSecretLink(medium))
        // Only a user or password before the host counts.
        #expect(RecipeLinkReader.hasCredentials("https://chef@medium.com/pie"))
        #expect(RecipeLinkReader.hasCredentials("https://chef:pw@medium.com/pie"))
        let shelf = shelf()
        try shelf.keep(#require(URL(string: medium)))
        #expect(shelf.waiting().map(\.absoluteString) == [medium])
    }

    @Test func theSavedSourceDropsSecretsButKeepsHarmlessWords() async throws {
        let raw = "https://x.com/r?author=ana&design=b&turkey=1&utm_source=z&x_signature=1&idToken=2&user_email=e"
        let kept = try RecipeLinkReader.stripTracking(#require(URL(string: raw)))
        #expect(kept.absoluteString == "https://x.com/r?author=ana&design=b&turkey=1")
        // Through a read: the recipe's source is the stripped final URL.
        LinkStub.pages["x.com"] = .init(body: Self.page(Self.chiliMac))
        let result = await reader().read(raw)
        #expect(
            result.kind == .read && result.sourceURL?.absoluteString == "https://x.com/r?author=ana&design=b&turkey=1",
            "\(result.sourceURL?.absoluteString ?? "nil")"
        )
    }
}
