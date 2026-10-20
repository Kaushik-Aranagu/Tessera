import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Batch 4, "My day, connected": Plan my day's Claude wording, Shutdown at 9 pm and the energy check-in. Each sits
/// behind its Review switch; Off leaves Now exactly as it was.
@MainActor
struct MyDayTests {
    private let calendar = Calendar.current

    private func at(_ hour: Int, _ minute: Int = 0, daysFromNow: Int = 0) throws -> Date {
        let base = try #require(calendar.date(byAdding: .day, value: daysFromNow, to: .now))
        return try #require(calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base))
    }

    private func choices() throws -> (ReviewChoices, UserDefaults) {
        let defaults = try #require(UserDefaults(suiteName: "my-day-\(UUID().uuidString)"))
        return (ReviewChoices(defaults: defaults, writes: true), defaults)
    }

    private func turnOn(_ id: String, in choices: ReviewChoices) throws {
        let row = try #require(ReviewChoices.all.first { $0.id == id })
        choices.set(row, to: "On")
    }

    // MARK: Switches

    @Test func theThreeSwitchesAreLiveAndOnlyThePlanNeedsClaude() throws {
        let rows = Dictionary(uniqueKeysWithValues: ReviewChoices.all.map { ($0.id, $0) })
        for id in ["planMyDay", "shutdown", "energyCheckIn"] {
            let row = try #require(rows[id])
            #expect(row.readiness == .live, "\(id)")
            #expect(row.defaultValue == "Off", "\(id)")
        }
        #expect(rows["planMyDay"]?.needsClaude == true)
        #expect(rows["shutdown"]?.needsClaude == false)
        #expect(rows["energyCheckIn"]?.needsClaude == false)
        // Copy rule: no "at" before a clock time.
        #expect(rows["shutdown"]?.says["On"]?.contains("at 9") == false)
    }

