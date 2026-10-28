import Foundation
@testable import TesseraCore
import Testing

/// The Pantry by places (design item 118).
@MainActor
@Suite(.oldWalls)
struct PantryPlacesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    let places: PantryPlaces

    init() throws {
        let classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        places = PantryPlaces(store: store, classes: classes)
    }

    func ingredient(_ name: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[.ingredient]), title: name)
    }

    func place(_ key: String) throws -> ObjectRecord {
        try #require(store.object(id: PantryPlaces.defaultID(key)))
    }

    @Test func theFourDefaultPlacesAreSeededOnceInOrder() throws {
        #expect(places.places().isEmpty)
        places.ensureDefaults()
        places.ensureDefaults()
        #expect(places.places().map(\.title) == ["Fridge", "Freezer", "Shelf", "Counter"])
        let fridge = try place("fridge")
        #expect(places.sections(of: fridge) == ["Door", "Shelves", "Drawer"])
        #expect(try places.sections(of: place("freezer")) == ["Drawers", "Ice"])
        #expect(try places.sections(of: place("shelf")).isEmpty)
        #expect(PantryPlaces.toGet == "To get")
    }

    @Test func aRemovedDefaultStaysRemoved() throws {
        places.ensureDefaults()
        try engine.perform(RemovePlace(place: place("counter").id), by: .user)
        places.ensureDefaults()
        #expect(places.places().map(\.title) == ["Fridge", "Freezer", "Shelf"])
    }

    @Test func aPlaceOfHisOwnIsAddedLastAndNamesAreChecked() throws {
        places.ensureDefaults()
        let made = try engine.perform(CreatePlace(name: "Spice rack", sections: "Baking, Spices, baking, ,Oils"),
                                      by: .user)
        #expect(places.places().last?.title == "Spice rack" && made.record.receipt == "Spice rack, new place")
        #expect(places.sections(of: made.output) == ["Baking", "Spices", "Oils"])
        #expect(throws: (any Error).self) { try engine.perform(CreatePlace(name: "fridge"), by: .user) }
        #expect(throws: (any Error).self) { try engine.perform(CreatePlace(name: "To get"), by: .user) }
        #expect(throws: (any Error).self) { try engine.perform(CreatePlace(name: "  "), by: .user) }
        #expect(places.places().count == 5)
    }

    @Test func renamingAndReorderingKeepEveryOrderContiguous() throws {
        places.ensureDefaults()
        let shelf = try place("shelf")
        try engine.perform(RenamePlace(place: shelf.id, name: "Cupboard"), by: .user)
        #expect(shelf.title == "Cupboard")
        #expect(throws: (any Error).self) { try engine.perform(RenamePlace(place: shelf.id, name: "Fridge"), by: .user)
        }
        try engine.perform(MovePlace(place: shelf.id, toIndex: 0), by: .user)
        #expect(places.places().map(\.title) == ["Cupboard", "Fridge", "Freezer", "Counter"])
        let orders = places.places().map { store.number("order", of: $0) }
        #expect(orders == [0, 1, 2, 3])
        try engine.perform(MovePlace(place: shelf.id, toIndex: 99), by: .user)
        #expect(places.places().last?.title == "Cupboard")
    }

    @Test func anItemKnowsItsPlaceAndSection() throws {
        places.ensureDefaults()
        let milk = try ingredient("milk"), peas = try ingredient("peas"), rice = try ingredient("rice")
        let fridge = try place("fridge"), freezer = try place("freezer")
        try engine.perform(SetItemPlace(item: milk.id, place: fridge.id, section: "Door"), by: .user)
        try engine.perform(SetItemPlace(item: peas.id, place: freezer.id, section: "Door"), by: .user)
        #expect(places.place(of: milk)?.id == fridge.id && places.section(of: milk) == "Door")
        // A section the place does not have is dropped.
        #expect(places.place(of: peas)?.id == freezer.id && places.section(of: peas) == nil)
        #expect(places.unplaced([milk, peas, rice]).map(\.title) == ["rice"])
        #expect(places.entries().map(\.count) == [1, 1, 0, 0])
        // Moving it takes it out of the old place; nil takes it out of any.
        try engine.perform(SetItemPlace(item: milk.id, place: freezer.id, section: "Ice"), by: .user)
        #expect(places.ingredients(in: fridge).isEmpty && places.ingredients(in: freezer).count == 2)
        try engine.perform(SetItemPlace(item: milk.id, place: nil), by: .user)
        #expect(places.place(of: milk) == nil && places.section(of: milk) == nil)
    }

    @Test func aPlaceListsItsSectionsInOrderThenTheRest() throws {
        places.ensureDefaults()
        let fridge = try place("fridge")
        for (name, section) in [("eggs", "Shelves"), ("milk", "Door"), ("butter", "Door"), ("leftovers", nil)] {
            try engine.perform(SetItemPlace(item: ingredient(name).id, place: fridge.id, section: section), by: .user)
        }
        let groups = places.grouped(in: fridge)
        #expect(groups.map(\.section) == ["Door", "Shelves", nil])
        #expect(groups.map { $0.ingredients.map(\.title) } == [["butter", "milk"], ["eggs"], ["leftovers"]])
        // A place with no sections lists directly.
        let shelf = try place("shelf")
        try engine.perform(SetItemPlace(item: ingredient("rice").id, place: shelf.id), by: .user)
        #expect(places.grouped(in: shelf).map(\.section) == [nil])
    }

    @Test func removingAPlaceUnplacesItsItemsAndUndoBringsThemBack() throws {
        places.ensureDefaults()
        let fridge = try place("fridge")
        let milk = try ingredient("milk")
        try engine.perform(SetItemPlace(item: milk.id, place: fridge.id, section: "Door"), by: .user)
        let removed = try engine.perform(RemovePlace(place: fridge.id), by: .user)
        #expect(removed.output.map(\.title) == ["milk"] && places.place(of: milk) == nil)
        #expect(places.places().map(\.title) == ["Freezer", "Shelf", "Counter"])
        #expect(places.places().map { store.number("order", of: $0) } == [0, 1, 2])
        engine.undo(removed.record)
        #expect(places.place(of: milk)?.id == fridge.id && places.section(of: milk) == "Door")
        #expect(places.places().first?.title == "Fridge")
    }

    @Test func aPlaceWithAWalledWordReadsPrivate() throws {
        let made = try engine.perform(CreatePlace(name: "Lexapro shelf"), by: .user).output
        #expect(places.name(of: made) == "Private place")
        #expect(try places.name(of: engine.perform(CreatePlace(name: "Garage"), by: .user).output) == "Garage")
    }

    @Test func nothingHereIsOfferedToTheModelOrNamedInAClaudeFile() throws {
        for name in ["createPlace", "renamePlace", "setPlaceSections", "movePlace", "removePlace", "setItemPlace"] {
            #expect(!ActionRegistry.offered.contains { $0.name == name }, "\(name)")
            #expect(ActionRegistry.descriptors.contains { $0.name == name }, "\(name)")
        }
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        var checked = 0
        for name in try FileManager.default.contentsOfDirectory(atPath: sources.path())
            where name.hasSuffix(".swift") && ["ClaudeTessModel", "PlanWording", "HomeDoneWording", "RecipeLinkReader",
                                               "TessTools", "TessSentLog", "DayNamer"].contains(where: name.hasPrefix)
        {
            let text = try String(contentsOf: sources.appending(path: name), encoding: .utf8)
            for word in ["PantryPlaces", "SetItemPlace", "CreatePlace", "RemovePlace"] {
                #expect(!text.contains(word), "\(name) mentions \(word)")
            }
            checked += 1
        }
        #expect(checked >= 5)
    }
}

