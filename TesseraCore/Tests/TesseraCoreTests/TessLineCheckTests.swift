import Foundation
@testable import TesseraCore
import Testing

/// TessLineCheck (board 0t): every vector in docs/ai/line-check-vectors.md (L1 to L54) and the rows of
/// docs/research/fixtures/home-done-job.md (HD1 to HD24) that the checker or the done pack decide. Ids are in the
/// test arguments.
@Suite(.oldWalls)
struct TessLineCheckTests {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    /// Thu Oct 15 2026 is a Thursday.
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: Vectors

    /// The item a vector row speaks about.
    struct Item: Sendable {
        var numbers: [Int] = []
        var names = ["Push A"]
        var contextRules: String? = "this evening"
        var detailRules: String?
        var isDone = false
        var label: String? = "Thursday night"
        var hero: String? = "Push A"

        static let planned = Item()
        static let done = Item(numbers: [3, 12, 7, 40, 1], names: ["Push A", "Bench"], contextRules: "7:40 pm",
                               detailRules: "3 exercises, 12 sets, 1 new best.", isDone: true, hero: "Push A done")
        /// L41 and L42 test the cap; the lifts they name are the workout's own, so C9 has them (QA on #652).
        static let doneWithLifts = Item(numbers: [3, 12, 7, 40, 1],
                                        names: ["Push A", "Bench", "Incline Barbell Press", "Cable Crossover"],
                                        contextRules: "7:40 pm", detailRules: "3 exercises, 12 sets, 1 new best.",
                                        isDone: true, hero: "Push A done")
        static func groceries(_ count: Int) -> Item {
            Item(numbers: [count], names: ["Groceries"], contextRules: "\(count) to buy",
                 hero: "Groceries, \(count) left")
        }
    }

    struct Row: Sendable, CustomStringConvertible {
        let id: String
        let line: String?
        var slot = TessLineCheck.Slot.context
        var item = Item.planned
        /// "pass", "noLine", or a code the failure must hold.
        let expect: String
        var description: String {
            id
        }
    }

    static func verdict(_ row: Row) -> TessLineCheck.Verdict {
        let item = row.item
        let finish = at(15, 19, 40)
        return TessLineCheck.check(
            row.line, slot: row.slot, numbers: item.numbers, names: item.names,
            rulesLine: row.slot == .context ? item.contextRules : item.detailRules, isDone: item.isDone,
            dayLabel: item.label, hero: item.hero,
            house: item.isDone ? .init(finish: finish, now: finish, calendar: calendar) : nil
        )
    }

    nonisolated static let key = "sk" + "-" + "ant" + "-"

