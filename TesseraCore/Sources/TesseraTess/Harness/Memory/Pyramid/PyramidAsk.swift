import Foundation

/// An ask as the pyramid router reads it (input-hygiene H7, docs/ai/harness/memory-pyramid.md "P3b with dates
/// normalized first"): its date words resolved at the moment it was asked and written the way node titles are, so
/// "last month" on Oct 23 reads "September 2026" and "2 Oct" reads "Fri, Oct 2, 2026 October". The ask's own words are
/// kept; the resolved date is added after them. Simulated, this alone routes 95 to 100% of asks right from the first
/// night, where learning without it reached 91 to 96% after 30 nights.
public enum PyramidAsk {
    /// Lowercased runs of letters and digits: what the router matches.
    public static func words(_ text: String) -> [String] {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    /// Words that say nothing about where to look. Left in, "how" in one ask would learn a pull toward whatever that
    /// ask cited and carry it into every other ask that starts with "how".
    static let stopWords: Set<String> = [
        "a", "about", "am", "an", "and", "are", "at", "be", "been", "did", "do", "does", "far", "for", "how", "i",
        "in", "is", "it", "many", "me", "much", "my", "of", "on", "or", "so", "that", "the", "to", "was", "we", "were",
        "what", "when", "you",
    ]

    /// What the router reads of an ask: its words with the date resolved, less the stop words.
    public static func terms(_ text: String, now: Date, calendar: Calendar) -> [String] {
        words(normalize(text, now: now, calendar: calendar)).filter { !stopWords.contains($0) }
    }

    static let monthNames: [String: Int] = {
        let full = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october",
                    "november", "december"]
        var names: [String: Int] = [:]
        for (index, name) in full.enumerated() {
            names[name] = index + 1
            names[String(name.prefix(3))] = index + 1
        }
        names["sept"] = 9
        return names
    }()

    static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    /// The ask with its resolved day or month added, or as it was when it names none.
    public static func normalize(_ text: String, now: Date, calendar: Calendar) -> String {
        let lower = text.lowercased()
        let tokens = words(lower)
        let today = calendar.startOfDay(for: now)
        func add(_ unit: Calendar.Component, _ value: Int, to date: Date) -> Date {
            calendar.date(byAdding: unit, value: value, to: date) ?? date
        }
        func firstOfMonth(_ date: Date) -> Date {
            calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        }
        func count(before unit: String) -> Int? {
            guard let index = tokens.firstIndex(of: unit), index > 0, tokens.indices.contains(index + 1),
                  tokens[index + 1] == "ago" else { return nil }
            return Int(tokens[index - 1])
        }

        var day: Date?
        var month: Date?
        if tokens.contains("yesterday") {
            day = add(.day, -1, to: today)
        } else if tokens.contains("today") {
            day = today
        } else if let index = tokens.firstIndex(of: "last"), tokens.indices.contains(index + 1),
                  let target = weekdays.firstIndex(of: tokens[index + 1])
        {
            let weekday = calendar.component(.weekday, from: today) - 1
            let back = (weekday - target + 7) % 7
            day = add(.day, -(back == 0 ? 7 : back), to: today)
        } else if let back = count(before: "days") ?? count(before: "day") {
            day = add(.day, -back, to: today)
        } else if lower.contains("this month") {
            month = firstOfMonth(today)
        } else if lower.contains("last month") {
            month = add(.month, -1, to: firstOfMonth(today))
        } else if let back = count(before: "months") ?? count(before: "month") {
            month = add(.month, -back, to: firstOfMonth(today))
        } else {
            let year = tokens.compactMap { Int($0) }.first { (1900 ... 2100).contains($0) }
            // The month's day is the number right beside its name ("Oct 2", "2 Oct"), so "3 sets on Oct 5" is the 5th.
            // "may" is a month only beside a day or a year: "may I ask" names none.
            var named: Int?
            var date: Int?
            for (index, token) in tokens.enumerated() {
                guard let value = monthNames[token] else { continue }
                let beside = [index + 1, index - 1].filter { tokens.indices.contains($0) }
                    .compactMap { Int(tokens[$0]) }
                    .first { (1 ... 31).contains($0) }
                if token == "may", beside == nil, year == nil {
                    continue
                }
                named = value
                date = beside
                break
            }
            if let named {
                let parts = calendar.dateComponents([.year, .month, .day], from: today)
                let thisYear = parts.year ?? 0
                if let date {
                    // The most recent such day on or before today, unless a year is named.
                    let passed = (named, date) <= (parts.month ?? 0, parts.day ?? 0)
                    day = calendar.date(from: DateComponents(year: year ?? (passed ? thisYear : thisYear - 1),
                                                             month: named, day: date))
                } else {
                    let passed = named <= (parts.month ?? 0)
                    month = calendar.date(from: DateComponents(year: year ?? (passed ? thisYear : thisYear - 1),
                                                               month: named, day: 1))
                }
            }
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let day {
            // The day's title, then its month's name, so the month level matches too.
            formatter.dateFormat = "EEE, MMM d, yyyy MMMM"
            return "\(text) \(formatter.string(from: day))"
        }
        if let month {
            formatter.dateFormat = "MMMM yyyy"
            return "\(text) \(formatter.string(from: month))"
        }
        return text
    }
}
