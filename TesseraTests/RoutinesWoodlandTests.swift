// swiftlint:disable identifier_name
import CoreGraphics
import Foundation
@testable import Tessera
import Testing
import UIKit

/// The Routines woodland (sheet 248, landing contract): stage and health thresholds, the log read by day and by week,
/// the state line forms and their fit, the brief rows, and private routines.
struct RoutinesWoodlandTests {
    private static func tree(_ name: String = "Push A", days: Int = 10, marks: [WoodlandMark] = [],
                             done: Bool = false, due: Bool = false, cap: CGFloat = 104,
                             isPrivate: Bool = false) -> WoodlandTree
    {
        WoodlandTree(id: UUID(), name: name, isPrivate: isPrivate, days: days, marks: marks, doneToday: done,
                     dueToday: due, cap: cap, species: .oak)
    }

    // MARK: Stages

    @Test func stagesFollowTheSheetDays() {
        #expect(WoodlandStage.of(days: 0) == .sprout)
        #expect(WoodlandStage.of(days: 2) == .sprout)
        #expect(WoodlandStage.of(days: 3) == .smallPlant)
        #expect(WoodlandStage.of(days: 6) == .smallPlant)
        #expect(WoodlandStage.of(days: 7) == .mediumPlant)
        #expect(WoodlandStage.of(days: 27) == .mediumPlant)
        #expect(WoodlandStage.of(days: 28) == .tree)
        #expect(WoodlandStage.height(days: 0) == 14)
        #expect(WoodlandStage.height(days: 28) == 76)
        #expect(WoodlandStage.height(days: 200) == 104)
    }

    @Test func fruitFromDay35AndNestFromDay30() {
        #expect(!Self.tree(days: 34).hasFruit)
        #expect(Self.tree(days: 35).hasFruit)
        #expect(Self.tree(days: 49).fruitCycle == 3)
        #expect(!Self.tree(days: 29).hasNest)
        #expect(Self.tree(days: 30).hasNest)
    }

    @Test func importanceSetsTheCeiling() {
        #expect(Self.tree(days: 60, cap: 46).stageWords == "shrub")
        #expect(Self.tree(days: 60, cap: 46).height == 46)
        #expect(Self.tree(days: 60, cap: 68).stageWords == "small tree")
        #expect(Self.tree(days: 60).stageWords == "tree")
        #expect(WoodlandLog.cap(steps: 2) == 46)
        #expect(WoodlandLog.cap(steps: 4) == 68)
        #expect(WoodlandLog.cap(steps: 6) == 104)
    }

    // MARK: Health

    @Test func threeInARowOrThreeInSevenWithers() {
        let k = WoodlandMark.kept, s = WoodlandMark.slipped, o = WoodlandMark.open
        #expect(!WoodlandHealth(marks: [k, k, k, k, s, s, k]).isWithering)
        #expect(WoodlandHealth(marks: [k, k, k, k, s, s, s]).isWithering)
        #expect(WoodlandHealth(marks: [s, k, s, k, s, k, k]).isWithering)
        // Rest days and an open today never count as slips, and do not break a run.
        #expect(WoodlandHealth(marks: [k, s, o, s, o, s, o]).consecutive == 3)
        // One kept day cannot undo a week with three slips.
        #expect(WoodlandHealth(marks: [k, k, s, s, s, k, k]).isWithering)
    }

    @Test func eightInARowIsBare() {
        let s = WoodlandMark.slipped
        let health = WoodlandHealth(marks: [.kept] + Array(repeating: s, count: 8))
        #expect(health.isBare)
        #expect(!health.isWithering)
        #expect(!WoodlandHealth(marks: [.kept] + Array(repeating: s, count: 7)).isBare)
    }

    @Test func softWordsNeverShame() {
        let bare = Self.tree(marks: Array(repeating: .slipped, count: 9))
        let care = Self.tree(marks: [.kept, .slipped, .slipped, .slipped])
        #expect(bare.stateWords == "begin again")
        #expect(care.stateWords == "needs a little care")
        for words in [bare.stateWords, care.stateWords].compactMap(\.self) {
            #expect(!words.contains("miss"))
            #expect(!words.contains("dead"))
        }
    }

    // MARK: The log