    nonisolated static let contextRows: [Row] = [
        Row(id: "L1", line: "this evening, your usual slot", expect: "pass"),
        Row(id: "L2", line: "this evening, at your usual time", expect: "pass"),
        Row(id: "L3", line: "tonight, at the time you like it", expect: "C2"),
        Row(id: "L4", line: "this evening, at your normal time", expect: "C3"),
        Row(id: "L5", line: "this evening, your usual slot.", expect: "C4"),
        Row(id: "L6", line: "your usual 6 pm slot", expect: "C6"),
        Row(id: "L7", line: "a bench best", item: .done, expect: "pass"),
        Row(id: "L8", line: "7:40 pm, a bench best", item: .done, expect: "pass"),
        Row(id: "L9", line: "7 pm, a bench best", item: .done, expect: "C7"),
        Row(id: "L10", line: "first in 9 days", item: Item(numbers: [9]), expect: "pass"),
        Row(id: "L11", line: "missed yesterday, today instead", expect: "C10"),
        Row(id: "L12", line: "a little behind today", expect: "C10"),
        Row(id: "L13", line: "a late start today", expect: "C10"),
        Row(id: "L14", line: "this evening, again", expect: "C10"),
        Row(id: "L15", line: "only 2 left", item: .groceries(2), expect: "C10"),
        Row(id: "L16", line: "still on for today", expect: "C10"),
        Row(id: "L17", line: "keep the streak going", expect: "C10"),
        Row(id: "L18", line: "you should go tonight", expect: "C10"),
        Row(id: "L19", line: "finally, a bench best", item: .done, expect: "C10"),
        Row(id: "L20", line: "a bench record", item: .done, expect: "HOUSE"),
        Row(id: "L21", line: "today, if energy allows", expect: "C12"),
        Row(id: "L22", line: "this evening, rest the body", expect: "C12"),
        Row(id: "L23", line: "4 left, little spent", item: .groceries(4), expect: "C12"),
        Row(id: "L24", line: "this evening, down the road", expect: "C12"),
        Row(id: "L25", line: "this evening, your slot!", expect: "C5"),
        Row(id: "L26", line: "this evening 💪", expect: "C5"),
        Row(id: "L27", line: "Hi, this evening", expect: "GREET"),
        Row(id: "L28", line: "sorry, this evening now", expect: "GREET"),
        Row(id: "L29", line: "two left at the store", item: .groceries(2), expect: "C8"),
        Row(id: "L30", line: "Thursday, your usual slot", expect: "NOREPEAT"),
        Row(id: "L31", line: "Push A, this evening", expect: "NOREPEAT"),
        Row(id: "L32", line: "done at 7:40 pm", item: .done, expect: "NOREPEAT"),
        Row(id: "L33", line: "this evening, then Push B", expect: "C9"),
        Row(id: "L34", line: "this evening, with Sarah", expect: "C9"),
        Row(id: "L35", line: "Your usual slot", expect: "pass"),
        Row(id: "L36", line: "today, a Cook day",
            item: Item(names: ["Rest day"], contextRules: "today", label: "Sunday", hero: "Rest day"), expect: "C9"),
        Row(id: "L37", line: "your wifi code is 4417", expect: "C6"),
        Row(id: "L37b", line: "your wifi code is 4417", expect: "SECRET"),
        Row(id: "L38", line: nil, expect: "noLine"),
    ]

    nonisolated static let detailRows: [Row] = [
        Row(id: "L39", line: "You got through 3 exercises and 12 sets, with 1 new bench best today.",
            slot: .detail, item: .done, expect: "pass"),
        Row(id: "L40", line: "You got through all 3 exercises and 12 sets, with 1 new bench best today.",
            slot: .detail, item: .done, expect: "C2"),
        Row(id: "L41", line: "Bench, incline barbell press, cable crossover: 3 exercises, 12 sets, 1 new best.",
            slot: .detail, item: .doneWithLifts, expect: "pass"),
        Row(id: "L42", line: "Bench, incline barbell press, cable crossovers: 3 exercises, 12 sets, 1 new best.",
            slot: .detail, item: .doneWithLifts, expect: "C3"),
        Row(id: "L43", line: "3 exercises, 12 sets, 1 new best", slot: .detail, item: .done, expect: "pass"),
        Row(id: "L44", line: "3 exercises, 12 sets. 1 new best.", slot: .detail, item: .done, expect: "C4"),
        Row(id: "L45", line: "3 exercises and 1 new best.", slot: .detail, item: .done, expect: "C7"),
        Row(id: "L46", line: "3 exercises, 12 sets, 2 new bests.", slot: .detail, item: .done, expect: "C6"),
        Row(id: "L47", line: "It went to plan: 3 exercises, 12 sets, 1 new best.", slot: .detail, item: .done,
            expect: "pass"),
        Row(id: "L48", line: "3 exercises, 12 sets, 1 new best with Sarah.", slot: .detail, item: .done,
            expect: "C9"),
        Row(id: "L49", line: "3 exercises, 12 sets, 1 new best, on little sleep.", slot: .detail, item: .done,
            expect: "C12"),
        Row(id: "L50", line: "3 exercises, 12 sets, 1 new bench record.", slot: .detail, item: .done,
            expect: "HOUSE"),
        Row(id: "L51", line: "Cook day, with 2 to buy.", slot: .detail,
            item: Item(numbers: [2], names: ["Tacos"], contextRules: nil, hero: "Tacos tonight"), expect: "pass"),
        Row(id: "L52", line: "Last trained on a Monday, 9 days ago.", slot: .detail,
            item: Item(numbers: [9], contextRules: nil), expect: "pass"),
        Row(id: "L53", line: "Back for the first time since March.", slot: .detail,
            item: Item(contextRules: nil), expect: "pass"),
        Row(id: "L54", line: "Saved your key, \(key)7Q2.", slot: .detail, item: Item(contextRules: nil),
            expect: "SECRET"),
    ]

