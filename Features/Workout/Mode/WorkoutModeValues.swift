import Foundation
import TesseraCore

/// Everything the mode's places show, as plain strings and numbers computed from the state (sheet 325). The views draw
/// these into fixed slots and never compute a word of their own, so a revision of the visuals does not touch the
/// words. No line ends in a full stop.
extension WorkoutModeState {
    /// Epley: weight × (1 + reps / 30). Nil without a weight or reps.
    static func epley(weight: Double, reps: Int) -> Double? {
        guard weight > 0, reps > 0 else { return nil }
        return weight * (1 + Double(reps) / 30)
    }

    /// The estimated max of the set you are on (or the last one done on the lift).
    var estimatedMax: Double? {
        if let set = currentSet {
            return Self.epley(weight: set.weight, reps: set.reps)
        }
        return current.sets.last { $0.done != nil }?.done.flatMap { Self.epley(weight: $0.weight, reps: $0.reps) }
    }

    /// Last time's same set: the set at this position, or the last set done last time.
    func lastTimeSet(of lift: Lift, at index: Int) -> LiftHistory.Set? {
        guard !lift.history.lastTime.isEmpty else { return nil }
        return lift.history.lastTime.indices.contains(index) ? lift.history.lastTime[index] : lift.history.lastTime.last
    }

    // MARK: Scoreboard

    /// The sentence place as a scoreboard: an uppercase header with a quiet fact on its right edge, the main thing at
    /// arm's length, and two lines of information.
    struct Scoreboard: Equatable {
        var header: String
        var trailing: String
        /// The numerals: the weight in a set, the countdown in a rest.
        var main: String
        /// The unit at a third of the numerals ("lb"); empty during a rest.
        var unit: String
        /// "× 5"; empty during a rest.
        var multiplier: String
        var info1: String
        var info2: String
        var isRest: Bool
    }

    func scoreboard(at now: Date) -> Scoreboard {
        if isDone {
            return finishedScoreboard(at: now)
        }
        if let left = restRemaining(at: now), case let .rest(_, _, restLift) = phase {
            let next = nextUp(after: restLift)
            return Scoreboard(
                header: "REST", trailing: next.map { "NEXT \($0.lift.name.uppercased())" } ?? "",
                main: Format.duration(left.rounded(.up)), unit: "", multiplier: "",
                info1: next
                    .map {
                        "Next, \($0.lift.name.lowercased()), \(Self.weightText($0.set.weight, unit)) × \($0.set.reps)"
                    }
                    ?? "Last set done",
                info2: "Tap to start now", isRest: true
            )
        }
        let lift = current
        if let warm = lift.warmUp, lift.nextIndex != nil {
            return Scoreboard(
                header: "WARM UP", trailing: "", main: "\(warm.minutes)", unit: "min", multiplier: "",
                info1: warm.name, info2: warm.note ?? "", isRest: false
            )
        }
        guard let index = lift.nextIndex else {
            return Scoreboard(
                header: lift.name.uppercased(),
                trailing: "",
                main: "0",
                unit: unit.symbol,
                multiplier: "",
                info1: "All sets done",
                info2: "",
                isRest: false
            )
        }
        let set = lift.sets[index]
        let best = lift.history.best.map { "BEST \(PlateLoad.number($0.weight))" } ?? ""
        return Scoreboard(
            header: "SET \(index + 1) OF \(lift.sets.count)", trailing: best,
            main: PlateLoad.number(set.weight), unit: unit.symbol, multiplier: "× \(set.reps)",
            info1: "\(lift.name), \(set.reps) \(set.reps == 1 ? "rep" : "reps")",
            info2: lastTimeLine(lift: lift, index: index, set: set), isRest: false
        )
    }

    private func finishedScoreboard(at now: Date) -> Scoreboard {
        let minutes = max(Int((elapsed(at: now) / 60).rounded()), 0)
        return Scoreboard(
            header: "FINISHED", trailing: "", main: "\(setsDone)", unit: setsDone == 1 ? "set" : "sets", multiplier: "",
            info1: "\(minutes) min, about \(Self.volumeText(volume)) \(unit.symbol) moved", info2: "", isRest: false
        )
    }

