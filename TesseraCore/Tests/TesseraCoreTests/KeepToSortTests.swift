import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// When Tess cannot read a phrase on the phone and Claude is not there, she keeps it as a note to sort later instead
/// of dropping it (Product): the thing first, a walled phrase kept without an echo, a key never kept.
@MainActor
struct KeepToSortTests {
    let store = ObjectStore.open(inMemory: true)

    func tess() throws -> (TessCaptureEngine, ActionEngine) {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        return (TessCaptureEngine(engine: engine), engine)
    }

    @Test func anUnreadablePhraseIsKeptWithItsOwnWordsAndOneUndo() async throws {
        let (tess, engine) = try tess()
        let capture = await tess.capture("the thing about the garage door", context: TessContext())
        #expect(capture.line == "the thing about the garage door, kept to sort later." && capture.keptToSort)
        #expect(capture.records.count == 1 && capture.records[0].state == .pending)
        try engine.commit(capture.records[0])
        let notes = try store.objects(of: #require(engine.classes[.note]))
        #expect(notes.contains { $0.title == "the thing about the garage door" })
        engine.undo(capture.records[0])
        #expect(try !store.objects(of: #require(engine.classes[.note])).contains { !$0.isDeleted })
    }

    @Test func aWalledPhraseIsKeptOnThePhoneWithNoEcho() async throws {
        let (tess, _) = try tess()
        let capture = await tess.capture("blorp I paid 40 for gas blorp", context: TessContext())
        #expect(capture.keptToSort && capture.line == "Kept to sort later.")
        #expect(!capture.line.contains("gas") && !capture.line.contains("40") && !capture.line.lowercased()
            .contains("private note"))
        // A bare medicine reads the same way: kept, never echoed.
        let health = await tess.capture("blorp lexapro blorp", context: TessContext())
        #expect(health.keptToSort && health.line == "Kept to sort later.")
    }

    @Test func aClaudeKeyIsNeverKeptOrEchoed() async throws {
        let (tess, engine) = try tess()
        let key = ["sk", "ant", "api03"].joined(separator: "-") + "-TESTFAKE" + String(repeating: "x", count: 30)
        let capture = await tess.capture(key, context: TessContext())
        #expect(!capture.keptToSort && capture.records.isEmpty && capture.line == TessRouter.keyLine)
        #expect(try store.objects(of: #require(engine.classes[.note])).isEmpty)
    }

    @Test func aLiveSetKeepsItsOwnTryLineAndNothingIsKept() async throws {
        let (tess, engine) = try tess()
        let workout = try store.create(#require(engine.classes[.workout]), title: "Push")
        let entry = try engine.perform(
            AddExercise(workout: workout.id, exercise: #require(engine.classes[.benchPress]).id),
            by: .user
        ).output
        var live = TessContext()
        live.entry = entry.id
        let capture = await tess.capture("blorp", context: live)
        #expect(!capture.keptToSort && capture.line == "Didn't catch that. Try \u{201C}80 × 8\u{201D}.")
    }

    @Test func siriCommitsAtOnce() async throws {
        let (tess, engine) = try tess()
        var shortcut = TessContext()
        shortcut.commitImmediately = true
        let capture = await tess.capture("blorp the thing with the car", context: shortcut)
        #expect(capture.keptToSort && capture.records.first?.state == .committed)
        #expect(try !store.objects(of: #require(engine.classes[.note])).isEmpty)
    }
}
