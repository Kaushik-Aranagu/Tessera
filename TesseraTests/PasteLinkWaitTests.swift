import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// Product ruling on #993: the wait line names the host while the link is read, and says "Asking Claude to read the
/// recipe." only at the moment the page is handed to Claude.
@MainActor
struct PasteLinkWaitTests {
    @Test func theStartLineNamesOnlyTheHost() throws {
        let link = try #require(URL(string: "https://www.seriouseats.com/the-best-dal-recipe?utm_source=x"))
        #expect(PasteLinkWait.startLine(link) == "Reading the recipe from seriouseats.com")
        #expect(!PasteLinkWait.startLine(link).contains("dal"))
        #expect(PasteLinkWait.startLine(link) != RecipeLinkLine.askingClaude)
        #expect(PasteLinkWait.askingLine == "Asking Claude to read the recipe")
    }

    /// The lines a read shows, in order: the start line, then whatever the reader's hook hands over.
    private func lines(for path: String, asksClaude: Bool, key: Bool = true,
                       overCap: Bool = false) async throws -> [String]
    {
        let link = try #require(URL(string: "https://blog.example.com/\(path)"))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [WaitStubPage.self]
        let session = URLSession(configuration: config)
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext)
        // A made-up key, built from pieces at run time and never written anywhere.
        let keys = InMemoryKeychain(key ? "sk-" + "ant-" + String(repeating: "x", count: 32) : nil)
        let ledger = TessUsageLedger(store: model.store, classes: model.classes)
        let today = Date.now
        if overCap {
            // The month's cap already spent.
            _ = ledger.record(use: .paste, model: ClaudeRecipeReader.model, input: 0, output: 0,
                              costNano: TessUsageLedger.capNano, latency: 0, outcome: "works", requestID: nil,
                              at: today)
        }
        var claude = ClaudeRecipeReader(keys: keys, ledger: ledger, session: session) { true }
        claude.now = { today }
        var shown = [PasteLinkWait.startLine(link)]
        let reader = PasteLinkWait.reader(session: session, claude: claude) { shown.append($0) }
        _ = await RecipePasteLink.read(link, reader: reader, asksClaude: asksClaude, shelf: nil)
        return shown
    }

    @Test func claudesLineShowsOnlyAtTheHandoff() async throws {
        let start = "Reading the recipe from blog.example.com"
        // A page only Claude could read, with Claude on: the start line, then Claude's line once.
        #expect(try await lines(for: "story", asksClaude: true) == [start, RecipeLinkLine.askingClaude])
        // Claude off: the start line alone.
        #expect(try await lines(for: "story", asksClaude: false) == [start])
        // No key saved: nothing leaves, so the start line alone.
        #expect(try await lines(for: "story", asksClaude: true, key: false) == [start])
        // A recipe the phone reads itself: never Claude's line.
        #expect(try await lines(for: "recipe", asksClaude: true) == [start])
    }

    /// QA on #1153: with the month's cap reached nothing goes to Claude, so his line never shows.
    @Test func overTheCapOnlyTheStartLineShows() async throws {
        #expect(try await lines(for: "story", asksClaude: true, overCap: true)
            == ["Reading the recipe from blog.example.com"])
    }
}

/// "/recipe" is a page with a recipe card; anything else is prose only Claude could read. Claude's own
/// endpoint gets a plain failure, so nothing is ever read from it.
private final class WaitStubPage: URLProtocol {
    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let url = request.url!
        let isClaude = url.host()?.contains("anthropic") == true
        let body = if url.path().hasSuffix("/recipe") {
            #"<html><head><script type="application/ld+json">{"@context":"https://schema.org","@type":"Recipe","#
                + #""name":"Dal","recipeIngredient":["1 cup red lentils","2 cups water","1 tsp salt"],"#
                + #""recipeInstructions":[{"@type":"HowToStep","text":"Rinse the lentils"},"#
                + #"{"@type":"HowToStep","text":"Simmer for 20 minutes"}]}</script></head><body></body></html>"#
        } else {
            "<html><body><p>A short story about a walk by the river.</p></body></html>"
        }
        let response = HTTPURLResponse(url: url, statusCode: isClaude ? 400 : 200, httpVersion: nil,
                                       headerFields: ["Content-Type": isClaude ? "application/json" : "text/html"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data((isClaude ? "{}" : body).utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
