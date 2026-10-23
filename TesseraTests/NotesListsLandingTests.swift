import Foundation
import Testing
@testable import Tessera

/// The Notes and Lists landings' fixed sentences (notes-lists-landing-build-sheet-oct22.md section 3 and 4).
struct NotesListsLandingTests {
    @Test func notesSubtitleTemplates() {
        #expect(NotesLandingWords.subtitle(hasNotes: false, topThings: []).text == "A place for loose thoughts.")
        let own = NotesLandingWords.subtitle(hasNotes: true, topThings: [])
        #expect(own.text == "Your notes are on their own." && own.key == "own")
        let one = NotesLandingWords.subtitle(hasNotes: true, topThings: ["Landlord"])
        #expect(one.text == "Landlord comes up most." && one.key == "Landlord")
        let two = NotesLandingWords.subtitle(hasNotes: true, topThings: ["Landlord", "Bench press"])
        #expect(two.text == "Landlord and Bench press come up most.")
    }

    @Test func thingsParagraphHasNoDigit() throws {
        let line = try #require(NotesLandingWords.paragraph(["Landlord", "Bench press", "Trip"]))
        #expect(line == "You write about Landlord, Bench press, and Trip.")
        #expect(NotesLandingWords.paragraph(["A", "B"]) == "You write about A and B.")
        #expect(NotesLandingWords.paragraph(["A"]) == "You write about A.")
        #expect(NotesLandingWords.paragraph([]) == nil)
        #expect(line.allSatisfy { !$0.isNumber })
    }

    @Test func filterMatchesWordStartsAndIgnoresCaseAndAccents() {
        #expect(NotesLandingWords.matches("Bench press", filter: "ben"))
        #expect(NotesLandingWords.matches("Bench press", filter: "PRE"))
        #expect(NotesLandingWords.matches("Café", filter: "cafe"))
        #expect(!NotesLandingWords.matches("Bench press", filter: "zzz"))
        #expect(NotesLandingWords.matches("Landlord", filter: ""))
        #expect(NotesLandingWords.noMatch("zzz") == "No thing called \u{201C}zzz\u{201D}. Return writes it as a note.")
    }

    @Test func notesMarginAndNewLines() {
        #expect(NotesLandingWords.names(weekday: "Tue", thing: "Bench press")
            == "Your note from Tue names Bench press.")
        #expect(NotesLandingWords.newNotes(things: ["Landlord"], loose: false, notes: 1) == "A new note about Landlord.")
        #expect(NotesLandingWords.newNotes(things: ["A", "B"], loose: false, notes: 1) == "A new note about A and B.")
        #expect(NotesLandingWords.newNotes(things: ["A", "B", "C"], loose: false, notes: 3) == "New notes about A and B.")
        #expect(NotesLandingWords.newNotes(things: [], loose: true, notes: 1) == "A new loose note.")
        #expect(NotesLandingWords.newNotes(things: [], loose: false, notes: 0) == nil)
    }

    @Test func listLinesReadTheirTemplates() {
        func line(left: Int, total: Int, groceries: Bool = false, running: Bool = false,
                  source: String? = nil) -> String
        {
            ListsLandingFacts.Line(id: UUID(), name: "Packing", isGroceries: groceries, isPrivate: false,
                                   isRunning: running, isReusable: false, isPickOne: false, left: left,
                                   total: total, newSource: source).line
        }
        #expect(line(left: 3, total: 9) == "3 left")
        #expect(line(left: 6, total: 9, groceries: true) == "6 to get")
        #expect(line(left: 6, total: 9, groceries: true, source: "Tacos") == "6 to get, new from Tacos")
        #expect(line(left: 3, total: 9, running: true) == "Running, 3 left")
        #expect(line(left: 0, total: 9) == "All done")
        #expect(line(left: 0, total: 0) == "Empty")
    }

    @Test func theFillIsTheShareDone() {
        let line = ListsLandingFacts.Line(id: UUID(), name: "Groceries", isGroceries: true, isPrivate: false,
                                          isRunning: false, isReusable: false, isPickOne: false, left: 6, total: 9)
        #expect(abs(line.fraction - 0.33) < 0.01)
        #expect(ListsLandingFacts.Line(id: UUID(), name: "x", isGroceries: false, isPrivate: false, isRunning: false,
                                       isReusable: false, isPickOne: false, left: 0, total: 0).fraction == 0)
    }

    @Test func joinedListsUseTheHouseAnd() {
        #expect(LandingList.joined(["A"]) == "A" && LandingList.joined(["A", "B"]) == "A and B")
        #expect(LandingList.joined(["A", "B", "C"]) == "A, B, and C")
    }
}
