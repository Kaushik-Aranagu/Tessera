import Foundation
import TesseraCore

/// The recipe laid on time: each step has a start and an end in clock minutes, on one lane or, with "Steps run in
/// parallel" on, two (docs/product/parallel-steps-acceptance.md PS1 to PS10; cook-mode-acceptance.md rulings 1 to 5).
/// A pure value so every figure on the clock page is derived and testable; nothing here counts.
struct CookClockPlan: Equatable {
    struct Step: Equatable, Identifiable {
        let index: Int
        let text: String
        /// Minutes the step runs: the sum of its durations' lower bounds, 2 when it has none (the backlog's constant).
        let minutes: Double
        /// A duration is written in the step's own words (ruling 1); only these own a timer.
        let isTimed: Bool
        /// Over 3 hours (marinate, rise): drawn at a fixed 10 minutes, no countdown, no timer.
        let isWait: Bool
        let start: Double
        let end: Double
        /// 0 is the host's lane, 1 the guest's.
        let lane: Int
        /// The cook's own written minutes for a wait ("12 HR"), nil otherwise.
        let waitMinutes: Double?

        var id: Int {
            index
        }

        /// The timer's own length in minutes (30 s is 0.5, though it is drawn at the 2-minute floor); nil for an
        /// untimed step and for a wait.
        let timer: Double?

        var timerMinutes: Double? {
            timer
        }
    }

    let steps: [Step]
    let total: Double
    /// Whether any step shares the clock with another (a second lane is drawn between them).
    var hasOverlap: Bool {
        steps.contains { $0.lane == 1 }
    }

    static let untimedMinutes = 2.0
    static let waitOver = 180.0
    static let waitWidth = 10.0
    static let minHost = 5.0
    /// At most two live tracks (PS7).
    static let maxTracks = 2

    /// The cue words that open a lane. Cue words alone do it (Open 1), and only beside a host of 5 minutes or more.
    static func isCued(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.hasPrefix("meanwhile") || lower.contains("meanwhile,") || lower.hasPrefix("while ")
            || lower.contains(" while the ") || lower.hasPrefix("at the same time")
    }

    /// Lays `steps` (text and the lower bounds of each duration) on the clock. With `lanes` off every step starts
    /// where the one before ended, exactly today's single lane.
    static func make(_ inputs: [(text: String, timers: [ClosedRange<Double>])], lanes: Bool) -> CookClockPlan {
        var placed: [Step] = []
        for (index, input) in inputs.enumerated() {
            var lower = input.timers.reduce(0) { $0 + $1.lowerBound }
            // "3 min a side", "per side", "each side" double the first duration (the fixture's rule).
            if let first = input.timers.first, input.text.lowercased().contains(/\b(a|per|each) side\b/) {
                lower += first.lowerBound
            }
            let timed = !input.timers.isEmpty && lower > 0
            let wait = timed && lower > waitOver
            let width = wait ? waitWidth : (timed ? max(lower, untimedMinutes) : untimedMinutes)
            let join = placed.map(\.end).max() ?? 0
            var start = join
            var lane = 0
            if lanes, isCued(input.text), let host = placed.last(where: { $0.lane == 0 }),
               host.isTimed, !host.isWait, host.minutes >= minHost, host.end > host.start
            {
                // Guest: opens beside the host at the host's start. A third candidate waits for the earliest end
                // of the two live tracks and takes the freed lane (PS7).
                let live = placed.filter { $0.end > host.start && $0.start <= host.start }
                let guestLane = placed.filter { $0.lane == 1 && $0.end > host.start }
                if guestLane.isEmpty, live.count < maxTracks {
                    start = host.start
                    lane = 1
                } else if let laneEnd = guestLane.map(\.end).max(), live.count >= maxTracks {
                    start = min(laneEnd, host.end)
                    lane = 1
                }
            }
            placed.append(Step(index: index, text: input.text, minutes: width, isTimed: timed, isWait: wait,
                               start: start, end: start + width, lane: lane, waitMinutes: wait ? lower : nil,
                               timer: timed && !wait ? lower : nil))
        }
        return CookClockPlan(steps: placed, total: placed.map(\.end).max() ?? 0)
    }