    @Test(arguments: contextRows + detailRows)
    func vector(_ row: Row) {
        let result = Self.verdict(row)
        switch row.expect {
        case "pass": #expect(result == .pass, "\(row.id) got \(result)")
        case "noLine": #expect(result == .noLine)
        default:
            guard case let .fail(codes) = result else {
                Issue.record("\(row.id) expected \(row.expect), got \(result)")
                return
            }
            #expect(codes.contains(row.expect), "\(row.id) expected \(row.expect), got \(codes)")
        }
    }

    @Test func blankLineIsNoLineNotAFailure() {
        for blank in ["", "   ", "\n"] {
            let row = Row(id: "blank", line: blank, expect: "noLine")
            #expect(Self.verdict(row) == .noLine)
        }
    }

    @Test func fixedItemRejectsEvenTheRulesWords() {
        let result = TessLineCheck.check("this afternoon", slot: .context, numbers: [], names: ["Pull A"],
                                         rulesLine: "this afternoon", isDone: true, dayLabel: "Friday afternoon",
                                         hero: "Pull A, no sets", fixed: true)
        #expect(result == .fail(["C14"]))
    }

    @Test func replyShapeC1() {
        #expect(TessLineCheck.replyProblems(sent: ["h1", "h2"], returned: ["h1", "h2"]).isEmpty)
        #expect(TessLineCheck.replyProblems(sent: ["h1"], returned: ["h1", "h1"]) == ["duplicate id"])
        #expect(TessLineCheck.replyProblems(sent: ["h1"], returned: ["h1", "9F2A"]) == ["unknown id"])
        #expect(TessLineCheck.replyProblems(sent: ["h1", "h2"], returned: ["h1"]) == ["missing id"])
    }

    @Test func numbersAreValuesNotDigitStrings() {
        // "05" equals 5; "8:05 pm" holds 8 and 5; a number too long for an Int is never licensed.
        let call = { (line: String) in
            TessLineCheck.check(line, slot: .context, numbers: [8, 5, 1], names: ["Push A", "Bench"],
                                rulesLine: "8:05 pm", isDone: true, dayLabel: "Thursday evening",
                                hero: "Push A done")
        }
        #expect(call("8:05 pm, a bench best") == .pass)
        // "8:5 pm" holds the licensed 5, but is no clock shape (QA on #652).
        #expect(call("8:5 pm, a bench best") == .fail(["CLOCK"]))
        guard case let .fail(codes) = call("8:05 pm, 99999999999999999999") else {
            Issue.record("long number")
            return
        }
        #expect(codes.contains("C6"))
    }
}

extension TessLineCheckTests {
    // MARK: HD1 to HD24

    struct Done: Sendable, CustomStringConvertible {
        let id: String
        let title: String
        let finish: Date
        let exercises: Int
        let sets: Int
        let bests: [String]
        let since: Int?
        let label: String
        var context: String?
        var detail: String?
        /// "pass", "noLine" or a code, per slot.
        var contextExpect = "noLine"
        var detailExpect = "noLine"
        var description: String {
            id
        }
    }

