import Foundation
import TesseraCore

/// The words of the finishing moments (Design 139): each app ends a piece of work with one small flourish and one
/// line. Pure functions only (no store, no clock), so the lines and the privacy wall are testable. The wall: a
/// private routine's or workout's name never shows; callers pass the label `ObjectPrivacy.shownLabel` gave
/// (nil means plain), and `shownName` picks it.
enum FinishWords {
    nonisolated static let choiceID = "finishV2"

    /// The Review switch "Finishing marks" (default Off): with it Off every finish ends as it always did.
    @MainActor static var isOn: Bool {
        isOn(value: ReviewChoices.shared.value(of: choiceID))
    }

    /// The pure reading of the switch's value.
    nonisolated static func isOn(value: String?) -> Bool {
        value == "On"
    }

    /// The name a line may print: the privacy label when there is one ("Private workout"), else the real name.
    nonisolated static func shownName(_ name: String, privateLabel: String?) -> String {
        if let privateLabel, !privateLabel.isEmpty {
            return privateLabel
        }
        return name
    }

    /// Whole minutes of a session, rounded down (the house length words round the same way).
    nonisolated static func minutes(of duration: TimeInterval) -> Int {
        max(Int(duration / 60), 0)
    }

    /// Training: "Push Day A, all sets in. 1 hr 35 min."
    nonisolated static func trainingLine(name: String, privateLabel: String? = nil, minutes: Int) -> String {
        "\(shownName(name, privateLabel: privateLabel)), all sets in. \(HouseTime.minutes(minutes))"
    }

    /// Kitchen: "Served at 7:02 pm."
    nonisolated static func servedLine(at date: Date, calendar: Calendar = .current) -> String {
        "Served at \(HouseTime.clock(date, calendar: calendar))"
    }

    /// Routines, first line: "Morning, 22 min."
    nonisolated static func routineLine(name: String, privateLabel: String? = nil, minutes: Int) -> String {
        "\(shownName(name, privateLabel: privateLabel)), \(HouseTime.minutes(minutes))"
    }

    /// Routines, second line: "Tomorrow, usually 6:40 am." Nil before seven runs (no usual start yet).
    nonisolated static func tomorrowLine(usualStartMinuteOfDay: Int?) -> String? {
        guard let usualStartMinuteOfDay else { return nil }
        return "Tomorrow, usually \(HouseTime.clock(minuteOfDay: usualStartMinuteOfDay))"
    }
}
