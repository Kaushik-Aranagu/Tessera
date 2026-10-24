import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Settings: Quiet hours and The day turns over at. Defaults are today's behaviour; phone only.
@MainActor
struct QuietHoursTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func theDefaultsAreTodaysBehaviour() {
        let settings = TesseraSettings()
        #expect(settings.quietHours == QuietHours.standard && QuietHours.standard.words == "11 pm to 7 am")
        #expect(settings.dayTurnsAtHour == 4)
        #expect(TesseraDay.startHour == 4 && QuietHours.current == .standard)
        #expect(QuietHours.standard.contains(at(23), calendar: calendar))
        #expect(QuietHours.standard.contains(at(2), calendar: calendar))
        #expect(!QuietHours.standard.contains(at(7), calendar: calendar))
        #expect(!QuietHours.standard.contains(at(22, 59), calendar: calendar))
    }

    @Test func quietHoursCanCrossMidnightOrNotAndEqualMeansNone() {
        let evening = QuietHours(startMinute: 22 * 60, endMinute: 6 * 60 + 30)
        #expect(evening.contains(at(22), calendar: calendar) && evening.contains(at(6, 29), calendar: calendar))
        #expect(!evening.contains(at(6, 30), calendar: calendar) && evening.words == "10 pm to 6:30 am")
        let nap = QuietHours(startMinute: 13 * 60, endMinute: 15 * 60)
        #expect(nap.contains(at(14), calendar: calendar) && !nap.contains(at(15), calendar: calendar))
        let none = QuietHours(startMinute: 600, endMinute: 600)
        #expect(none.isNone && !none.contains(at(10), calendar: calendar) && none.words == "Off")
        // Out of range is clamped.
        #expect(QuietHours(startMinute: -5, endMinute: 5000).startMinute == 0)
    }

    @Test func leavingMovesToTheEndOnTheRightDay() {
        let standard = QuietHours.standard
        #expect(standard.leaving(at(23, 20), calendar: calendar) == at(7, day: 23))
        #expect(standard.leaving(at(2), calendar: calendar) == at(7))
        #expect(standard.leaving(at(12), calendar: calendar) == at(12))
        let late = QuietHours(startMinute: 22 * 60 + 30, endMinute: 8 * 60 + 15)
        #expect(late.leaving(at(23), calendar: calendar) == at(8, 15, day: 23))
    }

    @Test func theSettingsRoundTripAndIgnoreNonsense() throws {
        let settings = SettingsStore(engine: engine)
        #expect(SettingsStore.quietHours(in: store) == .standard)
        try settings.update {
            $0.quietStartMinute = 22 * 60
            $0.quietEndMinute = 6 * 60
            $0.dayStartHour = 5
        }
        let read = settings.read()
        #expect(read.quietHours == QuietHours(startMinute: 22 * 60, endMinute: 6 * 60) && read.dayTurnsAtHour == 5)
        #expect(SettingsStore.quietHours(in: store).words == "10 pm to 6 am")
        try settings.update {
            $0.dayStartHour = 12
            $0.quietStartMinute = 2000
        }
        // Outside the ranges the stored numbers read as unset: today's behaviour.
        #expect(settings.read().dayTurnsAtHour == 4 && settings.read().quietStartMinute == nil)
    }

    @Test func theDayTurnsOverWhereHeSaysAndNowhereElseMoves() {
        let early = TesseraDay(calendar: calendar, startHour: 2)
        let late = TesseraDay(calendar: calendar, startHour: 6)
        let threeAM = at(3)
        #expect(early.day(of: threeAM) == calendar.startOfDay(for: threeAM))
        #expect(late.day(of: threeAM) == calendar.startOfDay(for: at(3, day: 21)))
        #expect(late.start(of: at(12)) == at(6) && late.end(of: at(12)) == at(6, day: 23))
        #expect(TesseraDay(calendar: calendar, startHour: 99).startHour == 8)
        #expect(TesseraDay(calendar: calendar).startHour == 4)
    }

    @Test func notNowLandsAfterHisQuietHoursNotAFixedSeven() throws {
        let task = try engine.perform(CreateTask(title: "Stretch", startsAt: at(21, 40)), by: .user).output
        try SettingsStore(engine: engine).update { $0.quietStartMinute = 21 * 60; $0.quietEndMinute = 8 * 60 }
        // Not now tomorrow lands at 9:40 pm, inside his new quiet hours, so it moves to 8 am that day.
        try engine.perform(MoveTask(task: task.id, time: at(21, 50), calendar: calendar), by: .user)
        #expect(engine.store.value("startsAt", of: task)?.dateValue == at(8, day: 23))
    }

    @Test func theGroceriesAskWaitsForHisQuietHoursToo() throws {
        try engine.perform(AddGroceries(lines: ["milk"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        let row = try #require(Groceries(store: store, classes: engine.classes).shoppingOrder().first)
        try engine.perform(CheckListItem(item: row.id), by: .user)
        let finish = Date.now
        try engine.perform(FinishShop(time: finish), by: .user)
        // A calendar whose clock reads 12:00 at the finish, so the default quiet hours (11 pm to 7 am) don't hold it.
        var noon = Calendar(identifier: .gregorian)
        var offset = (12 * 3600 - Int(finish.timeIntervalSince1970) % 86400) % 86400
        if offset > 12 * 3600 {
            offset -= 86400
        }
        noon.timeZone = try #require(TimeZone(secondsFromGMT: offset))
        let receipt = ShopReceipt(store: store, classes: engine.classes)
        #expect(receipt.nowPrompt(at: finish, calendar: noon, somethingRuns: false) != nil)
        try SettingsStore(engine: engine).update { $0.quietStartMinute = 11 * 60; $0.quietEndMinute = 13 * 60 }
        #expect(receipt.nowPrompt(at: finish, calendar: noon, somethingRuns: false) == nil)
    }

    @Test func theGrammarMovesAPickedTimeOutOfQuietHours() {
        let quiet = QuietHours(startMinute: 22 * 60, endMinute: 6 * 60)
        #expect(TessDates.outOfQuietHours(at(23), calendar: calendar, quiet: quiet) == at(6, day: 23))
        #expect(TessDates.outOfQuietHours(at(5), calendar: calendar, quiet: quiet) == at(6))
        #expect(TessDates.outOfQuietHours(at(23), calendar: calendar, quiet: .standard) == at(7, day: 23))
        #expect(TessDates.outOfQuietHours(at(12), calendar: calendar) == at(12))
    }

    @Test func anInstanceKeepsTheHourItWasMadeWithAndTheWhyLineIsPlain() {
        let made = TesseraDay(calendar: calendar, startHour: 5)
        TesseraDay.configuredStartHour = 4
        #expect(made.startHour == 5 && TesseraDay(calendar: calendar).startHour == 4)
        #expect(TesseraSettings
            .dayTurnsAtWhy == "Changing it moves late-night things between days, past days included.")
    }
}
