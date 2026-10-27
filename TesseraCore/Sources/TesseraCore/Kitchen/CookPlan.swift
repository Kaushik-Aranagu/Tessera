import Foundation

/// Several dishes, one clock, one pair of hands (multi-dish Cook, Part A, engine only). Pure: no store, no clock, no
/// network. Each dish arrives as its local timeline (segments in seconds from the dish's own start, from the one
/// start-minute function), and the plan places the dishes on the real clock so they finish together at the serve time,
/// moving a dish earlier only when two hands-on stretches would collide. Sentences are fixed templates over numbers
/// and names it is handed; a private dish's name is already "Private recipe" when it gets here.
public struct CookPlan: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        /// Hands on the food. Every step that is not a long timed wait.
        case hands
        /// A timed step of five minutes or more: the dish looks after itself.
        case wait
    }

    /// A stretch of one dish's cook, in seconds from that dish's own start.
    public struct Local: Sendable, Equatable {
        public let step: Int
        public let track: Int
        public let start: TimeInterval
        public let end: TimeInterval
        public let kind: Kind

        public init(step: Int, track: Int = 0, start: TimeInterval, end: TimeInterval, kind: Kind) {
            self.step = step
            self.track = track
            self.start = start
            self.end = end
            self.kind = kind
        }
    }

    /// How a dish wants to end. Off until the person adds one.
    public enum Finish: Sendable, Equatable {
        /// The plan's hold limit applies.
        case standard
        /// "Holds warm 15": this dish may wait that long before it is flagged.
        case holdsWarm(minutes: Int)
        /// "Last, no waiting": placed first and never moved or held; other dishes fit around it.
        case last
    }

    public struct Dish: Sendable, Equatable {
        public let id: UUID
        public let name: String
        public let order: Int
        public let local: [Local]
        public let finish: Finish
        /// Set when the cook of this dish has begun: its start is fixed on the clock and it never moves.
        public let startedAt: Date?
        /// Candidate placements to skip ("Start later" tries the next fit).
        public let skippedFits: Int
        /// Overrides the plural guess for the name ("Beans start", "Rice starts").
        public let isPlural: Bool?

        public init(id: UUID = UUID(), name: String, order: Int, local: [Local], finish: Finish = .standard,
                    startedAt: Date? = nil, skippedFits: Int = 0, isPlural: Bool? = nil)
        {
            self.id = id
            self.name = name
            self.order = order
            self.local = local
            self.finish = finish
            self.startedAt = startedAt
            self.skippedFits = skippedFits
            self.isPlural = isPlural
        }

        /// L(d): the dish's length, the end of its last segment.
        public var length: TimeInterval {
            local.map(\.end).max() ?? 0
        }
    }

    public struct Seg: Sendable, Equatable {
        public let dish: UUID
        public let step: Int
        public let track: Int
        public let start: Date
        public let end: Date
        public let kind: Kind

        /// The timer id of a timed step: session.dish.step is built by the caller from these.
        public func shifted(by seconds: TimeInterval) -> Seg {
            Seg(dish: dish, step: step, track: track, start: start.addingTimeInterval(seconds),
                end: end.addingTimeInterval(seconds), kind: kind)
        }
    }

    public struct Placement: Sendable, Equatable {
        public let dish: Dish
        public let start: Date
        public let end: Date
        /// Seconds moved earlier so hands are free: the dish then waits this long before serving.
        public let heldSec: TimeInterval
        /// Held longer than it is allowed to wait: the plan is kept and this is flagged.
        public let overHold: Bool
        public let segs: [Seg]
    }

    public static let holdMaxDefault: TimeInterval = 900
    public static let waitFloor: TimeInterval = 300

    public let placements: [Placement]
    /// The serve time asked for, or the one the plan implies.
    public let serveAt: Date
    /// When the plan runs past `serveAt` (a slow step, a late start): the time it will serve about.
    public let projectedServe: Date?
    public let now: Date

    public var segs: [Seg] {
        placements.flatMap(\.segs).sorted { $0.start < $1.start }
    }

    public var isLate: Bool {
        projectedServe != nil
    }

    /// The same plan, every stretch and the serve time moved by `seconds`: a pause of that length freezes the clock
    /// for both dishes alike.
    public func shifted(by seconds: TimeInterval) -> CookPlan {
        CookPlan(placements: placements.map { place in
            Placement(dish: place.dish, start: place.start.addingTimeInterval(seconds),
                      end: place.end.addingTimeInterval(seconds), heldSec: place.heldSec, overHold: place.overHold,
                      segs: place.segs.map { $0.shifted(by: seconds) })
        }, serveAt: serveAt.addingTimeInterval(seconds),
        projectedServe: projectedServe.map { $0.addingTimeInterval(seconds) },
        now: now.addingTimeInterval(seconds))
    }

    // MARK: Planning

    /// Builds the plan. Without `serveAt` the serve time is `now` plus the longest dish. Dishes that are already
    /// running keep their start; the rest are anchored backward from the serve time, longest first, and a dish whose
    /// hands collide with the ones already placed moves earlier by the smallest amount that clears them.
    public static func make(dishes: [Dish], serveAt: Date?, now: Date, holdMax: TimeInterval = holdMaxDefault)
        -> CookPlan
    {
        let longest = dishes.map(\.length).max() ?? 0
        // A serve time in the past is ignored.
        let asked = serveAt.flatMap { $0 > now ? $0 : nil }
        let serve = asked ?? now.addingTimeInterval(longest)

        var placed: [Placement] = []
        var occupied: [DateInterval] = []

        func place(_ dish: Dish, start: Date, held: TimeInterval) {
            let limit = limit(for: dish, holdMax: holdMax)
            let segs = dish.local.map { local in
                Seg(dish: dish.id, step: local.step, track: local.track,
                    start: start.addingTimeInterval(local.start), end: start.addingTimeInterval(local.end),
                    kind: local.kind)
            }
            placed.append(Placement(dish: dish, start: start, end: start.addingTimeInterval(dish.length),
                                    heldSec: held, overHold: held > limit, segs: segs))
            occupied += segs.filter { $0.kind == .hands && $0.end > $0.start }
                .map { DateInterval(start: $0.start, end: $0.end) }
        }

        // 1. Running dishes never move.
        let running = dishes.filter { $0.startedAt != nil }
        for dish in running.sorted(by: { $0.order < $1.order }) {
            place(dish, start: dish.startedAt ?? now, held: 0)
        }
        // 2. "Last, no waiting" dishes next, then the rest by length, longest first (ties: lower order first).
        let waiting = dishes.filter { $0.startedAt == nil }.sorted { lhs, rhs in
            let lhsLast = lhs.finish == .last, rhsLast = rhs.finish == .last
            if lhsLast != rhsLast {
                return lhsLast
            }
            if lhs.length != rhs.length {
                return lhs.length > rhs.length
            }
            return lhs.order < rhs.order
        }
        let criticalFirst = running.isEmpty
        for (index, dish) in waiting.enumerated() {
            let anchor = serve.addingTimeInterval(-dish.length)
            // The critical path (the first one placed with nothing running) never moves earlier, and a "last" dish
            // is never held.
            let pinned = (criticalFirst && index == 0) || dish.finish == .last
            let delta = pinned ? 0 : fit(dish, anchor: anchor, occupied: occupied, skipping: dish.skippedFits)
            var start = anchor.addingTimeInterval(-delta)
            var held = delta
            // Nothing starts in the past: a dish that would is placed at the first moment from now when its hands
            // are clear of every dish already placed (a late add is checked against the running dishes' hands).
            if start < now {
                start = laterFit(dish, notBefore: now, occupied: occupied)
                held = 0
            }
            place(dish, start: start, held: held)
        }

        let result = placed.sorted { $0.dish.order < $1.dish.order }
        let finish = result.map(\.end).max() ?? serve
        let projected = finish > serve ? finish : nil
        return CookPlan(placements: result, serveAt: serve, projectedServe: projected, now: now)
    }

    static func limit(for dish: Dish, holdMax: TimeInterval) -> TimeInterval {
        switch dish.finish {
        case .standard: holdMax
        case let .holdsWarm(minutes): TimeInterval(minutes) * 60
        case .last: 0
        }
    }

    /// The first start at or after `notBefore` with none of the dish's hands over an occupied stretch. Candidates are
    /// `notBefore` itself and every start that makes a stretch begin where an occupied one ends, or end where one
    /// begins.
    static func laterFit(_ dish: Dish, notBefore: Date, occupied: [DateInterval]) -> Date {
        let hands = dish.local.filter { $0.kind == .hands && $0.end > $0.start }
        func clear(_ start: Date) -> Bool {
            hands.allSatisfy { local in
                let from = start.addingTimeInterval(local.start), to = start.addingTimeInterval(local.end)
                return occupied.allSatisfy { to <= $0.start || from >= $0.end }
            }
        }
        var candidates: Set<Date> = [notBefore]
        for local in hands {
            for block in occupied {
                for start in [block.end.addingTimeInterval(-local.start), block.start.addingTimeInterval(-local.end)]
                    where start >= notBefore
                {
                    candidates.insert(start)
                }
            }
        }
        return candidates.sorted().first(where: clear) ?? notBefore
    }

    /// The smallest move earlier (seconds, 0 or more) with none of the dish's hands over an occupied stretch.
    /// Candidates are 0 and every move that makes one of its stretches end where an occupied one starts, or start
    /// where one ends; the first that fits wins, `skipping` of them first when "Start later" asked for the next.
    static func fit(_ dish: Dish, anchor: Date, occupied: [DateInterval], skipping: Int) -> TimeInterval {
        let hands = dish.local.filter { $0.kind == .hands && $0.end > $0.start }
        func clear(_ delta: TimeInterval) -> Bool {
            hands.allSatisfy { local in
                let start = anchor.addingTimeInterval(local.start - delta)
                let end = anchor.addingTimeInterval(local.end - delta)
                return occupied.allSatisfy { end <= $0.start || start >= $0.end }
            }
        }
        var candidates: Set<TimeInterval> = [0]
        for local in hands {
            let start = anchor.addingTimeInterval(local.start)
            let end = anchor.addingTimeInterval(local.end)
            for block in occupied {
                let abutBefore = end.timeIntervalSince(block.start)
                let abutAfter = start.timeIntervalSince(block.end)
                for delta in [abutBefore, abutAfter] where delta >= 0 {
                    candidates.insert(delta)
                }
            }
        }
        let fits = candidates.sorted().filter(clear)
        if fits.isEmpty {
            // Hands never clear (cannot happen with finite stretches, but never crash): no move.
            return 0
        }
        return fits[min(skipping, fits.count - 1)]
    }

    // MARK: Sentences

    /// "A and B", "A, B and C", "A, B and 2 more".
    public static func names(_ names: [String]) -> String {
        switch names.count {
        case 0: ""
        case 1: names[0]
        case 2: "\(names[0]) and \(names[1])"
        case 3: "\(names[0]), \(names[1]) and \(names[2])"
        default: "\(names[0]), \(names[1]) and \(names.count - 2) more"
        }
    }

    /// "Tacos and rice tonight, start at 6:05." The first start is the earliest dish's.
    public func landing(calendar: Calendar = .current) -> String {
        guard !placements.isEmpty else { return "Nothing planned for tonight" }
        let ordered = placements.sorted { $0.dish.order < $1.dish.order }.map(\.dish.name)
        let start = placements.map(\.start).min() ?? serveAt
        return "\(Self.names(ordered)) tonight, start at \(HouseTime.clock(start, calendar: calendar))"
    }

    /// "Cooking A and B, 12 min left."
    public func running(minutesLeft: Int?) -> String {
        let ordered = placements.sorted { $0.dish.order < $1.dish.order }.map(\.dish.name)
        var text = "Cooking \(Self.names(ordered))"
        if let minutesLeft, minutesLeft > 0 {
            text += ", \(minutesLeft) min left"
        }
        return text
    }

    /// "Serve at 7:00. Start Chicken at 6:17." The dish to start first is the earliest start.
    public func serveLine(calendar: Calendar = .current) -> String {
        guard let first = placements.min(by: { $0.start < $1.start }) else { return "" }
        return "Serve at \(HouseTime.clock(serveAt, calendar: calendar)). Start \(first.dish.name) at \(HouseTime.clock(first.start, calendar: calendar))"
    }

    /// One line for each dish that has to wait or move, in the order the dishes were added.
    public func notes() -> [String] {
        placements.sorted { $0.dish.order < $1.dish.order }.flatMap { place -> [String] in
            guard place.heldSec > 0 else { return [] }
            let minutes = Int((place.heldSec / 60).rounded())
            let name = place.dish.name
            if place.overHold {
                return ["\(name) would wait \(minutes) min"]
            }
            let plural = Self.isPlural(place.dish)
            return ["\(name) will wait \(minutes) min",
                    "\(name) \(plural ? "start" : "starts") \(minutes) min early so your hands are free"]
        }
    }

    /// "Serving about 7:02." only when the plan runs late.
    public func lateLine(calendar: Calendar = .current) -> String? {
        projectedServe.map { "Serving about \(HouseTime.clock($0, calendar: calendar))" }
    }

    /// An explicit flag on the dish wins over the house rule.
    static func isPlural(_ dish: Dish) -> Bool {
        dish.isPlural ?? HouseWords.isPlural(dish.name)
    }
}
