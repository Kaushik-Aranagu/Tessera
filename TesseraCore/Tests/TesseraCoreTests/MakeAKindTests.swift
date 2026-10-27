import Foundation
@testable import TesseraCore
import Testing

/// Together piece 6, Make a kind (product sheet 135): the offer, the kind, and keeping notes as objects.
@MainActor
struct MakeAKindTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let now = Date(timeIntervalSince1970: 1_792_000_000)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func daysAgo(_ days: Int) -> Date {
        now.addingTimeInterval(-Double(days) * 86400 - 60)
    }

    @discardableResult
    func thing(_ name: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[.thing]), title: name)
    }

    @discardableResult
    func note(_ body: String, daysAgo days: Int = 1) throws -> ObjectRecord {
        let made = try engine.perform(CreateNote(body: body), by: .user).output
        made.createdAt = daysAgo(days)
        return made
    }

    func notes(about word: String, _ count: Int, daysAgo days: Int = 1) throws {
        for index in 0 ..< count {
            try note("Called @\(word) about it \(index)", daysAgo: days)
        }
    }

    var offer: KindOffer? {
        KindOffer.today(engine: engine, now: now, calendar: calendar)
    }

    // MARK: The offer

    @Test func appearsAtFourNotesNotThree() throws {
        try thing("Landlord")
        try notes(about: "Landlord", 3)
        #expect(offer == nil)
        try note("@Landlord fixed the heat")
        let found = try #require(offer)
        #expect(found.word == "Landlord" && found.noteIDs.count == 4)
    }

    @Test func oldNotesDoNotCount() throws {
        try thing("Landlord")
        try notes(about: "Landlord", 3)
        try notes(about: "Landlord", 5, daysAgo: 45)
        #expect(offer == nil)
    }

    @Test func privateNotesDoNotCount() throws {
        try thing("Landlord")
        try notes(about: "Landlord", 3)
        let hidden = try note("@Landlord and my plans")
        try store.set("isPrivate", to: .bool(true), on: hidden)
        #expect(offer == nil)
    }

    @Test func aWalledWordIsNeverOffered() throws {
        let walled = try thing("lexapro")
        for index in 0 ..< 5 {
            let made = try note("felt fine \(index)")
            try store.setLinks("about", on: made, to: [walled])
        }
        #expect(offer == nil)
    }

    @Test func anExistingClassNameIsNotOffered() throws {
        try thing("Landlord")
        try notes(about: "Landlord", 4)
        try engine.perform(MakeKind(word: "landlord"), by: .user)
        #expect(offer == nil)
        try thing("Muscle")
        try notes(about: "Muscle", 4)
        #expect(offer == nil)
    }

    @Test func theBusiestWordWinsAndTiesGoToTheLatest() throws {
        try thing("Landlord")
        try thing("Trip")
        try thing("Garden")
        try notes(about: "Landlord", 4, daysAgo: 5)
        try notes(about: "Trip", 4, daysAgo: 2)
        #expect(offer?.word == "Trip")
        try notes(about: "Garden", 6, daysAgo: 10)
        #expect(offer?.word == "Garden")
        let ids = try #require(offer).noteIDs
        let dates = ids.compactMap { store.object(id: $0)?.createdAt }
        #expect(dates == dates.sorted(by: >))
    }

    // MARK: The kind

    @Test func makeKindCreatesTheClassWithFieldsAndUndoRemovesIt() throws {
        let result = try engine.perform(MakeKind(word: "landlord", fields: [" Phone ", "phone", "Due date"]), by: .user)
        let kind = result.output
        #expect(kind.name == "Landlord" && kind.parent?.id == engine.classes[.thing]?.id)
        let own = (kind.ownFields ?? []).sorted { $0.sortIndex < $1.sortIndex }
        #expect(own.map(\.key) == ["phone", "dueDate", "sourceNote"] && own.map(\.name).prefix(2) == [
            "Phone",
            "Due date",
        ])
        let textKinds = own.dropLast().map(\.kind)
        #expect(textKinds == [.text, .text] && own.last?.kind == .ref)
        #expect(result.record.summary == "Kind made" && result.record.receipt == "Landlord, made")
        #expect(result.record.ops.count == 1 || result.record.ops
            .allSatisfy {
                if case .createClass = $0 {
                    true
                } else {
                    false
                }
            })
        engine.undo(result.record)
        #expect(store.classDef(id: kind.id) == nil)
        #expect(store.context.all(FieldDef.self).allSatisfy { $0.owner?.id != kind.id })
    }

    @Test func makeKindRefusesBadInput() throws {
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "  "), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "lexapro"), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "Muscle"), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "Boss", fields: [""]), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "Boss", fields: ["lexapro"]), by: .user) }
        let seven = (1 ... 7).map { "Field \($0)" }
        #expect(throws: ActionError.self) { try engine.perform(MakeKind(word: "Boss", fields: seven), by: .user) }
        #expect(store.allClasses().first { $0.name == "Boss" } == nil)
        let six = try engine.perform(MakeKind(word: "Boss", fields: Array(seven.prefix(6))), by: .user).output
        #expect(six.ownFields?.count == 7)
        #expect(throws: ActionError.self) { try engine.perform(
            MakeKind(word: "Boss2", fields: ["Source note"]),
            by: .user
        ) }
    }

    // MARK: Keeping notes

    @Test func keepNoteMakesAnObjectLinkedToTheNoteAndLeavesTheNote() throws {
        try thing("Landlord")
        let kind = try engine.perform(MakeKind(word: "Landlord", fields: ["Details"]), by: .user).output
        let source = try note("Heat is out again\nCalled twice this week")
        let before = (source.title, store.value("body", of: source))
        let aboutBefore = store.linkedObjects("about", of: source).map(\.id)
        let result = try engine.perform(KeepNoteAsObject(note: source.id, kind: kind.id), by: .user)
        let object = result.output
        #expect(object.classDef?.id == kind.id && object.title == "Heat is out again")
        #expect(store.value("details", of: object)?.stringValue == "Heat is out again\nCalled twice this week")
        #expect(store.linkedObjects("sourceNote", of: object).map(\.id) == [source.id])
        #expect(store.linkedObjects("about", of: source).map(\.id) == aboutBefore)
        #expect(source.title == before.0 && store.value("body", of: source) == before.1)
        #expect(!source.isDeleted)
        #expect(result.record.summary == "Note kept")
        engine.undo(result.record)
        #expect(object.isDeleted)
    }

    @Test func theSourceLineReadsPrivateNoteOnceTheNoteTurnsPrivate() throws {
        let kind = try engine.perform(MakeKind(word: "Landlord", fields: ["Details"]), by: .user).output
        let source = try note("Heat is out again\nCalled twice this week")
        let object = try engine.perform(KeepNoteAsObject(note: source.id, kind: kind.id), by: .user).output
        #expect(KindSource.line(of: object, store: store, classes: engine.classes) == "Heat is out again")
        try store.set("isPrivate", to: .bool(true), on: source)
        #expect(KindSource.line(of: object, store: store, classes: engine.classes) == "Private note")
        store.softDelete(source)
        #expect(KindSource.line(of: object, store: store, classes: engine.classes) == nil)
    }

    @Test func aKindWithoutSourceNoteStillKeepsAndTheNoteIsUntouched() throws {
        let kind = try engine.perform(MakeKind(word: "Old", fields: ["Details"]), by: .user).output
        for field in kind.ownFields ?? [] where field.key == "sourceNote" {
            store.context.delete(field)
        }
        store.invalidateCaches()
        let source = try note("Legacy note")
        let aboutBefore = store.linkedObjects("about", of: source).map(\.id)
        let object = try engine.perform(KeepNoteAsObject(note: source.id, kind: kind.id), by: .user).output
        #expect(object.classDef?.id == kind.id && store.linkedObjects("about", of: source).map(\.id) == aboutBefore)
    }

    @Test func keepAllSkipsPrivateAndDeletedAndReportsTheCount() throws {
        let kind = try engine.perform(MakeKind(word: "Landlord", fields: ["Details"]), by: .user).output
        let first = try note("Heat out")
        let second = try note("Rent talk")
        let hidden = try note("Secret thing")
        try store.set("isPrivate", to: .bool(true), on: hidden)
        let gone = try note("Old news")
        try engine.perform(DeleteObject(object: gone.id), by: .user)
        let result = try engine.perform(
            KeepAllNotes(notes: [first.id, second.id, hidden.id, gone.id, first.id], kind: kind.id), by: .user
        )
        #expect(result.output == 2 && result.record.receipt == "2 kept")
        #expect(store.objects(of: kind).count == 2)
        #expect(!store.objects(of: kind).contains { $0.title.contains("Secret") })
        #expect(throws: ActionError.self) { try engine.perform(
            KeepNoteAsObject(note: hidden.id, kind: kind.id),
            by: .user
        ) }
        engine.undo(result.record)
        #expect(store.objects(of: kind).filter { !$0.isDeleted }.isEmpty)
    }

    @Test func summariesHoldNoNoteTextAndNothingGoesToTheModel() throws {
        let kind = try engine.perform(MakeKind(word: "Landlord", fields: ["Details"]), by: .user).output
        let source = try note("Zebra99 landlord rant about parking")
        let one = try engine.perform(KeepNoteAsObject(note: source.id, kind: kind.id), by: .user).record
        let all = try engine.perform(KeepAllNotes(notes: [source.id], kind: kind.id), by: .user).record
        for record in [one, all] {
            #expect(!record.summary.localizedCaseInsensitiveContains("landlord") && !record.summary.contains("Zebra"))
        }
        for descriptor in [MakeKind.descriptor, KeepNoteAsObject.descriptor, KeepAllNotes.descriptor] {
            #expect(!descriptor.isOfferedToModel)
            #expect(ActionRegistry.descriptors.contains(descriptor))
            #expect(!ActionRegistry.offered.contains(descriptor))
        }
    }
}
