import Foundation

/// The mode on the lock screen (sheet 326), as plain data: the Dynamic Island's word and number, and the Live
/// Activity's
/// three lines. Pure and Codable so it can ride an ActivityKit `ContentState`; every countdown is an end date drawn
/// with
/// `Text(timerInterval:)`, so it runs while the app sleeps.
///
/// Walls: a private workout carries only "Rest", the time and "Private workout". No lift name, weight, rep or set count
/// is ever built into the payload (the strings are never made, rather than made and hidden).
struct ModeLiveContent: Codable, Hashable {
    /// The Dynamic Island's word, in the room's face ("Bench"); "Rest" for a private workout.
    var word: String
    /// Live Activity top line, in the room colour: "Rest, then bench".
    var top: String
    /// Middle line, left: the big thing when it is not a countdown ("185 lb × 5"); empty during a rest.
    var big: String
    /// Middle line, right: the next thing ("185 lb × 5, each side 45 + 25").
    var next: String
    /// Bottom line: one quiet fact ("Done about 7:22").
    var quiet: String
    /// The countdown's end and length (Island right, middle left); nil when nothing is counting.
    var timerEnd: Date?
    var timerTotal: TimeInterval
    var isPrivate: Bool

    /// The countdown as a range for `Text(timerInterval:)`.
    var timerInterval: ClosedRange<Date>? {
        timerEnd.map { end in
            let start = end.addingTimeInterval(-max(timerTotal, 1))
            return start ... max(end, start)
        }
    }

    static func workout(_ state: WorkoutModeState, at now: Date) -> ModeLiveContent {
        if state.isPrivate {
            return privateWorkout(state, at: now)
        }
        let about = state.band(at: now).doneAbout
        switch state.phase {
        case let .rest(endsAt, total, restLift):
            let next = state.nextUp(after: restLift)
            let plates = state.board(at: now).plates
            return ModeLiveContent(
                word: next.map { Self.shortName($0.lift.name) } ?? "Rest",
                top: next.map { "Rest, then \(Self.shortName($0.lift.name).lowercased())" } ?? "Rest",
                big: "",
                next: next.map { Self.nextLine($0.set, state: state, plates: plates) } ?? "",
                quiet: about, timerEnd: endsAt, timerTotal: total, isPrivate: false
            )
        case .set:
            let set = state.currentSet
            return ModeLiveContent(
                word: Self.shortName(state.current.name), top: state.current.name,
                big: set.map { "\(WorkoutModeState.weightText($0.weight, state.unit)) × \($0.reps)" } ?? "",
                next: "", quiet: about, timerEnd: nil, timerTotal: 0, isPrivate: false
            )
        case .done:
            return ModeLiveContent(word: "Done", top: "Finished", big: "", next: "", quiet: "", timerEnd: nil,
                                   timerTotal: 0, isPrivate: false)
        }
    }

    private static func privateWorkout(_ state: WorkoutModeState, at _: Date) -> ModeLiveContent {
        if case let .rest(endsAt, total, _) = state.phase {
            return ModeLiveContent(word: "Rest", top: "Rest", big: "", next: "", quiet: "Private workout",
                                   timerEnd: endsAt, timerTotal: total, isPrivate: true)
        }
        return ModeLiveContent(word: "Rest", top: "Private workout", big: "", next: "", quiet: "Private workout",
                               timerEnd: nil, timerTotal: 0, isPrivate: true)
    }

    /// "185 lb × 5, each side 45 + 25"
    private static func nextLine(_ set: WorkoutModeState.PlannedSet, state: WorkoutModeState,
                                 plates: PlateLoad?) -> String
    {
        let base = "\(WorkoutModeState.weightText(set.weight, state.unit)) × \(set.reps)"
        return plates.map { "\(base), \($0.line)" } ?? base
    }

    /// "Bench press" reads "Bench" on the Island.
    static func shortName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
