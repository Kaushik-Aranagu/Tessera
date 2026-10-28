import CoreGraphics
import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The Chart room's player (R1): the document, the kit's parts and layout, the blank frame, the ghost with its drying
/// line, Allow and Undo, and the outline's coming down (sheet 358).
@MainActor
struct ChartRoomTests {
    // MARK: Decode

    @Test func coresFixtureDecodesWithAllTwelveKinds() {
        let doc = ChartFixture.document
        #expect(Set(doc.parts.map(\.kind)) == Set(PartKind.allCases))
        #expect(doc.reach == ["write Plant.lastWatered"])
        #expect(doc.look["density"] == "airy")
    }

    @Test func aDocumentRoundTripsThroughJSON() throws {
        let doc = ChartFixture.document
        #expect(try ChartDoc.decode(doc.encoded()) == doc)
    }

    @Test func theSpecsPatchDecodesEveryOp() throws {
        let patch = try ChartPatch.decode(ChartFixture.patchJSON)
        #expect(patch.say == "Plants, set")
        #expect(patch.ops.count == 7)
        #expect(patch.widensReach)
        #expect(patch.grantLine == "write Plant.lastWatered")
    }

    @Test func aPatchAppliesAndLeavesTheOriginalAlone() {
        let before = ChartDoc(name: "Chart room")
        let after = before.applying(ChartPatch(ChartRoomModel.canned[0].patch))
        #expect(before.parts.isEmpty)
        #expect(after.parts.map(\.id) == ["title", "line"])
        #expect(after.look["density"] == "airy")
    }

    // MARK: Resolve

    private func nodes(_ doc: ChartDoc) -> [Place: [PartNode]] {
        let data = DemoRoomData()
        return PartResolver.resolve(doc) { data.items($0) }
    }

    @Test func theFixtureFillsTheItsPlacesAndNothingTwice() throws {
        let resolved = nodes(ChartFixture.document)
        #expect(resolved[.title]?.count == 1)
        // The stack and the grid draw their children; the children are not drawn again on their own.
        #expect(resolved[.keystone]?.map(\.id) == ["pair"])
        #expect(resolved[.widget]?.map(\.id) == ["both"])
        let line = try #require(resolved[.switcher]?.first)
        #expect(line.words == ["4 plants, the orchid is thirsty"])
    }

    @Test func aRowIsRankedAndItsTopItemIsFlagged() {
        var doc = ChartDoc(name: "Chart room")
        for step in ChartRoomModel.canned.prefix(3) {
            doc = doc.applying(ChartPatch(step.patch))
        }
        guard case let .row(_, items)? = nodes(doc)[.keystone]?.first else {
            Issue.record("no row")
            return
        }
        #expect(items.map(\.small) == ["Orchid", "Monstera", "Fern", "Basil"])
        #expect(items.map(\.big) == ["6", "4", "2", "1"])
        #expect(items.map(\.isTop) == [true, false, false, false])
    }

    @Test func aShownLineHasNoFullStopAndFitsEightyCharacters() {
        #expect(PartText.shown("Plants, set.") == "Plants, set")
        let long = String(repeating: "water ", count: 30)
        let cut = PartText.shown(long)
        #expect(cut.count <= 80 && !cut.hasSuffix(" ") && !cut.contains("\u{2026}"))
        #expect(PartText.looksLikeKey("sk-" + "ant-" + "api03-abcdefghijklmnop"))
    }

    @Test func moneyAndBodyBindsNeverResolveAndMoneyIsNeverWritten() {
        var doc = ChartDoc(name: "Chart room")
        doc.parts = [ChartPart(
            id: "n",
            kind: .number,
            place: "keystone",
            props: ["agg": .text("count")],
            bind: "spend"
        )]
        let node = PartResolver.node(doc.parts[0], in: doc) { _ in [BoundItem(name: "x")] }
        #expect(node?.words.first == "0")
        #expect(RoomWalls.refusesWrite("write pool.balance"))
        #expect(!RoomWalls.refusesWrite("write Plant.lastWatered"))
    }

    @Test func aWriteWithoutItsGrantIsNotOffered() {
        var doc = ChartFixture.document
        let data = DemoRoomData()
        #expect(nodes(doc)[.actionWord]?.count == 1)
        doc.reach = []
        let resolved = PartResolver.resolve(doc) { data.items($0) }
        #expect(resolved[.actionWord] == nil)
    }

    // MARK: Layout

    @Test func aRowsPiecesStayInsideTheKeystoneAndNeverOverlap() {
        let frame = LandingPlace.keystone.frame
        let pieces = PartLayout.place(.row(id: "r", items: PartsKeystoneElement.sample), in: frame)
        #expect(pieces.count == 8)
        for piece in pieces {
            #expect(frame.insetBy(dx: -0.5, dy: -0.5).contains(piece.rect), "\(piece.text)")
        }
        for (index, piece) in pieces.enumerated() {
            for other in pieces[(index + 1)...] {
                #expect(!piece.rect.intersects(other.rect), "\(piece.text) and \(other.text)")
            }
        }
    }

    @Test func aNumbersUnitIsHalfSizeAndNeverUnderTen() {
        let node = PartNode.number(id: "n", value: "6", unit: "d", label: "days apart")
        let unit = PartLayout.place(node, in: LandingPlace.keystone.frame).first { $0.isUnit }
        #expect(unit?.size == 32)
        let tiny = PartLayout.place(node, in: LandingPlace.keystone.frame, scale: 0.1).first { $0.isUnit }
        #expect((tiny?.size ?? 0) >= 10)
    }

