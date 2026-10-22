import Foundation
@testable import TesseraCore
import Testing

/// The Routines landing (Product build sheet, Oct 22, trimmed): LR-1 to LR-13.
struct RoutinesLandingTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func runs(_ days: [Int], hour: Int, minute: Int, length: Int) -> [RoutineRun] {
        days.map { day in
            RoutineRun(start: at(day, hour, minute), end: at(day, hour, minute).addingTimeInterval(Double(length) * 60))
        }
    }

    func facts(_ items: [RoutinesLanding.Item], running: RoutinesLanding.Running? = nil) -> RoutinesLanding.Facts {
        RoutinesLanding.facts(items: items, running: running, now: at(22, 12), calendar: calendar)
    }

    @Test func lr1NothingSetUp() {
        let result = facts([])
        #expect(result.subtitle.text == "Nothing set up yet." && result.top.starts.isEmpty && result.lines.isEmpty)
        #expect(result.top.sentence.text == "Nothing is running")
    }

    @Test func lr2OneWorkoutDay() {
        let result = facts([.init(name: "Push A", isWorkout: true, count: 5)])
        #expect(result.subtitle.text == "1 routine." && result.top.starts == ["Start Push A"])
        #expect(result.lines == ["Push A, 5 exercises"])
    }

    @Test func lr3FiveRoutinesShowThreeStartsAndThreeLines() {
        let names = ["Morning", "Evening", "Push A", "Pull A", "Legs"]
        let items = names.enumerated().map { index, name in
            RoutinesLanding.Item(
                name: name,
                count: 4,
                runs: runs(Array(1 ... (5 - index)), hour: 7, minute: 0, length: 10)
            )
        }
        let result = facts(items)
        #expect(result.subtitle.text == "5 routines.")
        #expect(result.top.starts == ["Start Morning", "Start Evening", "Start Push A"])
        #expect(result.lines.count == 3)
    }

    @Test func lr4UsualLineAfterSevenRuns() {
        let morning = RoutinesLanding.Item(
            name: "Morning",
            count: 6,
            runs: runs(Array(1 ... 14), hour: 6, minute: 40, length: 22)
        )
        #expect(facts([morning]).lines == ["Morning, 14 days, usually 6:40, 22 min"])
    }

    @Test func lr5SixRunsStillSayTheSteps() {
        let morning = RoutinesLanding.Item(
            name: "Morning",
            count: 6,
            runs: runs(Array(1 ... 6), hour: 6, minute: 40, length: 22)
        )
        #expect(facts([morning]).lines == ["Morning, 6 steps"])
        #expect(facts([.init(name: "Short", count: 1)]).lines == ["Short, 1 step"])
    }

    @Test func lr6EveningRoutineKeepsItsPmAndHoursReadHouseWay() {
        let night = RoutinesLanding.Item(
            name: "Night",
            count: 5,
            runs: runs(Array(1 ... 11), hour: 18, minute: 35, length: 95)
        )
        #expect(facts([night]).lines == ["Night, 11 days, usually 6:35 pm, 1 hr 35 min"])
    }

    @Test func lr7UsualIsTheMedianOfTheLastFourteenRoundedToFive() {
        let early = runs(Array(1 ... 3), hour: 5, minute: 0, length: 30) // older, outside the last 14
        let recent = runs(Array(5 ... 18), hour: 6, minute: 43, length: 20)
        let item = RoutinesLanding.Item(name: "Morning", count: 6, runs: early + recent)
        #expect(facts([item]).lines == ["Morning, 17 days, usually 6:45, 20 min"])
    }

    @Test func lr8Running() {
        let running = RoutinesLanding.Running(name: "Morning", step: "Shoes on", secondsOnStep: 250)
        let result = facts([.init(name: "Morning", count: 6)], running: running)
        #expect(result.top.sentence.text == "Morning is running" && result.top.step == "Shoes on")
        #expect(result.top.onThisStep == "4 min on this step" && result.top.starts.isEmpty)
    }

    @Test func lr9Paused() {
        let running = RoutinesLanding.Running(name: "Morning", step: "Shoes on", secondsOnStep: 250, isPaused: true)
        let result = facts([.init(name: "Morning", count: 6)], running: running)
        #expect(result.top.sentence.text == "Morning is paused" && result.top
            .onThisStep == "Paused at 4 min on this step")
    }

    @Test func lr10DoneAtAndTheSubtitleCountsDone() {
        let done = RoutinesLanding.Item(name: "Morning", count: 6, doneToday: at(22, 6, 58))
        let other = RoutinesLanding.Item(name: "Evening", count: 4)
        let result = facts([done, other])
        #expect(result.subtitle.text == "2 routines, 1 done today.")
        #expect(result.lines == ["Evening, 4 steps", "Morning, done at 6:58"])
    }

    @Test func lr11EverythingDone() {
        let result = facts([.init(name: "Morning", count: 6, doneToday: at(22, 6, 58))])
        #expect(result.top.sentence.text == "Everything is done today" && result.subtitle.text == "All done today.")
        #expect(result.top.starts.isEmpty)
    }

    @Test func lr12PrivateRoutinesAndStepsAreMaskedEverywhere() {
        let secret = RoutinesLanding.Item(name: "Knee rehab day", count: 6, isPrivate: true,
                                          runs: runs(Array(1 ... 9), hour: 7, minute: 0, length: 20))
        let running = RoutinesLanding.Running(name: "Knee rehab day", isPrivate: true, step: "Ice the knee",
                                              isStepPrivate: true, secondsOnStep: 60)
        let result = facts([secret], running: running)
        #expect(result.top.sentence.text == "Private routine is running" && result.top.step == "Private step")
        #expect(result.lines == ["Private routine"])
        let quiet = facts([secret])
        #expect(quiet.top.starts == ["Start Private routine"])
        let every = ([result.top.sentence.text, result.top.step ?? ""] + result.lines + quiet.top.starts).joined()
        #expect(!every.contains("Knee") && !every.contains("Ice"))
    }

    @Test func lr13ASkippedStepNeverSaysMissedOrSkipped() {
        let item = RoutinesLanding.Item(
            name: "Morning",
            count: 6,
            runs: runs(Array(1 ... 3), hour: 7, minute: 0, length: 20)
        )
        let result = facts([item, .init(name: "Evening", count: 4)])
        let every = ([result.subtitle.text, result.top.sentence.text] + result.lines + result.top.starts)
            .joined(separator: " ")
        for word in ["missed", "skipped", "streak", "behind", "late"] {
            #expect(!every.lowercased().contains(word))
        }
    }

    @Test func theSharedSwitchIdIsAlreadyInReview() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Features/Settings/ReviewChoices.swift")
        let text = try String(contentsOf: sources, encoding: .utf8)
        #expect(text.contains("Choice(id: \"landingPages\""))
    }
}
