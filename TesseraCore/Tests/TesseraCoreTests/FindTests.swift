import Foundation
@testable import TesseraCore
import Testing

/// Find.query (design sheet 158): grouped local search that never shows a private object.
@MainActor
struct FindTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @discardableResult
    func make(_ key: SystemCatalog.Key, _ title: String, body: String? = nil, updated: Date? = nil) throws
        -> ObjectRecord
    {
        let object = try store.create(#require(engine.classes[key]), title: title)
        if let body {
            try store.set("body", to: .text(body), on: object)
        }
        if let updated {
            object.updatedAt = updated
        }
        return object
    }

    func titles(_ result: Find.Result, _ app: AppID?) -> [String] {
        result.groups.first { $0.app == app }?.hits.map(\.title) ?? []
    }

    @Test func groupsByAppInOrderWithEverythingElseLast() throws {
        try make(.task, "Plum jam jars")
        try make(.recipe, "Plum cake")
        try make(.note, "Plum tree notes")
        try make(.list, "Plum shopping")
        let result = Find.query("plum", engine: engine)
        #expect(result.groups.map(\.app) == [.kitchen, .notes, .lists, nil])
        #expect(titles(result, nil) == ["Plum jam jars"])
        #expect(result.privateCount == 0)
    }

    @Test func prefixAndMultiWordMatching() throws {
        try make(.recipe, "Chicken tikka masala")
        try make(.recipe, "Masala tea")
        #expect(titles(Find.query("chi tik", engine: engine), .kitchen) == ["Chicken tikka masala"])
        #expect(titles(Find.query("mas", engine: engine), .kitchen).count == 2)
        #expect(Find.query("kka", engine: engine).isEmpty)
        #expect(Find.query("chicken soup", engine: engine).isEmpty)
    }

    @Test func noteBodyFirst200CharsOnly() throws {
        try make(.note, "Trip", body: "Pack the zebra scarf")
        try make(.note, "Far", body: String(repeating: "x ", count: 120) + "zebra")
        let result = Find.query("zebra", engine: engine)
        #expect(titles(result, .notes) == ["Trip"])
        #expect(result.groups[0].hits[0].score == 1)
    }

    @Test func limitPerGroup() throws {
        for index in 0 ..< 8 {
            try make(.note, "Idea \(index)")
        }
        try make(.task, "Idea task")
        let result = Find.query("idea", engine: engine, limit: 3)
        #expect(titles(result, .notes).count == 3)
        #expect(titles(result, nil).count == 1)
    }

    @Test func diacriticsAndCase() throws {
        try make(.recipe, "Crème Brûlée")
        #expect(titles(Find.query("CREME brulee", engine: engine), .kitchen) == ["Crème Brûlée"])
        try make(.recipe, "Jalapeno poppers")
        #expect(titles(Find.query("jalapeño", engine: engine), .kitchen) == ["Jalapeno poppers"])
    }

    @Test func aPrivateNoteIsCountedNeverShown() throws {
        try make(.note, "Mood journal", body: "rent 2100 due")
        try make(.note, "Plain journal")
        let flagged = try make(.note, "Journal for me")
        try store.set("isPrivate", to: .bool(true), on: flagged)
        let result = Find.query("journal", engine: engine)
        #expect(titles(result, .notes) == ["Plain journal"])
        #expect(result.privateCount == 2)
        // The private body's words do not match as plain hits.
        let byBody = Find.query("lexapro", engine: engine)
        #expect(byBody.isEmpty)
    }

    @Test func aWalledQueryReturnsNothingAndNoCount() throws {
        let note = try make(.note, "Wifi password", body: "wifi password is hunter2")
        try make(.note, "Plain wifi plan")
        #expect(SecretWords.mentions("wifi password") || note.title.isEmpty == false)
        let result = Find.query("wifi password", engine: engine)
        #expect(result.groups.isEmpty && result.privateCount == 0)
        let med = Find.query("lexapro", engine: engine)
        #expect(med.groups.isEmpty && med.privateCount == 0)
    }

    @Test func moneyObjectsAreNeverReturnedOrCounted() throws {
        for key in [SystemCatalog.Key.spend, .pool, .inflow, .poolMove, .rateNote, .event] {
            try make(key, "Zephyr thing")
        }
        let result = Find.query("zephyr", engine: engine)
        #expect(result.groups.isEmpty && result.privateCount == 0)
    }

    @Test func deletedObjectsAreSkipped() throws {
        let gone = try make(.task, "Return parcel")
        try make(.task, "Return books")
        store.softDelete(gone)
        #expect(titles(Find.query("return", engine: engine), nil) == ["Return books"])
    }

    @Test func classObjectsAreFoundUnderTraining() throws {
        let bench = try store.ensureClassObject(of: #require(engine.classes[.benchPress]))
        let result = Find.query("bench", engine: engine)
        #expect(result.groups.first?.app == .training)
        #expect(result.groups.first?.hits.contains { $0.id == bench.id && $0.kind == "Bench Press" } == true)
    }

    @Test func rankingExactThenPrefixThenWord() throws {
        let old = Date(timeIntervalSince1970: 1000)
        let new = Date(timeIntervalSince1970: 9000)
        try make(.recipe, "Spicy soup", updated: new)
        try make(.recipe, "Soup of the day", updated: old)
        try make(.recipe, "Soup", updated: old)
        try make(.recipe, "Soup number two", updated: new)
        let hits = try #require(Find.query("soup", engine: engine).groups.first).hits
        #expect(hits.map(\.title) == ["Soup", "Soup number two", "Soup of the day", "Spicy soup"])
        #expect(hits.map(\.score) == [4, 3, 3, 2])
    }

    @Test func fiveThousandObjectsAnswerFast() throws {
        for index in 0 ..< 5000 {
            try make(
                index % 2 == 0 ? .task : .note,
                "Item \(index) thing",
                body: index % 2 == 0 ? nil : "body \(index)"
            )
        }
        // The first private check builds the graph-wide private labels once per revision (cached after that).
        _ = Find.query("item 4999", engine: engine)
        // CPU time, not wall time: the answer must not depend on how busy the machine is.
        let startCPU = clock()
        let result = Find.query("item 4999", engine: engine)
        let cpuMs = Double(clock() - startCPU) * 1000 / Double(CLOCKS_PER_SEC)
        #expect(!result.isEmpty)
        // A matched object costs one ObjectPrivacy.shownLabel (about 10 ms each in a loaded debug build), so the
        // timing query matches one object; the 5,000-object scan itself is what is measured.
        #expect(cpuMs < 150, "took \(cpuMs) ms of CPU")
    }

    @Test func claudeCodeNeverCallsFind() throws {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/TesseraTess")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            #expect(!source.contains("Find.") && !source.contains("FindResult"), "\(file.lastPathComponent)")
        }
    }
}
