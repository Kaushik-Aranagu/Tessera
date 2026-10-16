import ActivityKit
import Foundation

/// The rest-timer Live Activity: the Lock Screen / Dynamic Island face of a running workout between sets.
/// Shared by the app (which starts and updates it) and the widget extension (which draws it).
struct RestActivityAttributes: ActivityAttributes {
    /// The workout's title, fixed for the life of the activity.
    var workoutTitle: String

    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            /// Counting down to the next set.
            case resting
            /// Rest is over; the planned set is waiting to be logged.
            case ready
        }

        /// The exercise of the planned set.
        var exercise: String
        /// 1-based number of the planned set within its exercise.
        var setNumber: Int
        /// Planned weight in kg.
        var weight: Double
        /// Planned reps.
        var reps: Int
        /// When the rest ends (in the past once `phase` is `.ready`).
        var restEndsAt: Date
        /// Length of the whole rest, including any +15s, for the draining bar.
        var restTotal: TimeInterval
        var phase: Phase
        /// The day and night look names (the same name twice when pinned), so the extension draws the right one by
        /// the Lock Screen's appearance. Optional: older states decode without them.
        var lookDay: String?
        var lookNight: String?

        /// The rest as a range for `Text(timerInterval:)` and `ProgressView(timerInterval:)`.
        var restInterval: ClosedRange<Date> {
            let start = restEndsAt.addingTimeInterval(-max(restTotal, 1))
            return start ... max(restEndsAt, start)
        }

        /// "82.5 × 8", the planned set in the app's notation.
        var plannedSet: String {
            "\(Self.format(weight)) × \(reps)"
        }

        static func format(_ weight: Double) -> String {
            weight.formatted(.number.precision(.fractionLength(0 ... 2)))
        }
    }
}
