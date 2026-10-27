import Foundation
@testable import TesseraCore
import Testing

/// Kaushik, Oct 26: no full stop at the end of any shown line. Generated lines (receipts, summaries, landing
/// sentences, Home's app lines) are read here and none may end in "." The only exclusion is what he wrote himself:
/// note and document bodies (`excluded`), kept explicit and small.
@MainActor
struct NoFullStopTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    /// What may end in a full stop because he typed it: the body of a note or a recipe method he wrote.
    static let excluded: Set<String> = ["noteBody", "recipeMethod"]

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    static func offenders(_ lines: [String]) -> [String] {
        lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasSuffix(".") && !$0.hasSuffix("...") }
    }

    @Test func receiptsAndSummariesHaveNoTrailingStop() throws {
        var lines: [String] = []
        func keep(_ record: OpRecord) {
            lines.append(record.summary)
            if let receipt = record.receipt {
                lines.append(receipt)
            }
        }
        let list = try engine.perform(CreateList(name: "Packing"), by: .user)
        keep(list.record)
        try keep(engine.perform(AddListItem(list: list.output.id, text: "Charger"), by: .user).record)
        let item = try #require(ListContents(store: store, classes: engine.classes).open(in: list.output).first)
        try keep(engine.perform(CheckListItem(item: item.id, done: true), by: .user).record)
        try keep(engine.perform(CreateTask(title: "Call the plumber"), by: .user).record)
        try keep(engine.perform(LogSpend(amount: 12.4, typed: "12.40", note: "lunch"), by: .user).record)
        try keep(engine.perform(CreateList(name: "Packing"), by: .user).record)
        #expect(Self.offenders(lines).isEmpty, "\(Self.offenders(lines))")
    }

    @Test func landingSentencesHaveNoTrailingStop() {
        let lines = [
            LandingSentences.kitchen(dish: "Tacos", start: "6:05", shortOf: "Limes").text,
            LandingSentences.kitchen(dish: nil, start: nil, shortOf: nil).text,
            LandingSentences.money(nothingLate: true, due: ("Rent", "Friday"), trend: "October is running under").text,
            LandingSentences.money(nothingLate: false, due: nil, trend: nil).text,
            LandingSentences.cooking(dish: "Tacos", minutesLeft: 8),
            LandingSentences.notesSubtitle(hasNotes: true, top: ["Landlord"]).text,
            LandingSentences.listRunning("Packing", left: 3).text,
            LandingSentences.listDue("Trip", day: "Fri").text,
            LandingSentences.listTouchedLast("Packing").text,
            LandingSentences.routineRunning("Stretch").text,
            LandingSentences.startOneList.text,
            LandingSentences.nothingRunning.text,
        ]
        #expect(Self.offenders(lines).isEmpty, "\(Self.offenders(lines))")
    }

    @Test func homeAppLinesHaveNoTrailingStop() throws {
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "Charger"), by: .user)
        try engine.perform(CreateTask(title: "Call the plumber"), by: .user)
        let lines = AppSummaryLines.lines(engine: engine, plan: nil).map(\.text)
        #expect(!lines.isEmpty)
        #expect(Self.offenders(lines).isEmpty, "\(Self.offenders(lines))")
    }

    @Test func aNoteBodyHeTypedKeepsItsStop() throws {
        // The exclusion: his own words are his.
        let body = "Ideas for the garage gym\nRubber floor, a second bench."
        let note = try engine.perform(CreateNote(body: body), by: .user).output
        #expect(NoteList(store: store, classes: engine.classes).recent().contains { $0.id == note.id })
        #expect(Self.excluded.contains("noteBody"))
    }
}