    @Test func stacksAndGridsNestAndPlaceTheirChildren() {
        let a = PartNode.number(id: "a", value: "4", unit: "", label: "plants")
        let b = PartNode.number(id: "b", value: "7", unit: "d", label: "apart")
        let frame = LandingPlace.widget.frame
        let across = PartLayout.place(.stack(id: "s", axis: .horizontal, gap: 10, children: [a, b]), in: frame)
        #expect(Set(across.map(\.id)) == ["a", "a.label", "b", "b.unit", "b.label"])
        let first = across.first { $0.id == "a" }, second = across.first { $0.id == "b" }
        #expect((first?.rect.minX ?? 0) < (second?.rect.minX ?? 0))
        let grid = PartNode.grid(id: "g", columns: 2, children: [a, b, a, b])
        #expect(PartLayout.place(grid, in: frame).count == 10)
        #expect(PartNode.stack(id: "s", axis: .vertical, gap: 6, children: [grid]).flattened.count == 6)
    }

    // MARK: The room

    @Test func theBlankRoomHoldsOnlyTheNavWordAndSay() {
        let room = DocumentRoom(nodes: [:])
        let screen = room.screen(for: .landing("chart"), state: RoomState())
        #expect(Set(screen.slots.keys) == [.navWord, .actionWord])
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else {
            Issue.record("no action")
            return
        }
        #expect(steps.map(\.verb) == ["Say"] && steps.first?.object == "what to build")
    }

    @Test func partsRideTheOneNewSlotKindAndAGhostIsFlagged() {
        let room = DocumentRoom(nodes: nodes(ChartFixture.document), ghost: [.keystone])
        let screen = room.screen(for: .landing("chart"), state: RoomState())
        #expect(screen[.keystone]?.kind == .parts)
        #expect(screen[.keystone]?.ghost == true)
        #expect(screen[.widget]?.ghost == false)
        #expect(screen[.title]?.kind == .text)
    }

    // MARK: Ghost, drying, Allow, Undo

    private func model(said: Said = Said()) -> ChartRoomModel {
        ChartRoomModel(data: DemoRoomData(), defaults: nil, drying: .milliseconds(60)) { text, undo in
            said.lines.append(text)
            said.undo = undo
        }
    }

    final class Said {
        var lines: [String] = []
        var undo: (() -> Void)?
    }

    @Test func aPatchShowsAsAGhostThenSetsWhenTheLineEnds() async throws {
        let said = Said()
        let room = model(said: said)
        room.saySomething()
        #expect(room.pending != nil)
        #expect(room.document.parts.isEmpty)
        #expect(room.ghostPlaces == [.title, .switcher])
        #expect(room.heard == "Make this my plant room")
        try await Task.sleep(for: .milliseconds(250))
        #expect(room.pending == nil)
        #expect(room.document.parts.count == 2)
        #expect(said.lines == ["Plants, set"])
    }

    @Test func aTapSetsAGhostAtOnce() {
        let room = model()
        room.saySomething()
        room.tapGhost()
        #expect(room.pending == nil && room.document.parts.count == 2)
    }

    @Test func undoUnDriesThenPutsTheRoomBack() async throws {
        let said = Said()
        let room = model(said: said)
        room.saySomething()
        room.tapGhost()
        said.undo?()
        // Sheet 368: the change is a ghost again while its drying line runs back; it is undone only at 0.
        #expect(room.unDrying && room.pending != nil && room.document.parts.count == 2)
        try await Task.sleep(for: .seconds(ChartRoomModel.unDrySeconds + 0.3))
        #expect(!room.unDrying && room.pending == nil)
        #expect(room.document.parts.isEmpty && room.cursor == 0)
    }

    private func upToTheWideningPatch(_ room: ChartRoomModel) {
        for _ in 0 ..< 3 {
            room.saySomething()
            room.tapGhost()
        }
    }

    @Test func aWideningPatchWaitsForAllowAndNeverSetsOnTheLine() async throws {
        let said = Said()
        let room = model(said: said)
        upToTheWideningPatch(room)
        room.saySomething()
        try await Task.sleep(for: .milliseconds(250))
        #expect(room.pending != nil, "the drying line alone never sets it")
        #expect(room.reachLine == "This room can now mark plants watered")
        room.tapGhost()
        #expect(room.pending != nil, "a tap on the ghost never sets it either")
        #expect(room.nodes[.actionWord] == nil, "no write before Allow")
        room.allow()
        #expect(room.pending == nil)
        #expect(room.document.reach == ["write Plant.lastWatered"])
        #expect(room.nodes[.actionWord]?.count == 1)
        said.undo?()
        try await Task.sleep(for: .seconds(ChartRoomModel.unDrySeconds + 0.3))
        #expect(room.document.reach.isEmpty, "undo takes the grant back with the change")
    }

