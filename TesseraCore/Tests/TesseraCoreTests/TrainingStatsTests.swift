import Foundation
@testable import TesseraCore
import Testing

/// Training Stats (Product build sheet, Oct 22): the engine behind the Stats page and the Training landing.
@MainActor
struct TrainingStatsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let stats: TrainingStats
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Thursday, October 22, 2026, 12:00.
    var now: Date {
        Date(timeIntervalSince1970: 1_792_670_400)
    }

    init() throws {
        classes = try store.prepareCatalog()
        stats = TrainingStats(store: store, classes: classes)
    }

    var ledger: TrainingLedger {
        stats.ledger
    }

    @discardableResult
    func session(daysAgo: Double, _ exercise: SystemCatalog.Key = .benchPress, sets: [(Double, Double)],
                 rpe: Double? = nil, title: String = "Push Day A", minutes: Double? = nil, endedAt: Date? = nil)
        throws -> ObjectRecord
    {
        let ended = endedAt ?? now.addingTimeInterval(-daysAgo * 86400)
        let workout = try store.create(#require(classes[.workout]), title: title)
        try store.set("endedAt", to: .date(ended), on: workout)
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(classes[exercise]))
        for (index, set) in sets.enumerated() {
            let made = try ledger.logSet(weight: set.0, reps: set.1, rpe: rpe, in: entry)
            let at = ended.addingTimeInterval(-(minutes ?? 0) * 60 * Double(sets.count - 1 - index) / Double(max(
                sets.count - 1,
                1
            )))
            try store.set("loggedAt", to: .date(at), on: made)
        }
        return workout
    }

    /// 1
    @Test func e1RMOf80x5IsAbout93AndRPEAddsRepsInReserve() throws {
        #expect(try abs(#require(ledger.e1RM(weight: 80, reps: 5)) - 93.33) < 0.01)
        #expect(try abs(#require(ledger.e1RM(weight: 80, reps: 5, rpe: 8)) - 98.67) < 0.01)
    }

    /// 2
    @Test func bestIsTheNewestSessionThatBeatEveryEarlierOne() throws {
        try session(daysAgo: 60, sets: [(70, 5)])
        try session(daysAgo: 16, sets: [(80, 5)]) // 93.3, Oct 6
        try session(daysAgo: 8, sets: [(75, 5)]) // lower: not a best
        let best = try #require(stats.bestInRange(.threeMonths, now: now, calendar: calendar))
        #expect(best.exercise == "Bench Press" && abs(best.e1RM - 93.33) < 0.01)
        #expect(TrainingSentences.best(best, unit: .kilograms, calendar: calendar)
            == "Your best Bench Press is about 93 kg for 1, on Oct 6.")
        #expect(!TrainingSentences.best(best, unit: .kilograms, calendar: calendar).lowercased().contains("record"))
    }

    /// 3
    @Test func ninetyThenNinetyFiveIsUpFiveKilosInThreeMonths() throws {
        try session(daysAgo: 85, sets: [(90, 5)])
        try session(daysAgo: 50, sets: [(92.5, 5)])
        try session(daysAgo: 6, sets: [(95, 5)])
        let lines = stats.strengthLines(.threeMonths, now: now, calendar: calendar)
        let bench = try #require(lines.first)
        #expect(bench.change == .up(steps: 2) && bench.sessions == 3)
        #expect(TrainingSentences.strength(bench, range: .threeMonths, unit: .kilograms)
            == "Bench Press is up 5 kg in 3 months.")
        #expect(TrainingSentences.strengthOpening(lines, range: .threeMonths, unit: .kilograms)
            == "Bench Press is up 5 kg in 3 months.")
        #expect(TrainingSentences.strength(bench, range: .year, unit: .kilograms)?.hasSuffix("in the year.") == true)
        #expect(TrainingSentences
            .strength(bench, range: .threeMonths, unit: .pounds) == "Bench Press is up 10 lb in 3 months.")
    }

    /// 4
    @Test func aLowerLiftReadsHoldingNearItsBestAndNeverDown() throws {
        try session(daysAgo: 85, sets: [(100, 5)])
        try session(daysAgo: 50, sets: [(97.5, 5)])
        try session(daysAgo: 6, sets: [(95, 5)])
        let bench = try #require(stats.strengthLines(.threeMonths, now: now, calendar: calendar).first)
        let text = try #require(TrainingSentences.strength(bench, range: .threeMonths, unit: .kilograms))
        #expect(text == "Bench Press is holding near its best.")
        for word in ["down", "lost", "broke", "streak", "record"] {
            #expect(!text.lowercased().contains(word))
        }
    }

    /// 5
    @Test func twoSessionsOmitTheLiftAndOneGivesTheFirstNumber() throws {
        try session(daysAgo: 20, .barbellLift, sets: [(100, 5)])
        try session(daysAgo: 10, .barbellLift, sets: [(105, 5)])
        try session(daysAgo: 8, sets: [(80, 5)])
        let lines = stats.strengthLines(.threeMonths, now: now, calendar: calendar)
        #expect(lines.map(\.exercise) == ["Bench Press"])
        let first = try #require(lines.first)
        #expect(first.change == .first)
        #expect(TrainingSentences.strength(first, range: .threeMonths, unit: .kilograms)
            == "First number for Bench Press: about 93 kg for 1.")
    }

    /// 6
    @Test func massConvertsAtTheEdgeOnly() {
        #expect(StatsMass.text(kg: 95.0, unit: .pounds) == "210 lb")
        #expect(StatsMass.text(kg: 95.0, unit: .kilograms) == "95 kg")
        #expect(StatsMass.text(kg: 82.5, unit: .kilograms) == "82.5 kg")
        #expect(StatsMass.estimate(kg: 93.3, unit: .kilograms) == "93 kg")
    }

    /// 7
    @Test func aPrivateWorkoutChangesNothingAndTheLogShowsAnOutlineRow() throws {
        try session(daysAgo: 85, sets: [(90, 5)])
        try session(daysAgo: 50, sets: [(92.5, 5)])
        try session(daysAgo: 6, sets: [(95, 5)])
        let before = stats.bestInRange(.threeMonths, now: now, calendar: calendar)
        let lines = stats.strengthLines(.threeMonths, now: now, calendar: calendar)
        let rows = stats.logMonths(now: now, calendar: calendar).flatMap(\.rows).count
        try session(daysAgo: 2, .barbellLift, sets: [(120, 5)], title: "Knee rehab day")
        #expect(stats.bestInRange(.threeMonths, now: now, calendar: calendar) == before)
        #expect(stats.strengthLines(.threeMonths, now: now, calendar: calendar) == lines)
        let log = stats.logMonths(now: now, calendar: calendar).flatMap(\.rows)
        #expect(log.count == rows + 1)
        let outline = try #require(log.first)
        #expect(outline.isPrivate && outline.title == "Private workout" && outline.setsText == nil && outline
            .duration == nil)
        #expect(stats.volume(.threeMonths, now: now, calendar: calendar).rows.allSatisfy { $0.name != "Quads" })
    }

    /// 8
    @Test func fourBenchSetsCreditChestOneAndTricepsHalf() throws {
        try session(daysAgo: 1, sets: [(80, 5), (80, 5), (80, 5), (80, 5)])
        let volume = stats.volume(.threeMonths, now: now, calendar: calendar)
        let chest = try #require(volume.rows.first { $0.name == "Chest" })
        #expect(chest.sets == 4)
        #expect(volume.rows.first { $0.name == "Triceps" }?.sets == 2)
        #expect(TrainingSentences.volume(chest) == "Chest 4 sets this week, toward a usual 10.")
        #expect(TrainingSentences.volume(.init(name: "Lats", sets: 14, band: .within))
            == "Lats 14 sets this week, in its usual 10 to 20.")
        #expect(TrainingSentences.volume(.init(name: "Lats", sets: 24, band: .above)) == "Lats 24 sets this week.")
        #expect(volume.totalSets >= 6)
    }

    func weekly(_ counts: [Int], endingWeeksAgo: Int = 0) throws {
        // `counts` oldest first; each entry is the number of sessions in that week, on the week's Tuesday.
        for (index, count) in counts.enumerated() {
            let weeksAgo = counts.count - 1 - index + endingWeeksAgo
            for session in 0 ..< count {
                // The current week's Tuesday is 2 days ago (Thursday now).
                try self.session(daysAgo: Double(weeksAgo * 7 + 3 - session), sets: [(60, 5), (60, 5)])
            }
        }
    }

    /// 9
    @Test func weeksOfThreeThreeNothingFourThreeGiveAUsualOfThree() throws {
        try weekly([3, 3, 0, 4, 3])
        let habit = stats.habit(.threeMonths, now: now, calendar: calendar)
        #expect(habit.usual == 3)
        let last5 = Array(habit.weeks.suffix(5))
        let counts = last5.map(\.sessions)
        #expect(counts == [3, 3, 0, 4, 3])
        #expect(last5[2].isEmpty)
        #expect(TrainingSentences.sessions(3, usual: 3) == "3 sessions this week. Usual 3.")
        #expect(TrainingSentences.sessions(1, usual: 3) == "1 session this week. Usual 3.")
    }

    /// 10
    @Test func aFinishedRunOfNineShowsAndARunOfTwoAloneDoesNot() throws {
        try weekly(Array(repeating: 1, count: 9) + [0, 0, 1, 1, 1], endingWeeksAgo: 0)
        let nine = stats.habit(.year, now: now, calendar: calendar)
        #expect(nine.bestRun == 9 && TrainingSentences.bestRun(nine.bestRun) == "Best run: 9 weeks in a row.")
    }

    @Test func aRunOfTwoAloneIsNeverTold() throws {
        try weekly([1, 1, 0, 0, 1])
        let habit = stats.habit(.threeMonths, now: now, calendar: calendar)
        #expect(habit.bestRun == nil && TrainingSentences.bestRun(habit.bestRun) == nil && TrainingSentences
            .bestRun(2) == nil)
    }

    @Test func theRunStillGoingIsNeverTold() throws {
        try weekly(Array(repeating: 1, count: 6))
        #expect(stats.habit(.threeMonths, now: now, calendar: calendar).bestRun == nil)
    }

    /// 11
    @Test func aLightWeekNeedsFourPriorWeeksAndItsSwitch() throws {
        // Four weeks of 21 sets, then a week of 12: 12 <= 60% of 21.
        for week in 1 ... 4 {
            for day in 0 ..< 3 {
                try session(daysAgo: Double(week * 7 + 3 - day), sets: Array(repeating: (60, 5), count: 7))
            }
        }
        try session(daysAgo: 2, sets: Array(repeating: (60, 5), count: 12))
        #expect(stats.habit(.threeMonths, now: now, lightWeeks: true, calendar: calendar).current?.isLight == true)
        #expect(stats.habit(.threeMonths, now: now, lightWeeks: false, calendar: calendar).current?.isLight == false)
        #expect(TrainingSentences.lighterWeek == "A lighter week.")
    }

    @Test func withOnlyThreePriorWeeksNothingIsLight() throws {
        for week in 1 ... 3 {
            for day in 0 ..< 3 {
                try session(daysAgo: Double(week * 7 + 3 - day), sets: Array(repeating: (60, 5), count: 7))
            }
        }
        try session(daysAgo: 2, sets: Array(repeating: (60, 5), count: 12))
        #expect(stats.habit(.threeMonths, now: now, lightWeeks: true, calendar: calendar).weeks
            .allSatisfy { !$0.isLight })
    }

    /// 12
    @Test func balanceCases() {
        func lines(_ push: Double, _ pull: Double, _ lower: Double) -> [String] {
            TrainingSentences.balance(.init(push: push, pull: pull, lower: lower))
        }
        #expect(lines(10, 10, 20) == ["Push and pull are even.", "Upper and lower are even."])
        #expect(lines(8, 12, 20) == ["Pull is a little ahead of push.", "Upper and lower are even."])
        #expect(lines(12, 8, 8) == ["Push is a little ahead of pull.", "Upper gets more of your sets."])
        #expect(lines(10, 10, 5) == ["Push and pull are even.", "Upper gets more of your sets."])
        #expect(lines(5, 5, 20) == ["Push and pull are even.", "Lower gets more of your sets."])
    }

    @Test func balanceCountsOnlyTheNamedGroups() throws {
        try session(daysAgo: 1, sets: Array(repeating: (80, 5), count: 4))
        let balance = try #require(stats.balance(.threeMonths, now: now, calendar: calendar))
        #expect(balance.push > 0 && balance.lower == 0)
        #expect(TrainingStats.pushMuscles.isDisjoint(with: TrainingStats.pullMuscles))
        #expect(!TrainingStats.pushMuscles.union(TrainingStats.pullMuscles).union(TrainingStats.lowerMuscles)
            .contains("Abs"))
    }

    /// 13
    @Test func logDurationsReadTheHouseWay() throws {
        try session(daysAgo: 3, sets: [(60, 5), (60, 5), (60, 5)], minutes: 35)
        try session(daysAgo: 2, sets: [(60, 5), (60, 5)], minutes: 60)
        try session(daysAgo: 1, sets: [(60, 5), (60, 5)], minutes: 95)
        let rows = stats.logMonths(now: now, calendar: calendar).flatMap(\.rows)
        #expect(rows.map(\.duration) == ["1 hr 35 min", "1 hr", "35 min"])
        #expect(rows.map(\.setsText) == ["2 sets", "2 sets", "3 sets"])
        #expect(rows.allSatisfy { !$0.isPrivate && $0.calories == nil })
    }

    /// 14
    @Test func caloriesRoundToTenAreOffByDefaultAndNeverStored() throws {
        #expect(CaloriesBurned.estimate(met: 5, weightKg: 80, minutes: 72) == 480)
        #expect(CaloriesBurned.estimate(met: 5, weightKg: 83, minutes: 72) == 500)
        #expect(CaloriesBurned.estimate(met: 5, weightKg: 0, minutes: 72) == nil)
        try session(daysAgo: 1, sets: [(60, 5), (60, 5)], minutes: 40)
        let before = store.revision
        let off = stats.logMonths(now: now, calories: CaloriesOptions(on: false, healthKg: 80), calendar: calendar)
        #expect(off.flatMap(\.rows).allSatisfy { $0.calories == nil })
        _ = stats.logMonths(now: now, calories: CaloriesOptions(on: true, healthKg: 80), calendar: calendar)
        #expect(store.revision == before)
        let export = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(!export.contains("kcal"))
    }

    /// 15
    @Test func theLandingSentenceReusesTheLandingWords() {
        #expect(TrainingSentences.today(routine: "Push A", minutes: 45, opener: ("Bench", "82.5")).text
            == "Push A today, about 45 min. Bench opens at 82.5.")
        #expect(TrainingSentences.today(routine: "Push A", minutes: nil, opener: nil).text == "Push A today.")
        #expect(TrainingSentences.running(routine: "Push A", done: 6, total: 20) == "Push A is running. 6 of 20 sets.")
        #expect(TrainingSentences.finished(routine: "Push A", minutes: 95) == "Push A done, 1 hr 35 min.")
        #expect(TrainingSentences.restDay == "Rest day." && TrainingSentences.noPlan == "No plan yet.")
        #expect(TrainingSentences.privateToday == "A private workout today.")
    }

    /// 16
    @Test func nothingAtAllAndOneSessionAreQuiet() throws {
        #expect(stats.bestInRange(.threeMonths, now: now, calendar: calendar) == nil)
        #expect(stats.strengthLines(.threeMonths, now: now, calendar: calendar).isEmpty)
        #expect(stats.balance(.threeMonths, now: now, calendar: calendar) == nil)
        #expect(stats.logMonths(now: now, calendar: calendar).isEmpty)
        #expect(stats.habit(.threeMonths, now: now, calendar: calendar).usual == 0)
        try session(daysAgo: 3, sets: [(80, 5)])
        #expect(stats.strengthLines(.threeMonths, now: now, calendar: calendar).first?.change == .first)
        #expect(stats.habit(.threeMonths, now: now, calendar: calendar).bestRun == nil)
    }

    /// 17
    @Test func anEditReflowsTheBest() throws {
        try session(daysAgo: 20, sets: [(70, 5)])
        let made = try session(daysAgo: 4, sets: [(80, 5)])
        #expect(try abs(#require(stats.bestInRange(.threeMonths, now: now, calendar: calendar)).e1RM - 93.33) < 0.01)
        let set = try #require(made.orderedChildren.first?.orderedChildren.first)
        try store.set("weight", to: .mass(60), on: set)
        let after = try #require(stats.bestInRange(.threeMonths, now: now, calendar: calendar))
        #expect(abs(after.e1RM - 81.67) < 0.01)
        store.softDelete(made)
        #expect(try abs(#require(stats.bestInRange(.threeMonths, now: now, calendar: calendar)).e1RM - 81.67) < 0.1)
    }

    /// The 4 AM boundary and daylight saving.
    @Test func aSessionBeforeFourBelongsToTheDayBeforeAndItsWeek() throws {
        // 02:00 on Monday Oct 19 is still Sunday Oct 18: last week's.
        let monday2am = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 2)))
        try session(daysAgo: 0, sets: [(60, 5)], endedAt: monday2am)
        let weeks = stats.habit(.threeMonths, now: now, calendar: calendar).weeks
        let lastWeek = weeks[weeks.count - 2], thisWeek = weeks[weeks.count - 1]
        #expect(lastWeek.sessions == 1 && thisWeek.sessions == 0)
        #expect(lastWeek.days == [0, 0, 0, 0, 0, 0, 1])
    }

    @Test func daylightSavingMovesNoSessionOutOfItsWeek() throws {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = try #require(TimeZone(identifier: "Europe/London"))
        // The clocks go back at 02:00 on Sunday Oct 25: 00:30 that night is Saturday's, in the week of Oct 19.
        let night = try #require(london.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 0, minute: 30)))
        let monday = try #require(london.date(from: DateComponents(year: 2026, month: 10, day: 26, hour: 12)))
        try session(daysAgo: 0, sets: [(60, 5)], endedAt: night)
        let weeks = stats.habit(.threeMonths, now: monday, calendar: london).weeks
        let previous = weeks[weeks.count - 2]
        #expect(previous.sessions == 1 && previous.days == [0, 0, 0, 0, 0, 1, 0])
        #expect(weeks.last?.sessions == 0)
        #expect(weeks.map(\.start).sorted() == weeks.map(\.start))
    }

    /// 18
    @Test(.timeLimit(.minutes(5))) func fiveYearsOfHistoryAnswersEachCallQuickly() throws {
        for week in 0 ..< 260 {
            for day in 0 ..< 3 {
                try session(
                    daysAgo: Double(week * 7 + day + 1),
                    sets: Array(repeating: (60 + Double(week % 20), 5), count: 3)
                )
            }
        }
        func millis(_ body: () throws -> Void) rethrows -> Double {
            let clock = ContinuousClock()
            let took = try clock.measure(body)
            return Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15
        }
        _ = stats.bestInRange(.year, now: now, calendar: calendar) // builds the index once
        #expect(millis { _ = stats.bestInRange(.year, now: now, calendar: calendar) } < 150)
        #expect(millis { _ = stats.strengthLines(.year, now: now, calendar: calendar) } < 150)
        #expect(millis { _ = stats.volume(.year, now: now, calendar: calendar) } < 150)
        #expect(millis { _ = stats.habit(.year, now: now, calendar: calendar) } < 150)
        #expect(millis { _ = stats.balance(.year, now: now, calendar: calendar) } < 150)
        #expect(millis { _ = stats.logMonths(now: now, calendar: calendar) } < 150)
    }

    @Test func landingFactsWithNoPlanNameNoRoutine() {
        let facts = stats.landingFacts(plan: nil, now: now, calendar: calendar)
        #expect(facts.routine == nil && facts.minutes == nil && facts.opener == nil && !facts.isPrivate)
        #expect(facts.marks.count == 7)
    }

    @Test func usualMinutesIsTheMedianOfTheLastThreeToFive() throws {
        let routine = try store.create(#require(classes[.routine]), title: "Push A")
        for (days, minutes) in [(9.0, 44.0), (6.0, 48.0), (3.0, 52.0)] {
            let workout = try session(daysAgo: days, sets: [(60, 5), (60, 5)], minutes: minutes)
            try store.setLinks("routine", on: workout, to: [routine])
        }
        #expect(stats.usualMinutes(of: routine) == 50)
        let other = try store.create(#require(classes[.routine]), title: "Pull A")
        #expect(stats.usualMinutes(of: other) == nil)
    }

    @Test func aLogRowCarriesItsWorkoutIdEvenWhenPrivate() throws {
        let plain = try session(daysAgo: 3, sets: [(60, 5)])
        let secret = try session(daysAgo: 2, sets: [(60, 5)], title: "Knee rehab day")
        let rows = stats.logMonths(now: now, calendar: calendar).flatMap(\.rows)
        #expect(Set(rows.map(\.workout)) == [plain.id, secret.id])
        #expect(rows.first { $0.workout == secret.id }?.title == "Private workout")
    }

    @Test func nothingHereReachesClaude() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        for file in try FileManager.default.contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            where file.pathExtension == "swift"
        {
            let text = try String(contentsOf: file, encoding: .utf8)
            for name in ["TrainingStats", "TrainingSentences", "StatsMass"] {
                #expect(!text.contains(name), "\(file.lastPathComponent) mentions \(name)")
            }
        }
    }
}
