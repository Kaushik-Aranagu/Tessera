import CoreGraphics
import Foundation

/// How her words arrive in the conversation (sheet 215 rev 16): one at a time, 62 ms per word and 40 ms more after
/// punctuation, each settling with a 3 pt rise over 180 ms. No fade, and no letter flips (those stay on Home's top
/// lines). Pure, so the timings are tested; under Reduce Motion the whole line is simply there.
enum TessWords {
    static let perWord: TimeInterval = 0.062
    static let afterPunctuation: TimeInterval = 0.040
    static let rise: CGFloat = 3
    static let riseSeconds: TimeInterval = 0.180

    struct Arrival: Equatable {
        let word: String
        /// Seconds after the line begins that this word starts to settle.
        let delay: TimeInterval
    }

    /// The words of a line, each with when it arrives.
    static func arrivals(_ line: String) -> [Arrival] {
        var result: [Arrival] = []
        var delay = 0.0
        for word in line.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
            result.append(Arrival(word: word, delay: delay))
            delay += perWord
            if let last = word.last, ".,?!:;".contains(last) {
                delay += afterPunctuation
            }
        }
        return result
    }

    /// When the last word has settled.
    static func total(_ line: String) -> TimeInterval {
        (arrivals(line).last?.delay ?? 0) + riseSeconds
    }

    /// 0 before a word's turn, 1 once settled: ease-out over the rise.
    static func progress(elapsed: TimeInterval, delay: TimeInterval) -> Double {
        let unit = min(max((elapsed - delay) / riseSeconds, 0), 1)
        return 1 - pow(1 - unit, 3)
    }

    /// The word's vertical offset: 3 pt down at the start, 0 when settled.
    static func offset(elapsed: TimeInterval, delay: TimeInterval) -> CGFloat {
        rise * (1 - CGFloat(progress(elapsed: elapsed, delay: delay)))
    }

    /// Whether a word has begun to show (a word not yet due takes no room's worth of motion, it is simply absent).
    static func isShown(elapsed: TimeInterval, delay: TimeInterval) -> Bool {
        elapsed >= delay
    }
}

/// The time markers in the conversation (sheet 215 rev 10 and 16): clock time only, after a gap of 20 minutes or more;
/// on opening after such a gap the newest marker reads "Now, 1:31 pm".
enum TessTimeMarker {
    static let gap: TimeInterval = 20 * 60

    /// For each turn time (oldest first), the marker that goes above it, or nil. The first turn has none above it
    /// unless it is the only thing there; a marker shows only after a gap.
    static func markers(for times: [Date], calendar: Calendar = .current, locale: Locale = .current) -> [String?] {
        times.enumerated().map { index, time in
            guard index > 0, time.timeIntervalSince(times[index - 1]) >= gap else { return nil }
            return clock(time, calendar: calendar, locale: locale)
        }
    }

    /// "Now, 1:31 pm" when the layer opens and her last turn was 20 minutes or more ago; else nil.
    static func openingMarker(last: Date?, now: Date, calendar: Calendar = .current, locale: Locale = .current)
        -> String?
    {
        guard let last, now.timeIntervalSince(last) >= gap else { return nil }
        return "Now, \(clock(now, calendar: calendar, locale: locale))"
    }

    static func clock(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar,
                                     timeZone: calendar.timeZone)
        style.locale = locale
        return date.formatted(style).replacingOccurrences(of: "\u{202F}", with: " ").lowercased()
    }
}

/// The echo (sheet 215 rev 10, 16): when her new line names something named higher up, the latest earlier mention
/// brightens, ink2 to ink. Only shown labels are ever compared: a private item never shows its real name.
enum TessEcho {
    /// The index of the latest earlier line that contains one of `names` (case-insensitive, whole words), or nil.
    static func earlierMention(of names: [String], in earlier: [String]) -> (line: Int, name: String)? {
        for index in earlier.indices.reversed() {
            for name in names where mentions(name, in: earlier[index]) {
                return (index, name)
            }
        }
        return nil
    }

    static func mentions(_ name: String, in line: String) -> Bool {
        guard !name.isEmpty else { return false }
        return line.range(of: "\\b\(NSRegularExpression.escapedPattern(for: name))\\b",
                          options: [.regularExpression, .caseInsensitive]) != nil
    }
}
