import Foundation
import TesseraCore

/// Pantry's words (sheet 78): the context line, Tess's line and the swipe's receipt.
enum PantryCopy {
    /// "since Saturday's shop", on his day (4 AM): "since today's shop", "since yesterday's shop", the weekday within
    /// the week, then "since the Oct 3 shop". Nil with no shop yet.
    static func context(lastShop: Date?, now: Date, calendar: Calendar = .current) -> String? {
        guard let lastShop else { return nil }
        let house = TesseraDay(calendar: calendar)
        let then = house.day(of: lastShop)
        let days = calendar.dateComponents([.day], from: then, to: house.day(of: now)).day ?? 0
        switch days {
        case ..<1: return "since today's shop"
        case 1: return "since yesterday's shop"
        case 2 ... 6: return "since \(TesseraDay.weekdayName(of: then, calendar: calendar))'s shop"
        default:
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMM d"
            return "since the \(formatter.string(from: then)) shop"
        }
    }

    /// Tess's band line: what the last cook used up, "Tacos took the cilantro and limes." Up to three names, then
    /// "and N more".
    static func tess(recipe: String, names: [String]) -> String {
        "\(recipe) took the \(list(names))."
    }

    /// The empty page's one line.
    static let emptyBody = "Clear a shop or finish a cook and this fills in."

    /// The swipe's receipt: "Milk, on Groceries." (thing first).
    static func added(_ label: String) -> String {
        "\(label), on Groceries."
    }

    /// "cilantro", "cilantro and limes", "a, b and c", "a, b and 2 more".
    static func list(_ names: [String]) -> String {
        switch names.count {
        case 0: ""
        case 1: names[0]
        case 2 ... 3: names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
        default: "\(names[0]), \(names[1]) and \(names.count - 2) more"
        }
    }
}
