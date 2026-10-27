import Foundation

/// Sheet 341: the Read step names a page, not a time. From the book's last page and about 0.7 pages a minute: "to
/// about page 226"; and when the step is tended, "Read, tended, about page 219" from the minutes actually read.
enum RoutineReading {
    static let pagesPerMinute = 0.7
    /// The word before the number never breaks from it ("page 226").
    static let page = "page\u{00A0}"

    /// Whether a step is the reading one.
    static func isReading(_ title: String) -> Bool {
        title.trimmingCharacters(in: .whitespaces).lowercased() == "read"
    }

    static func page(after minutes: Double, from last: Int) -> Int {
        last + Int((minutes * pagesPerMinute).rounded())
    }

    /// "to about page 226" for a step of `minutes`.
    static func label(last: Int, minutes: Double) -> String {
        "to about \(page)\(page(after: minutes, from: last))"
    }

    /// "Read, tended, about page 219" from the seconds actually spent.
    static func receipt(title: String, last: Int, spent seconds: TimeInterval) -> String {
        "\(title), tended, about \(page)\(page(after: seconds / 60, from: last))"
    }
}
