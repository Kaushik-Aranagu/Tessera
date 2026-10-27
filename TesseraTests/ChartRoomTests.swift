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
        #expect(PartText.looksLikeKey("sk-ant-api03-abcdefghijklmnop"))
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

    @Test func undoPutsTheRoomBack() {
        let said = Said()
        let room = model(said: said)
        room.saySomething()
        room.tapGhost()
        said.undo?()
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
        #expect(room.document.reach.isEmpty, "undo takes the grant back with the change")
    }

    @Test func theActionWordWaterstheThirstiestAndUndoPutsItBack() {
        let said = Said()
        let room = model(said: said)
        upToTheWideningPatch(room)
        room.saySomething()
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
