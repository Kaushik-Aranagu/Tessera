import Foundation
import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Deck's door pages open the single lift where the data names one, and Start from the shell hands the workout to
/// whoever owns the root cover (`shellOpenWorkout`).
@MainActor
struct DeckRowsTests {
    private static let bench = UUID()
    private static let row = UUID()

    private static func facts(todayLifts: [UUID?], week: [BoardDay]) -> DeckRoomContent.Facts {
        let doors = [
            DialDoor(id: "today", name: "Today", color: .blue, label: "Push, 3 lifts",
                     lines: ["Bench 80 kg", "Row", "Plank"]),
            DialDoor(id: "week", name: "This week", color: .blue, label: "Monday to Sunday", lines: ["2 done"]),
        ]
        let wall = TrainingWallFacts(day: .ready(name: "Push A", minutes: 45, lifts: 3), words: [], doors: doors,
                                     brief: nil, action: TrainingFoot(verb: "Start", object: "Push A", hold: true),
                                     restOption: nil, todayLiftIDs: todayLifts)
        let board = TrainingBoard(headline: "Push A today", detail: "", week: week, bests: [])
        let deck = TrainingDeckFacts(board: board, routineWords: [], needs: [], widget: [])
        return DeckRoomContent.Facts(wall: wall, deck: deck, rows: DeckRoomContent.Facts.rows(wall: wall, deck: deck))
    }

    @Test func todayRowsCarryTheirLift() throws {
        let facts = Self.facts(todayLifts: [Self.bench, Self.row, nil], week: [])
        let rows = try #require(facts.rows["today"])
        #expect(rows.count == 3)
        #expect(TrainingWallTarget(id: rows[0].id) == .exercise(Self.bench))
        #expect(TrainingWallTarget(id: rows[1].id) == .exercise(Self.row))
        // A line with no lift falls back to the Training page.
        #expect(TrainingWallTarget(id: rows[2].id) == nil)
        #expect(rows[2].id.hasPrefix("page#"))
        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @Test func trainedDaysOpenTheirFirstLiftWithDistinctIDs() throws {
        let week = [
            BoardDay(id: 0, letter: "M", done: true, isToday: false, liftID: Self.bench, liftName: "Bench"),
            BoardDay(id: 1, letter: "T", done: true, isToday: false, liftID: Self.bench, liftName: "Bench"),
            BoardDay(id: 2, letter: "W", done: false, isToday: true),
        ]
        let rows = try #require(Self.facts(todayLifts: [], week: week).rows["week"])
        #expect(TrainingWallTarget(id: rows[0].id) == .exercise(Self.bench))
        #expect(TrainingWallTarget(id: rows[1].id) == .exercise(Self.bench))
        #expect(rows[0].id != rows[1].id)
        #expect(rows[0].detail == "Trained, Bench")
        #expect(TrainingWallTarget(id: rows[2].id) == nil)
        #expect(rows[2].detail == "Today")
    }

    @Test func aLiftRowOpensTheExercisePage() {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        var opened: [TrainingGo] = []
        let actions = DeckActions(model: model) { opened.append($0) }
        actions.item("\(TrainingWallTarget.exercise(Self.bench).id)#t0")
        actions.item("page#2")
        #expect(opened == [.route(.classDef(Self.bench)), .page])
    }

    @Test func pickingUpTheWorkoutCallsTheHook() {
        let model = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                             launchDefaults: .testSuite())
        var raised = 0
        let actions = DeckActions(model: model, openWorkout: { raised += 1 }) { _ in }
        actions.step("log")
        #expect(raised == 0)
        actions.step("pickUp")
        #expect(raised == 1)
        #expect(DeckActions.opensWorkout("start"))
        #expect(DeckActions.opensWorkout("startNext"))
        #expect(!DeckActions.opensWorkout("rest"))
    }
}
