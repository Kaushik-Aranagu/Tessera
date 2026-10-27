import Foundation

// The test world as pyramid leaves (P1, docs/ai/harness/memory-pyramid.md), so the pyramid is scored on a known
// world before it reads his store. What must never count never becomes a leaf: a workout deleted as a mistake, a
// reversed spend, a line he had forgotten.

public extension EvalWorld {
    func pyramidLeaves() -> [PyramidLeaf] {
        var leaves: [PyramidLeaf] = []
        func add(_ kind: String, _ index: Int, _ at: Date, _ text: String, _ stats: [String: Double],
                 taint: Taint = .claudeSafe)
        {
            leaves.append(PyramidLeaf(id: "\(kind)-\(index)", at: at, kind: kind, text: text, taint: taint,
                                      stats: stats))
        }
        for (index, workout) in workouts.enumerated() where !workout.isDeleted {
            let volume = workout.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            // A private workout is its label: never its routine or its lifts.
            let lifts = workout.sets.map { "\($0.exercise) \(PyramidStats.format($0.weight)) kg x\($0.reps)" }
            let text = workout.isPrivate ? "Private workout" : "\(workout.routine): \(lifts.joined(separator: ", "))"
            // Nor its numbers: private workouts never reach Claude, so they add nothing to a claude-safe total.
            add("workout", index, workout.start, text,
                workout.isPrivate ? [:] : ["workouts": 1, "sets": Double(workout.sets.count), "volumeKg": volume])
        }
        for (index, cook) in cooks.enumerated() {
            add("cook", index, cook.day, "Cooked \(cook.recipe)", ["cooks": 1])
        }
        for (index, spend) in spends.enumerated() where !spend.isReversed {
            let amount = Double(spend.cents) / 100
            let sign = spend.currency == "EUR" ? "€" : "$"
            add("spend", index, spend.at, "Spent \(sign)\(String(format: "%.2f", amount)) on \(spend.category): "
                + spend.note, [spend.currency == "EUR" ? "spentEUR" : "spentUSD": amount], taint: .deviceOnly)
        }
        for (index, inflow) in inflows.enumerated() {
            let amount = Double(inflow.cents) / 100
            add("inflow", index, inflow.at, "Got $\(String(format: "%.2f", amount)): \(inflow.note)",
                ["earnedUSD": amount], taint: .deviceOnly)
        }
        for (index, note) in notes.enumerated() {
            add("note", index, note.at, note.isPrivate ? "Private note" : note.body, ["notes": 1])
        }
        var chore = 0
        for item in chores {
            for day in item.done {
                add("chore", chore, day, "Did \(item.title)", ["chores": 1])
                chore += 1
            }
        }
        var habit = 0
        for item in habits {
            for day in item.done {
                add("habit", habit, day, "\(item.name): done", ["habits": 1])
                habit += 1
            }
        }
        for (index, night) in nights.enumerated() {
            add("sleep", index, night.day, "Slept \(PyramidStats.format(night.hours)) h",
                ["nights": 1, "sleepHours": night.hours], taint: .deviceOnly)
        }
        for (index, weighIn) in weighIns.enumerated() {
            add("weight", index, weighIn.at, "Weighed \(PyramidStats.format(weighIn.kg)) kg",
                ["weighIns": 1, "weightKg": weighIn.kg], taint: .deviceOnly)
        }
        for (index, event) in events.enumerated() {
            add("event", index, event.start, "\(event.title), \(event.minutes) min", ["events": 1], taint: .deviceOnly)
        }
        for (index, line) in told.enumerated() where line.forgotten.map({ $0 > now }) ?? true {
            add("told", index, line.at, "He told you: \(line.text)", ["told": 1])
        }
        return leaves
    }
}
