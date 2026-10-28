import Foundation
@testable import TesseraCore
import Testing

/// R1 spec section 9, one case per arrow: a change is staged, stopped, waiting for Allow, set, un-dried, refused or
/// queued; a room is blank, live, archiving, archived or restored. Three rules hold in every state: nothing is
/// written before a change sets, taking a room down deletes nothing it binds to, and a stopped or un-dried change
/// leaves the store as it was.
@MainActor
struct RoomLifecycleTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        try RoomSample.seedPlants(store: store, classes: classes)
    }

    var book: RoomBook {
        RoomBook(store: store, classes: classes)
    }

    /// Live objects (class, title, parent, order, values) and the links between live objects.
    func fingerprint() -> [String] {
        var lines: [String] = []
        for object in store.context.objects.values where !object.isDeleted && !object.isClassObject {
            let values = object.values.storage.keys.sorted()
                .map { "\($0)=\(String(describing: object.values.storage[$0]!))" }
            lines.append("o \(object.id) \(object.title) \(object.classDef?.id.uuidString ?? "-") "
                + "\(object.parent?.id.uuidString ?? "-") \(object.sortIndex) \(values.joined(separator: ";"))")
        }
        for link in store.context.links.values {
            guard let from = link.from, !from.isDeleted else { continue }
            if let to = link.toObject, to.isDeleted {
                continue
            }
            lines.append("l \(link.fieldID) \(from.id) \(link.toObject?.id.uuidString ?? "-")")
        }
        return lines.sorted()
    }

    func title(_ text: String = "Plants") -> RoomPatch {
        RoomPatch(room: "Chart room", say: "Title, set",
                  ops: [.init(op: "add", id: "title", kind: "title", place: "title", props: ["text": .string(text)])])
    }

    var widening: RoomPatch {
        RoomPatch(room: "Chart room", say: "Watered, set", ops: [
            .init(op: "add", id: "water", kind: "actionWord", place: "actionWord",
                  props: ["verb": .string("Water"), "does": .string("write Plant.lastWatered")]),
        ])
    }

    // MARK: A change

    @Test func stagedToSetWhenTheLineEnds() throws {
        let result = try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess, pending: true)
        #expect(result.record.state == .pending && !result.output.needsAllow)
        engine.commitExpired(now: .now.addingTimeInterval(3))
        #expect(result.record.state == .committed)
    }

    @Test func stagedToStoppedLeavesTheStoreAsItWas() throws {
        let before = fingerprint()
        let result = try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess, pending: true)
        #expect(fingerprint() != before, "the ghost shows while it dries")
        #expect(RoomPatcher.stop([result.record], in: engine))
        #expect(fingerprint() == before)
        #expect(RoomHistory.entries(of: "Chart room", engine: engine).isEmpty)
    }

    @Test func stagedToWaitingForAllowWhenTheValidatorSaysNeedsAllow() throws {
        let result = try engine.perform(PatchRoom(patch: widening, sentence: "Let me mark one watered"), by: .tess,
                                        pending: true)
        #expect(result.output.needsAllow)
        engine.commitExpired(now: .now.addingTimeInterval(60))
        #expect(result.record.state == .pending, "the line ending never sets a change that widens reach")
    }

    @Test func waitingToSetOnAllow() throws {
        let result = try engine.perform(PatchRoom(patch: widening, sentence: "Let me mark one watered"), by: .tess,
                                        pending: true)
        #expect(RoomReach.allow(result.record, in: engine) && result.record.state == .committed)
        let room = try #require(book.room(named: "Chart room"))
        #expect(book.grants(of: room) == ["write Plant.lastWatered"])
    }

    @Test func waitingToUndriedOnNotNow() throws {
        let before = fingerprint()
        let result = try engine.perform(PatchRoom(patch: widening, sentence: "Let me mark one watered"), by: .tess,
                                        pending: true)
        #expect(RoomReach.notNow(result.record, in: engine) && result.record.state == .undone)
        #expect(fingerprint() == before, "the change and its grant go back together")
    }

    @Test func setToUndriedByUndo() throws {
        let before = fingerprint()
        let result = try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess, pending: true)
        engine.commitExpired(now: .now.addingTimeInterval(3))
        engine.undo(result.record)
        #expect(result.record.state == .undone && fingerprint() == before)
    }

    @Test func refusedChangesNothingAndStagesNothing() throws {
        let before = fingerprint()
        let box = RoomPatch(
            room: "Chart room",
            say: "x",
            ops: [.init(op: "add", id: "b", kind: "box", place: "widget")]
        )
        guard case let .refused(refusal, queued) = try RoomPatcher.apply(box, sentence: "A box", engine: engine) else {
            Issue.record("a box is refused")
            return
        }
        #expect(queued == nil && refusal.offer != nil && fingerprint() == before)
        let money = RoomPatch(room: "Chart room", say: "x", ops: [.init(op: "grant", reach: "write Pool.name")])
        guard case .refused = try RoomPatcher.apply(money, sentence: "Money", engine: engine) else {
            Issue.record("money is refused")
            return
        }
        #expect(fingerprint() == before)
    }

    @Test func queuedChangesNoPartNow() throws {
        try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess)
        let room = try #require(book.room(named: "Chart room"))
        let parts = book.document(of: room).parts
        let ring = RoomPatch(
            room: "Chart room",
            say: "x",
            ops: [.init(op: "add", id: "r", kind: "ring", place: "keystone")]
        )
        guard case let .refused(refusal, queued) = try RoomPatcher.apply(ring, sentence: "A ring", engine: engine),
              queued != nil
        else {
            Issue.record("a ring is queued")
            return
        }
        #expect(refusal.queue == "ring" && book.document(of: room).parts == parts)
        #expect(book.queue(of: room) == ["ring"])
    }

    @Test func onlyOneChangeIsStagedAtATime() throws {
        let first = try RoomPatcher.apply(title(), sentence: "Title", engine: engine)
        guard case let .applied(firstRecord, _) = first else {
            Issue.record("the first applies")
            return
        }
        #expect(firstRecord.state == .pending)
        let second = RoomPatch(room: "Chart room", say: "Line, set", ops: [
            .init(op: "add", id: "line", kind: "line", place: "caption", props: ["text": .string("hello")]),
        ])
        guard case let .applied(secondRecord, _) = try RoomPatcher.apply(second, sentence: "A line", engine: engine)
        else {
            Issue.record("the second applies")
            return
        }
        #expect(firstRecord.state == .committed, "a new sentence sets the one still drying")
        #expect(secondRecord.state == .pending)
    }

    // MARK: The room

    @Test func blankToLiveAfterTheFirstSetChange() throws {
        #expect(book.room(named: "Chart room") == nil)
        let result = try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess, pending: true)
        engine.commitExpired(now: .now.addingTimeInterval(3))
        #expect(result.record.state == .committed && book.room(named: "Chart room") != nil)
    }

    @Test func liveToArchivingToArchivedAndBackToLiveByStopping() throws {
        try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess)
        let room = try #require(book.room(named: "Chart room"))
        let before = fingerprint()
        let archiving = try engine.perform(TakeDownRoom(room: room.id), by: .user, pending: true)
        #expect(RoomPatcher.stop([archiving.record], in: engine) && book.room(named: "Chart room") != nil)
        #expect(fingerprint() == before)
        let down = try engine.perform(TakeDownRoom(room: room.id), by: .user, pending: true)
        engine.commitExpired(now: .now.addingTimeInterval(3))
        #expect(down.record.state == .committed && book.room(named: "Chart room") == nil)
    }

    @Test func archivedToRestoredRoundTripsTheDocumentItsHistoryAndItsGrants() throws {
        let made = try engine.perform(PatchRoom(patch: widening, sentence: "Let me mark one watered"), by: .tess,
                                      pending: true)
        RoomReach.allow(made.record, in: engine)
        let room = try #require(book.room(named: "Chart room"))
        let document = book.document(of: room)
        let history = RoomHistory.entries(of: "Chart room", engine: engine).map(\.note)
        let plantClass = try #require(store.classDef(named: "Plant")).id.uuidString
        let plants = fingerprint().filter { $0.contains(plantClass) }
        let down = try engine.perform(TakeDownRoom(room: room.id), by: .user)
        #expect(fingerprint().filter { $0.contains(plantClass) } == plants, "what it showed is untouched")
        // Undo and the words "bring back" end in the same room.
        engine.undo(down.record)
        #expect(book.document(of: room) == document)
        let again = try engine.perform(TakeDownRoom(room: room.id), by: .user)
        _ = again
        try engine.perform(BringBackRoom(room: room.id), by: .user)
        #expect(book.document(of: room) == document && book.grants(of: room) == document.reach)
        #expect(RoomHistory.entries(of: "Chart room", engine: engine).map(\.note) == history)
    }

    @Test func restoredReplaysOnceAndWritesNothing() throws {
        try engine.perform(PatchRoom(patch: title(), sentence: "Title"), by: .tess)
        let room = try #require(book.room(named: "Chart room"))
        try engine.perform(TakeDownRoom(room: room.id), by: .user)
        try engine.perform(BringBackRoom(room: room.id), by: .user)
        #expect(RoomReplay.isOwed(room, in: store))
        let before = fingerprint()
        let steps = try RoomReplay.steps(of: "Chart room", engine: engine)
        #expect(steps.map(\.note) == ["Title"] && fingerprint() == before)
        try engine.perform(MarkRoomOpened(room: room.id), by: .system)
        #expect(!RoomReplay.isOwed(room, in: store))
    }
}
