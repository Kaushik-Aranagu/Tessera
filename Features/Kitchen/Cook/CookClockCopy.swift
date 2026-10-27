import Foundation

/// The clock page's own words and its derived schedule. Pure, so every figure is tested without a view.
enum CookClockCopy {
    /// "33 min left", "1 hr 5 min left" (shown in label caps by its role).
    static func keyFigure(minutes: Int) -> String {
        guard minutes >= 60 else { return "\(max(minutes, 0)) min left" }
        let (hours, rest) = (minutes / 60, minutes % 60)
        return rest == 0 ? "\(hours) hr left" : "\(hours) hr \(rest) min left"
    }

    /// The spoken key value: "33 minutes left", "under a minute left".
    static func spokenLeft(minutes: Int, seconds: TimeInterval? = nil) -> String {
        if let seconds, seconds < 60 {
            return seconds > 0 ? "under a minute left" : "done"
        }
        return CookModeCopy.duration(Double(minutes) * 60) + " left"
    }

    /// A timer's spoken value, changing only at whole-minute boundaries (G233): "8 minutes left, ends 6:52 pm",
    /// "under a minute left", then "done". Never per second.
    static func spokenTimer(remaining: TimeInterval, endsAt: Date) -> String {
        if remaining <= 0 {
            return "Done"
        }
        if remaining < 60 {
            return "Under a minute left"
        }
        return "\(CookModeCopy.duration(remaining)) left, \(CookUnits.endsLine(endsAt))"
    }

    /// The other track's line under the key row: "Meanwhile, rice, step 2 of 4, 9 minutes left." (sheet 114, PL-S3).
    static func meanwhile(step: Int, of count: Int, text: String, left: TimeInterval?) -> String {
        let time = left.map { ", \(CookModeCopy.duration($0)) left" } ?? ""
        return "Meanwhile, step \(step + 1) of \(count)\(time). \(text)"
    }

    /// The label above a timer line: the plain label, with " (2)" never added; stays "Timer" when walled.
    static func line(_ label: String) -> String {
        label.isEmpty ? "Timer" : label
    }

    static let listen = "Listen"
    static let listening = "Listening"
    static let listeningLabel = "Listening for next, back and timer"
    static let noMic = "Tap the page instead"
    static let ingredients = "Ingredients"
    static let steps = "Steps"
    static let timers = "Timers"
    static let stop = "Stop"
    static let more = "5 more minutes"
    static let startTimerHint = "Starts a timer"
    static let swipeHint = "Swipe up for the next step, down for the one before"
}

/// When the clock page redraws under Reduce Motion and Low Power: only at the whole-minute boundaries of each timer's
/// `endsAt`, and every 10 s in the last minute so a short timer still moves (CCK item 56, ruled G220). Normal motion
/// draws at 30 fps and needs no list.
enum CookClockTimeline {
    static func dates(endsAt: [Date], from now: Date, cap: Int = 240) -> [Date] {
        var all: Set<Date> = [now]
        for end in endsAt where end > now {
            let remaining = end.timeIntervalSince(now)
            var wholeMinutes = Int((remaining / 60).rounded(.down))
            while wholeMinutes >= 1, all.count < cap {
                let boundary = end.addingTimeInterval(-Double(wholeMinutes) * 60)
                if boundary > now {
                    all.insert(boundary)
                }
                wholeMinutes -= 1
            }
            for tail in stride(from: 50.0, through: 10.0, by: -10.0) {
                let step = end.addingTimeInterval(-tail)
                if step > now {
                    all.insert(step)
                }
            }
            all.insert(end)
        }
        return all.sorted()
    }
}