    /// Minutes still ahead from the bead: what is left of the lead step (its timer, else the whole step) plus
    /// everything after the join of its own end. The join, never a sum of the lanes (PS3, Open 5).
    func minutesLeft(atStep index: Int, timerRemaining: TimeInterval?) -> Double {
        guard steps.indices.contains(index) else { return 0 }
        let step = steps[index]
        // A fixed-width wait is not running time: it never counts in the figure (D3: 167, not 177).
        let waits = steps.filter { $0.isWait && $0.start >= step.start }.count
        let waitTime = Double(waits) * Self.waitWidth
        let ahead = max(0, total - step.end)
        if let timerRemaining {
            return max(0, timerRemaining / 60 + ahead - waitTime)
        }
        return max(0, total - step.start - waitTime)
    }

    /// The figure the key row shows: whole minutes, rounded up, so it changes when the remainder crosses k x 60 s
    /// (CCK item 56), "33 MIN LEFT".
    static func figure(minutesLeft: Double) -> Int {
        Int(minutesLeft.rounded(.up))
    }

    /// The next minute boundary of `endsAt` after `now`: the key figure flips there, never on a 60 s period from
    /// when the view appeared (item 56, `minuteFigureFiresAtEndsAtBoundary`).
    static func nextBoundary(endsAt: Date, after now: Date) -> Date? {
        let remaining = endsAt.timeIntervalSince(now)
        guard remaining > 0 else { return nil }
        let whole = (remaining / 60).rounded(.down)
        // Exactly on a boundary: the next one is a minute on.
        let steps = remaining.truncatingRemainder(dividingBy: 60) == 0 ? whole - 1 : whole
        return endsAt.addingTimeInterval(-max(0, steps) * 60)
    }
}

/// What a step's timer is called: the verb nearest its duration ("Roast" for "Add the chicken and roast 20 min"),
/// else "Step 3" (cook-mode-acceptance.md ASSUMED 2, ruled Oct 16 after the day-one walk).
enum CookTimerLabel {
    private static let verbs: Set<String> = [
        "bake", "boil", "braise", "broil", "chill", "cook", "fry", "grill", "marinate", "microwave", "poach", "proof",
        "rest", "rise", "roast", "saute", "sauté", "sear", "simmer", "soak", "steam", "steep", "stew", "toast",
        "bring", "heat", "reduce", "freeze", "cool", "set", "stir", "knead", "whisk", "blend",
    ]

    static func label(for text: String, stepIndex: Int) -> String {
        // Words before the first digit, nearest to it first.
        let head = text.prefix { !$0.isNumber }
        let words = head.split { !$0.isLetter && $0 != "é" }.map { $0.lowercased() }
        if let verb = words.reversed().first(where: { verbs.contains($0) }) {
            return verb.prefix(1).uppercased() + verb.dropFirst()
        }
        return "Step \(stepIndex + 1)"
    }
}

/// US units on the clock page: ingredients read as written (cups, oz, lb, °F) and flip to metric on a tap; times read
/// in the 12-hour house form. Nothing converts on its own (us-shop-acceptance.md K7.5).
enum CookUnits {
    /// "ends 6:52 pm" for the timer's spoken value.
    static func endsLine(_ endsAt: Date, calendar: Calendar = .current) -> String {
        "ends \(HouseTime.clock(endsAt, calendar: calendar))"
    }

    /// "425°F" stays as written; a step written in Celsius ("220°C") is shown with its Fahrenheit beside it, since
    /// the oven is in °F. Returns the text unchanged when there is no temperature.
    static func withFahrenheit(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"(\d{2,3})\s?°\s?C\b"#) else { return text }
        var result = text
        let whole = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: whole).reversed() {
            guard let all = Range(match.range, in: result), let digits = Range(match.range(at: 1), in: result),
                  let celsius = Double(result[digits]) else { continue }
            // Ovens move in 5s: 220°C is 430°F, not 428.
            let fahrenheit = Int(((celsius * 9 / 5 + 32) / 5).rounded()) * 5
            result.insert(contentsOf: " (\(fahrenheit)°F)", at: all.upperBound)
        }
        return result
    }
}