    @Test func dailyLogMarksDueDaysAndKeepsTodayOpen() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_790_000_000))
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let marks = WoodlandLog.marks(runDays: [yesterday], daily: true, weekdays: [], today: today, span: 4,
                                      calendar: calendar)
        #expect(marks == [.slipped, .slipped, .kept, .open])
        let doneToday = WoodlandLog.marks(runDays: [today], daily: true, weekdays: [], today: today, span: 2,
                                          calendar: calendar)
        #expect(doneToday == [.slipped, .kept])
    }

    @Test func fixedDaysOnlyCountTheirWeekdays() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_790_000_000))
        let weekday = calendar.component(.weekday, from: today)
        let other = weekday == 1 ? 7 : weekday - 1 // yesterday's weekday only
        let marks = WoodlandLog.marks(runDays: [], daily: false, weekdays: [other], today: today, span: 7,
                                      calendar: calendar)
        #expect(marks.filter { $0 == .slipped }.count == 1)
        #expect(marks[5] == .slipped)
    }

    @Test func weeklyRoutinesAreReadByWeek() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_790_000_000))
        let tenDaysAgo = try #require(calendar.date(byAdding: .day, value: -10, to: today))
        let marks = WoodlandLog.marks(runDays: [tenDaysAgo], daily: false, weekdays: [], today: today, span: 3,
                                      calendar: calendar)
        #expect(marks == [.slipped, .kept, .open])
    }

    // MARK: Words and fit

    @Test func stateLineFormsAreLongestFirstWithNoCounters() {
        let trees = [Self.tree(done: true), Self.tree(), Self.tree(marks: [.slipped, .slipped, .slipped])]
        let forms = RoutinesWoodlandFacts.stateLine(trees)
        #expect(forms.first == "1 done today, 1 to tend, 1 needs a little care.")
        #expect(forms == forms.sorted { $0.count > $1.count })
        for form in forms {
            #expect(!form.contains(" of "))
            #expect(!form.contains("..."))
        }
        #expect(RoutinesWoodlandFacts.stateLine([]).last == "Quiet day.")
    }

    @Test func theShortestFormsFitAtDefaultAndAX5() throws {
        let width: CGFloat = 354
        let trees = (0 ..< 12).map { i in Self.tree(marks: i > 8 ? [.slipped, .slipped, .slipped] : [], done: i < 4) }
        let forms = RoutinesWoodlandFacts.stateLine(trees)
        // Figtree 16 at the default size and about 3.1x at AX5 (the body ramp).
        for (size, form) in try [(CGFloat(16), #require(forms.first)), (CGFloat(16 * 3.1), #require(forms.last))] {
            let font = UIFont(name: "Figtree-Regular", size: size) ?? .systemFont(ofSize: size)
            let measured = (form as NSString).size(withAttributes: [.font: font]).width
            #expect(measured <= width, "\(form) at \(size) pt is \(measured) pt")
        }
    }

    @Test func briefRowsCutOnWholeWordsAndDropSmallWords() {
        let forms = RoutineUpdateRow.forms(name: "Chest and shoulders", rest: " is next, around 6:10 pm")
        #expect(forms.map(\.rest).first == " is next, around 6:10 pm")
        #expect(forms[1].rest == " is next")
        #expect(forms.map(\.name).contains("Chest"))
        #expect(!forms.map(\.name).contains("Chest and"))
        #expect(RoutineUpdateRow.short(" needs a little care") == " needs care")
    }

    @Test func doorsAreTheSixGrovesAndFruitCounts() {
        let facts = RoutinesWoodlandFacts(trees: [Self.tree(days: 40), Self.tree(due: true)])
        #expect(facts.doors.map(\.name) == ["Today", "Body", "Mind", "Home", "Fruit", "Across the lake"])
        #expect(facts.doors.first { $0.id == "fruit" }?.count == 1)
        #expect(facts.doors.first { $0.id == "today" }?.count == 1)
        #expect(facts.doors.allSatisfy { !$0.lines.isEmpty && $0.lines.count <= 3 })
    }

    @Test func theWoodlandShowsAtMostTwelveWithTodayInFront() {
        var trees = (0 ..< 20).map { Self.tree("R\($0)", days: $0) }
        trees.append(Self.tree("Due", days: 1, due: true))
        let facts = RoutinesWoodlandFacts(trees: trees)
        #expect(facts.trees.count == 12)
        #expect(facts.trees.first?.name == "Due")
        #expect(WoodlandLayout.places(count: 12).count == 12)
    }

    @Test func neighboursNeverShareAColourAndBlueStaysAtTheEdges() {
        let places = WoodlandLayout.places(count: 12)
        let families = WoodlandLayout.families(for: places)
        for (i, a) in places.enumerated() {
            if families[i] == .blue {
                #expect(a.x < 30 || a.x > 330)
            }
            for (j, b) in places.enumerated() where j > i && abs(a.x - b.x) < 56 && abs(a.base - b.base) < 40 {
                #expect(families[i] != families[j])
            }
        }
    }

    @Test func everyPlantHasItsOwnTapTarget() {
        let trees = (0 ..< 12).map { Self.tree("R\($0)", days: 5 + $0 * 4) }
        let places = WoodlandLayout.places(count: trees.count)
        for (tree, place) in zip(trees, places) {
            let point = CGPoint(x: place.x, y: place.base - tree.height * place.scale / 2)
            #expect(RoutinesWoodlandScene.hit(point, trees: trees, places: places) == tree.id)
        }
    }

    // MARK: Privacy

    @Test func privateRoutinesShowOnlyAsPrivateRoutine() {
        let hidden = Self.tree(RoutinesLandingWords.privateName, days: 40, marks: [.slipped, .slipped, .slipped],
                               isPrivate: true)
        let facts = RoutinesWoodlandFacts(trees: [hidden])
        let caption = RoutinesWoodlandFacts.caption(for: hidden, selected: true)
        #expect(caption.allSatisfy { $0.hasPrefix("Private routine") })
        #expect(facts.updates.allSatisfy { $0.name == "Private routine" })
        #expect(facts.doors.flatMap(\.lines).allSatisfy { !$0.contains("Pills") })
    }

    @Test func notNowStaysOnThisPhoneForTheDay() throws {
        let defaults = try #require(UserDefaults(suiteName: "woodland-\(UUID().uuidString)"))
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        let id = UUID()
        RoutinesNotNow.set(id, on: day, hidden: true, defaults: defaults)
        #expect(RoutinesNotNow.ids(on: day, defaults: defaults) == [id])
        #expect(RoutinesNotNow.ids(on: day.addingTimeInterval(86400), defaults: defaults).isEmpty)
        RoutinesNotNow.set(id, on: day, hidden: false, defaults: defaults)
        #expect(RoutinesNotNow.ids(on: day, defaults: defaults).isEmpty)
    }
}
