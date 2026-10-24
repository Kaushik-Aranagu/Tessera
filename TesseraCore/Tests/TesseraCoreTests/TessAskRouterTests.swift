import Foundation
@testable import TesseraCore
import Testing

/// Sheet 215: the ObjectRef ask router and the room log. Phone first; Claude only for plain objects of allowed classes
/// when asksClaude is on; money, health, body, calorie and calendar always stay.
@MainActor
struct TessAskRouterTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func make(_ key: SystemCatalog.Key, _ title: String) throws -> ObjectRecord {
        try store.create(#require(engine.classes[key]), title: title)
    }

    func route(_ object: ObjectRecord, claude: Bool) -> TessAsk {
        TessAskRouter.route(object, engine: engine, asksClaude: claude, calendar: calendar)
    }

    // MARK: The class gate

    @Test func aPlainTaskIsAnsweredOnThePhoneAndOnlySendsItsShownTextWhenAsksClaudeIsOn() throws {
        let task = try engine.perform(CreateTask(title: "Mail forms"), by: .user).output
        let off = route(task, claude: false)
        #expect(off.phoneAnswer == "Mail forms, still to do." && off.claudeText == nil)
        #expect(off.actions == [.markTaskDone(task.id)])
        let on = route(task, claude: true)
        #expect(on.phoneAnswer == off.phoneAnswer && on.claudeText == "Mail forms, still to do.")
    }

    @Test func moneyHealthBodyAndCalendarObjectsAlwaysStayOnThePhone() throws {
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user).output
        let spend = try engine.perform(LogSpend(amount: 12, typed: "12", pool: pool.id), by: .user).output
        let objects = try [pool, spend, make(.event, "Dentist"), make(.meProfile, "Me"), make(.sleepNight, "Night"),
                           make(.stepsDay, "Steps"), make(.tessTurn, "")]
        for object in objects {
            for claude in [false, true] {
                let ask = route(object, claude: claude)
                #expect(ask.phoneAnswer == "That stays on this phone." && ask.claudeText == nil && ask.actions.isEmpty,
                        "\(object.classDef?.name ?? "?") claude=\(claude)")
            }
        }
    }

    @Test func privateAndWalledThingsAreAnsweredByTheirLabelAndNeverSent() throws {
        let secret = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user).output
        let ask = route(secret, claude: true)
        #expect(ask.phoneAnswer == "Private task." && ask.claudeText == nil && ask.actions.isEmpty)
        let routine = try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user).output
        #expect(route(routine, claude: true).claudeText == nil)
        let note = try engine.perform(CreateNote(body: "wifi password is hunter2zebra"), by: .user).output
        #expect(route(note, claude: true).claudeText == nil && !route(note, claude: true).phoneAnswer
            .contains("hunter2"))
        // A plain-titled item with a walled word inside stays too.
        let walled = try make(.list, "Pay 1200 rent list")
        #expect(route(walled, claude: true).claudeText == nil)
    }

    @Test func onlyAllowedClassesCanGoToClaude() throws {
        let list = try make(.list, "Packing")
        let recipe = try make(.recipe, "Tacos")
        #expect(route(list, claude: true).claudeText == "Packing" && route(recipe, claude: true).claudeText != nil)
        // A note, a workout and an exercise class object are answered on the phone but never offered.
        let note = try engine.perform(CreateNote(body: "Trip packing ideas"), by: .user).output
        #expect(route(note, claude: true).claudeText == nil)
        let workout = try make(.workout, "Push A")
        let ask = route(workout, claude: true)
        #expect(ask.claudeText == nil && !ask.phoneAnswer.isEmpty)
    }

    @Test func noMoneyActionIsEverOffered() throws {
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user).output
        let move = try engine.perform(
            LogMove(from: pool.id, to: engine.perform(CreatePool(name: "Savings", opening: "0"), by: .user).output.id,
                    sent: "10", arrived: "10"), by: .user
        ).output
        for object in [pool, move] {
            #expect(route(object, claude: true).actions.isEmpty)
        }
        let done = try engine.perform(CreateTask(title: "Call"), by: .user).output
        try engine.perform(SetTaskDone(task: done.id), by: .user)
        #expect(route(done, claude: false).actions.isEmpty)
    }

    // MARK: The room log

    @Test func theRoomLogIsTodaysActionsMaskedWithTheirUndoAndMoneyReversed() throws {
        let now = Date.now
        let task = try engine.perform(CreateTask(title: "Mail forms"), by: .user)
        _ = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user)
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user)
        try engine.perform(AddGroceries(lines: ["milk"]), by: .system)
        let entries = TessRoomLog.today(engine: engine, now: now, calendar: calendar)
        #expect(entries.count >= 3 && entries.map(\.time) == entries.map(\.time).sorted(by: >))
        #expect(!entries.map(\.sentence).joined().lowercased().contains("lexapro"))
        #expect(!entries.map(\.sentence).joined().lowercased().contains("checking"))
        let money = try #require(entries.first { $0.id == pool.record.id })
        #expect(money.isMoney && money.undoWord == "Reversed")
        let plain = try #require(entries.first { $0.id == task.record.id })
        #expect(plain.undoWord == "Undo" && !plain.isMoney)
        // The system's own housekeeping is not in the log; an undo goes through the op log with its own word.
        #expect(TessRoomLog.undo(plain, engine: engine) == .putBack(line: "Put back."))
        #expect(task.output.isDeleted)
        #expect(TessRoomLog.undo(money, engine: engine) == .putBack(line: "Reversed."))
        // Yesterday's changes are not today's.
        let tomorrow = TessRoomLog.today(engine: engine, now: now.addingTimeInterval(2 * 86400), calendar: calendar)
        #expect(tomorrow.isEmpty)
    }
}
