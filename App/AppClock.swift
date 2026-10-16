import Foundation
import TesseraCore

/// The app's notion of "now". Normally the real time; `-demoTime HH:mm` (DEBUG) shifts the clock so demos and
/// recordings look the same whatever time it actually is.
enum AppClock {
    private nonisolated(unsafe) static var offset: TimeInterval = 0

    static var now: Date {
        Date().addingTimeInterval(offset)
    }

    /// Maps a real date (e.g. from a `TimelineView` context) onto app time.
    static func adjust(_ date: Date) -> Date {
        date.addingTimeInterval(offset)
    }

    static func configure(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if DEBUG
            // Simulator only: a shifted clock on the phone would stamp logs and backups with wrong dates.
            guard let time = LaunchFlags.value(after: "-demoTime", in: arguments) else { return }
            let parts = time.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return }
            let real = Date()
            guard let target = Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: real)
            else {
                return
            }
            offset = target.timeIntervalSince(real)
        #endif
    }
}

enum Format {
    /// The unit the dial and labels use. Weights are stored as kilograms either way; kg until Kaushik picks.
    nonisolated(unsafe) static var unit: MassUnit = .kilograms

    /// A stored kilogram value in the chosen unit, with its symbol ("82.5 kg", "180 lb").
    static func mass(_ kilograms: Double) -> String {
        unit.format(kilograms: kilograms)
    }

    static func kilograms(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }

    /// "6:30 pm": the one house time (TW9 closes TW10 to TW14's 24-hour times).
    static func clock(_ date: Date) -> String {
        HouseTime.clock(date)
    }

    /// 3:00, 12:05, 1:02:03
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        let hours = total / 3600, minutes = (total % 3600) / 60, secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    static func shortDay(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }

    /// "pushDayA" style identifier for class lines.
    static func identifier(_ name: String, upperFirst: Bool) -> String {
        let words = name.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        guard let first = words.first else { return "untitled" }
        let head = upperFirst ? first.prefix(1).uppercased() + first.dropFirst() : first.prefix(1).lowercased() + first
            .dropFirst()
        return head + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
}
