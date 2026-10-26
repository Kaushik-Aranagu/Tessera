import Foundation
@testable import TesseraCore
import Testing

/// Sheets 211 and 212: Today's day lines with their fact line, and the ranked notices for the departure board.
@MainActor
struct TodayLinesTests {
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

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func facts(_ now: Date, events: [HandsEvent] = []) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4), events: events)
    }

    func today(_ now: Date, events: [HandsEvent] = []) -> TodayFacts {
        TodayFacts.make(engine: engine, facts: facts(now, events: events), events: events, calendar: calendar)
    }

    func calendarEvent(_ title: String, start: Date, cancelled: Bool = false, allDay: Bool = false) throws {
        let event = try store.create(#require(engine.classes[.event]), title: title)
        try store.set("start", to: .date(start), on: event)
        try store.set("end", to: .date(start.addingTimeInterval(3600)), on: event)
        try store.set("cancelled", to: .bool(cancelled), on: event)
        try store.set("allDay", to: .bool(allDay), on: event)
    }

    // MARK: Today (211)

    @Test func theDayIsInOrderWithTheSunAndTheFactLineCountsWhatIsLeft() throws {
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user)
        _ = try engine.perform(CreateTask(title: "Stamps", startsAt: at(18, 30)), by: .user)
        try calendarEvent("Dentist", start: at(16))
        let workout = HandsEvent(app: .training, label: "Push A", start: at(19), end: at(20), hands: [], isFixed: false)
        let day = today(at(12), events: [workout])
        let sequence = day.lines.map(\.name)
        #expect(sequence.first == "Sunrise" && sequence.contains("Sunset"))
        let items = day.lines.filter { $0.kind != .sunrise && $0.kind != .sunset }.map(\.name)
        #expect(items == ["Mail forms", "Dentist", "Stamps", "Push A"])
        #expect(day.lines.map(\.time) == day.lines.map(\.time).sorted())
        #expect(day.left == 4 && day.factLine == "Four things left, the next at 3 pm")
        #expect(day.lines.first { $0.name == "Push A" }?.kind == .item(.training))
        #expect(day.lines.first { $0.name == "Dentist" }?.isCalendar == true)
        #expect(day.lines.first { $0.name == "Mail forms" }?.isCalendar == false)
        // Later in the day, what is behind him no longer counts.
        let evening = today(at(17), events: [workout])
        #expect(evening.left == 2 && evening.factLine == "Two things left, the next at 6:30 pm")
        #expect(evening.lines.first { $0.name == "Mail forms" }?.isPast == true)
        #expect(today(at(18, 45), events: [workout]).factLine == "One thing left, at 7 pm")
        #expect(today(at(21), events: [workout]).factLine == "Nothing left today")
    }

    @Test func titlesAreMaskedAndCancelledOrAllDayCalendarEventsAreLeftOut() throws {
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: at(15)), by: .user)
        try calendarEvent("Dr Lin checkup", start: at(16))
        try calendarEvent("Cancelled thing", start: at(17), cancelled: true)
        try calendarEvent("Birthday", start: at(0), allDay: true)
        let secret = HandsEvent(app: .training, label: "Private workout", start: at(19), end: at(20), hands: [],
                                isFixed: false)
        let day = today(at(12), events: [secret])
        let names = day.lines.map(\.name)
        #expect(!names.contains("Cancelled thing") && !names.contains("Birthday"))
        #expect(!names.joined().lowercased().contains("lexapro") && !names.joined().lowercased().contains("lin"))
        #expect(day.lines.filter(\.isPrivate).count >= 3)
        #expect(day.lines.first { $0.name == "Private workout" }?.isPrivate == true)
    }

    @Test func aCookIsNotALineAndABigCountIsDigits() throws {
        let cook = HandsEvent(app: .kitchen, label: "Tacos", start: at(18), end: at(19), hands: [], isFixed: true)
        #expect(!today(at(12), events: [cook]).lines.contains { $0.name == "Tacos" })
        for hour in 13 ..< 24 {
            _ = try engine.perform(CreateTask(title: "T\(hour)", startsAt: at(hour)), by: .user)
        }
        let many = today(at(12))
        #expect(many.left == 11 && many.factLine == "11 things left, the next at 1 pm")
    }

    // MARK: Notices (212)

    @Test func noticesAreCompleteSentencesWithTheAppWordMarkedAndAtMostSix() throws {
        let recipe = try engine.perform(
            CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Fry it."), by: .user
        ).output
        let cookTask = try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(18)), by: .user).output
        try store.setLinks("about", on: cookTask, to: [recipe])
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        for item in ["socks", "charger"] {
            _ = try engine.perform(AddListItem(list: list.id, text: item), by: .user)
        }
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(15)), by: .user)
        let notices = HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar)
        #expect(notices.count <= 6 && !notices.isEmpty)
        for notice in notices {
            #expect(notice.text.hasSuffix(".") && !notice.text.hasSuffix(".."), "\(notice.text)")
            if let range = notice.clause.keyWord {
                let key = String(notice.text.utf16.dropFirst(range.lowerBound).prefix(range.count)) ?? ""
                #expect(!key.isEmpty && notice.text.hasPrefix(key))
            }
        }
        let texts = notices.map(\.text)
        #expect(texts.contains("Packing, 2 left."), "\(texts)")
        let packing = try #require(notices.first { $0.text.hasPrefix("Packing") })
        #expect(packing.clause.app == .lists && packing.clause.keyWord == 0 ..< 7)
        // The soonest timed thing comes first; the sun's turn is a notice too.
        #expect(texts.first == "Mail forms at 3 pm.")
        #expect(texts.contains { $0.hasPrefix("Sunset at ") })
        // Targets: a static map. Sunset goes to the weather, a task to Today, an app's own line to its room.
        #expect(notices.first { $0.text.hasPrefix("Sunset") }?.target == .weather)
        #expect(notices.first { $0.text.hasPrefix("Mail forms") }?.target == .today)
        #expect(packing.target == .room(.lists) && packing.sourceWord == "Packing")
        #expect(notices.first { $0.text.hasPrefix("Sunset") }?.sourceWord == nil)
    }

    @Test func groceriesWithNoDishReadGroceriesAndPrivateItemsAreMasked() throws {
        try engine.perform(AddGroceries(lines: ["milk", "eggs", "rice", "butter"]), by: .user)
        let first = HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar)
        let groceries = try #require(first.first { $0.text.hasPrefix("Groceries") })
        #expect(groceries.text == "Groceries, 4 to get." && groceries.clause.app == .kitchen)
        #expect(groceries.clause.keyWord == 0 ..< 9)
        let secretList = try store.create(#require(engine.classes[.list]), title: "Lexapro refills")
        _ = try engine.perform(AddListItem(list: secretList.id, text: "pharmacy"), by: .user)
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: at(14)), by: .user)
        let masked = HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar)
        #expect(!masked.map(\.text).joined().lowercased().contains("lexapro"))
        #expect(masked.contains { $0.text == "Private." && $0.clause.keyWord == nil })
    }

    @Test func noMoneyAmountOrCalendarTitleOrBodyFactIsEverANotice() throws {
        try calendarEvent("Dentist cleaning", start: at(14))
        let due = HomeSentence.MoneyDue(name: "Rent 1850", at: at(9, day: 23))
        let notices = HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, moneyDue: due,
                                         calendar: calendar)
        let joined = notices.map(\.text).joined(separator: " ")
        #expect(!joined.contains("1850") && !joined.contains("Dentist"))
        #expect(joined.contains("A bill is due Friday."))
    }

    @Test func noticesStopAtSixAndTheLimitIsHonoured() throws {
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        _ = try engine.perform(AddListItem(list: list.id, text: "socks"), by: .user)
        for hour in 13 ... 21 {
            _ = try engine.perform(CreateTask(title: "T\(hour)", startsAt: at(hour)), by: .user)
        }
        let all = HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar)
        #expect(all.count >= 3 && all.count <= 6)
        #expect(HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar, limit: 2)
            .count == 2)
        #expect(HomeNotices.ranked(engine: engine, facts: facts(at(12)), plan: nil, calendar: calendar, limit: 0)
            .isEmpty)
    }

    @Test func aMaskedNextItemIsNotShownTwice() {
        let secret = HandsEvent(app: .training, label: "Private workout", start: at(18), end: at(19), hands: [],
                                isFixed: false)
        let notices = HomeNotices.ranked(engine: engine, facts: facts(at(12), events: [secret]), plan: nil,
                                         calendar: calendar)
        #expect(notices.count { $0.time.map { abs($0.timeIntervalSince(at(18))) < 60 } ?? false } <= 1)
    }

    // MARK: Short why and the calendar-text wall

    @Test func theShortWhyIsAWholePhraseOfThirtyCharactersOrFewer() {
        #expect(Pick.shortened("At 6:30 pm, due today") == "At 6:30 pm, due today")
        #expect(Pick.shortened("Carried from Wednesday, your evening slot") == "Carried from Wednesday")
        #expect(Pick.shortened("") == "")
        // A first reason that is too long on its own is cut at a word edge, never to nothing and never mid-word.
        let long = Pick.shortened("Carried over from the Wednesday before last, your evening slot")
        #expect(long == "Carried over from the" && long.count <= 30)
        #expect(Pick.shortened("Averyveryveryveryveryveryverylongword") == "")
        #expect(Pick.shortened("Carried from Wednesday, your evening slot").count <= 30)
        #expect(Pick.shortened("Welcome back. Small on purpose") == "Welcome back. Small on purpose")
    }

    @Test func calendarTextNeverReachesWidgetsWatchIntentsOrClaudeLines() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        // Every Swift file of the app target except the Home screens (which draw Today and the notices) and every other
        // process: the types must appear nowhere else, so no writer (surfaces, logging, Tess, Claude) can carry them.
        func sources(_ relative: String, except allowed: [String] = []) -> [(path: String, text: String)] {
            guard let walker = FileManager.default.enumerator(at: package.appending(path: relative),
                                                              includingPropertiesForKeys: nil) else { return [] }
            return walker.compactMap { item -> (String, String)? in
                guard let url = item as? URL, url.pathExtension == "swift",
                      !allowed.contains(where: { url.path.contains($0) }),
                      let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                return (url.path, text)
            }
        }
        let banned = ["TodayFacts", "TodayLine", "isCalendar", "HomeNotices", "HomeNotice"]
        var checked = 0
        let places: [(String, [String])] = [
            ("../Widgets", []), ("../Watch", []), ("../Shared", []), ("Sources/TesseraIntents", []),
            ("Sources/TesseraTess", []), ("../App", []), ("../DesignSystem", []),
            ("../Features", ["/Features/Home/"]),
        ]
        for (path, allowed) in places {
            let files = sources(path, except: allowed)
            // A scan that finds nothing in a folder would pass for the wrong reason.
            #expect(!files.isEmpty, "no Swift files found in \(path)")
            for file in files {
                checked += 1
                for word in banned {
                    // A whole word: "TriedTodayLine" is another type.
                    let pattern = try Regex("\\b\(word)\\b")
                    #expect(file.text.firstMatch(of: pattern) == nil, "\(word) in \(file.path)")
                }
            }
        }
        #expect(checked > 100)
        // Calendar events are mirrors: in no backup copy and no export (the mirror ids are cut from every copy).
        let event = try store.create(#require(engine.classes[.event]), title: "Dentist")
        #expect(PrivateWords.mirrorIDs(in: store.context).contains(event.id))
    }
}
