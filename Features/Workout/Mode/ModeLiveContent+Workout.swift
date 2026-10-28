import Foundation

/// Builds the lock-screen payload from the workout mode's state (the data type is in Shared, drawn by the widget).
extension ModeLiveContent {
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
                quiet: about, timerEnd: endsAt, timerTotal: total, isPrivate: false,
                // The face for 0:00, ready before the app could be asleep: the lift and the set you are up for.
                ended: next.map {
                    Ended(top: "Rest done, you\u{2019}re up", big: Self.shortName($0.lift.name),
                          next: WorkoutModeState.weightText($0.set.weight, state.unit) + " \u{00D7} \($0.set.reps)")
                }
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
            // "Rest done" with a big "Up": no lift name and no weight, ever.
            return ModeLiveContent(word: "Rest", top: "Rest", big: "", next: "", quiet: "Private workout",
                                   timerEnd: endsAt, timerTotal: total, isPrivate: true,
                                   ended: Ended(top: "Rest done", big: "Up", next: ""))
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

/// What the open workout mode wants the lock screen to say. The mode screen writes it on every change; the rest Live
/// Activity controller reads it when it builds the activity's state, so there is one activity, not two.
@MainActor
enum ModeLiveBridge {
    static var current: ModeLiveContent?

    /// The content with its countdown moved onto the real clock (the activity counts down in real time; the app clock
    /// may be shifted by `-demoTime`).
    static func onRealClock(appNow: Date, realNow: Date) -> ModeLiveContent? {
        guard var content = current else { return nil }
        let shift = realNow.timeIntervalSince(appNow)
        content.timerEnd = content.timerEnd.map {
            Date(timeIntervalSinceReferenceDate: $0.addingTimeInterval(shift).timeIntervalSinceReferenceDate.rounded())
        }
        return content
    }
}