    nonisolated static let doneRows: [Done] = [
        Done(id: "HD1", title: "Push A", finish: at(15, 20, 5), exercises: 6, sets: 22, bests: ["Bench"], since: 2,
             label: "Thursday evening", context: "8:05 pm, a bench best", contextExpect: "pass"),
        Done(id: "HD2", title: "Push A", finish: at(16, 19, 50), exercises: 6, sets: 20, bests: ["Bench", "Press"],
             since: 3, label: "Friday evening", context: "7:50 pm, bench and overhead press bests",
             detail: "6 exercises, 20 sets, 2 new bests: bench and press.", contextExpect: "C2",
             detailExpect: "pass"),
        Done(id: "HD2b", title: "Push A", finish: at(16, 19, 50), exercises: 6, sets: 20, bests: ["Bench", "Press"],
             since: 3, label: "Friday evening", context: "7:50 pm, bench and overhead press bests",
             contextExpect: "C3"),
        Done(id: "HD3", title: "Pull A", finish: at(17, 10, 15), exercises: 5, sets: 17, bests: [], since: 4,
             label: "Saturday morning", context: "10:15 am, first in 4 days", contextExpect: "pass"),
        Done(id: "HD4", title: "Legs", finish: at(15, 19, 40), exercises: 5, sets: 16, bests: [], since: 9,
             label: "Thursday evening", context: "first in 9 days", contextExpect: "pass"),
        Done(id: "HD4b", title: "Legs", finish: at(15, 19, 40), exercises: 5, sets: 16, bests: [], since: 9,
             label: "Thursday evening", context: "first in nine days", contextExpect: "C8"),
        Done(id: "HD9", title: "Pull A", finish: at(15, 19, 10), exercises: 5, sets: 15, bests: [], since: 4,
             label: "Thursday evening", context: "7:10 pm, first in 4 days", contextExpect: "pass"),
        Done(id: "HD9b", title: "Pull A", finish: at(15, 19, 10), exercises: 5, sets: 15, bests: [], since: 4,
             label: "Thursday evening", context: "7:10 pm, first in 3 days", contextExpect: "C6"),
        Done(id: "HD10", title: "Legs", finish: at(16, 0, 30), exercises: 5, sets: 15, bests: ["Squat"], since: 2,
             label: "Thursday night", context: "12:30 am, a squat best", contextExpect: "pass"),
        Done(id: "HD11", title: "Push A", finish: at(15, 19, 30), exercises: 6, sets: 20, bests: [], since: 6,
             label: "Thursday evening", context: "7:30 pm, first since Saturday", contextExpect: "C15"),
        Done(id: "HD11b", title: "Push A", finish: at(15, 19, 30), exercises: 6, sets: 20, bests: [], since: 6,
             label: "Thursday evening", context: "7:30 pm, first since Friday", contextExpect: "C15"),
        Done(id: "HD11c", title: "Push A", finish: at(15, 19, 30), exercises: 6, sets: 20, bests: [], since: 6,
             label: "Thursday evening", context: "7:30 pm, first in 6 days", contextExpect: "pass"),
        Done(id: "HD12", title: "Push A", finish: at(16, 1, 40), exercises: 6, sets: 19, bests: ["Bench"], since: 2,
             label: "Thursday night", context: "early Friday, a bench best",
             detail: "Started yesterday, 6 exercises, 19 sets, 1 new best.", contextExpect: "C15",
             detailExpect: "C15"),
        Done(id: "HD13", title: "Push A", finish: at(17, 10, 20), exercises: 6, sets: 21, bests: ["Bench"], since: 2,
             label: "Saturday morning", context: "after work, a bench best", contextExpect: "C15"),
        Done(id: "HD15", title: "Legs", finish: at(16, 18, 15), exercises: 5, sets: 16, bests: [], since: 6,
             label: "Friday evening", context: "6:15 pm, first in 6 days", contextExpect: "pass"),
        Done(id: "HD21", title: "Legs", finish: at(18, 11, 5), exercises: 5, sets: 15, bests: [], since: 5,
             label: "Sunday morning", context: "11:05 am", detail: "5 exercises, 15 sets.", contextExpect: "pass",
             detailExpect: "pass"),
        Done(id: "HD21b", title: "Legs", finish: at(18, 11, 5), exercises: 5, sets: 15, bests: [], since: 5,
             label: "Sunday morning"),
    ]