    @Test func everythingOffIsTodaysNow() throws {
        let (review, _) = try choices()
        let switches = MyDaySwitches(choices: review)
        #expect(!switches.planWording && !switches.shutdown && !switches.energyCheckIn)
        #expect(!switches.wordsPlanViaClaude(asksClaude: true, shipped: false))
        #expect(try ShutdownModel.stage(switchOn: switches.shutdown, now: at(21, 30), calendar: calendar,
                                        closed: false, closedLine: nil) == nil)
        let log = try EnergyLog(defaults: #require(UserDefaults(suiteName: "energy-\(UUID().uuidString)")),
                                writes: true)
        #expect(try !log.asks(switchOn: switches.energyCheckIn, at: at(8), calendar: calendar))
    }

    @Test func claudeWordsThePlanOnlyUnderTessAsksClaude() throws {
        let (review, _) = try choices()
        try turnOn("planMyDay", in: review)
        let switches = MyDaySwitches(choices: review)
        #expect(switches.planWording)
        #expect(switches.wordsPlanViaClaude(asksClaude: true, shipped: false))
        // The switch never turns Claude on.
        #expect(!switches.wordsPlanViaClaude(asksClaude: false, shipped: false))
        #expect(!switches.wordsPlanViaClaude(asksClaude: false, shipped: true))
    }

    // MARK: Time windows

    @Test func shutdownOpensAtNineAndStaysUntilTheDayChanges() throws {
        #expect(try !MyDayWindow.shutdownIsOpen(at: at(20, 59), calendar: calendar))
        #expect(try MyDayWindow.shutdownIsOpen(at: at(21), calendar: calendar))
        #expect(try MyDayWindow.shutdownIsOpen(at: at(23, 30), calendar: calendar))
        #expect(try MyDayWindow.shutdownIsOpen(at: at(3, 59), calendar: calendar))
        #expect(try !MyDayWindow.shutdownIsOpen(at: at(4), calendar: calendar))
        #expect(try !MyDayWindow.shutdownIsOpen(at: at(12), calendar: calendar))
    }

    @Test func energyAsksOnlyInTheMorning() throws {
        #expect(try !MyDayWindow.energyIsOpen(at: at(6, 59), calendar: calendar))
        #expect(try MyDayWindow.energyIsOpen(at: at(7), calendar: calendar))
        #expect(try MyDayWindow.energyIsOpen(at: at(11, 59), calendar: calendar))
        #expect(try !MyDayWindow.energyIsOpen(at: at(12), calendar: calendar))
    }

    @Test func aClosedDayShowsHisLineOrNothing() throws {
        let night = try at(21, 30)
        #expect(ShutdownModel.stage(switchOn: true, now: night, calendar: calendar, closed: false, closedLine: nil)
            == .open)
        #expect(ShutdownModel.stage(switchOn: true, now: night, calendar: calendar, closed: true, closedLine: nil)
            == nil)
        #expect(ShutdownModel.stage(switchOn: true, now: night, calendar: calendar, closed: true, closedLine: "  ")
            == nil)
        #expect(ShutdownModel.stage(switchOn: true, now: night, calendar: calendar, closed: true,
                                    closedLine: "Reply to the landlord") == .closed(line: "Reply to the landlord"))
        #expect(try ShutdownModel.stage(switchOn: true, now: at(18), calendar: calendar, closed: false,
                                        closedLine: nil) == nil)
    }

    // MARK: Copy

    @Test func shutdownWordsCountWhereThingsGo() {
        var inputs = ShutdownInputs()
        #expect(ShutdownCopy.moving(3, inputs) == "3 moving to tomorrow")
        #expect(ShutdownCopy.value(later: false, inputs) == "Tomorrow")
        #expect(ShutdownCopy.value(later: true, inputs) == "Later")
        inputs.pastMidnight = true
        inputs.nextWeekday = "Friday"
        #expect(ShutdownCopy.moving(2, inputs) == "2 moving to Friday")
        #expect(ShutdownCopy.value(later: false, inputs) == "Friday")
        #expect(ShutdownCopy.more(2) == "2 more")
        #expect(ShutdownCopy.takenBack == "Shutdown, taken back.")
        for line in [ShutdownCopy.hero, ShutdownCopy.tomorrowFirst, ShutdownCopy.closeKey, ShutdownCopy.closeHint,
                     ShutdownCopy.didntClose, ShutdownCopy.fallbackPlaceholder]
        {
            #expect(!line.contains("—") && !line.contains("!"), "\(line)")
        }
    }

    @Test func energyWordsAreCountsAndNeverAList() {
        #expect(EnergyCopy.ask == "Energy today?")
        #expect(EnergyCopy.spoken(3) == "3 of 5")
        #expect(EnergyCopy.slept(400) == "slept 6h40")
        #expect(EnergyCopy.dayLog(level: 4, asleepMinutes: 412) == "Energy 4, slept 7 h")
        #expect(EnergyCopy.dayLog(level: 4, asleepMinutes: nil) == "Energy 4")
        #expect(EnergyCopy.dayLog(level: nil, asleepMinutes: 412) == nil)
        #expect(LastNightSleep.short(420) == "7h")
    }

    // MARK: Energy level

    @Test func energyIsAskedOnceADayAndKeptByHisDay() throws {
        let defaults = try #require(UserDefaults(suiteName: "energy-\(UUID().uuidString)"))
        let log = EnergyLog(defaults: defaults, writes: true)
        let morning = try at(8, 10)
        #expect(log.startingLevel == 3)
        #expect(log.asks(switchOn: true, at: morning, calendar: calendar))
        log.set(4, at: morning, calendar: calendar)
        #expect(log.level(at: morning, calendar: calendar) == 4)
        #expect(!log.asks(switchOn: true, at: morning, calendar: calendar))
        #expect(EnergyLog(defaults: defaults, writes: true).level(at: morning, calendar: calendar) == 4)
        #expect(EnergyLog(defaults: defaults, writes: true).startingLevel == 4)
        // 02:00 still belongs to the day before (his day starts at 04:00); the next morning asks again.
        #expect(try log.level(at: at(2, daysFromNow: 1), calendar: calendar) == 4)
        #expect(try log.asks(switchOn: true, at: at(8, daysFromNow: 1), calendar: calendar))
        log.set(9, at: morning, calendar: calendar)
        #expect(log.level(at: morning, calendar: calendar) == 4)
    }

    @Test func underADemoTheLevelIsNeverWritten() throws {
        let defaults = try #require(UserDefaults(suiteName: "energy-\(UUID().uuidString)"))
        let log = EnergyLog(defaults: defaults, writes: false)
        let morning = try at(9)
        log.set(2, at: morning, calendar: calendar)
        #expect(log.level(at: morning, calendar: calendar) == 2)
        #expect(defaults.dictionaryRepresentation().keys.allSatisfy { !$0.hasPrefix("energy.") })
    }

    // MARK: Shutdown, end to end

    @Test func closingMovesRowsKeepsTheLineAndUndoesAsOne() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let physio = try model.engine.perform(CreateTask(title: "Book the physio", startsAt: at(10)), by: .user)
            .output
        let oven = try model.engine.perform(CreateTask(title: "Clean the oven", startsAt: at(11)), by: .user).output
        let (review, _) = try choices()
        try turnOn("shutdown", in: review)
        let switches = MyDaySwitches(choices: review)
        let night = try at(21, 30)
        let shutdown = ShutdownModel()

        let off = try MyDaySwitches(choices: choices().0)
        #expect(shutdown.stage(model: model, now: night, calendar: calendar, switches: off) == nil)
        #expect(shutdown.stage(model: model, now: night, calendar: calendar, switches: switches) == .open)
        let rows = ShutdownModel.rows(model: model, now: night, calendar: calendar)
        #expect(Set(rows.map(\.id)) == [physio.id, oven.id])

        shutdown.toggle(oven.id)
        shutdown.line = "Reply to the landlord"
        let inputs = ShutdownModel.inputs(model: model, now: night, calendar: calendar)
        #expect(shutdown.close(model: model, rows: rows, inputs: inputs, now: night, calendar: calendar))

        #expect(shutdown.stage(model: model, now: night, calendar: calendar, switches: switches)
            == .closed(line: "Reply to the landlord"))
        #expect(model.store.value("startsAt", of: oven) == nil)
        let moved = try #require(model.store.value("startsAt", of: physio)?.dateValue)
        #expect(TesseraDay(calendar: calendar).day(of: moved) > TesseraDay(calendar: calendar).day(of: night))
        #expect(TessVoice.shared.note?.text == "Closed. Your line is waiting at 8 am.")

        // UNDO takes the whole close back.
        TessVoice.shared.note?.takeBack?()
        #expect(ShutdownDay(store: model.store, classes: model.classes, calendar: calendar).closedMark(for: night)
            == nil)
        #expect(model.store.value("startsAt", of: oven)?.dateValue != nil)
        #expect(shutdown.stage(model: model, now: night, calendar: calendar, switches: switches) == .open)
    }
}
