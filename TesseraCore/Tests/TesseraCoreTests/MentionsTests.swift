import Foundation
@testable import TesseraCore
import Testing

/// Together piece 3: which app a class is, where a thing is mentioned, and how a word is drawn.
@MainActor
struct MentionsTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func app(_ key: SystemCatalog.Key) throws -> AppID? {
        try ClassResolver.app(for: #require(engine.classes[key]))
    }

    @Test func eachClassBelongsToItsApp() throws {
        for key in [
            SystemCatalog.Key.workout,
            .exercise,
            .benchPress,
            .barbellLift,
            .routine,
            .plan,
            .set,
            .muscle,
            .equipment,
        ] {
            #expect(try app(key) == .training, "\(key)")
        }
        for key in [SystemCatalog.Key.recipe, .ingredient, .cook, .kitchenTimer, .recipeStep, .cookSession, .cookDish] {
            #expect(try app(key) == .kitchen, "\(key)")
        }
        #expect(try app(.routine) == .routines)
        #expect(try app(.spend) == .money && app(.note) == .notes && app(.list) == .lists && app(.listItem) == .lists)
        for key in [SystemCatalog.Key.task, .book, .event, .settings, .process, .thing] {
            #expect(try app(key) == nil, "\(key)")
        }
    }

    @Test func aSubclassBelongsToItsParentsApp() throws {
        // Bench Press sits under Barbell Lift under Strength Exercise under Exercise: Training all the way.
        #expect(try app(.benchPress) == .training)
    }

    @Test func mentionsCountEachAppsLinksAndOpenTheOneOrTheApp() throws {
        let lemon = try #require(store.create(#require(engine.classes[.ingredient]), title: "Lemon"))
        try engine.perform(CreateNote(body: "Need @Lemon for the cake"), by: .user)
        let packing = try engine.perform(CreateList(name: "Packing"), by: .user).output
        let first = try engine.perform(
            AddListItem(list: packing.id, text: "Lemon squeezer", about: [lemon.id]),
            by: .user
        ).output
        let second = try engine.perform(
            AddListItem(list: packing.id, text: "Lemon zester", about: [lemon.id]),
            by: .user
        ).output
        let found = store.mentions(of: lemon, classes: engine.classes)
        #expect(found.map(\.app) == [.notes, .lists])
        let lists = try #require(found.first { $0.app == .lists })
        #expect(lists.count == 2 && lists.opens == .app(.lists))
        let notes = try #require(found.first { $0.app == .notes })
        #expect(notes.count == 1)
        guard case let .object(id) = notes.opens else {
            Issue.record("one note opens the note")
            return
        }
        #expect(store.object(id: id)?.classDef?.id == engine.classes[.note]?.id)
        // A deleted item stops counting.
        store.softDelete(first)
        #expect(store.mentions(of: lemon, classes: engine.classes).first { $0.app == .lists }?
            .opens == .object(second.id))
    }

    @Test func aThingNothingLinksToHasNoMentions() throws {
        let lonely = try store.create(#require(engine.classes[.ingredient]), title: "Saffron")
        #expect(store.mentions(of: lonely, classes: engine.classes).isEmpty)
    }

    @Test func aPrivateSourceNeverCountsAndNeverShowsItExists() throws {
        let lemon = try store.create(#require(engine.classes[.ingredient]), title: "Lemon")
        try engine.perform(CreateNote(body: "Hide @Lemon, my password is hunter2"), by: .user)
        #expect(store.mentions(of: lemon, classes: engine.classes).isEmpty)
        try engine.perform(CreateNote(body: "Plain note about @Lemon"), by: .user)
        #expect(store.mentions(of: lemon, classes: engine.classes).map(\.count) == [1])
    }

    @Test func aPrivateOrWalledThingReadsPrivateInPlainInkWithNoMentions() throws {
        let walled = try store.create(#require(engine.classes[.ingredient]), title: "Ozempic dose")
        try engine.perform(CreateNote(body: "About @[Ozempic dose] today"), by: .user)
        let word = store.thingWord(of: walled, classes: engine.classes)
        #expect(word == ThingWord(text: "Private", isPrivate: true, app: nil) && !word.usesAppColour)
        #expect(store.mentions(of: walled, classes: engine.classes).isEmpty)
        let plain = try store.create(#require(engine.classes[.ingredient]), title: "Lemon")
        let plainWord = store.thingWord(of: plain, classes: engine.classes)
        #expect(plainWord.text == "Lemon" && plainWord.app == .kitchen && plainWord.usesAppColour)
        let loose = try store.create(#require(engine.classes[.thing]), title: "Landlord")
        #expect(store.thingWord(of: loose, classes: engine.classes).usesAppColour == false)
    }
}