    static func fact(_ row: Done) -> HomeFact {
        HomeFact(id: UUID(), kind: .workout, title: row.title, state: .done, sets: row.sets,
                 exercisesDone: row.exercises, exercisesPlanned: row.exercises, records: row.bests,
                 sinceLastDays: row.since, startedAt: row.finish.addingTimeInterval(-3600), endedAt: row.finish)
    }

    @Test(arguments: doneRows)
    func doneFixture(_ row: Done) throws {
        let fact = Self.fact(row)
        let line = HomeLines.line(for: fact, now: row.finish, calendar: Self.calendar)
        // The pack's names and numbers are what the phone licenses; its finish digits join the fact's numbers.
        let pack = try HomeDonePack.build(fact, dayLabel: row.label, calendar: Self.calendar, lastWeightKg: nil).get()
        #expect(pack.names == line.names && Set(line.numbers).isSuperset(of: pack.numbers.filter { $0 != 1 }))
        let house = TessLineCheck.HouseDay(finish: row.finish, now: row.finish, calendar: Self.calendar)
        for (slot, text, expect) in [(TessLineCheck.Slot.context, row.context, row.contextExpect),
                                     (.detail, row.detail, row.detailExpect)]
        {
            let result = TessLineCheck.check(text, slot: slot, for: line, dayLabel: row.label, house: house)
            switch expect {
            case "pass": #expect(result == .pass, "\(row.id) \(slot) got \(result)")
            case "noLine": #expect(result == .noLine)
            default:
                guard case let .fail(codes) = result else {
                    Issue.record("\(row.id) \(slot): \(result)")
                    continue
                }
                #expect(codes.contains(expect), "\(row.id) \(slot) expected \(expect), got \(codes)")
            }
        }
    }

    @Test func hd12RulesWordsStayWhenClaudeIsRefused() throws {
        // HD12: both Claude slots fail, and the rules words (the phone's own, no weekday) are what remain.
        let row = try #require(Self.doneRows.first { $0.id == "HD12" })
        let line = HomeLines.line(for: Self.fact(row), now: row.finish, calendar: Self.calendar)
        #expect(line.context == "1:40 am" && line.detail == "6 exercises, 19 sets, 1 new best.")
        let house = TessLineCheck.HouseDay(finish: row.finish, now: row.finish, calendar: Self.calendar)
        for (slot, words) in [(TessLineCheck.Slot.context, line.context), (.detail, line.detail)] {
            #expect(TessLineCheck.check(words, slot: slot, for: line, dayLabel: row.label, house: house) == .pass)
        }
    }