extension PantryPlacesTests {
    @Test func theReceiptAndTheSummaryReadPrivateForWalledWords() throws {
        let made = try engine.perform(CreatePlace(name: "Lexapro shelf"), by: .user)
        #expect(made.record.receipt == "Private place, new place")
        #expect(!made.record.summary.lowercased().contains("lexapro"))
        let item = try ingredient("lexapro")
        let put = try engine.perform(SetItemPlace(item: item.id, place: made.output.id), by: .user)
        #expect(put.record.summary == "Put Private item in a place")
        // A plain one says its words.
        let plain = try engine.perform(CreatePlace(name: "Garage"), by: .user)
        #expect(plain.record.receipt == "Garage, new place")
        let milk = try ingredient("milk")
        #expect(try engine.perform(SetItemPlace(item: milk.id, place: plain.output.id), by: .user).record.summary
            == "Put milk in a place")
        // And no op summary anywhere holds the walled words.
        #expect(!store.context.operations.values.contains { $0.summary.lowercased().contains("lexapro") })
    }

    @Test func sectionWordsAreMaskedForAWalledPlaceAndForAWalledWord() throws {
        let hidden = try engine.perform(CreatePlace(name: "Lexapro shelf", sections: "Top, Bottom"), by: .user).output
        #expect(places.shownSections(of: hidden) == ["Private section", "Private section"])
        let mixed = try engine.perform(CreatePlace(name: "Garage", sections: "Left, Lexapro box"), by: .user).output
        #expect(places.shownSections(of: mixed) == ["Left", "Private section"])
        #expect(places.entries().first { $0.place.id == mixed.id }?.sections == ["Left", "Private section"])
        let item = try ingredient("rope")
        try engine.perform(SetItemPlace(item: item.id, place: mixed.id, section: "Lexapro box"), by: .user)
        let groups = places.grouped(in: mixed)
        #expect(groups.map(\.section) == ["Lexapro box"] && groups.map(\.label) == ["Private section"])
    }

    @Test func aPrivatePlaceLeftOutOfTheICloudCopyLeavesNoDanglingLink() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "places-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let disk = try ObjectStore(context: TesseraContext(url: dir.appending(path: "tessera.sqlite")))
        let classes = try disk.prepareCatalog()
        let diskEngine = ActionEngine(store: disk, classes: classes)
        let diskPlaces = PantryPlaces(store: disk, classes: classes)
        let secret = try diskEngine.perform(CreatePlace(name: "Lexapro shelf", sections: "Top"), by: .user).output
        let item = try disk.create(#require(classes[.ingredient]), title: "oats")
        try diskEngine.perform(SetItemPlace(item: item.id, place: secret.id, section: "Top"), by: .user)
        disk.save()
        let icloud = dir.appending(path: "icloud.sqlite")
        try TesseraBackup.write(from: disk.context, to: icloud, leavingOutPrivate: true)
        let copy = try ObjectStore(context: TesseraContext(url: icloud))
        let copyClasses = try copy.prepareCatalog()
        let copyPlaces = PantryPlaces(store: copy, classes: copyClasses)
        let restored = try #require(copy.object(id: item.id))
        // The private place is gone from the copy and the item simply has no place: it asks once again.
        #expect(copy.object(id: secret.id) == nil)
        #expect(copyPlaces.place(of: restored) == nil && copyPlaces.section(of: restored) == nil)
        #expect(copyPlaces.unplaced([restored]).map(\.title) == ["oats"])
        #expect(copyPlaces.places().isEmpty && diskPlaces.places().count == 1)
    }
}
