import Foundation
@testable import Tessera
import TesseraCore
import Testing
import UIKit

/// The Training landing on the shared kit (landing contract §12): the state line forms and their fit, the foot's
/// word, split colours, wall words and doors from the seeded data, and private routines kept off the wall.
@MainActor
struct TrainingWallLandingTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    private static let days: [TrainingDay] = [
        .ready(name: "Push A", minutes: 45, lifts: 4),
        .running(name: "Pull B", liftsDone: 2),
        .done(name: "Legs A", next: "Push B"),
        .rest(next: "Pull B", nextDay: Date(timeIntervalSince1970: 1_761_350_400)),
        .rest(next: nil, nextDay: nil),
        .nothing,
    ]

    // MARK: Words and fit

    @Test func stateFormsRunLongestFirstWithNoCounters() {
        for day in Self.days {
            let forms = TrainingWallFacts.stateForms(day)
            #expect(!forms.isEmpty)
            #expect(forms == forms.sorted { $0.count > $1.count }, "\(forms)")
            #expect(forms.allSatisfy { !$0.contains(" of ") && !$0.contains("...") && !$0.contains("…") })
            #expect(forms.allSatisfy { $0.first?.isUppercase == true })
        }
    }

    @Test func restDayNamesTheNextDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        calendar.locale = Locale(identifier: "en_US")
        let saturday = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 9)))
        let forms = TrainingWallFacts.stateForms(.rest(next: "Pull B", nextDay: saturday), calendar: calendar)
        #expect(forms.first == "Rest today. Next is Saturday.", "\(forms)")
        #expect(forms.last == "Rest today.")
    }

    @Test func longestFormsFitAtDefaultAndShortestAtAX5() throws {
        let width: CGFloat = 354
        for day in Self.days {
            let forms = TrainingWallFacts.stateForms(day)
            for (size, form) in try [(CGFloat(16), #require(forms.first)), (CGFloat(16 * 3.1), #require(forms.last))] {
                let font = UIFont(name: "Figtree-Regular", size: size) ?? .systemFont(ofSize: size)
                let measured = (form as NSString).size(withAttributes: [.font: font]).width
                // FitLine lets the last form step down to 0.8x at the largest sizes.
                let limit = size > 16 ? width / 0.8 : width
                #expect(measured <= limit, "\(form) at \(size) pt is \(measured) pt")
            }
        }
    }

    @Test func footWordFollowsTheDay() {
        #expect(TrainingWallFacts.actionWord(.ready(name: "Push A", minutes: 45, lifts: 4)) == "Start Push A")
        #expect(TrainingWallFacts.actionWord(.running(name: "Push A", liftsDone: 1)) == "Pick up Push A")
        #expect(TrainingWallFacts.actionWord(.rest(next: "Pull B", nextDay: nil)) == "Log a walk")
        #expect(TrainingWallFacts.actionWord(.done(name: "Push A", next: nil)) == nil)
        let hidden = TrainingDay.ready(name: ObjectPrivacy.routineLabel, minutes: 30, lifts: 3)
        #expect(TrainingWallFacts.actionWord(hidden) == "Start private workout")
    }

    @Test func splitsTakeTheirColorsByName() {
        #expect(TrainingSplit(name: "Push A") == .push)
        #expect(TrainingSplit(name: "Pull B") == .pull)
        #expect(TrainingSplit(name: "Legs A") == .legs)
        #expect(TrainingSplit(name: "Full body") == nil)
    }

    @Test func wallTargetsRoundTrip() {
        let id = UUID()
        #expect(TrainingWallTarget(id: TrainingWallTarget.exercise(id).id) == .exercise(id))
        #expect(TrainingWallTarget(id: TrainingWallTarget.routine(id).id) == .routine(id))
        #expect(TrainingWallTarget(id: "nonsense") == nil)
    }

    @Test func recentAndBestWeighMost() {
        #expect(TrainingWallFacts.weight(daysSince: 0, bestIsNewest: true) == 1)
        #expect(TrainingWallFacts.weight(daysSince: 1, bestIsNewest: false)
            > TrainingWallFacts.weight(daysSince: 30, bestIsNewest: false))
        #expect(TrainingWallFacts.weight(daysSince: 90, bestIsNewest: false) == 0)
        #expect(TrainingWallFacts.short("Incline Dumbbell Bench Press").count <= 14)
    }

    // MARK: Facts from data

    @Test func seededDataGivesFiveDoorsAndAWall() {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let facts = TrainingWallFacts.load(model)
        #expect(facts.doors.map(\.name) == ["This week", "Routines", "Exercises", "Programs", "Goals"])
        #expect(!facts.words.isEmpty)
        #expect(facts.doors.allSatisfy { $0.lines.count <= 3 })
        #expect(facts.doors.flatMap(\.lines).allSatisfy { !$0.contains(" of ") })
    }

    @Test func privateRoutinesNeverReachTheWall() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let plan = try #require(model.plan)
        let routine = try #require(model.store.linkedObjects("routines", of: plan).first)
        _ = try model.engine.perform(RenameObject(object: routine.id, title: SecretWords.title), by: .user)
        model.touch()
        let facts = TrainingWallFacts.load(model)
        #expect(!facts.words.contains { $0.id == TrainingWallTarget.routine(routine.id).id })
        #expect(!facts.words.contains { $0.text == ObjectPrivacy.routineLabel })
        let routineLines = facts.doors.first { $0.id == "routines" }?.lines ?? []
        #expect(!routineLines.contains(SecretWords.title))
    }

    // MARK: Deck (blackboard and scaffold)

    @Test func boardLinesCutOnWholeWords() {
        #expect(TrainingBoard.fitted("Push A today", limit: 18) == "Push A today")
        let cut = TrainingBoard.fitted("Bench Press opens at 80 kg tonight after work", limit: 20)
        #expect(cut.count <= 20)
        #expect(!cut.contains("...") && !cut.contains("…"))
        #expect("Bench Press opens at 80 kg tonight after work".hasPrefix(cut))
    }

    @Test func weekWordsNeverCount() {
        #expect(TrainingDeckFacts.weekNumber(done: 1) == ("1", "day"))
        #expect(TrainingDeckFacts.weekNumber(done: 3) == ("3", "days"))
        #expect(TrainingDeckFacts.leftWords(done: 2, perWeek: 4) == "2 to go")
        #expect(TrainingDeckFacts.leftWords(done: 4, perWeek: 4) == "Week done")
        #expect(TrainingDeckFacts.leftWords(done: 0, perWeek: 0) == "No plan days")
    }

    @Test func seededDataFillsTheBoardMastheadAndWidget() {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let wall = TrainingWallFacts.load(model)
        let deck = TrainingDeckFacts.load(model, wall: wall)
        #expect(deck.board.week.count == 7)
        #expect(deck.board.week.filter(\.isToday).count <= 1)
        #expect(deck.board.bests.count <= 3)
        #expect(deck.board.headline.count <= 18)
        #expect(deck.needs.count == TrainingDeckFacts.across.count)
        #expect(deck.needs.allSatisfy { $0.count == 2 })
        #expect(!deck.widget.isEmpty && deck.widget.count <= 3)
        #expect(deck.widget.allSatisfy { !$0.strikeable })
        let shown = deck.needs.flatMap(\.self) + deck.widget.flatMap { [$0.big, $0.middle, $0.small] }
            + [deck.board.headline, deck.board.detail]
        #expect(shown.allSatisfy { !$0.contains(" of ") && !$0.contains("...") && !$0.contains("…") }, "\(shown)")
    }

    @Test func privateRoutinesStayOffTheBoardAndSwitcher() throws {
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        let plan = try #require(model.plan)
        for routine in model.store.linkedObjects("routines", of: plan) {
            _ = try model.engine.perform(RenameObject(object: routine.id, title: SecretWords.title), by: .user)
        }
        model.touch()
        let deck = TrainingDeckFacts.load(model, wall: TrainingWallFacts.load(model))
        let shown = deck.routineWords + deck.needs.flatMap(\.self) + [deck.board.headline, deck.board.detail]
            + deck.widget.map(\.big)
        #expect(!shown.contains { $0.contains(SecretWords.title) }, "\(shown)")
    }
}
