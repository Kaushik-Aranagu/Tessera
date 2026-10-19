import Foundation
@testable import Tessera
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
        #expect(RecipesKeptCopy.removed(link) == "seriouseats.com, removed.")
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
}