    @Test func theActionWordWaterstheThirstiestAndUndoPutsItBack() async throws {
        let said = Said()
        let room = model(said: said)
        upToTheWideningPatch(room)
        room.saySomething()
        try await Task.sleep(for: .milliseconds(250))
        room.allow()
        room.does("water")
        #expect(said.lines.last == "Orchid, watered")
        guard case let .row(_, items)? = room.nodes[.keystone]?.first else {
            Issue.record("no row")
            return
        }
        #expect(items.first { $0.small == "Orchid" }?.big == "0")
        said.undo?()
        guard case let .row(_, back)? = room.nodes[.keystone]?.first else { return }
        #expect(back.first { $0.small == "Orchid" }?.big == "6")
    }

    @Test func aMoneyGrantIsRefusedWithOneLine() {
        let said = Said()
        let room = model(said: said)
        room.propose(RoomPatch(room: "Chart room", say: "Pool, set", ops: [
            .init(op: "grant", reach: "write pool.balance"),
        ]))
        #expect(room.pending == nil)
        #expect(said.lines == ["Rooms can't change money"])
    }

    // MARK: Sheet 358, the scaffolding comes down

    @Test func theStaggerIsOneMillisecondPerFourPoints() {
        #expect(OutlineSetting.delay(y: 50, reduceMotion: false) == 0.0125)
        #expect(abs(OutlineSetting.delay(y: 196, reduceMotion: false) - OutlineSetting.delay(
            y: 50,
            reduceMotion: false
        ) - 0.0365) < 0.0005)
        #expect(OutlineSetting.delay(y: 640, reduceMotion: true) == 0)
    }

    @Test func anOutlineDropsShrinksAndFadesThenUndoRaisesItBack() {
        let rest = OutlineSetting.frame(at: 0, y: 0, setting: true, reduceMotion: false)
        #expect(abs(rest.offset) < 0.001 && abs(rest.scale - 1) < 0.0001 && rest.opacity > 0.999)
        let gone = OutlineSetting.frame(at: 0.38, y: 0, setting: true, reduceMotion: false)
        #expect(abs(gone.offset - 6) < 0.001 && abs(gone.scale - 0.985) < 0.0001 && gone.opacity < 0.001)
        let before = OutlineSetting.frame(at: 0.2, y: 4000, setting: true, reduceMotion: false)
        #expect(abs(before.offset) < 0.001, "a lower place waits its stagger")
        let up = OutlineSetting.frame(at: 0.38, y: 0, setting: false, reduceMotion: false)
        #expect(abs(up.offset) < 0.001 && up.opacity > 0.999)
    }

    @Test func underReduceMotionItOnlyFadesOver200Milliseconds() {
        let mid = OutlineSetting.frame(at: 0.1, y: 640, setting: true, reduceMotion: true)
        #expect(mid.offset == 0 && mid.scale == 1 && mid.opacity > 0 && mid.opacity < 1)
        #expect(OutlineSetting.frame(at: 0.2, y: 640, setting: true, reduceMotion: true).opacity < 0.001)
        #expect(OutlineSetting.duration(reduceMotion: true) == 0.2)
    }

    // MARK: Sheet 365: the dial row

    private func defaults(_ doc: ChartDoc?) -> UserDefaults {
        let suite = UserDefaults(suiteName: "chart.\(UUID().uuidString)")!
        if let doc {
            suite.set(doc.encoded(), forKey: ChartRoomModel.defaultsKey)
        }
        return suite
    }

    @Test func anUnnamedRoomReadsChartRoomInSlateWithSayWhatItsFor() {
        let row = ChartRoomSummary.row(defaults: defaults(nil))
        #expect(row.name == "Chart room" && row.line == "Say what it's for")
    }

    @Test func aNamedRoomCarriesItsOwnNameColourAndTopFact() {
        var doc = ChartDoc(name: "Chart room")
        doc.color = "olive"
        for step in ChartRoomModel.canned.prefix(3) {
            doc = doc.applying(ChartPatch(step.patch))
        }
        let row = ChartRoomSummary.row(defaults: defaults(doc))
        #expect(row.name == "Plants")
        #expect(row.line == "Orchid, 6 days")
    }

    @Test func theAppsDialHasTheChartRowRightAfterPurse() {
        let rows = AppsListRows.make([])
        let chart = rows.firstIndex { $0.extra == .chart }
        #expect(chart != nil && rows[(chart ?? 1) - 1].app == .money && rows[(chart ?? 1) - 1].extra == nil)
    }

    // MARK: Sheet 359: after a dozen sentences

    @Test func twelveSentencesBuildTheSheet359Room() {
        let room = model()
        room.setSentences(12)
        #expect(ChartRoomModel.canned.count == 12)
        #expect(room.document.color == "olive")
        let screen = DocumentRoom(nodes: room.nodes).screen(for: .landing("chart"), state: RoomState())
        guard case let .switcher(across, _)? = screen[.switcher]?.payload else {
            Issue.record("no switcher words")
            return
        }
        #expect(across == ["Thirsty", "This week", "Light"])
        guard case let .lines(needs)? = screen[.needs]?.payload else {
            Issue.record("no needs")
            return
        }
        #expect(needs == ["Orchid, 6 days", "Monstera, 4 days"])
        let later = DocumentRoom(nodes: room.nodes).screen(for: .landing("chart"), state: RoomState(switcherIndex: 2))
        if case let .lines(second)? = later[.needs]?.payload {
            #expect(second == ["Orchid by the window", "Fern in the shade"])
        }
        guard case let .widget(items)? = screen[.widget]?.payload else {
            Issue.record("no widget")
            return
        }
        #expect(items.map(\.big) == ["Orchid", "Monstera", "Basil"])
        #expect(items.first?.bigColor != nil && items.first?.middle == "Last watered Wednesday")
        #expect(screen[.glyph]?.kind == .glyph)
        guard case let .dial(doors)? = screen[.dial]?.payload else {
            Issue.record("no doors")
            return
        }
        #expect(doors.map(\.name) == ["Orchid", "Monstera", "Fern", "Basil"])
        #expect(doors.first?.label == "Last watered Wednesday")
        #expect(doors.first?.lines == ["Water every 7 days", "By the east window", "Ice cubes, not a pour"])
        #expect(screen[.doorSummary] != nil)
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else { return }
        #expect(steps.map(\.verb) == ["Watered", "Say"] && steps.first?.object == "the orchid")
        // The caption and the keystone row keep inside their places and over nothing.
        let resolved = room.nodes
        var pieces: [(Place, PlacedPart)] = []
        for place in [Place.keystone, .caption] {
            let rect = ShellLayout.ownFrame(place)
            for node in resolved[place] ?? [] {
                for piece in PartLayout.place(node, in: rect) {
                    #expect(rect.insetBy(dx: -0.5, dy: -0.5).contains(piece.rect), "\(piece.text)")
                    pieces.append((place, piece))
                }
            }
        }
        #expect(!pieces.isEmpty)
    }

    // MARK: Sheet 362: the room's history

    @Test func theHistoryListsEverySentenceNewestFirstAndPreviewingWritesNothing() {
        let said = Said()
        let room = model(said: said)
        var clock = Date(timeIntervalSince1970: 1_700_000_000)
        room.now = { clock }
        for _ in 0 ..< 2 {
            room.saySomething()
            room.tapGhost()
            clock += 60
        }
        room.openHistory()
        #expect(room.historyRows.map(\.note) == [
            "Put them on the keystone by when I last watered",
            "Make this my plant room",
        ])
        let latest = room.document
        room.preview(room.historyRows[1])
        #expect(room.document == latest, "looking writes nothing")
        #expect(room.shown.parts.map(\.id) == ["title", "line"])
        #expect(room.ghostPlaces == Set(room.nodes.keys), "every place is a ghost")
        #expect(room.historyFoot?.first?.verb == "Go back")
        #expect(room.goBackObject?.hasPrefix("to how it was at ") == true)
        room.goBack()
        #expect(room.document.parts.map(\.id) == ["title", "line"] && !room.historyOpen)
        #expect(said.lines.last?.hasPrefix("Back to ") == true)
        said.undo?()
        #expect(room.document == latest, "Undo returns to the latest version")
    }

    @Test func theClockReadsLikeTheSheet() {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 10
        parts.day = 27
        parts.hour = 13
        parts.minute = 18
        #expect(ChartRoomModel.clock(Calendar.current.date(from: parts) ?? .now) == "1:18 pm")
    }

    // MARK: A real store: Allow runs RoomReach.allow, refusals speak, the colour table is the dial's

    @Test func allowRunsRoomReachAllowOnARealStore() async throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let said = Said()
        let room = model(said: said)
        room.attach(app.engine)
        for _ in 0 ..< 3 {
            room.saySomething()
            room.tapGhost()
        }
        #expect(room.document.parts.map(\.id).contains("row"), "the first three sentences are in the store")
        room.saySomething()
        #expect(room.pending?.needsAllow == true, "refused: \(room.note?.line ?? "nothing")")
        let held = app.engine.pendingRecords().filter { $0.action == "patchRoom" }
        #expect(held.count == 1 && RoomReach.holds(held[0], in: app.store), "the engine holds the widening patch")
        try await Task.sleep(for: .milliseconds(250))
        #expect(room.pending != nil, "the drying line never commits it")
        let before = said.lines.count
        room.allow()
        #expect(room.pending == nil)
        #expect(app.engine.pendingRecords().filter { $0.action == "patchRoom" }.isEmpty, "Allow committed it")
        #expect(said.lines.count == before + 1 && said.lines.last == "Watered, set",
                "the receipt shows only after RoomReach.allow returned true")
        let book = RoomBook(store: app.store, classes: app.classes)
        let stored = try #require(book.room(named: "Chart room").map(book.document(of:)))
        #expect(stored.reach == ["write Plant.lastWatered"])
    }

    @Test func allTwelveSentencesGoThroughTheRealPatcherAndMatchTheInMemoryRoom() async throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let room = model()
        room.attach(app.engine)
        for index in 0 ..< 12 {
            room.saySomething()
            #expect(room.pending != nil, "sentence \(index + 1) refused: \(room.note?.line ?? "nothing")")
            if room.pending?.needsAllow == true {
                try await Task.sleep(for: .milliseconds(250))
                room.allow()
            } else {
                room.tapGhost()
            }
        }
        let book = RoomBook(store: app.store, classes: app.classes)
        let stored = try #require(book.room(named: "Chart room").map(book.document(of:)))
        let memory = ChartRoomModel(data: DemoRoomData(), defaults: nil)
        memory.setSentences(12)
        #expect(ChartDoc(stored).parts.map(\.id) == memory.document.parts.map(\.id))
        #expect(stored.color == "olive" && stored.reach == ["write Plant.lastWatered"])
    }

    @Test func roomReachAllowCommitsAHeldWideningPatchOnARealStore() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        _ = try RoomSample.seedPlants(store: app.store, classes: app.classes)
        let patch = RoomPatch(room: "Chart room", say: "Watered, set", ops: [
            .init(op: "grant", reach: "write Plant.lastWatered"),
            .init(op: "add", id: "water", kind: "actionWord", place: "actionWord",
                  props: ["verb": .string("Watered"), "does": .string("write Plant.lastWatered")]),
        ])
        let record = try app.engine.perform(PatchRoom(patch: patch), by: .tess, pending: true).record
        #expect(RoomReach.holds(record, in: app.store), "the engine holds a patch that widens reach")
        app.engine.commitExpired(now: .distantFuture)
        #expect(record.state == .pending, "the drying line never commits it")
        #expect(RoomReach.allow(record, in: app.engine))
        #expect(record.state == .committed)
        let book = RoomBook(store: app.store, classes: app.classes)
        let stored = try #require(book.room(named: "Chart room").map(book.document(of:)))
        #expect(stored.reach == ["write Plant.lastWatered"])
    }

    @Test func aKitMissOnARealStoreIsQueuedWithUndo() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let said = Said()
        let room = model(said: said)
        room.attach(app.engine)
        room.propose(RoomPatch(room: "Chart room", say: "Ring", ops: [
            .init(op: "add", id: "ring", kind: "ring", place: "keystone"),
        ]))
        #expect(room.pending == nil, "a refusal is never a ghost")
        #expect(said.lines.last?.hasSuffix("queued for your next install") == true)
    }

    // MARK: Sheet 371: taking a room down

    @Test func theFoldIsTheUnrollBackwardsTitleLast() {
        #expect(OutlineUnroll.foldDelay(rank: 5, count: 6, reduceMotion: false) == 0.4)
        #expect(abs(OutlineUnroll.foldDelay(rank: 0, count: 6, reduceMotion: false) - 0.75) < 1e-9)
        #expect(OutlineUnroll.foldDelay(rank: 0, count: 6, reduceMotion: true) == 0)
        #expect(OutlineUnroll.foldTrim(at: 0, rank: 0, count: 6, reduceMotion: false) == 1)
        #expect(OutlineUnroll
            .foldTrim(at: OutlineUnroll.downSeconds(count: 6), rank: 0, count: 6, reduceMotion: false) < 0.001)
        #expect(OutlineUnroll.downSeconds(count: 6) > 1.1 && OutlineUnroll.downSeconds(count: 6) < 1.4)
    }

    @Test func takingTheRoomDownLeavesThePlantsAndUndoBringsItBack() async throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let said = Said()
        let room = model(said: said)
        room.attach(app.engine)
        room.saySomething()
        room.tapGhost()
        let book = RoomBook(store: app.store, classes: app.classes)
        let plants = try #require(RoomBind(store: app.store, classes: app.classes).classDef(for: "Plant"))
        let before = app.store.objects(of: plants).map(\.title).sorted()
        #expect(before.count == 4 && book.room(named: "Chart room") != nil)
        room.takeDown()
        #expect(room.phase == .archiving, "the fold plays first")
        try await Task.sleep(for: .seconds(OutlineUnroll.downSeconds(count: DocumentRoom.outlined.count) + 0.4))
        #expect(room.phase == .archived)
        #expect(said.lines.last == "Room taken down, not the plants")
        #expect(book.room(named: "Chart room") == nil, "the room leaves the dial")
        #expect(app.store.objects(of: plants).map(\.title).sorted() == before, "the plants are never touched")
        #expect(room.document.parts.isEmpty)
        said.undo?()
        #expect(room.phase == .live, "restored, then live after the replay")
        #expect(book.room(named: "Chart room") != nil, "Undo brings the room back")
        #expect(room.document.parts.map(\.id) == ["title", "line"])
        #expect(app.store.objects(of: plants).map(\.title).sorted() == before)
    }

    @Test func aRoomWaitingForAllowStaysUpAndSaysWhy() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        _ = try RoomSample.seedPlants(store: app.store, classes: app.classes)
        let patch = RoomPatch(room: "Chart room", say: "Watered, set", ops: [
            .init(op: "grant", reach: "write Plant.lastWatered"),
            .init(op: "add", id: "water", kind: "actionWord", place: "actionWord",
                  props: ["verb": .string("Watered"), "does": .string("write Plant.lastWatered")]),
        ])
        _ = try app.engine.perform(PatchRoom(patch: patch), by: .tess, pending: true)
        let room = model()
        room.attach(app.engine)
        room.takeDown()
        #expect(room.note?.line == "This room is waiting for your Allow, so it stays up")
        #expect(RoomBook(store: app.store, classes: app.classes).room(named: "Chart room") != nil)
    }

    // MARK: Sheet 373: stopping a drying change

    @Test func aStopHoldsThenRunsBackAtUndosPace() {
        #expect(StopRun.progress(at: 0.05, from: 0.5, reduceMotion: false) == 0.5)
        #expect(abs(StopRun.progress(at: 0.12 + 0.3, from: 0.5, reduceMotion: false)) < 1e-9)
        #expect(StopRun.progress(at: 0.2, from: 0.5, reduceMotion: false) < 0.5)
        #expect(abs(StopRun.total(from: 1, reduceMotion: false) - 0.72) < 1e-9)
        #expect(StopRun.total(from: 1, reduceMotion: true) == 0)
        #expect(StopRun.progress(at: 0.01, from: 0.5, reduceMotion: true) == 0)
    }

    @Test func cancellingADryingChangeWritesNothingAndSaysSo() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let said = Said()
        let room = model(said: said)
        room.attach(app.engine)
        room.saySomething()
        #expect(room.pending != nil)
        #expect(room.cancelPending())
        #expect(room.pending == nil && room.document.parts.isEmpty)
        #expect(said.lines.last == "Stopped, nothing changed")
        #expect(room.retry == "Make this my plant room")
        #expect(app.engine.pendingRecords().filter { $0.action == "patchRoom" }.isEmpty, "no pending group is left")
        let book = RoomBook(store: app.store, classes: app.classes)
        #expect(book.room(named: "Chart room") == nil || book.room(named: "Chart room").map(book.document(of:))?.parts
            .isEmpty == true)
    }

    @Test func aChangeThatHasSetCanOnlyBeUndone() {
        let room = model()
        room.saySomething()
        room.tapGhost()
        #expect(!room.cancelPending(), "past the drying it falls through to Undo")
    }

    // MARK: Sheet 383: the Tess line

    @Test func aTessLineArrivesSixtyMillisecondsAWordWithABreathAfterEachComma() {
        let text = "Every plant's page has it now, not just the monstera's"
        let starts = TessLineTiming.starts(text)
        #expect(starts.count == 10)
        #expect(starts[0] == 0 && abs(starts[1] - 0.06) < 1e-9)
        // "now," is the sixth word: the seventh starts one word and one breath later.
        #expect(abs(starts[5] - starts[4] - TessLineTiming.perWord) < 1e-9)
        #expect(abs(starts[6] - starts[5] - (TessLineTiming.perWord + TessLineTiming.breath)) < 1e-9)
        #expect(TessLineTiming.shown(text, at: 0) == 1 && TessLineTiming.shown(text, at: 10) == 10)
        #expect(TessLineTiming.total("") == 0)
    }

    @Test func herFaceBlinksOncePerNewLineAndNotForAnOpeningLine() {
        #expect(TessLineTiming.blinks(arrives: true, reduceMotion: false))
        #expect(!TessLineTiming.blinks(arrives: false, reduceMotion: false), "an opening line appears whole, no blink")
        #expect(!TessLineTiming.blinks(arrives: true, reduceMotion: true), "Reduce Motion: no blink")
        let soul = SoulRouter()
        #expect(soul.strokeBlink == nil)
        soul.lineStarted()
        #expect(soul.strokeBlink != nil, "the soul blinks as the line starts")
    }

    // MARK: Sheet 374, one lifecycle: one test per arrow (r1-spec section 9)

    @Test func everyArrowOfAChangeIsListedAndNoOther() {
        typealias Arrow = (ChangeState, ChangeEvent, ChangeState)
        let arrows: [Arrow] = [
            (.idle, .sentence, .staged), (.set, .sentence, .staged), (.refused, .sentence, .staged),
            (.queued, .sentence, .staged), (.waiting, .sentence, .waiting),
            (.idle, .refuse, .refused), (.idle, .queue, .queued), (.refused, .settled, .idle), (
                .queued,
                .settled,
                .idle
            ),
            (.staged, .lineEnded(needsAllow: false), .set), (.staged, .lineEnded(needsAllow: true), .waiting),
            (.staged, .newSentence, .set), (.staged, .touchWords, .stopped), (.stopped, .stopEnded, .idle),
            (.waiting, .allow, .set), (.waiting, .notNow, .undried), (.set, .undo, .undried),
            (.undried, .unDryEnded, .idle),
        ]
        for (from, event, to) in arrows {
            #expect(Lifecycle.next(from, event) == to, "\(from) on \(event)")
        }
        // Nothing else leaves a state: no unlisted exit (a stopped change cannot be undone, a waiting one cannot be
        // stopped, a set one cannot be touched, and so on).
        let events: [ChangeEvent] = [.sentence, .lineEnded(needsAllow: false), .lineEnded(needsAllow: true),
                                     .newSentence, .touchWords, .stopEnded, .allow, .notNow, .undo, .unDryEnded,
                                     .refuse, .queue, .settled]
        var listed = 0
        for state in ChangeState.allCases {
            for event in events where Lifecycle.next(state, event) != nil {
                listed += 1
            }
        }
        // idle/set/refused/queued each take sentence, refuse and queue (4 x 3 = 12) except `idle`+`settled` etc.
        #expect(listed == arrows.count + 6, "only the listed arrows exist (refuse and queue from the resting states)")
        #expect(Lifecycle.next(.stopped, .undo) == nil && Lifecycle.next(.waiting, .touchWords) == nil)
        #expect(Lifecycle.next(.set, .touchWords) == nil && Lifecycle.next(.undried, .sentence) == nil)
        #expect(Lifecycle.canUndo(.set) && !Lifecycle.canUndo(.staged) && !Lifecycle.canUndo(.waiting))
    }

    @Test func everyArrowOfTheRoomIsListedAndNoOther() {
        let arrows: [(RoomPhase, RoomEvent, RoomPhase)] = [
            (.blank, .firstSet, .live), (.live, .takeDown, .archiving), (.archiving, .foldEnded, .archived),
            (.archiving, .touchWords, .live), (.archived, .restore, .restored), (.restored, .replayEnded, .live),
        ]
        for (from, event, to) in arrows {
            #expect(RoomLifecycle.next(from, event) == to, "\(from) on \(event)")
        }
        let events: [RoomEvent] = [.firstSet, .takeDown, .foldEnded, .touchWords, .restore, .replayEnded]
        var listed = 0
        for phase in RoomPhase.allCases {
            for event in events where RoomLifecycle.next(phase, event) != nil {
                listed += 1
            }
        }
        #expect(listed == arrows.count, "no other exit")
        #expect(RoomLifecycle.next(.blank, .takeDown) == nil, "a blank room has nothing to take down")
    }

    @Test func theFlowsGoThroughTheMachine() async throws {
        let room = model()
        #expect(room.change == .idle && room.phase == .blank)
        room.saySomething()
        #expect(room.change == .staged)
        room.tapGhost()
        #expect(room.change == .set && room.phase == .live)
        room.saySomething()
        #expect(room.cancelPending())
        #expect(room.change == .idle, "stopped, then at rest")
        room.saySomething()
        room.tapGhost()
        room.saySomething()
        room.tapGhost()
        room.saySomething()
        #expect(room.change != .waiting, "the drying line has not ended")
        try await Task.sleep(for: .milliseconds(250))
        #expect(room.change == .waiting, "a widening change waits for Allow")
        room.notNow()
        #expect(room.change == .undried && room.unDrying)
        try await Task.sleep(for: .seconds(ChartRoomModel.unDrySeconds + 0.3))
        #expect(room.change == .idle && room.pending == nil, "Not now un-dried it")
    }

    @Test func aNewSentenceWhileOneDriesSetsItInOneHundredSixtyMillisecondsThenStagesTheNext() async throws {
        let said = Said()
        let room = ChartRoomModel(data: DemoRoomData(), defaults: nil, drying: .seconds(5)) { text, undo in
            said.lines.append(text)
            said.undo = undo
        }
        room.saySomething()
        #expect(room.change == .staged)
        room.saySomething()
        #expect(room.completing && room.pending != nil, "the first line is running to its end")
        try await Task.sleep(for: .milliseconds(450))
        #expect(!room.completing)
        #expect(said.lines.first == "Plants, set", "the first change stood")
        #expect(room.pending != nil && room.change == .staged, "the second is now staged")
        #expect(room.receipt == nil, "the last receipt came down as the new one started")
    }

    @Test func underReduceMotionAnUndoIsDoneAtOnce() {
        // The model's wait is zero when Reduce Motion is on: tested through the pure rule the model reads.
        #expect(StopRun.total(from: 0.5, reduceMotion: true) == 0)
        #expect(OutlineUnroll.foldDelay(rank: 0, count: 6, reduceMotion: true) == 0)
        #expect(OutlineSetting.delay(y: 500, reduceMotion: true) == 0)
        #expect(OutlineUnroll.delay(rank: 3, reduceMotion: true) == 0)
        #expect(OutlineUnroll.trim(at: 0, rank: 3, reduceMotion: true) == 1)
    }

    @Test func touchingHisWordsOrSayingWaitOrStopStopsAChangeThatDries() {
        let room = model()
        room.saySomething()
        #expect(!room.hear("what is this"), "other words are not a stop")
        #expect(room.change == .staged)
        #expect(room.hear("Wait."))
        #expect(room.change == .idle && room.pending == nil, "stopped, nothing written, at rest")
        #expect(room.document.parts.isEmpty)
        room.saySomething()
        #expect(room.hear("stop"))
        room.saySomething()
        room.tapGhost()
        #expect(!room.hear("stop"), "a change that has set can only be undone")
    }

    @Test func aStopRunsItsLineBackFromWhereItGot() {
        let room = model()
        room.saySomething()
        #expect(room.cancelPending())
        #expect(room.stopping != nil && (room.stopping?.progress ?? 2) <= 1, "the layer runs the line back from here")
    }

    @Test func aTakeDownFoldsThenArchivesAndTheDialLosesItsRow() async throws {
        let suite = UserDefaults(suiteName: "chart.\(UUID().uuidString)") ?? .standard
        let said = Said()
        let room = ChartRoomModel(data: DemoRoomData(), defaults: suite, drying: .milliseconds(60)) { text, undo in
            said.lines.append(text)
            said.undo = undo
        }
        room.saySomething()
        room.tapGhost()
        #expect(ChartRoomSummary.isUp(defaults: suite))
        var arrived = false
        room.onArchived = { arrived = true }
        room.takeDown()
        #expect(room.phase == .archiving && !room.document.parts.isEmpty, "the room is still there while it folds")
        #expect(room.ghostPlaces == Set(room.nodes.keys), "every place is a ghost")
        try await Task.sleep(for: .seconds(OutlineUnroll.downSeconds(count: DocumentRoom.outlined.count) + 0.4))
        #expect(room.phase == .archived && room.document.parts.isEmpty && arrived)
        #expect(!ChartRoomSummary.isUp(defaults: suite), "no row in the dial")
        #expect(said.lines.last == "Room taken down, not the plants")
        said.undo?()
        #expect(room.phase == .live && ChartRoomSummary.isUp(defaults: suite) && !room.document.parts.isEmpty)
    }

    @Test func wordsHalfWayThroughTheFoldKeepTheRoom() async throws {
        let room = model()
        room.saySomething()
        room.tapGhost()
        room.takeDown()
        #expect(room.phase == .archiving)
        #expect(room.hear("stop"))
        #expect(room.phase == .live && !room.document.parts.isEmpty)
        try await Task.sleep(for: .seconds(OutlineUnroll.downSeconds(count: DocumentRoom.outlined.count) + 0.4))
        #expect(room.phase == .live, "the fold never finishes")
    }

    // MARK: Sheets 360 and 361: point, then say; how the room says no

    @Test func aTapPicksAFilledPlaceWritesNothingAndLetsGoAfterItsTime() async throws {
        let room = model()
        room.pickFor = .milliseconds(60)
        room.pick(.keystone)
        #expect(room.picked == nil, "an empty place cannot be picked")
        room.setSentences(2)
        let before = room.document
        room.pick(.keystone)
        #expect(room.picked == .keystone)
        #expect(room.sayObject == "what to change about the keystone")
        #expect(room.document == before, "picking writes nothing")
        try await Task.sleep(for: .milliseconds(200))
        #expect(room.picked == nil && room.sayObject == "what to build")
    }

    @Test func aRefusalOffersAChangeThatPlaysAsAnOrdinaryGhost() {
        let room = model()
        room.setSentences(2)
        let bigger = RoomPatch(
            room: "Chart room",
            say: "Bigger numbers",
            ops: [.init(op: "look", trait: "size", value: "big")]
        )
        room.refuse("That size is not in the scale.", offer: ("Bigger numbers", bigger))
        #expect(room.note?.line == "That size is not in the scale")
        #expect(room.note?.button == "Bigger numbers")
        room.takeOffer()
        #expect(room.note == nil && room.pending != nil)
    }

    @Test func aKitMissIsQueuedWithUndo() {
        let said = Said()
        let room = model(said: said)
        room.kitMiss("Ring")
        #expect(said.lines == ["Ring, queued for your next install"] && room.queued == ["Ring"])
        said.undo?()
        #expect(room.queued.isEmpty)
    }

    // MARK: Sheet 359 acceptance: the finished room, frames

    /// Where each place of the finished room sits on the 402 x 874 design screen.
    private func frame(_ place: Place, hasNeeds: Bool) -> CGRect {
        var rect = ShellLayout.ownFrame(place)
        if place == .switcher, !hasNeeds {
            rect.size.width = 354
        }
        return rect
    }

    @Test func theFinishedRoomKeepsEveryPieceInsideItsPlaceAndOverNothing() {
        let resolved = nodes(ChartFixture.document)
        let hasNeeds = resolved[.needs] != nil
        var placed: [(place: Place, piece: PlacedPart)] = []
        for (place, list) in resolved where [.title, .switcher, .needs, .keystone, .caption, .widget].contains(place) {
            let rect = frame(place, hasNeeds: hasNeeds)
            for node in list {
                for piece in PartLayout.place(node, in: rect) {
                    #expect(
                        rect.insetBy(dx: -0.5, dy: -0.5).contains(piece.rect),
                        "\(place) \(piece.text) leaves its place"
                    )
                    placed.append((place, piece))
                }
            }
        }
        #expect(placed.count > 10)
        for (index, one) in placed.enumerated() {
            for two in placed[(index + 1)...] where one.piece.rect.intersects(two.piece.rect) {
                Issue.record("\(one.place) \(one.piece.text) crosses \(two.place) \(two.piece.text)")
            }
        }
    }

    // MARK: Sheet 366, the outlines unroll

    @Test func theOutlinesUnrollDownTheScreenSeventyMillisecondsApartFromThreeHundred() {
        let frames = [CGRect(x: 24, y: 412, width: 354, height: 200), CGRect(x: 24, y: 50, width: 260, height: 48),
                      CGRect(x: 24, y: 196, width: 354, height: 182), CGRect(x: 24, y: 106, width: 354, height: 76)]
        #expect(OutlineUnroll.order(frames) == [1, 3, 2, 0])
        #expect(OutlineUnroll.delay(rank: 0, reduceMotion: false) == 0.3)
        #expect(abs(OutlineUnroll.delay(rank: 3, reduceMotion: false) - 0.51) < 1e-9)
        #expect(OutlineUnroll.delay(rank: 3, reduceMotion: true) == 0)
        #expect(OutlineUnroll.trim(at: 0.2, rank: 0, reduceMotion: false) == 0)
        #expect(OutlineUnroll.trim(at: 0.3 + 0.45, rank: 0, reduceMotion: false) == 1)
        #expect(OutlineUnroll.trim(at: 0, rank: 2, reduceMotion: true) == 1)
        #expect(!OutlineUnroll.nameShown(at: 0.35, rank: 0, reduceMotion: false))
        #expect(OutlineUnroll.nameShown(at: 0.43, rank: 0, reduceMotion: false))
    }

    // MARK: The kit is an element

    @Test func theKitElementIsRegisteredAndPassesWithNoBlock() {
        #expect(ElementRegistry.contains("Parts"))
        let results = ElementConformance.run(spec: PartsKeystoneElement().spec)
        let blocks = ElementConformance.blocks(results)
        #expect(blocks.isEmpty, "\(blocks.map { "\($0.check.rawValue) \($0.outcome)" })")
    }
}
