import Foundation
@testable import TesseraCore
import Testing

/// K88, ship list slice 7: pick one (docs/product/lists-acceptance.md section 7, lists-screens 12.3 and G13, decisions
/// Oct 15: "a skip is not a pick").
@MainActor
struct ListPickTests {
    let store = ObjectStore.open(inMemory: true)
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let day: TimeInterval = 86400

    /// A fixed-seed generator (SplitMix64), so a pick is repeatable.
    struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
            value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
            return value ^ (value >> 31)
        }
    }

    struct Fixture {
        let engine: ActionEngine
        let lists: ListContents
        let films: ObjectRecord
        let items: [ObjectRecord]
    }

    func setUp(texts: [String] = ["Heat", "Alien", "Paris, Texas"]) throws -> Fixture {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let films = try engine.perform(CreateList(name: "Films"), by: .user).output
        var items: [ObjectRecord] = []
        for text in texts {
            try items.append(engine.perform(AddListItem(list: films.id, text: text), by: .user).output)
        }
        return Fixture(engine: engine, lists: ListContents(store: store, classes: classes), films: films, items: items)
    }

    func picks(_ fixture: Fixture, excluding: Set<UUID> = [], seeds: Range<UInt64> = 0 ..< 200) -> Set<String> {
        var seen: Set<String> = []
        for seed in seeds {
            var generator = Seeded(state: seed)
            if let item = fixture.lists.pick(from: fixture.films, excluding: excluding, now: now, using: &generator) {
                seen.insert(item.text)
            }
        }
        return seen
    }

    // MARK: pick(from:)

    @Test func pickReturnsOnlyOpenItems() throws {
        let fixture = try setUp()
        try fixture.engine.perform(CheckListItem(item: fixture.items[0].id, time: now), by: .user)
        try fixture.engine.perform(CheckListItem(item: fixture.items[1].id, time: now), by: .user)
        #expect(picks(fixture) == ["Paris, Texas"])
    }

    @Test func anEmptyOrFinishedListGivesNil() throws {
        let empty = try setUp(texts: [])
        #expect(empty.lists.pick(from: empty.films, now: now) == nil)
        let fixture = try setUpFinished()
        #expect(fixture.lists.pick(from: fixture.films, now: now) == nil)
    }

    func setUpFinished() throws -> Fixture {
        let other = ObjectStore.open(inMemory: true)
        let classes = try other.prepareCatalog()
        let engine = ActionEngine(store: other, classes: classes)
        let films = try engine.perform(CreateList(name: "Films"), by: .user).output
        let heat = try engine.perform(AddListItem(list: films.id, text: "Heat"), by: .user).output
        try engine.perform(CheckListItem(item: heat.id, time: now), by: .user)
        return Fixture(engine: engine, lists: ListContents(store: other, classes: classes), films: films, items: [heat])
    }

    @Test func pickingWritesNothingAndNeverChecksAnItem() throws {
        let fixture = try setUp()
        let before = fixture.engine.history(limit: 500).count
        for seed in 0 ..< 20 as Range<UInt64> {
            var generator = Seeded(state: seed)
            _ = fixture.lists.pick(from: fixture.films, now: now, using: &generator)
        }
        _ = fixture.lists.pick(from: fixture.films, now: now)
        #expect(fixture.engine.history(limit: 500).count == before)
        #expect(fixture.lists.open(in: fixture.films).count == 3)
        #expect(fixture.items.allSatisfy { fixture.lists.pickedAt($0) == nil })
    }

    @Test func aFixedSeedGivesTheSamePickEveryTime() throws {
        let fixture = try setUp()
        var first = Seeded(state: 7)
        var second = Seeded(state: 7)
        let one = fixture.lists.pick(from: fixture.films, now: now, using: &first)
        let two = fixture.lists.pick(from: fixture.films, now: now, using: &second)
        #expect(one?.id == two?.id)
    }

    @Test func everyOpenItemCanComeUp() throws {
        let fixture = try setUp()
        #expect(picks(fixture) == ["Heat", "Alien", "Paris, Texas"])
    }

    @Test func anItemPickedInTheLastSevenDaysIsNeverChosenWhileOthersExist() throws {
        let fixture = try setUp()
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - 2 * day), by: .user)
        #expect(picks(fixture) == ["Alien", "Paris, Texas"])
    }

    @Test func theWindowIsSevenDaysToTheSecond() throws {
        let fixture = try setUp(texts: ["Heat", "Alien"])
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - 7 * day + 1), by: .user)
        #expect(picks(fixture) == ["Alien"])
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - 7 * day), by: .user)
        #expect(picks(fixture) == ["Heat", "Alien"])
    }

    @Test func whenEveryOpenItemWasPickedRecentlyOneStillComesUp() throws {
        let fixture = try setUp(texts: ["Heat", "Alien"])
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - day), by: .user)
        try fixture.engine.perform(AcceptPick(item: fixture.items[1].id, time: now - 2 * day), by: .user)
        #expect(picks(fixture) == ["Heat", "Alien"])
    }

    @Test func aRecentlyPickedItemThatIsDoneDoesNotMatter() throws {
        let fixture = try setUp(texts: ["Heat", "Alien"])
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - day), by: .user)
        try fixture.engine.perform(CheckListItem(item: fixture.items[0].id, time: now), by: .user)
        #expect(picks(fixture) == ["Alien"])
    }

    // MARK: Skip

    @Test func aSkipWritesNoStampAndPicksAgainWithoutIt() throws {
        let fixture = try setUp()
        var generator = Seeded(state: 3)
        let first = try #require(fixture.lists.pick(from: fixture.films, now: now, using: &generator))
        let before = fixture.engine.history(limit: 500).count
        let again = picks(fixture, excluding: [first.id])
        #expect(!again.contains(first.text) && again.count == 2)
        #expect(fixture.lists.pickedAt(first.object) == nil)
        #expect(fixture.engine.history(limit: 500).count == before)
    }

    @Test func skippingEveryItemEndsInNilNotInARepeat() throws {
        let fixture = try setUp()
        let all = Set(fixture.items.map(\.id))
        #expect(picks(fixture, excluding: all).isEmpty)
        #expect(picks(fixture, excluding: Set(fixture.items.prefix(2).map(\.id))) == ["Paris, Texas"])
    }

    @Test func aSkippedItemRecentlyPickedStillCountsAsSkipped() throws {
        let fixture = try setUp(texts: ["Heat", "Alien"])
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - day), by: .user)
        #expect(picks(fixture, excluding: [fixture.items[1].id]) == ["Heat"])
        #expect(picks(fixture, excluding: Set(fixture.items.map(\.id))).isEmpty)
    }

    // MARK: AcceptPick

    @Test func acceptingAPickStampsItAndNeverChecksIt() throws {
        let fixture = try setUp()
        let accepted = try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now), by: .user)
        #expect(fixture.lists.pickedAt(fixture.items[0]) == now)
        #expect(fixture.lists.open(in: fixture.films).count == 3)
        #expect(fixture.lists.item(fixture.items[0]).isDone == false)
        #expect(accepted.record.receipt == "Heat, from Films")
        #expect(accepted.record.summary == "Picked Heat from Films")
    }

    @Test func undoingAnAcceptRestoresTheStampItHad() throws {
        let fixture = try setUp()
        let first = try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now - 10 * day), by: .user)
        let second = try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now), by: .user)
        #expect(fixture.lists.pickedAt(fixture.items[0]) == now)
        #expect(fixture.engine.undo(second.record) == .applied)
        #expect(fixture.lists.pickedAt(fixture.items[0]) == now - 10 * day)
        #expect(fixture.engine.undo(first.record) == .applied)
        #expect(fixture.lists.pickedAt(fixture.items[0]) == nil)
        fixture.engine.redo(first.record)
        #expect(fixture.lists.pickedAt(fixture.items[0]) == now - 10 * day)
    }

    @Test func acceptingLeavesTheItemsOtherNotesAlone() throws {
        let fixture = try setUp()
        try store.set("notes", to: .richText("Seen it once"), on: fixture.items[0])
        let accepted = try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now), by: .user)
        #expect(store.value("notes", of: fixture.items[0])?.stringValue?.hasPrefix("Seen it once") == true)
        fixture.engine.undo(accepted.record)
        #expect(store.value("notes", of: fixture.items[0])?.stringValue == "Seen it once")
    }

    @Test func aPrivateItemsWordsNeverPrintWhenItIsAccepted() throws {
        let fixture = try setUp(texts: [])
        let pill = try fixture.engine.perform(AddListItem(list: fixture.films.id, text: "lexapro"), by: .user).output
        let accepted = try fixture.engine.perform(AcceptPick(item: pill.id, time: now), by: .user)
        #expect(accepted.record.receipt == "Private item, from Films")
        #expect(accepted.record.summary == "Picked Private item from Films")
        #expect(!(accepted.record.receipt ?? "").lowercased().contains("lexapro"))
    }

    @Test func onlyAListItemCanBeAccepted() throws {
        let fixture = try setUp()
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.self) { try fixture.engine.perform(AcceptPick(item: fixture.films.id), by: .user) }
        #expect(fixture.engine.history(limit: 500).count == before)
    }

    @Test func tessDoingItShowsAsTessAndHisOwnDoesNot() throws {
        let fixture = try setUp()
        try fixture.engine.perform(AcceptPick(item: fixture.items[0].id, time: now), by: .user)
        try fixture.engine.perform(AcceptPick(item: fixture.items[1].id, time: now), by: .tess)
        let tess = fixture.engine.history(limit: 500).filter { $0.actor == .tess && $0.action == "acceptPick" }
        #expect(tess.count == 1)
        #expect(fixture.engine.history(limit: 500).filter { $0.actor == .user && $0.action == "acceptPick" }.count == 1)
    }

    // MARK: The option

    @Test func pickOneIsOffByDefaultAndTurnsOnAndOffWithUndo() throws {
        let fixture = try setUp()
        #expect(!fixture.lists.isPickOne(fixture.films))
        let turnedOn = try fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user)
        #expect(fixture.lists.isPickOne(fixture.films))
        #expect(turnedOn.record.receipt == "Films, pick one on")
        #expect(!fixture.lists.isReusable(fixture.films))
        fixture.engine.undo(turnedOn.record)
        #expect(!fixture.lists.isPickOne(fixture.films))
        try fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user)
        let turnedOff = try fixture.engine.perform(SetListPickOne(list: fixture.films.id, on: false), by: .user)
        #expect(turnedOff.record.receipt == "Films, pick one off")
        #expect(!fixture.lists.isPickOne(fixture.films))
    }

    @Test func pickOneAndReusableAreIndependentOptions() throws {
        let fixture = try setUp()
        try fixture.engine.perform(SetListReusable(list: fixture.films.id), by: .user)
        try fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user)
        try fixture.engine.perform(SetListReusable(list: fixture.films.id, reusable: false), by: .user)
        #expect(fixture.lists.isPickOne(fixture.films) && !fixture.lists.isReusable(fixture.films))
    }

    @Test func turningItOnTwiceWritesNothing() throws {
        let fixture = try setUp()
        try fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user)
        let before = fixture.engine.history(limit: 500).count
        #expect(throws: ActionError.self) {
            try fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user)
        }
        #expect(fixture.engine.history(limit: 500).count == before)
    }

    @Test func everyReceiptIsThingFirstAndNeverSaysAt() throws {
        let fixture = try setUp()
        let lines = try [
            fixture.engine.perform(SetListPickOne(list: fixture.films.id), by: .user).record.receipt,
            fixture.engine.perform(AcceptPick(item: fixture.items[2].id, time: now), by: .user).record.receipt,
        ].compactMap(\.self)
        #expect(lines == ["Films, pick one on", "Paris, Texas, from Films"])
        #expect(lines.allSatisfy { !$0.contains(" at ") })
    }

    @Test func theActionsDecodeFromAToolCall() throws {
        let fixture = try setUp()
        try fixture.engine.perform(
            named: "setListPickOne", arguments: Data(#"{"list":"\#(fixture.films.id.uuidString)"}"#.utf8), by: .user
        )
        #expect(fixture.lists.isPickOne(fixture.films))
        try fixture.engine.perform(
            named: "acceptPick", arguments: Data(#"{"item":"\#(fixture.items[0].id.uuidString)"}"#.utf8), by: .user
        )
        #expect(fixture.lists.pickedAt(fixture.items[0]) != nil)
    }
}
