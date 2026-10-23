import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Sheet 215 rev 5: her opening line. What changed since her last turn (never a value), else the newest Today notice;
/// nothing in quiet hours; nothing about money, health, body, calories or the calendar.
@MainActor
struct TessOpenerTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var conversation: TessConversation {
        TessConversation(store: store, classes: engine.classes)
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func facts(_ now: Date, events: [HandsEvent] = []) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4), events: events)
    }

    func opening(_ now: Date, quiet: QuietHours = .standard, quietUntil: Date? = nil, events: [HandsEvent] = [])
        -> TessOpening?
    {
        TessOpener.opening(engine: engine, facts: facts(now, events: events), plan: nil,
                           lastTurn: conversation.lastTessTurn(), quiet: quiet, quietUntil: quietUntil,
                           events: events, calendar: calendar)
    }

    @Test func somethingTheNamedThingChangedIsSaidWithNoValue() throws {
        let task = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user).output
        _ = conversation.append(
            role: .tess,
            text: "Mail forms is at 3 pm.",
            about: [task],
            at: Date.now.addingTimeInterval(-60)
        )
        try engine.perform(MoveTask(task: task.id, to: at(17, 30), calendar: calendar), by: .user)
        let open = try #require(opening(at(12)))
        #expect(open.line == "Since then, Mail forms changed." && open.source == .sinceThen(task.id))
        #expect(!open.line.contains("5:30") && !open.line.contains("17") && open.replies.count <= 3)
        #expect(open.replies == ["Show me", "Fine as it is"])
    }

    @Test func aConflictNamesTheOtherThingWithoutTimes() throws {
        let workout = try engine.perform(CreateTask(title: "Push day", startsAt: at(18, 30)), by: .user).output
        _ = conversation.append(
            role: .tess,
            text: "Push day is set.",
            about: [workout],
            at: Date.now.addingTimeInterval(-60)
        )
        try engine.perform(RenameObject(object: workout.id, title: "Push day"), by: .user)
        try engine.perform(MoveTask(task: workout.id, to: at(19), calendar: calendar), by: .user)
        let events = [
            HandsEvent(app: .training, label: "Push day", start: at(19), end: at(20), hands: [], isFixed: false),
            HandsEvent(app: .routines, label: "Stretch", start: at(19, 30), end: at(20), hands: [], isFixed: false),
        ]
        let open = try #require(opening(at(12), events: events))
        #expect(open.line == "Since then, Push day changed. Stretch may run into it.")
        #expect(open.replies == ["Move it later", "Leave it", "Not now"])
    }

    @Test func herOwnChangeIsNotNewsAndNothingChangedOpensWithTheNewestNotice() throws {
        let task = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user).output
        // Her turn comes after the task was made; then only she changes it.
        _ = conversation.append(role: .tess, text: "Mail forms is at 3 pm.", about: [task], at: Date.now)
        Thread.sleep(forTimeInterval: 0.02)
        try engine.perform(RenameObject(object: task.id, title: "Mail the forms"), by: .tess)
        let notice = try #require(opening(at(12)))
        #expect(notice.source == .notice && !notice.line.hasPrefix("Since then"))
        #expect(notice.line.hasSuffix(".") && notice.replies == ["Show me", "Not now"])
    }

    @Test func aChangedMoneyHealthBodyOrCalendarThingGivesNoSinceThenAtAll() throws {
        let pool = try engine.perform(CreatePool(name: "US checking", opening: "100"), by: .user).output
        let event = try store.create(#require(engine.classes[.event]), title: "Dentist")
        for object in [pool, event] {
            _ = conversation.append(
                role: .tess,
                text: "That one",
                about: [object],
                at: Date.now.addingTimeInterval(-60)
            )
        }
        try engine.perform(LogInflow(amount: "50", pool: pool.id), by: .user)
        try store.set("start", to: .date(at(14)), on: event)
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user)
        let open = try #require(opening(at(12)))
        #expect(open.source == .notice && !open.line.contains("Since then") && !open.line.lowercased()
            .contains("checking"))
        #expect(!open.line.contains("Dentist"))
    }

    @Test func aPrivateChangedThingIsNamedByItsLabelAndADeletionCounts() throws {
        let secret = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user).output
        _ = conversation.append(
            role: .tess,
            text: "Reminder set",
            about: [secret],
            at: Date.now.addingTimeInterval(-60)
        )
        try engine.perform(RenameObject(object: secret.id, title: "Lexapro refill today"), by: .user)
        let open = try #require(opening(at(12)))
        #expect(open.line == "Since then, Private task changed." && !open.line.lowercased().contains("lexapro"))
        let gone = try engine.perform(CreateTask(title: "Pick up forms"), by: .user).output
        _ = conversation.append(
            role: .tess,
            text: "Forms are on your list",
            about: [gone],
            at: Date.now.addingTimeInterval(-30)
        )
        try engine.perform(DeleteObject(object: gone.id), by: .user)
        #expect(try #require(opening(at(12))).line == "Since then, Pick up forms changed.")
    }

    @Test func quietHoursAndQuietForAnHourSayNothing() throws {
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user)
        #expect(opening(at(12)) != nil)
        #expect(opening(at(23, 30)) == nil && opening(at(3)) == nil)
        #expect(opening(at(12), quietUntil: at(13)) == nil)
        #expect(opening(at(12), quietUntil: at(11)) != nil)
        let mine = QuietHours(startMinute: 11 * 60, endMinute: 13 * 60)
        #expect(opening(at(12), quiet: mine) == nil && opening(at(14), quiet: mine) != nil)
    }

    @Test func theLineIsNeverWalledAndTheTypeStaysOutOfClaudeCode() throws {
        #expect(TessOpener.passes("Mail forms, due Friday.", store: store))
        #expect(!TessOpener.passes("You paid 1200 rent.", store: store))
        #expect(!TessOpener.passes("That was 600 calories.", store: store))
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        var checked = 0
        for path in ["../Widgets", "../Watch", "../Shared", "Sources/TesseraIntents", "../DesignSystem"] {
            guard let walker = FileManager.default.enumerator(at: package.appending(path: path),
                                                              includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in walker where url.pathExtension == "swift" {
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
                checked += 1
                for word in ["TessOpener", "TessOpening", "TessLastTurn"] {
                    #expect(try text.firstMatch(of: Regex("\\b\(word)\\b")) == nil, "\(word) in \(url.path)")
                }
            }
        }
        #expect(checked > 20)
    }
}
