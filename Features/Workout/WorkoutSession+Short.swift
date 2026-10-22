import Foundation
import TesseraCore

/// Short (Design 128): cut today's workout to 45, 35 or 25 minutes, or back to all of it. The cut exercises count as
/// done for today and are marked skipped when the workout ends; the plan itself is never rewritten. Logging a set on a
/// cut exercise brings it back.
extension WorkoutSession {
    /// What Undo puts back.
    struct ShortReceipt {
        let text: String
        fileprivate let previousMinutes: Int?
        fileprivate let previousCut: Set<UUID>
    }

    func isCut(_ entry: ObjectRecord) -> Bool {
        cut.contains(entry.id)
    }

    /// Whether Short has anything to work on: another exercise still has sets, or a cut is on.
    var canShorten: Bool {
        hasOtherUnfinished || !cut.isEmpty
    }

    /// Steps to the next minutes (All, 45, 35, 25, All) and returns the receipt. Nil once the workout is over.
    func stepShort() -> ShortReceipt? {
        guard finishedAt == nil else { return nil }
        let previous = (cutMinutes, cut)
        let minutes = ShortPlan.next(after: cutMinutes)
        let items = entries.compactMap { entry -> ShortPlan.Item? in
            guard !isFinished(entry) || isCut(entry) else { return nil }
            let keeps = !setRows(of: entry).isEmpty || entry.id == currentEntry?.id
            return ShortPlan.Item(id: entry.id, plannedSets: plannedSets(of: entry), keeps: keeps)
        }
        // Finished exercises count against the budget too: they already took their time.
        let spent = entries.filter { isFinished($0) && !isCut($0) }.map(plannedSets(of:)).reduce(0, +)
        let doneItems = spent > 0 ? [ShortPlan.Item(id: UUID(), plannedSets: spent, keeps: true)] : []
        cut = ShortPlan.dropped(doneItems + items, minutes: minutes)
        cutMinutes = minutes
        refreshAfterExternalWrite()
        return ShortReceipt(text: ShortPlan.receipt(minutes: minutes, droppedCount: cut.count),
                            previousMinutes: previous.0, previousCut: previous.1)
    }

    /// Takes a Short step back: the minutes and the cut are as they were.
    func undoShort(_ receipt: ShortReceipt) {
        cutMinutes = receipt.previousMinutes
        cut = receipt.previousCut
        refreshAfterExternalWrite()
    }

    /// A planned set count that ignores sets skipped today: the plan's, for the budget.
    func plannedSets(of entry: ObjectRecord) -> Int {
        max(Int(model.store.number("targetSets", of: entry) ?? 3), 1)
    }
}
