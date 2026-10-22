import Foundation
@testable import TesseraCore
import Testing

/// Tess's memory (architecture section 4, Design 49): told, noticed and recent lines as objects; the screen; the pack;
/// forgetting with redaction; the 04:00 turnover.
@MainActor
struct TessMemoryTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    static func at(_ day: Int, _ hour: Int = 12, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let memory: TessMemoryStore
    let forgetLog: URL

    init() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        self.classes = classes
        self.engine = engine
        engine.zone = { Self.la }
        forgetLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("tess-forgotten-\(UUID().uuidString).json")
        memory = TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: forgetLog,
                                 fileProtection: [])
    }

    @discardableResult
    func run<A: EngineAction>(_ action: A, at time: Date) throws -> ActionEngine.Result<A.Output> {
        let result = try engine.perform(action, by: .user)
        result.record.createdAt = time
        if let object = result.output as? ObjectRecord {
            object.createdAt = time
        }
        return result
    }

    func train(at time: Date) throws {
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try run(StartRoutine(routine: routine.id, time: time), at: time).output
        let entry = try #require(workout.orderedChildren.first)
        try run(LogSet(entry: entry.id, weight: 60, reps: 5, time: time), at: time)
        try run(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(2400)), at: time)
    }

    // MARK: The screen

    @Test func theScreenRefusesHealthMoneyAndLooseNumbers() {
        #expect(TessMemoryScreen.refusal(for: "Trains after work on weekdays.") == nil)
        #expect(TessMemoryScreen.refusal(for: "Slept 6 hours") == .health("slept"))
        #expect(TessMemoryScreen.refusal(for: "Weighed 82 kg") == .health("weighed"))
        #expect(TessMemoryScreen.refusal(for: "Spent $40 at Costco") == .money("spent"))
        #expect(TessMemoryScreen.refusal(for: "Shops at Whole Foods") == .place("whole foods"))
        #expect(TessMemoryScreen.refusal(for: "Trains 4 days a week") == .unlicensedNumber(4))
        #expect(TessMemoryScreen.refusal(for: "Trains 4 days a week", numbers: [4]) == nil)
        #expect(TessMemoryScreen.refusal(for: "key sk-ant-abc") == .looksLikeKey)
        #expect(TessMemoryScreen.refusal(for: String(repeating: "a", count: 81)) == .tooLong)
        #expect(TessMemoryScreen.refusal(for: "   ") == .empty)
        #expect(TessMemoryScreen.refusal(for: "Lives at 12 Oak Street", numbers: [12]) == .place("street"))
        #expect(TessMemoryScreen.Refusal.money("").line == "I don't keep sums of money.")
        #expect(TessMemoryScreen.Refusal.place("").line == "I don't keep places.")
    }

    // MARK: Told

    @Test func rememberForgetAndUndo() throws {
        let kept = try run(RememberFact(text: "I train after work on weekdays"), at: Self.at(9))
        #expect(kept.record.summary == "Kept. You train after work on weekdays.")
        let line = try #require(memory.lines(of: .told).first)
        #expect(line.text == "You train after work on weekdays." && line.area == .training && !line.isPrivate)
        #expect(line.sourceLine(now: Self.at(9)) == "you said so today")
        #expect(line.sourceLine(now: Self.at(16)) == "you said so on Oct 9")
        memory.markUsed([line.id], at: Self.at(16))
        #expect(memory.lines(of: .told).first?.sourceLine(now: Self.at(16)) == "you said so on Oct 9, used today")
        #expect(memory.countLine() == "1 thing. 1 you told me, 0 I noticed." && memory.countWord() == "1 thing")

        // A body fact is his to keep, but private; a health value is refused.
        try run(RememberFact(text: "my left shoulder gets sore on overhead pressing"), at: Self.at(10))
        let shoulder = try #require(memory.lines(of: .told).first { $0.text.contains("shoulder") })
        #expect(shoulder.isPrivate && shoulder.sourceLine(now: Self.at(10)).hasSuffix("stays on this phone"))
        // A health word keeps the line private; money and places are refused with Tess's line (addendum S6).
        let slept = try run(RememberFact(text: "slept badly before leg day"), at: Self.at(10))
        #expect(memory.lines(of: .told).last?.isPrivate == true)
        #expect(slept.record.summary == "Kept, on this phone only.")
        let money = #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "rent is $2000"), by: .user)
        }
        #expect(money.flatMap(RememberFact.refusalLine) == "I don't keep sums of money.")
        let place = #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "I live at 12 Oak Street"), by: .user)
        }
        #expect(place.flatMap(RememberFact.refusalLine) == "I don't keep places.")
        try run(RememberFact(text: "mom means Lakshmi"), at: Self.at(11))
        try run(RememberFact(text: "I like the window seat"), at: Self.at(11))
        #expect(memory.grouped().map(\.area) == [.training, .people, .about])

        let forgot = try run(ForgetMemory(memory: line.id), at: Self.at(12))
        #expect(forgot.record.summary == "Train after, forgotten.")
        #expect(memory.lines(of: .told).count == 4)
        engine.undo(forgot.record)
        #expect(memory.lines(of: .told).count == 5)
        // After the UNDO window the words leave history for good.
        try run(ForgetMemory(memory: line.id), at: Self.at(12))
        memory.redact(line.id, now: Self.at(12))
        #expect(memory.lines(of: .told).count == 4)
        let history = store.context.operations.values
        #expect(!history.contains { $0.ops.contains { op in
            if case let .create(_, _, _, title) = op {
                title.contains("after work")
            } else {
                false
            }
        } })
        #expect(!history.contains { $0.summary.contains("after work") })
        #expect(store.object(id: line.id)?.title == TessMemoryStore.redacted)

        let all = try run(ForgetAllMemory(), at: Self.at(13))
        #expect(all.output == 4 && memory.all().isEmpty && memory.countLine() == "Nothing kept yet.")
        #expect(all.record.summary == "Everything forgotten, 4 things.")
        engine.undo(all.record)
        #expect(memory.all().count == 4)
    }

    // MARK: The pack

    @Test func thePackNeverCarriesPrivateLinesAndKeepsItsBudget() throws {
        try run(RememberFact(text: "I train after work"), at: Self.at(9))
        try run(RememberFact(text: "my knee hates deep squats", isPrivate: true), at: Self.at(9))
        for index in 0 ..< 38 {
            try run(RememberFact(text: "Fact number \(index) about nothing much at all, said so", area: .about),
                    at: Self.at(9))
        }
        let pack = memory.pack(.init(told: true))
        #expect(!pack.contains { $0.isPrivate })
        #expect(pack.reduce(0) { $0 + $1.text.count + 1 } <= TessMemoryStore.packBudget)
        #expect(memory.pack(.init(noticed: true)).isEmpty)
    }

    // MARK: The turnover

    @Test func twoWeeksAcrossTheFallBackNightAreTwo() throws {
        // Research dst-nov-1 DS36 (board 0ag): Sun Oct 18 to Sun Nov 1 is 14 of his days, 2 weeks, so 12 sessions
        // read "about 6 days a week" (seconds said 2.006 weeks, rounded up to 3, "about 4").
        var day = Self.at(18, 18)
        var sessions = 0
        while sessions < 12 {
            if Self.calendar.component(.weekday, from: day) != 7 {
                try train(at: day)
                sessions += 1
            }
            day = try #require(Self.calendar.date(byAdding: .day, value: 1, to: day))
        }
        _ = memory.turnover(now: Self.at(1, 19, month: 11))
        let noticed = memory.lines(of: .noticed).map(\.text)
        #expect(noticed.contains("You train about 6 days a week."), "\(noticed)")
    }

    @Test func theTurnoverWritesYesterdayFoldsOldDaysAndNoticesTraining() throws {
        // Six weeks of evening training, Mondays and Thursdays, and Sunday cooks.
        for week in 0 ..< 6 {
            try train(at: Self.at(31, 18, month: 8).addingTimeInterval(Double(week * 7) * 86400))
            try train(at: Self.at(3, 18, month: 9).addingTimeInterval(Double(week * 7) * 86400))
        }
        let recipe = try run(CreateRecipe(text: RecipeParserTests.carbonara), at: Self.at(1, 9, month: 9)).output
        for week in 0 ..< 4 {
            let sunday = Self.at(6, 18, month: 9).addingTimeInterval(Double(week * 7) * 86400)
            let cook = try run(StartCooking(recipe: recipe.id, time: sunday), at: sunday).output
            try run(FinishCooking(cook: cook.id, time: sunday.addingTimeInterval(1800)), at: sunday)
        }
        // Thursday 15 Oct 18:00 trained; the turnover runs Friday 04:30.
        try train(at: Self.at(15, 18))
        let now = Self.at(16, 4).addingTimeInterval(1800)
        let turnover = memory.turnover(now: now)
        #expect(turnover.wroteRecent && turnover.recomputedNoticed)
        let recent = memory.lines(of: .recent)
        #expect(recent.count == 1 && recent.first?.text.hasPrefix("Thu: Push A done") == true)
        let noticed = memory.lines(of: .noticed).map(\.text)
        #expect(noticed.contains("You usually train 6 pm to 8 pm."), "\(noticed)")
        #expect(noticed.contains { $0.hasPrefix("You train about ") && $0.hasSuffix(" days a week.") }, "\(noticed)")
        #expect(noticed.contains("You cook most on Sundays."), "\(noticed)")
        let training = try #require(memory.lines(of: .noticed).first { $0.text.hasPrefix("You usually") })
        #expect(training.evidence.count >= 8 && training
            .sourceLine(now: now) == "from \(training.evidence.count) workouts")
        // Every noticed line's digits are licensed by what it counted.
        for line in memory.lines(of: .noticed) {
            #expect(TessMemoryScreen.refusal(for: line.text, numbers: Set(HomeLines.digits(in: line.text))) == nil)
        }
        // Running it again the same day writes nothing new.
        memory.turnover(now: now.addingTimeInterval(3600))
        #expect(memory.lines(of: .recent).count == 1)

        // Old day lines go after 14 days; no week line is stored (the week is counted live).
        memory.write(kind: .recent, area: .days, text: "Tue: Pull A done, 2 tasks.", evidence: [],
                     day: Self.at(22, 0, month: 9))
        memory.turnover(now: Self.at(17, 5))
        #expect(!memory.lines(of: .recent).contains { $0.text.hasPrefix("Tue:") || $0.text.hasPrefix("Week of") })
        #expect(memory.grouped().last?.area == .days)
    }

    @Test func atTheCapNothingIsWritten() throws {
        // Addendum S7: 40 told lines; the 41st is refused with Tess's line, nothing drops on its own.
        for index in 0 ..< 40 {
            try run(RememberFact(text: "Thing \(index) he said", area: .about), at: Self.at(1, 9, month: 6))
        }
        let error = #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "Thing 40 he said"), by: .user)
        }
        #expect(error.flatMap(RememberFact.refusalLine) == "I keep 40 things. Forget one and say it again.")
        memory.turnover(now: Self.at(16, 5))
        #expect(memory.lines(of: .told).count == 40)
        try run(ForgetMemory(memory: #require(memory.lines(of: .told).first).id), at: Self.at(16, 9))
        try run(RememberFact(text: "Thing 40 he said"), at: Self.at(16, 9))
        #expect(memory.lines(of: .told).count == 40)
    }

    @Test func forgottenLinesStayForgotten() throws {
        // Research F1: a forgotten noticed line never comes back at the Sunday recompute; forget-everything holds.
        for week in 0 ..< 6 {
            try train(at: Self.at(31, 18, month: 8).addingTimeInterval(Double(week * 7) * 86400))
            try train(at: Self.at(3, 18, month: 9).addingTimeInterval(Double(week * 7) * 86400))
        }
        memory.turnover(now: Self.at(11, 5)) // a Sunday
        let hours = try #require(memory.lines(of: .noticed).first { $0.text.hasPrefix("You usually") })
        try run(ForgetMemory(memory: hours.id), at: Self.at(11, 9))
        memory.redact(hours.id, now: Self.at(11, 9))
        memory.turnover(now: Self.at(18, 5)) // next Sunday
        #expect(!memory.lines(of: .noticed).contains { $0.text.hasPrefix("You usually") })
        #expect(memory.lines(of: .noticed).contains { $0.text.hasPrefix("You train about") })
        // Forget everything, quit inside the UNDO window: the next turnover sweeps the words and nothing returns, not
        // on the Monday with no noticed lines, not on the Sunday after.
        try run(ForgetAllMemory(), at: Self.at(18, 9))
        memory.turnover(now: Self.at(19, 5))
        memory.turnover(now: Self.at(25, 5))
        #expect(memory.lines(of: .noticed).isEmpty && memory.all().isEmpty)
        let memoryObjects = try store.objects(of: #require(classes[.tessMemory]))
        #expect(memoryObjects.filter(\.isDeleted).allSatisfy { $0.title == TessMemoryStore.redacted })
        #expect(!store.context.operations.values.contains { $0.summary.contains("usually train") })

        // Research F2: words he forgot come back from a restore, and the forget log takes them again.
        try run(RememberFact(text: "I train after work"), at: Self.at(20))
        let told = try #require(memory.lines(of: .told).first)
        try run(ForgetMemory(memory: told.id), at: Self.at(20, 13))
        memory.redact(told.id, now: Self.at(20, 13))
        let memoryClass = try #require(classes[.tessMemory])
        let restored = store.create(memoryClass, title: "You train after work.")
        try store.set("kind", to: .choice("told"), on: restored)
        restored.createdAt = Self.at(1) // written before the forget, as a restored backup's line would be
        #expect(memory.lines(of: .told).count == 1)
        #expect(memory.reapplyForgets() == 1 && memory.lines(of: .told).isEmpty)
        #expect(restored.title == TessMemoryStore.redacted)
        // Forgotten hashes never show on the page or in a pack.
        #expect(memory.grouped().isEmpty && memory.pack(.init(told: true, noticed: true, recent: true)).isEmpty)

        // QA F2b: a backup from before the forget is a whole other store; the log outside it still catches the words.
        let older = ObjectStore.open(inMemory: true)
        let olderClasses = try older.prepareCatalog()
        let olderEngine = ActionEngine(store: older, classes: olderClasses)
        try olderEngine.perform(RememberFact(text: "I train after work"), by: .user)
        let olderMemory = TessMemoryStore(engine: olderEngine, calendar: Self.calendar, forgetLogURL: forgetLog,
                                          fileProtection: [])
        // The restored line was written before the forget (an old backup), so the log catches it.
        olderMemory.lines(of: .told).first.flatMap { older.object(id: $0.id) }?.createdAt = Self.at(1)
        #expect(olderMemory.lines(of: .told).count == 1)
        #expect(olderMemory.reapplyForgets() == 1 && olderMemory.lines(of: .told).isEmpty)
        #expect(FileManager.default.fileExists(atPath: forgetLog.path))
        #expect(try !String(contentsOf: forgetLog, encoding: .utf8).contains("train"))

        // QA F6: forget, say it again, foreground: kept. Saying it again is his consent.
        try run(RememberFact(text: "I train after work"), at: Self.at(21))
        #expect(memory.lines(of: .told).count == 1)
        #expect(memory.reapplyForgets() == 0 && memory.lines(of: .told).count == 1)
        memory.turnover(now: Self.at(22, 5))
        #expect(memory.lines(of: .told).count == 1)
        // Only the first launch after a restore re-applies, and only once (no restore marker on an in-memory store).
        #expect(memory.reapplyForgetsIfRestored(now: Self.at(22, 6)) == 0)
    }

    @Test func aPrivateLineIsKeptAsSaid() throws {
        // Research F3, QA F3: a health word keeps the line private; a measured value is never kept, private or not;
        // body words match whole words, and only with a sore word.
        try run(RememberFact(text: "I sleep badly before leg day"), at: Self.at(9))
        #expect(memory.lines(of: .told).first?.isPrivate == true)
        #expect(memory.pack(.init(told: true)).isEmpty)
        #expect(throws: ActionError.self) { try engine.perform(RememberFact(text: "I weighed 82 kg"), by: .user) }
        #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "I weigh 82 kg and my back hurts", isPrivate: true), by: .user)
        }
        try run(RememberFact(text: "I'm back from work by 6"), at: Self.at(9))
        #expect(memory.lines(of: .told).first { $0.text.contains("from work") }?.isPrivate == false)
        try run(RememberFact(text: "my back hurts after deadlifts"), at: Self.at(9))
        #expect(memory.lines(of: .told).first { $0.text.contains("back hurts") }?.isPrivate == true)
        // QA F5: a body word alone is private ("my left knee clicks on squats"); S8: a health word with a number is a
        // measured value, refused.
        try run(RememberFact(text: "my left knee clicks on squats"), at: Self.at(9))
        #expect(memory.lines(of: .told).first { $0.text.contains("knee clicks") }?.isPrivate == true)
        #expect(throws: ActionError.self) {
            try engine.perform(RememberFact(text: "my resting heart rate is 52"), by: .user)
        }
        // A number far from the health word is not a measurement: kept, private.
        try run(RememberFact(text: "my knee hurts after 3 sets of heavy squats on leg day"), at: Self.at(9))
        #expect(memory.lines(of: .told).first { $0.text.contains("3 sets") }?.isPrivate == true)
    }

    @Test func secondPersonAndTheThing() {
        #expect(TessMemoryStore.secondPerson("I rest on Sundays") == "You rest on Sundays.")
        #expect(TessMemoryStore.secondPerson("my mom's name is Lakshmi") == "Your mom's name is Lakshmi.")
        #expect(TessMemoryStore.thing(of: "Left shoulder gets sore on overhead pressing") == "Left shoulder")
        #expect(TessMemoryStore.guessArea("I rest on Sundays") == .training)
        #expect(TessMemoryStore.guessArea("espresso after sunset in any weather") == .about)
        #expect(TessMemoryScreen.refusal(for: "my chili has 7 steps", numbers: [7]) == nil)
        #expect(TessMemoryScreen.refusal(for: "shops at Trader Joe's") == .place("trader"))
        #expect(TessMemoryScreen.refusal(for: "call mom back on Sundays") == nil)
        #expect(TessMemoryStore.guessArea("cook tacos on Tuesdays") == .kitchen)
        #expect(TessMemoryStore.guessArea("likes the window seat") == .about)
    }

    @Test func forgetReceiptKeepsTheWholeThing() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let made = try engine.perform(RememberFact(text: "You rest on Sundays"), by: .user)
        let forgot = try engine.perform(ForgetMemory(memory: made.output.id), by: .user)
        #expect(forgot.record.summary == "Rest on Sundays, forgotten.", "\(forgot.record.summary)")
        #expect(TessMemoryStore.receiptThing(of: "Left shoulder is sore") == "Left shoulder")
    }
}
