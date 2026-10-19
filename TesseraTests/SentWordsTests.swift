import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// G653 (CL55): under each receipt, the words that went to Claude ("Private phrase" for a walled one), matched by
/// request id; how many never left; and "Clear what was sent", which deletes the words and keeps the spend.
@MainActor
struct SentWordsTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @discardableResult
    private func row(_ key: SystemCatalog.Key, words: String? = nil, request: String) throws -> ObjectRecord {
        let object = try model.store.create(#require(model.classes[key]), title: "request")
        if let words {
            try model.store.set("words", to: .text(words), on: object)
        }
        try model.store.set("requestID", to: .text(request), on: object)
        return object
    }

    @Test func eachReceiptShowsItsOwnWords() throws {
        try row(.tessSent, words: "buy oat milk", request: "a")
        try row(.tessSent, words: TessSentLog.privatePhrase, request: "b")
        let callA = try row(.tessCall, request: "a")
        let callB = try row(.tessCall, request: "b")
        let callC = try row(.tessCall, request: "c")
        let log = TessSentLog(store: model.store, classes: model.classes)
        let words = SentWords.byRequest(log)
        #expect(SentWords.of(callA, in: model.store, words: words) == "\u{201C}buy oat milk\u{201D}")
        #expect(SentWords.of(callB, in: model.store, words: words) == "Private phrase")
        #expect(SentWords.of(callC, in: model.store, words: words) == nil)
    }

    @Test func clearTakesTheWordsAndKeepsTheReceipts() throws {
        try row(.tessSent, words: "buy oat milk", request: "a")
        try row(.tessCall, request: "a")
        let log = TessSentLog(store: model.store, classes: model.classes)
        #expect(log.clear() == "Cleared what was sent.")
        #expect(log.count == 0)
        #expect(TessUsageLedger(store: model.store, classes: model.classes).calls().count == 1)
    }

    @Test func heldBackCountsOnlyWhenThereAreAny() {
        #expect(SentWords.heldBackLine(0) == nil)
        #expect(SentWords.heldBackLine(1) == "1 request held back on this phone")
        #expect(SentWords.heldBackLine(3) == "3 requests held back on this phone")
    }
}
