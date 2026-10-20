import Foundation
import TesseraCore

/// Reading's words (ship-list-m5-reading.md with its Oct 17 amendments; sheet money-reading-grammar). The thing
/// comes first; never a count anywhere ("47 to read" never appears); clocks and dates through the house rules.
enum ReadingCopy {
    /// The shelf's context line: "Dune last night", "Dune today"; "Nothing on the go" when no book is being read.
    static func context(lastTouched: (title: String, at: Date)?, now: Date, calendar: Calendar = .current) -> String {
        guard let last = lastTouched else { return "Nothing on the go" }
        return "\(last.title) \(when(last.at, now: now, calendar: calendar))"
    }

    /// "today", "last night" (yesterday from 5 pm), "yesterday", "Tue", "Oct 3", on his 4 am day.
    static func when(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let house = TesseraDay(calendar: calendar)
        let days = calendar.dateComponents([.day], from: house.day(of: date), to: house.day(of: now)).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return calendar.component(.hour, from: date) >= 17 || calendar.component(.hour, from: date) < 4
            ? "last night" : "yesterday"
        case 2 ..< 7: return String(TesseraDay.weekdayName(of: house.day(of: date), calendar: calendar).prefix(3))
        default: return format(date, "MMM d", calendar: calendar)
        }
    }

    /// The drawn page: "p 142 of 612", or "p 142" when the count is unknown (the label role draws it uppercase).
    static func page(_ page: Int, of pages: Int?) -> String {
        pages.map { "p \(page) of \($0)" } ?? "p \(page)"
    }

    /// The spoken page: "page 142 of 612" (G307); "P 142" is never spoken.
    static func spokenPage(_ page: Int, of pages: Int?) -> String {
        pages.map { "page \(page) of \($0)" } ?? "page \(page)"
    }

    /// Where a set-aside book stopped: "at p 88".
    static func setAside(at page: Int) -> String {
        "at p \(page)"
    }

    /// When a finished book was finished: "Oct 3".
    static func finished(_ date: Date, calendar: Calendar = .current) -> String {
        format(date, "MMM d", calendar: calendar)
    }

    /// The book page's context line: "p 142 of 612, started 9 days ago" (the US-dates line, amendment 3).
    static func bookContext(page: Int, pages: Int?, started: Date?, now: Date,
                            calendar: Calendar = .current) -> String
    {
        let drawn = self.page(page, of: pages)
        guard let started else { return drawn }
        return "\(drawn), \(startedWords(started, now: now, calendar: calendar))"
    }

    /// The spoken form of the same line: "page 142 of 612, started 9 days ago".
    static func spokenBookContext(page: Int, pages: Int?, started: Date?, now: Date,
                                  calendar: Calendar = .current) -> String
    {
        let spoken = spokenPage(page, of: pages)
        guard let started else { return spoken }
        return "\(spoken), \(startedWords(started, now: now, calendar: calendar))"
    }

    static func startedWords(_ started: Date, now: Date, calendar: Calendar = .current) -> String {
        let house = TesseraDay(calendar: calendar)
        let days = calendar.dateComponents([.day], from: house.day(of: started), to: house.day(of: now)).day ?? 0
        switch days {
        case ..<1: return "started today"
        case 1: return "started yesterday"
        default: return "started \(days) days ago"
        }
    }

    /// The resume line on Now (the evening slot, 7 pm to 11 pm): Core's next step, "Dune, p 142". A private book
    /// reads "Private book, p 142".
    static func resumeLine(title: String, page: Int, isPrivate: Bool) -> String {
        "\(isPrivate ? ObjectPrivacy.bookLabel : title), p \(page)"
    }

    /// VoiceOver for the same line: "Resume Dune, page 142".
    static func spokenResume(title: String, page: Int, isPrivate: Bool) -> String {
        "Resume \(isPrivate ? ObjectPrivacy.bookLabel : title), page \(page)"
    }

    /// Announced once when a resumed book opens (G311): "Dune, page 142".
    static func arrival(title: String, page: Int) -> String {
        "\(title), page \(page)"
    }

    /// The Finish key's only VoiceOver form (G304): "Finish Dune".
    static func finishName(_ title: String) -> String {
        "Finish \(title)"
    }

    /// The empty shelf's Tess line.
    static let emptyTess = "Tell me what you're reading. Try: reading Dune."
    static let prompt = "reading Dune"
    static let reviewPrompt = "One line on it?"

    private static func format(_ date: Date, _ pattern: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

/// The shelf's writing line: "reading Dune" queues it and starts it; "read Dune", "queue Dune" or a bare title
/// queues it. Core's grammar (Reading phrases) owns the ask bar; this reads only this page.
enum ReadingCapture {
    enum Intent: Equatable {
        case start(String)
        case queue(String)
    }

    static func intent(_ text: String) -> Intent? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let lead = trimmed.firstMatch(of: /^(?i:reading|start reading|started)\s+/) {
            let title = String(trimmed[lead.range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return title.isEmpty ? nil : .start(title)
        }
        if let lead = trimmed.firstMatch(of: /^(?i:read|queue|to read)\s+/) {
            let title = String(trimmed[lead.range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return title.isEmpty ? nil : .queue(title)
        }
        return .queue(trimmed)
    }
}
