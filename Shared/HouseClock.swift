import Foundation

/// The house clock (docs/research/time-words-sweep.md; decisions 12:35 PM PT Oct 16): every time he reads is 12-hour,
/// lower case, with a space, and drops ":00" ("6:12 pm", "8 pm", "12:50 am"). Shared by the app and the widget
/// extension, so the Live Activity and the workout finish read the same.
enum HouseClock {
    static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0, minute = parts.minute ?? 0
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let half = hour < 12 ? "am" : "pm"
        return minute == 0 ? "\(twelve) \(half)" : String(format: "%d:%02d %@", twelve, minute, half)
    }
}