    /// "Last time 185 × 5, now +5 lb", "Last time 185 × 5, now the same", "First time with this lift".
    func lastTimeLine(lift: Lift, index: Int, set: PlannedSet) -> String {
        guard let last = lastTimeSet(of: lift, at: index) else { return "First time with this lift" }
        let delta = set.weight - last.weight
        let now = if abs(delta) < 0.001 {
            "now the same"
        } else {
            "now \(delta > 0 ? "+" : "-")\(PlateLoad.number(abs(delta))) \(unit.symbol)"
        }
        return "Last time \(PlateLoad.number(last.weight)) × \(last.reps), \(now)"
    }

    /// The next set to do after a rest: the same lift while it has sets, else the next lift with sets left.
    func nextUp(after liftIndex: Int) -> (lift: Lift, set: PlannedSet)? {
        if let index = lifts[liftIndex].nextIndex {
            return (lifts[liftIndex], lifts[liftIndex].sets[index])
        }
        let order = Array(lifts.indices)
        let pick = (order.drop { $0 <= liftIndex } + order.prefix { $0 <= liftIndex }).first { !lifts[$0].isComplete }
        return pick.flatMap { i in lifts[i].nextIndex.map { (lifts[i], lifts[i].sets[$0]) } }
    }

    // MARK: Band

    /// The band is the clock: time in and when it ends.
    struct Band: Equatable {
        /// "12 min in"
        var timeIn: String
        /// "3 of 5 lifts to go"
        var lifts: String
        /// "0:12" (the clock, whole minutes and seconds)
        var clock: String
        /// "Done about 7:22"; empty when finished.
        var doneAbout: String
    }

    func band(at now: Date) -> Band {
        let seconds = elapsed(at: now)
        let about = doneAbout(at: now).map { isDone ? "" : "Done about \(Format.clock(Self.roundedToFive($0)))" } ?? ""
        return Band(
            timeIn: "\(Int(seconds / 60)) min in",
            lifts: isDone ? "All \(lifts.count) lifts done" : "\(liftsLeft) of \(lifts.count) lifts to go",
            clock: Format.duration(seconds), doneAbout: about
        )
    }

