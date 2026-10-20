import Foundation
import TesseraCore

// Batch 4, "My day, connected": Plan my day's Claude wording, Shutdown at 9 pm and the energy check-in, each behind
// its Review switch. Every switch Off leaves Now exactly as it was.

/// The three Review switches My day reads, in one place so Now and the tests read the same values.
@MainActor
struct MyDaySwitches {
    var choices: ReviewChoices = .shared

    /// Plan my day, Claude wording: On lets Claude word the rules plan.
    var planWording: Bool {
        choices.value(of: "planMyDay") == "On"
    }

    /// Shutdown: On shows the close of the day on Now from 9 pm.
    var shutdown: Bool {
        choices.value(of: "shutdown") == "On"
    }

    /// Energy check-in: On asks for a 1 to 5 level on the morning plan line.
    var energyCheckIn: Bool {
        choices.value(of: "energyCheckIn") == "On"
    }

    /// Claude words the plan only when "Tess asks Claude" is on and either the wording has shipped
    /// (`AppModel.planWordingReady`) or he is trying it through the Review switch. The switch never turns Claude on.
    func wordsPlanViaClaude(asksClaude: Bool, shipped: Bool = AppModel.planWordingReady) -> Bool {
        asksClaude && (shipped || planWording)
    }
}

/// When each part of My day may show, on the app's clock (`AppClock.now`, which `-demoTime` shifts).
enum MyDayWindow {
    /// Shutdown opens at 21:00 and stays reachable until the day changes at 04:00 (late night files to the day before).
    static let shutdownOpensHour = 21

    static func shutdownIsOpen(at now: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: now)
        return hour >= shutdownOpensHour || hour < TesseraDay.startHour
    }

    /// The morning plan line asks for energy from the end of quiet hours (07:00) until noon.
    static let energyFromHour = 7
    static let energyUntilHour = 12

    static func energyIsOpen(at now: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: now)
        return hour >= energyFromHour && hour < energyUntilHour
    }
}

// MARK: - Sleep

/// Last night's sleep from the Health mount's Sleep Night object, read live and never stored with the energy level
/// (Design 112). Nil when Health has written nothing for the night ending today.
enum LastNightSleep {
    @MainActor
    static func asleepMinutes(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date,
                              calendar: Calendar) -> Int?
    {
        guard let sleepClass = classes[.sleepNight] else { return nil }
        let day = TesseraDay(calendar: calendar)
        let start = calendar.startOfDay(for: day.day(of: now))
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let night = store.objects(of: sleepClass)
            .filter { !$0.isDeleted }
            .compactMap { object -> (Date, Double)? in
                guard let date = store.value("date", of: object)?.dateValue, date >= start, date < end,
                      store.value("partial", of: object) != .bool(true),
                      store.value("basis", of: object)?.stringValue != "inBed",
                      let minutes = store.value("asleepMinutes", of: object)?.numericValue else { return nil }
                return (date, minutes)
            }
            .max { $0.0 < $1.0 }
        return night.map { Int($0.1.rounded()) }
    }

    /// "6h40", the plan line's and Shutdown's form; "7h" on the hour.
    static func short(_ minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours)h" : String(format: "%dh%02d", hours, rest)
    }

    /// "7 h": rounded to the hour, the Day log's form.
    static func rounded(_ minutes: Int) -> String {
        "\(Int((Double(minutes) / 60).rounded())) h"
    }
}
