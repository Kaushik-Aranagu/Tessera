import Foundation

/// What Builder B's cook feeds the activity when a pan timer hits zero (sheet 344). Plain values only.
struct CookReadyInput: Equatable {
    /// The food whose timer ended ("Chicken").
    var food: String
    var endedAt: Date
    /// The next running timer, if any ("onions to go" ending at 5:58 from now).
    var next: (label: String, endsAt: Date)?
    var cookID: String
    var isPrivate: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.food == rhs.food && lhs.endedAt == rhs.endedAt && lhs.cookID == rhs.cookID
            && lhs.isPrivate == rhs.isPrivate && lhs.next?.label == rhs.next?.label
            && lhs.next?.endsAt == rhs.next?.endsAt
    }
}

/// The seam: the cook asks nothing of the activity layer except this. Builder B conforms; tests use a sample.
protocol CookReadyFeed {
    /// The timer that just ended, or nil when none has.
    func ready(at now: Date) -> CookReadyInput?
}

enum CookReadyFace {
    static let privateFood = "Timer"

    /// The link a tap on the activity follows: the ticket, with the alert line for that food printed. A private cook's
    /// link names no food.
    static func link(cookID: String, food: String) -> URL? {
        var parts = URLComponents()
        parts.scheme = "tessera"
        parts.host = "cook"
        parts.queryItems = [URLQueryItem(name: "cook", value: cookID), URLQueryItem(name: "alert", value: food)]
        return parts.url
    }

    /// The activity's state for a timer that ended: the food ready, the next timer beside it. A private cook carries
    /// "Timer" and no label, food or recipe word anywhere in the payload.
    static func state(_ input: CookReadyInput) -> CookActivityAttributes.ContentState {
        let food = input.isPrivate ? privateFood : input.food
        return CookActivityAttributes.ContentState(
            timerLabel: food, endsAt: input.endedAt, total: 1, others: 0, nextStep: nil,
            readyFood: food,
            nextLabel: input.isPrivate ? nil : input.next?.label,
            nextEndsAt: input.next?.endsAt,
            link: link(cookID: input.cookID, food: food)
        )
    }

    /// The state to show now, or nil when nothing has ended.
    static func state(from feed: some CookReadyFeed, at now: Date) -> CookActivityAttributes.ContentState? {
        feed.ready(at: now).map(state)
    }
}
