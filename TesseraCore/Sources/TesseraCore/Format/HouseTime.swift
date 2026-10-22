import Foundation

/// The one way a time of day reads in Tessera: 12-hour, lowercase, minutes only when they aren't zero ("6:30 pm",
/// "7 pm", "12 am"). Every screen, line and VoiceOver label uses it (Research time-words-sweep TW9, decisions 12:35
/// PM PT Oct 16): he never reads a 24-hour time.
public enum HouseTime {
    public static func clock(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0, minute = parts.minute ?? 0
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        let half = hour < 12 ? "am" : "pm"
        return minute == 0 ? "\(twelve) \(half)" : String(format: "%d:%02d %@", twelve, minute, half)
    }

    /// A length of time the house way: "45 min", "1 hr", "1 hr 30 min", never "90 min". Whole minutes, rounded down;
    /// anything under one minute reads "1 min".
    public static func minutes(_ total: Int) -> String {
        let total = max(total, 1)
        guard total >= 60 else { return "\(total) min" }
        let rest = total % 60
        return rest == 0 ? "\(total / 60) hr" : "\(total / 60) hr \(rest) min"
    }
}