    /// "Done about 7:22" is an estimate: it reads on the nearest five minutes so it does not shuffle every set.
    static func roundedToFive(_ date: Date) -> Date {
        let step = 300.0
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / step).rounded() * step)
    }

    // MARK: Board (the keystone)

    struct SetChip: Equatable, Identifiable {
        enum State: Equatable { case done, current, left }
        var id: Int
        /// "185×5"
        var text: String
        var state: State
    }

    struct Board: Equatable {
        var liftName: String
        var chips: [SetChip]
        var equipment: Equipment
        /// The bar's plates for the set you are on (the next set in a rest); nil for a stack.
        var plates: PlateLoad?
        /// The lifts along the bottom, ticked when done.
        var lifts: [(name: String, done: Bool, focused: Bool)]
        /// During a rest: "then bench 185, each side 45 + 25".
        var loadNext: String?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.liftName == rhs.liftName && lhs.chips == rhs.chips && lhs.equipment == rhs.equipment
                && lhs.plates == rhs.plates && lhs.loadNext == rhs.loadNext
                && lhs.lifts.map(\.name) == rhs.lifts.map(\.name) && lhs.lifts.map(\.done) == rhs.lifts.map(\.done)
                && lhs.lifts.map(\.focused) == rhs.lifts.map(\.focused)
        }
    }

    func board(at now: Date, plateMath: some PlateMath = .greedy) -> Board {
        let lift = current
        let nextIndex = lift.nextIndex
        let chips = lift.sets.enumerated().map { index, set in
            let weight = set.done?.weight ?? set.weight
            let reps = set.done?.reps ?? set.reps
            let state: SetChip.State = set.done != nil ? .done : (index == nextIndex ? .current : .left)
            return SetChip(id: index, text: "\(PlateLoad.number(weight))×\(reps)", state: state)
        }
        let target = restRemaining(at: now) != nil ? nextUp(after: focus) : nextIndex.map { (lift, lift.sets[$0]) }
        let plates = target.flatMap { $0.lift.equipment == .barbell
            ? plateMath.load(target: $0.set.weight, bar: inventory.bar, inventory: inventory) : nil
        }
        var loadNext: String?
        if restRemaining(at: now) != nil, let target {
            loadNext = "then \(target.lift.name.lowercased()) \(PlateLoad.number(target.set.weight))"
                + (plates.map { ", \($0.line)" } ?? ", pin to \(PlateLoad.number(target.set.weight))")
        }
        return Board(
            liftName: lift.name, chips: chips, equipment: lift.equipment, plates: plates,
            lifts: lifts.enumerated().map { ($1.name, $1.isComplete, $0 == focus) }, loadNext: loadNext
        )
    }

    // MARK: Summary (the focused lift's ledger)

    struct LedgerRow: Equatable, Identifiable {
        enum State: Equatable { case done, current, left }
        var id: Int
        /// "Set 2"
        var label: String
        /// "185 × 5"
        var value: String
        /// The Felt word beside a logged set, or empty.
        var felt: String
        var state: State
    }

    struct Summary: Equatable {
        var rows: [LedgerRow]
        /// "Best 205, 3 weeks ago, est. max 215"; empty with no history.
        var footer: String
    }

    func summary(at now: Date) -> Summary {
        let lift = current
        let nextIndex = lift.nextIndex
        let rows = lift.sets.enumerated().map { index, set in
            let weight = set.done?.weight ?? set.weight
            let reps = set.done?.reps ?? set.reps
            return LedgerRow(
                id: index, label: "Set \(index + 1)", value: "\(PlateLoad.number(weight)) × \(reps)",
                felt: set.done?.felt?.word ?? "",
                state: set.done != nil ? .done : (index == nextIndex ? .current : .left)
            )
        }
        var parts: [String] = []
        if let best = lift.history.best {
            let ago = lift.history.bestDate.map { ", \(Self.ago($0, now: now))" } ?? ""
            parts.append("Best \(PlateLoad.number(best.weight))\(ago)")
        }
        if let estimate = lift.history.bestEstimate ?? estimatedMax {
            parts.append("est. max \(PlateLoad.number(estimate.rounded()))")
        }
        return Summary(rows: rows, footer: parts.joined(separator: ", "))
    }

    static func ago(_ date: Date, now: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        case 2 ..< 14: return "\(days) days ago"
        case 14 ..< 60: return "\(days / 7) weeks ago"
        default: return "\(max(days / 30, 2)) months ago"
        }
    }

    // MARK: Finish

    /// "Finished, 41 min, 12 sets": the part of the Done line that stays still while the total counts up.
    func finishHead(at now: Date) -> String {
        let minutes = Int((elapsed(at: now) / 60).rounded())
        return "Finished, \(minutes) min, \(setsDone) \(setsDone == 1 ? "set" : "sets")"
    }

    /// "Finished, 41 min, 12 sets, about 9,795 lb"; compares with the last same workout when it is known.
    func finishLine(at now: Date, lastVolume: Double? = nil) -> String {
        let minutes = Int((elapsed(at: now) / 60).rounded())
        var line = "Finished, \(minutes) min, \(setsDone) \(setsDone == 1 ? "set" : "sets"), about "
            + "\(Self.volumeText(volume)) \(unit.symbol)"
        if let lastVolume, lastVolume > 0 {
            let delta = volume - lastVolume
            let word = delta >= 0 ? "more" : "less"
            line += ", \(Self.volumeText(abs(delta))) \(unit.symbol) \(word) than last \(title)"
        }
        return line
    }

    static func weightText(_ value: Double, _ unit: MassUnit) -> String {
        "\(PlateLoad.number(value)) \(unit.symbol)"
    }

    /// Volume to the nearest 5, with a thousands separator.
    static func volumeText(_ value: Double) -> String {
        let rounded = (value / 5).rounded() * 5
        return rounded.formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
    }
}
