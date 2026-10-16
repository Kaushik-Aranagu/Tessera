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

    init() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        self.classes = classes
        self.engine = engine
        engine.zone = { Self.la }
        memory = TessMemoryStore(engine: engine, calendar: Self.calendar)
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
        #expect(TessMemoryScreen.refusal(for: "Shops at Whole Foods") == .money("whole foods"))
        #expect(TessMemoryScreen.refusal(for: "Trains 4 days a week") == .unlicensedNumber(4))
        #expect(TessMemoryScreen.refusal(for: "Trains 4 days a week", numbers: [4]) == nil)
        #expect(TessMemoryScreen.refusal(for: "key sk-ant-abc") == .looksLikeKey)
        #expect(TessMemoryScreen.refusal(for: String(repeating: "a", count: 81)) == .tooLong)
        #expect(TessMemoryScreen.refusal(for: "   ") == .empty)
    }

    // MARK: Told

    @Test func rememberForgetAndUndo() throws {
        let kept = try run(RememberFact(text: "I train after work on weekdays"), at: Self.at(9))
        #expect(kept.record.summary == "Kept. You train after work on weekdays.")
        let line = try #require(memory.lines(of: .told).first)
        #expect(line.area == .training && !line.isPrivate && line.evidence.isEmpty)
        #expect(line.sourceLine(now: Self.at(9)) == "you said so today")
        #expect(line.sourceLine(now: Self.at(16)) == "you said so on Oct 9")
        memory.markUsed([line.id], at: Self.at(16))
        #expect(memory.lines(of: .told).first?.sourceLine(now: Self.at(16)) == "you said so on Oct 9, used today")
        #expect(memory.countLine() == "1 thing. 1 you told me, 0 I noticed." && memory.countWord() == "1 thing")

        // A body fact is his to keep, but private; a health value is refused.
        try run(RememberFact(text: "my left shoulder gets sore on overhead pressing"), at: Self.at(10))
        let shoulder = try #require(memory.lines(of: .told).first { $0.text.contains("shoulder") })
        #expect(shoulder.isPrivate && shoulder.sourceLine(now: Self.at(10)).hasSuffix("stays on this phone"))
        #expect(throws: ActionError.self) { try engine.perform(RememberFact(text: "slept 6 hours"), by: .user) }
        #expect(throws: ActionError.self) { try engine.perform(RememberFact(text: "rent is $2000"), by: .user) }
        try run(RememberFact(text: "mom means Lakshmi"), at: Self.at(11))
        #expect(memory.grouped().map(\.area) == [.training, .people, .other]
            || memory.grouped().map(\.area) == [.training, .people])

        let forgot = try run(ForgetMemory(memory: line.id), at: Self.at(12))
        #expect(forgot.record.summary == "I train after, forgotten.")
        #expect(memory.lines(of: .told).count == 2)
        engine.undo(forgot.record)
        #expect(memory.lines(of: .told).count == 3)
        // After the UNDO window the words leave history for good.
        try run(ForgetMemory(memory: line.id), at: Self.at(12))
        memory.redact(line.id)
        #expect(memory.lines(of: .told).count == 2)
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
        #expect(all.output == 2 && memory.all().isEmpty && memory.countLine() == "Nothing yet.")
        engine.undo(all.record)
        #expect(memory.all().count == 2)
    }

    // MARK: The pack

    @Test func thePackNeverCarriesPrivateLinesAndKeepsItsBudget() throws {
        try run(RememberFact(text: "I train after work"), at: Self.at(9))
        try run(RememberFact(text: "my knee hates deep squats", isPrivate: true), at: Self.at(9))
        for index in 0 ..< 60 {
            try run(RememberFact(text: "Fact number \(index) about nothing much at all, said so", area: .other),
                    at: Self.at(9))
        }
        let pack = memory.pack(.init(told: true))
        #expect(!pack.contains { $0.isPrivate })
        #expect(pack.reduce(0) { $0 + $1.text.count + 1 } <= TessMemoryStore.packBudget)
        #expect(memory.pack(.init(noticed: true)).isEmpty)
    }

    // MARK: The turnover

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
        #expect(turnover.wroteRecent && turnover.recomputedNoticed && turnover.dropped == nil)
        let recent = memory.lines(of: .recent)
        #expect(recent.count == 1 && recent.first?.text.hasPrefix("Thu: Push A done") == true)
        let noticed = memory.lines(of: .noticed).map(\.text)
        #expect(noticed.contains("Usually trains 6 pm to 8 pm."), "\(noticed)")
        #expect(noticed.contains { $0.hasPrefix("Trains about ") && $0.hasSuffix(" days a week.") }, "\(noticed)")
        #expect(noticed.contains("Cooks most on Sundays."), "\(noticed)")
        let training = try #require(memory.lines(of: .noticed).first { $0.text.hasPrefix("Usually") })
        #expect(training.evidence.count >= 8 && training
            .sourceLine(now: now) == "from \(training.evidence.count) workouts")
        // Every noticed line's digits are licensed by what it counted.
        for line in memory.lines(of: .noticed) {
            #expect(TessMemoryScreen.refusal(for: line.text, numbers: Set(HomeLines.digits(in: line.text))) == nil)
        }
        // Running it again the same day writes nothing new.
        memory.turnover(now: now.addingTimeInterval(3600))
        #expect(memory.lines(of: .recent).count == 1)

        // Old day lines fold into a week line kept 8 weeks.
        memory.write(kind: .recent, area: .days, text: "Tue: Pull A done, 2 tasks.", evidence: [],
                     day: Self.at(22, 0, month: 9))
        memory.write(
            kind: .recent,
            area: .days,
            text: "Thu: cooked chili.",
            evidence: [],
            day: Self.at(24, 0, month: 9)
        )
        memory.turnover(now: Self.at(17, 5))
        let week = try #require(memory.lines(of: .recent).first { $0.text.hasPrefix("Week of ") })
        #expect(week.text == "Week of Sep 21: trained 1 day, cooked once.")
        #expect(!memory.lines(of: .recent).contains { $0.text.hasPrefix("Tue:") })
        // The 14-day group on the page comes newest first.
        #expect(memory.grouped().last?.area == .days && memory.grouped().last?.lines.first?.text
            .hasPrefix("Fri:") == true
            || memory.grouped().last?.lines.first?.text.hasPrefix("Thu:") == true)
    }

    @Test func theFortiethToldLineDropsTheOldestUnusedOne() throws {
        for index in 0 ..< 41 {
            try run(RememberFact(text: "Thing \(index) he said", area: .other),
                    at: Self.at(1, 9, month: 6).addingTimeInterval(Double(index)))
        }
        try memory.markUsed([#require(memory.lines(of: .told).first?.id)], at: Self.at(15))
        let turnover = memory.turnover(now: Self.at(16, 5))
        #expect(turnover.dropped == "Thing 1 he said" && memory.lines(of: .told).count == 40)
        // Over the cap again: the next oldest unused goes; one said within 90 days never does.
        try run(RememberFact(text: "Thing 41 he said", area: .other), at: Self.at(15))
        #expect(memory.turnover(now: Self.at(16, 6)).dropped == "Thing 2 he said")
        #expect(memory.lines(of: .told).count == 40)
        try run(RememberFact(text: "Thing 42 he said", area: .other), at: Self.at(15))
        for line in memory.lines(of: .told) {
            memory.markUsed([line.id], at: Self.at(15))
        }
        #expect(memory.turnover(now: Self.at(16, 7)).dropped == nil && memory.lines(of: .told).count == 41)
    }

    @Test func secondPersonAndTheThing() {
        #expect(TessMemoryStore.secondPerson("I rest on Sundays") == "You rest on Sundays.")
        #expect(TessMemoryStore.secondPerson("my mom's name is Lakshmi") == "Your mom's name is Lakshmi.")
        #expect(TessMemoryStore.thing(of: "Left shoulder gets sore on overhead pressing") == "Left shoulder gets")
        #expect(TessMemoryStore.guessArea("cook tacos on Tuesdays") == .kitchen)
    }
}
