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

/// The closing screen's words (sheet 335): a big "Tended", the days in a row as a quiet cue, and "5 of 5" as the time
/// line, with non-breaking spaces so it never splits. Only ever counts up: nothing here says what a missed day did.
enum RoutineFinish {
    /// "5 of 5" with non-breaking spaces.
    static func count(_ tended: Int, of total: Int) -> String {
        "\(tended)\u{00A0}of\u{00A0}\(total)"
    }

    /// Nothing counts a streak (Core's rule); until Design sends a cue, the closing line is this.
    static func cue(streak _: Int?) -> String {
        "Evening tended. Sleep well"
    }

    /// Days in a row ending today, from the days the routine was tended (one per Tessera day).
    static func streak(days: Set<Date>, today: Date, calendar: Calendar = .current) -> Int {
        var count = 0
        var day = today
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
