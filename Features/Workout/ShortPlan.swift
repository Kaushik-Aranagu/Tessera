import Foundation

/// Which exercises a time budget drops (Design 128, "Short"). A set takes about two and a half minutes with its rest,
/// the same figure the Training page's "about 40 min" uses. Pure so it can be tested.
enum ShortPlan {
    /// The steps, in the order the word walks them: All, then 45, 35, 25, then All again.
    static let minutes = [45, 35, 25]
    static let minutesPerSet = 2.5

    struct Item: Equatable {
        let id: UUID
        let plannedSets: Int
        /// Already has sets logged, or is the exercise on screen: never dropped.
        let keeps: Bool
    }

    /// The next step after `current` (nil is "All"): 45, 35, 25, then back to All.
    static func next(after current: Int?) -> Int? {
        guard let current, let index = minutes.firstIndex(of: current) else { return minutes.first }
        return minutes.indices.contains(index + 1) ? minutes[index + 1] : nil
    }

    /// Walking the order, kept exercises stay and the others stay while their sets fit the budget; at the first one
    /// that does not, every unstarted exercise after it drops too, so the cut is always the tail of the plan.
    static func dropped(_ items: [Item], minutes: Int?) -> Set<UUID> {
        guard let minutes else { return [] }
        let budget = Int((Double(minutes) / minutesPerSet).rounded(.down))
        var used = 0
        var over = false
        var dropped = Set<UUID>()
        for item in items {
            if item.keeps {
                used += item.plannedSets
            } else if !over, used + item.plannedSets <= budget {
                used += item.plannedSets
            } else {
                over = true
                dropped.insert(item.id)
            }
        }
        return dropped
    }

    /// "Cut to 35 min.", "Cut to 45 min, nothing dropped.", or the way back.
    static func receipt(minutes: Int?, droppedCount: Int) -> String {
        guard let minutes else { return "Back to the whole workout." }
        return droppedCount == 0 ? "Cut to \(minutes) min, nothing dropped." : "Cut to \(minutes) min."
    }
}
