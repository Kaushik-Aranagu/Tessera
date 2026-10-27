import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// docs/research/fixtures/spoken-normaliser.md, "Live-workout number words" (board item 78): K811, K812, N01 to N24,
/// plus SQ8's Q24 and Q25 and K885. The text each gives, then what the grammar does with it in a live workout.
@MainActor
struct SpokenNumbersTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let id: String
        let heard: String
        let text: String
        init(_ id: String, _ heard: String, _ text: String) {
            self.id = id
            self.heard = heard
            self.text = text
        }

        var testDescription: String {
            "\(id) \(heard)"
        }
    }

    nonisolated static let rows: [Row] = [
        .init("K811", "eighty two and a half for eight", "82.5 for 8"),
        .init("K812", "a hundred for five at eight", "100 for 5 at 8"),
        .init("N01", "a hundred and five", "105"),
        .init("N02", "a hundred and five for three", "105 for 3"),
        .init("N03", "a hundred, five", "100, 5"),
        .init("N04", "eighty two point four", "82.4"),
        .init("N05", "eighty two  point four for six", "82.4 for 6"),
        .init("N06", "one oh five for five", "105 for 5"),
        .init("N07", "twenty four reps", "24 reps"),
        .init("N08", "twenty four", "24"),
        .init("N09", "eight at three", "8 at 3"),
        .init("N10", "eight reps at nine", "8 reps at 9"),
        .init("N11", "same at nine and a half", "same at 9.5"),
        .init("N12", "eighty for 8", "80 for 8"),
        .init("N13", "100 for five at 8", "100 for 5 at 8"),
        .init("N14", "a couple more", "a couple more"),
        .init("N15", "ten ten ten", "10 10 10"),
        .init("N16", "ten, ten, ten", "10, 10, 10"),
        .init("N17", "one more set", "one more set"),
        .init("N18", "a hundred for for", "100 for 4"),
        .init("N19", "eighty four eight", "84 8"),
        .init("N20", "a eighty for a eight", "80 for 8"),
        .init("N21", "and eighty for eight reps", "80 for 8"),
        .init("N22", "drop to seventy two for ten", "drop to 72 for 10"),
        .init("N23", "call mum at seven", "call mum at 7"),
        .init("N24", "plus five", "+5"),
        .init("Q24", "two kilos times ten", "2 kg x 10"),
        .init("Q25", "two times ten", "2 x 10"),
        .init("ST1", "eighty eighty for eight", "80 for 8"),
        .init("ST2", "one more", "one more"),
        .init("ST3", "two plates for five", "two plates for 5"),
        .init("ST4", "one twenty five for five", "125 for 5"),
        .init("ST5", "Eighty-five for six", "85 for 6"),
        .init("ST6", "185 pounds for 5", "185 lb for 5"),
    ]

    @Test(arguments: rows) func spokenNumbers(_ row: Row) {
        #expect(TessSpoken.numbers(row.heard) == row.text)
        // Idempotent: digits pass through untouched.
        #expect(TessSpoken.numbers(row.text) == row.text)
    }

    struct Parse: Sendable, CustomTestStringConvertible {
        let id: String
        let heard: String
        let line: String
        var testDescription: String {
            "\(id) \(heard)"
        }
    }

    /// Bench Press in focus, last set 80 x 8 (context W), through the capture engine with no model.
    nonisolated static let parses: [Parse] = [
        .init(id: "K811", heard: "eighty two and a half for eight", line: "Set 2 logged. 82.5 × 8"),
        .init(id: "K812", heard: "a hundred for five at eight", line: "Set 2 logged. 100 × 5, RPE 8"),
        .init(id: "N01", heard: "a hundred and five", line: "105 for how many reps?"),
        .init(id: "N05", heard: "eighty two point four for six", line: "Set 2 logged. 82.5 × 6, nearest load to 82.4"),
        .init(id: "N06", heard: "one oh five for five", line: "Set 2 logged. 105 × 5"),
        .init(id: "N10", heard: "eight reps at nine", line: "Set 2 logged. 80 × 8, RPE 9"),
        .init(id: "N11", heard: "same at nine and a half", line: "Set 2 logged, same again, RPE 9.5"),
        .init(id: "N16", heard: "ten, ten, ten", line: "Sets 2 to 4 logged. 80 × 10"),
        .init(id: "N22", heard: "drop to seventy two for ten", line: "Drop set logged. 72.5 × 10, nearest load to 72"),
        .init(id: "N24", heard: "plus five", line: "Say the set, like 85 × 8"),
    ]

    @Test(arguments: parses) func throughTheGrammar(_ row: Parse) async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let capture = await TessCaptureEngine(engine: engine)
            .capture(TessSpoken.numbers(row.heard), context: TessContext(entry: entry.id, process: workout.id))
        #expect(capture.line == row.line)
    }

    @Test func aHundredCommaFiveIsNeverGroceries() async throws {
        // K885: "a hundred, five" in a live workout: one set from two parts is not guessed, and never a grocery list.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        for heard in ["a hundred, five", TessSpoken.numbers("a hundred, five")] {
            let capture = await TessCaptureEngine(engine: engine)
                .capture(heard, context: TessContext(entry: entry.id, process: workout.id))
            #expect(capture.records.isEmpty, "\(heard)")
        }
    }
}
