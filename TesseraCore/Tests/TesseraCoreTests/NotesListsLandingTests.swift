import Foundation
@testable import TesseraCore
import Testing

/// Notes and Lists landing facts (Product build sheet, Oct 22): sentences from fixed templates, masked first.
@MainActor
struct NotesListsLandingTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    // MARK: Notes

    @discardableResult
    func thing(_ name: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[.thing]), title: name)
    }

    @discardableResult
    func note(_ body: String, isPrivate: Bool = false, on day: Int? = nil) throws -> ObjectRecord {
        let made = try engine.perform(CreateNote(body: body, isPrivate: isPrivate ? true : nil), by: .user).output
        if let day {
            made.createdAt = at(day)
        }
        return made
    }

    var notes: NotesLanding {
        NotesLanding(store: store, classes: engine.classes)
    }

    func seedThree() throws {
        try thing("Landlord")
        try thing("Squat day")
        try thing("Trip")
        for index in 0 ..< 4 {
            try note("Called @Landlord about the heat \(index)")
        }
        for _ in 0 ..< 3 {
            try note("@Squat day felt strong")
        }
        try note("Pack for the @Trip")
    }

    @Test func thingsAreWeighedAndOrderedAndTheTopThreeAreLarge() throws {
        try seedThree()
        let facts = notes.facts()
        #expect(facts.things.map(\.name) == ["Landlord", "Squat day", "Trip"])
        #expect(facts.things.map(\.weight) == [4, 3, 1] && facts.things.allSatisfy(\.isLarge))
        #expect(facts.hasNotes && !facts.hasLoose && !facts.hasPrivate)
    }

    @Test func subtitleAndWriteAboutHoldNoDigit() throws {
        try seedThree()
        let facts = notes.facts()
        let subtitle = LandingSentences.notesSubtitle(hasNotes: facts.hasNotes, top: facts.topNames)
        #expect(subtitle.text == "Landlord and Squat day come up most." && subtitle.key == "Landlord")
        let about = try #require(LandingSentences.youWriteAbout(facts.topNames))
        #expect(about.text == "You write about Landlord, Squat day, and Trip.")
        for text in [subtitle.text, about.text] {
            #expect(text.allSatisfy { !$0.isNumber })
        }
    }

    @Test func everyNotesTemplate() {
        #expect(LandingSentences.notesSubtitle(hasNotes: false, top: []).text == "A place for loose thoughts.")
        #expect(LandingSentences.notesSubtitle(hasNotes: true, top: []).text == "Your notes are on their own.")
        #expect(LandingSentences.notesSubtitle(hasNotes: true, top: ["Landlord"]).text == "Landlord comes up most.")
        #expect(LandingSentences.youWriteAbout(["A", "B"])?.text == "You write about A and B.")
        #expect(LandingSentences.youWriteAbout(["A"])?.text == "You write about A.")
        #expect(LandingSentences.youWriteAbout(["A", "B", "C", "D", "E"])?.text == "You write about A, B, C, and D.")
        #expect(LandingSentences.youWriteAbout([]) == nil)
        #expect(LandingSentences.noThingCalled("Lando")
            .text == "No thing called \"Lando\". Return writes it as a note.")
        #expect(LandingSentences.noteOpen(title: "Heat", isPrivate: false).text == "Heat is open.")
        #expect(LandingSentences.noteOpen(title: "Heat", isPrivate: true).text == "Private note is open.")
        #expect(LandingSentences.notThingYet("Zed").text == "@Zed is not a thing yet.")
        #expect(LandingSentences.newNotes(count: 1, about: ["Landlord"]).text == "A new note about Landlord.")
        #expect(LandingSentences.newNotes(count: 1, about: ["A", "B", "C"]).text == "A new note about A and B.")
        #expect(LandingSentences.newNotes(count: 3, about: ["A", "B"]).text == "New notes about A and B.")
        #expect(LandingSentences.newNotes(count: 1, about: []).text == "A new loose note.")
    }

    @Test func aPrivateNoteNeverLeavesTheNotesFileExceptAsHasPrivate() throws {
        try seedThree()
        try note("my password is hunter2", isPrivate: true)
        let facts = notes.facts(.init(lastSeen: at(1)))
        #expect(facts.hasPrivate)
        let sentences = (facts.margin.map(\.sentence.text) + [
            LandingSentences.notesSubtitle(hasNotes: true, top: facts.topNames).text,
            LandingSentences.youWriteAbout(facts.topNames)?.text ?? "",
        ]).joined(separator: " ")
        #expect(!sentences.contains("hunter2") && !sentences.lowercased().contains("password"))
        // A private note about a thing never adds weight.
        for _ in 0 ..< 5 {
            try note("@Landlord secret thing", isPrivate: true)
        }
        let after = notes.facts()
        #expect(after.hasPrivate && after.things.first?.weight == 4)
    }

    @Test func looseNotesAreFlagged() throws {
        try note("Just a thought")
        #expect(notes.facts().hasLoose)
        #expect(notes.facts().things.isEmpty)
    }

    @Test func linkSuggestNamesAThingInAnUnlinkedNote() throws {
        try seedThree()
        // Tuesday, Oct 20.
        try note("squat day was heavy", on: 20)
        let withSuggest = notes.facts(.init(linkSuggest: true, now: at(22), calendar: calendar))
        let first = try #require(withSuggest.margin.first)
        #expect(first.sentence.text == "Your note from Tue names Squat day." && first.action == "Link them")
        #expect(first.kind == .waiting)
        let off = notes.facts(.init(linkSuggest: false, now: at(22), calendar: calendar))
        #expect(off.margin.isEmpty)
    }

    @Test func anUnknownAtWordSaysMakeItAThing() throws {
        try note("Ask @Zebra about it")
        let line = try #require(notes.facts().margin.first)
        #expect(line.sentence.text == "@Zebra is not a thing yet." && line.action == "Make it a thing")
    }

    @Test func newNotesAreTheLastLinesAndWaitingComesFirst() throws {
        try seedThree()
        try note("squat day was heavy", on: 20)
        try note("Another @Landlord note", on: 21)
        try note("Ask @Zebra about it", on: 21)
        let facts = notes.facts(.init(linkSuggest: true, lastSeen: at(20, 23), now: at(22), calendar: calendar))
        #expect(facts.margin.count == 3)
        #expect(facts.margin.map(\.kind) == [.waiting, .waiting, .new])
        let off = notes.facts(.init(
            margin: false,
            linkSuggest: true,
            lastSeen: at(20),
            now: at(22),
            calendar: calendar
        ))
        #expect(off.margin.isEmpty)
    }

    @Test func aWalledThingNeverAppears() throws {
        try thing("my password hunter2")
        try note("About @[my password hunter2] again")
        let facts = notes.facts()
        #expect(facts.things.isEmpty)
        #expect(LandingSentences.notesSubtitle(hasNotes: true, top: facts.topNames)
            .text == "Your notes are on their own.")
    }

    @Test func noNotesAtAllReadsTheEmptyLine() {
        let facts = notes.facts()
        #expect(!facts.hasNotes && facts.things.isEmpty && facts.margin.isEmpty && facts.book == nil)
        #expect(LandingSentences.notesSubtitle(hasNotes: facts.hasNotes, top: []).text == "A place for loose thoughts.")
    }

    // MARK: Lists

    var lists: ListsLanding {
        ListsLanding(engine: engine)
    }

    @discardableResult
    func list(_ name: String, items: [String] = [], done: Int = 0) throws -> ObjectRecord {
        let made = try engine.perform(CreateList(name: name), by: .user).output
        for text in items {
            try engine.perform(AddListItem(list: made.id, text: text), by: .user)
        }
        for item in ListContents(store: store, classes: engine.classes).open(in: made).prefix(done) {
            try engine.perform(CheckListItem(item: item.id, done: true), by: .user)
        }
        return made
    }

    func words(_ count: Int) -> [String] {
        (1 ... count).map { "Thing \($0)" }
    }

    @Test func aRunningListLeadsWithItsLeftAndItsNextItems() throws {
        let packing = try list("Packing, Lisbon", items: (1 ... 24).map { "Item \($0)" }, done: 18)
        try engine.perform(StartListRun(list: packing.id), by: .user)
        let lead = try #require(lists.facts().lead)
        #expect(lead.sentence.text == "Packing, Lisbon is running, 6 left." && lead.sentence.key == "Packing, Lisbon")
        #expect(lead.leftOf == "6 left of 24" && lead.left == 6 && lead.total == 24)
        #expect(lead.nextItems == ["Item 19", "Item 20", "Item 21", "Item 22"])
    }

    @Test func theLeadOrderIsRunningThenDueThenLastTouched() throws {
        let old = try list("Chores", items: ["Dust"])
        let due = try list("Trip", items: ["Passport"])
        let tomorrow = at(23)
        let item = try #require(ListContents(store: store, classes: engine.classes).open(in: due).first)
        try store.set(
            "notes",
            to: .richText(ListNoteTags.setting(stamp: ListNoteTags.duePrefix, to: tomorrow, in: nil) ?? ""),
            on: item.object
        )
        _ = old
        let touched = try list("Movies", items: ["Dune"])
        _ = touched
        // Nothing running, switch off: last touched.
        #expect(try #require(lists.facts(.init(now: at(22), calendar: calendar)).lead).sentence.text
            == "Movies is the one you touched last.")
        // The due switch on: the list due soonest.
        let byDue = try #require(lists.facts(.init(leadByDue: true, now: at(22), calendar: calendar)).lead)
        #expect(byDue.sentence.text == "Trip is due tomorrow.")
        // A run beats both.
        try engine.perform(StartListRun(list: old.id), by: .user)
        let running = try #require(lists.facts(.init(leadByDue: true, now: at(22), calendar: calendar)).lead)
        #expect(running.sentence.text == "Chores is running, 1 left.")
    }

    @Test func noListsReadsTheStartLine() {
        let facts = lists.facts()
        #expect(facts.lead == nil && facts.others.isEmpty && facts.margin.isEmpty)
        #expect(facts.subtitle.text == "Start one with a few words.")
    }

    @Test func groceriesFillsAndSaysWhatIsNewFromARecipe() throws {
        let recipe = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n200 g beef mince\n4 tortillas\n1 lime\n"
                + "2 tomatoes\n1 onion\n1 avocado\nMethod\n1. Cook it."), by: .user).output
        let seen = Date()
        try engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        let groceries = try #require(Groceries(store: store, classes: engine.classes).list)
        for text in ["Milk", "Eggs", "Butter"] {
            try engine.perform(AddListItem(list: groceries.id, text: text), by: .user)
        }
        let items = ListContents(store: store, classes: engine.classes).open(in: groceries)
        for item in items.suffix(3) {
            try engine.perform(CheckListItem(item: item.id, done: true), by: .user)
        }
        // A list touched later takes the lead; Groceries sits among the others.
        try list("Movies", items: ["Dune"])
        let facts = lists.facts(.init(lastSeen: seen.addingTimeInterval(-1)))
        let row = try #require(facts.others.first { $0.name == "Groceries" })
        #expect(row.total == 9 && row.done == 3 && abs(row.fill - 1.0 / 3.0) < 0.001)
        #expect(row.line == "6 to get, new from Tacos")
        #expect(facts.margin.first?.sentence.text == "Groceries has 6 new, from Tacos.")
    }

    @Test func fillIsZeroWithNothingDoneAndOneWhenAllDoneAndSays() throws {
        try list("Empty", items: [])
        try list("Fresh", items: words(9))
        try list("Finished", items: words(9), done: 9)
        try list("Lead", items: ["One"])
        let others = lists.facts().others
        func row(_ name: String) throws -> ListsLanding.Other {
            try #require(others.first { $0.name == name })
        }
        #expect(try row("Fresh").fill == 0 && row("Fresh").line == "9 left")
        #expect(try row("Finished").fill == 1 && row("Finished").line == "All done")
        #expect(try row("Empty").line == "Empty" && row("Empty").fill == 0)
    }

    @Test func aDueListSaysWhenAndAnItemDueTomorrowIsWaiting() throws {
        let packing = try list("Packing", items: ["Passport", "Socks"])
        let passport = try #require(ListContents(store: store, classes: engine.classes).open(in: packing).first)
        try store.set("notes", to: .richText("due: " + at(23).formatted(.iso8601)), on: passport.object)
        try list("Movies", items: ["Dune"])
        let facts = lists.facts(.init(now: at(22), calendar: calendar))
        #expect(facts.margin.first?.sentence.text == "Passport is due tomorrow on Packing.")
        #expect(facts.margin.first?.kind == .waiting)
        #expect(!facts.margin.contains { $0.sentence.text.lowercased().contains("late") })
        let other = try #require(facts.others.first { $0.name == "Packing" })
        #expect(other.line == "Due tomorrow, 2 left")
    }

    @Test func aReusableListThatIsDoneAsksForAReset() throws {
        let packing = try list("Packing", items: ["Passport"], done: 1)
        try store.set("notes", to: .richText(ListNoteTags.reusable), on: packing)
        try list("Movies", items: ["Dune"])
        let line = try #require(lists.facts().margin.first)
        #expect(line.sentence.text == "Packing is done. Reset it for next time" && line.action == "Reset it")
        #expect(lists.facts().doors.reusable == 1)
    }

    @Test func privateListsAndItemsAreMaskedAndTheirCountsStay() throws {
        let secret = try list("Ozempic dose", items: (1 ... 24).map { "Ozempic dose \($0)" }, done: 18)
        try engine.perform(StartListRun(list: secret.id), by: .user)
        let facts = lists.facts()
        let lead = try #require(facts.lead)
        #expect(lead.sentence.text == "Private list is running, 6 left." && lead.leftOf == "6 left of 24", "\(lead)")
        #expect(lead.nextItems.allSatisfy { $0 == "Private item" })
        let every = ([lead.sentence.text] + lead.nextItems + facts.margin.map(\.sentence.text)).joined(separator: " ")
        #expect(!every.lowercased().contains("ozempic"))
    }

    @Test func otherListsAreCappedAtSix() throws {
        for index in 0 ..< 9 {
            try list("List \(index)", items: ["a"])
        }
        let facts = lists.facts()
        #expect(facts.others.count == 6 && facts.lead != nil)
    }

    @Test func nothingHereIsAClaudeJob() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        for file in try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            let text = try String(contentsOf: file, encoding: .utf8)
            for name in ["NotesLanding", "ListsLanding"] {
                #expect(!text.contains(name), "\(file.lastPathComponent) mentions \(name)")
            }
        }
    }
}