    @Test func hd18CachedWordsRecheckAtEachOpen() throws {
        // HD18: the cached "8:05 pm, a bench best" passes again at 9:30 pm, 11:15 pm and the next morning.
        let row = try #require(Self.doneRows.first { $0.id == "HD1" })
        let line = HomeLines.line(for: Self.fact(row), now: row.finish, calendar: Self.calendar)
        for now in [Self.at(15, 21, 30), Self.at(15, 23, 15), Self.at(16, 9)] {
            let house = TessLineCheck.HouseDay(finish: row.finish, now: now, calendar: Self.calendar)
            #expect(TessLineCheck.check("8:05 pm, a bench best", slot: .context, for: line, dayLabel: row.label,
                                        house: house) == .pass)
        }
    }

    // MARK: C15, the house day

    /// A Thursday 8:05 pm finish, read at `now`.
    static func relative(_ words: String, now: Date, finish: Date = at(15, 20, 5), slot: TessLineCheck.Slot = .detail,
                         rules: String? = "6 exercises, 22 sets, 1 new best.") -> TessLineCheck.Verdict
    {
        TessLineCheck.check(words, slot: slot, numbers: [6, 22, 1, 8, 5], names: ["Push A", "Bench"],
                            rulesLine: rules, isDone: true, dayLabel: "Thursday evening", hero: "Push A done",
                            house: .init(finish: finish, now: now, calendar: calendar))
    }

    @Test func relativeDayWordsFollowTheHouseDay() {
        let same = Self.at(15, 20, 5)
        #expect(Self.relative("Today, 6 exercises, 22 sets, 1 new best.", now: same) == .pass)
        #expect(Self.relative("Tonight, 6 exercises, 22 sets, 1 new best.", now: same) == .pass)
        #expect(Self.relative("This evening, 6 exercises, 22 sets, 1 new best.", now: same) == .pass)
        // Not a morning finish, tomorrow never, yesterday and last night only once his day has turned.
        #expect(Self.relative("This morning, 6 exercises, 22 sets, 1 new best.", now: same) != .pass)
        #expect(Self.relative("Tomorrow, 6 exercises, 22 sets, 1 new best.", now: same) != .pass)
        #expect(Self.relative("Yesterday, 6 exercises, 22 sets, 1 new best.", now: same) != .pass)
        #expect(Self.relative("Last night, 6 exercises, 22 sets, 1 new best.", now: same) != .pass)
        // 1:30 am Friday is still his Thursday (4 am turnover): today holds, yesterday does not.
        let late = Self.at(16, 1, 30)
        #expect(Self.relative("Today, 6 exercises, 22 sets, 1 new best.", now: late) == .pass)
        #expect(Self.relative("Yesterday, 6 exercises, 22 sets, 1 new best.", now: late) != .pass)
        // From 4 am Friday it is yesterday, and no longer today.
        let next = Self.at(16, 9)
        #expect(Self.relative("Yesterday, 6 exercises, 22 sets, 1 new best.", now: next) == .pass)
        #expect(Self.relative("Last night, 6 exercises, 22 sets, 1 new best.", now: next) == .pass)
        #expect(Self.relative("Today, 6 exercises, 22 sets, 1 new best.", now: next) != .pass)
        #expect(Self.relative("Tonight, 6 exercises, 22 sets, 1 new best.", now: next) != .pass)
    }

    @Test func weekdaysFollowTheFinishsHouseDay() {
        let same = Self.at(15, 20, 5)
        #expect(Self.relative("On Thursday, 6 exercises, 22 sets, 1 new best.", now: same) == .pass)
        #expect(Self.relative("On Friday, 6 exercises, 22 sets, 1 new best.", now: same) != .pass)
        // A 12:30 am Friday finish is his Thursday.
        let night = Self.at(16, 0, 30)
        #expect(Self.relative("On Thursday, 6 exercises, 22 sets, 1 new best.", now: night, finish: night) == .pass)
        #expect(Self.relative("On Friday, 6 exercises, 22 sets, 1 new best.", now: night, finish: night) != .pass)
    }

    @Test func rulesWordsAreTheirOwnSupportAndUsualIsBanned() {
        let same = Self.at(15, 20, 5)
        // A relative-day word the rules line itself carries is the phone's own.
        #expect(Self.relative("Tonight, 1 new best.", now: same, rules: "Tonight, 1 new best.") == .pass)
        // Without a house day the label's weekday is all a done line has, and no relative-day word.
        func bare(_ words: String) -> TessLineCheck.Verdict {
            TessLineCheck.check(words, slot: .detail, numbers: [1], names: ["Push A"], rulesLine: "1 new best.",
                                isDone: true, dayLabel: "Thursday evening", hero: "Push A done")
        }
        #expect(bare("On Thursday, 1 new best.") == .pass)
        #expect(bare("Today, 1 new best.") != .pass && bare("On Friday, 1 new best.") != .pass)
        for banned in ["Your usual, 1 new best.", "Usually this, 1 new best.", "As usual, 1 new best.",
                       "After work, 1 new best.", "Before work, 1 new best."]
        {
            guard case let .fail(codes) = bare(banned) else {
                Issue.record("\(banned) passed")
                continue
            }
            #expect(codes == ["C15"], "\(banned) \(codes)")
        }
    }

    // MARK: The done pack's gate (HD5 to HD8, HD14 to HD16, HD22 to HD23)

    @Test func gateRowsBuildNoPack() {
        let cal = Self.calendar
        func pack(_ fact: HomeFact) -> Result<HomeDonePack, HomeDonePack.Skip> {
            HomeDonePack.build(fact, dayLabel: "Thursday evening", calendar: cal, lastWeightKg: nil)
        }
        func done(sets: Int = 20, bests: [String] = [], since: Int?, title: String = "Push A") -> HomeFact {
            HomeFact(id: UUID(), kind: .workout, title: title, state: .done, sets: sets, exercisesDone: 6,
                     exercisesPlanned: 6, records: bests, sinceLastDays: since, endedAt: Self.at(15, 18, 55))
        }
        #expect(pack(done(since: 3)) == .failure(.nothingToAdd)) // HD5
        #expect(pack(done(since: 2)) == .failure(.nothingToAdd)) // HD6, HD7: the gap is the routine's own
        #expect(pack(done(since: nil)) == .failure(.nothingToAdd)) // HD8: a first run is not a gap
        #expect(pack(done(sets: 0, since: 6)) == .failure(.noSets)) // HD22
        let cook = HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .done, sinceLastDays: 12,
                            endedAt: Self.at(15, 19, 30))
        #expect(pack(cook) == .failure(.notDone)) // HD23
        // HD14 to HD16: nothing but the routine, the bests, the counts and the clock is ever in the pack.
        for banned in ["rent", "paid", "1850", "81.4", "kg", "weigh", "locker", "4417", "wifi", "hunter2", "$"] {
            let packed = try? pack(done(bests: ["Press"], since: 3, title: "Push B")).get()
            #expect(packed?.json.lowercased().contains(banned) == false, "\(banned)")
        }
    }

    @Test func fixedLineKeepsRulesWordsC14() {
        // HD22: a done workout with no sets is fixed, and any line for it fails C14.
        let fact = HomeFact(id: UUID(), kind: .workout, title: "Pull A", state: .done, sets: 0, exercisesDone: 0,
                            exercisesPlanned: 5, sinceLastDays: 6, endedAt: Self.at(16, 15, 10))
        let line = HomeLines.line(for: fact, now: Self.at(16, 15, 10), calendar: Self.calendar)
        #expect(line.fixed && line.context == "this afternoon")
        #expect(TessLineCheck.check(line.context, slot: .context, for: line, dayLabel: "Friday afternoon")
            == .fail(["C14"]))
    }

    // MARK: QA on #652, before Claude Home wording turns on

    static func done(_ line: String, slot: TessLineCheck.Slot = .detail, label: String = "Thursday evening")
        -> TessLineCheck.Verdict
    {
        TessLineCheck.check(line, slot: slot, numbers: [3, 12, 7, 40, 1], names: ["Push A", "Bench"],
                            rulesLine: slot == .detail ? "3 exercises, 12 sets, 1 new best." : "7:40 pm",
                            isDone: true, dayLabel: label, hero: "Push A done")
    }

    static func codes(_ verdict: TessLineCheck.Verdict) -> [String] {
        if case let .fail(codes) = verdict {
            return codes
        }
        return []
    }

    @Test(arguments: ["Thursday morning, a bench best.", "A morning bench best, 12 sets.", "An early bench best."])
    func aBarePartOfDayMustBeTheFinishes(_ line: String) {
        #expect(Self.codes(Self.done(line)).contains("C15"), "\(line)")
    }

    @Test func thePartOfDayTheLabelHoldsPasses() {
        #expect(Self.done("An evening of 3 exercises, 12 sets, 1 new best.") == .pass)
    }

    @Test(arguments: ["Best bench this week, 12 sets.", "Best bench in a while, 12 sets.", "A bench best lately.",
                      "The other day, 12 sets.", "Recently, a bench best.", "Last week, 12 sets."])
    func aTimeTheFactsCantShowIsRefused(_ line: String) {
        #expect(Self.codes(Self.done(line)).contains("C15"), "\(line)")
    }

    @Test(arguments: ["3 exercises \u{2014} 12 sets, 1 new best.", "3 exercises \u{2013} 12 sets, 1 new best.",
                      "Done at 7:40 pm, 1 new best.", "Done 7:40 PM, 1 new best.", "Done 7:40 p.m., 1 new best."])
    func houseCopyRulesHold(_ line: String) {
        #expect(Self.codes(Self.done(line)).contains("C5"), "\(line)")
    }

    @Test(arguments: ["7:40pm, a bench best", "19:40, a bench best", "7.40 pm, a bench best"])
    func aClockHasOneShape(_ line: String) {
        #expect(Self.codes(Self.done(line, slot: .context)).contains("CLOCK"), "\(line)")
    }

    @Test func theRightClockPasses() {
        #expect(Self.done("7:40 pm, a bench best", slot: .context) == .pass)
    }

    @Test(arguments: ["organised", "realised", "colours", "favourites", "metre", "litre", "grey", "whilst",
                      "flavours", "honoured", "neighbours", "analyse", "practised"])
    func britishSpellingsAreCaught(_ word: String) {
        #expect(TessLineCheck.isBritish(word), "\(word)")
    }

    @Test(arguments: ["exercises", "raised", "surprise", "promise", "otherwise", "praise", "our", "hour", "four",
                      "pour", "your", "tour", "rise"])
    func americanWordsPassC13(_ word: String) {
        #expect(!TessLineCheck.isBritish(word), "\(word)")
    }

    @Test func theLowsHold() {
        // A lowercase lift he didn't do, a question in context, and the engine's own walls on the line.
        #expect(Self.codes(Self.done("3 exercises, 12 sets, 1 new squat best.")).contains("C9"))
        #expect(Self.codes(Self.done("A bench best?", slot: .context)).contains("C4"))
        #expect(Self.codes(Self.done("3 exercises, 12 sets, 1 new best, bp 120/80.")).contains("C12"))
        #expect(Self.done("3 exercises, 12 sets, 1 new bench best.") == .pass)
    }

    // MARK: QA lows on #655

    @Test(arguments: ["promising", "surprising", "praising", "supervised"])
    func moreAmericanWordsPass(_ word: String) {
        #expect(!TessLineCheck.isBritish(word), "\(word)")
    }

    @Test(arguments: ["A midnight bench best.", "A bench best by dinner.", "Bench best of the year, this year.",
                      "A bench best before bedtime."])
    func moreTimesTheFactsCantShow(_ line: String) {
        #expect(Self.codes(Self.done(line)).contains("C15"), "\(line)")
    }

    @Test func eachDigitCountsWhatItSays() {
        // 3 exercises and 9 days since: "first in 3 days" borrows the wrong 3.
        let check = { (line: String) in
            TessLineCheck.check(line, slot: .context, numbers: [3, 9, 12, 7, 40, 1], names: ["Push A", "Bench"],
                                rulesLine: "7:40 pm", isDone: true, dayLabel: "Thursday evening", hero: "Push A done",
                                counts: ["days": [9], "exercises": [3], "sets": [12], "bests": [1]])
        }
        #expect(Self.codes(check("first in 3 days")).contains("C6"))
        #expect(check("first in 9 days") == .pass)
    }

    @Test func theBeltKnowsHisWeight() {
        let line = "A bench best, 82 this morning."
        #expect(Self.codes(TessLineCheck.check(line, slot: .detail, numbers: [82], names: ["Push A", "Bench"],
                                               rulesLine: nil, isDone: false, dayLabel: nil, hero: nil,
                                               lastWeightKg: 82)).contains("C12"))
    }
}
