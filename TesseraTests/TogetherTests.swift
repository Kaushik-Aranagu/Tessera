import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Together (sheet 135): link colours and "Mentioned in".
@MainActor
struct TogetherTests {
    @Test func theSwitchesSitOnTheirOwnPageAndStartOff() throws {
        let page = try #require(ReviewChoices.facets.first { $0.word == "Together" })
        #expect(page.ids == [Together.daySentence, Together.linkColours, Together.writeAnywhere, Together.oneHands,
                             Together.occasions, Together.makeAKind])
        for id in page.ids {
            #expect(ReviewChoices.all.first { $0.id == id }?.defaultValue == "Off")
        }
    }

    @Test func aMentionTakesItsHomeAppsLineAndStaysInk() {
        let text = "@Bench Press felt heavy, then @Tacos"
        var line = AttributedString(text)
        LinkColours.underline(&line, text: text, homes: ["bench press": .training])
        let underlined = line.runs.filter { $0.underlineStyle != nil }.map { String(line[$0.range].characters) }
        #expect(underlined == ["@Bench Press"])
    }

    @Test func aPrivateNoteNamesNoHome() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        let note = try #require(try? model.engine.perform(CreateNote(body: "@Bench Press\nmore"), by: .user).output)
        try model.store.set("isPrivate", to: .bool(true), on: note)
        // NoteRow only colours a note Core does not call private; the private one stays as it was.
        #expect(NotesLanding(store: model.store, classes: model.classes).isPrivate(note))
        #expect(try HomeApp.of(classDef: #require(model.classes[.benchPress]), classes: model.classes) == .training)
    }

    @Test func homeAppsByClass() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        let note = try #require(try? model.engine.perform(CreateNote(body: "Sleep\nmore"), by: .user).output)
        #expect(HomeApp.of(note, classes: model.classes) == .notes)
        #expect(Mentions.lines(of: note, store: model.store, classes: model.classes).isEmpty)
    }
}

/// Write anywhere steps aside while Tess is in the middle of something (QA on #1245).
@MainActor
struct WriteAnywhereTests {
    @Test func aLiveWorkoutKeepsItsOwnReading() throws {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        #expect(model.routedWrite("80 x 5", enabled: false) == nil)
        let routine = try #require(model.objects(of: .routine).first { !$0.isDeleted })
        model.startRoutine(routine)
        #expect(model.session != nil)
        #expect(model.routedWrite("80 x 5", enabled: true) == nil)
    }
}
