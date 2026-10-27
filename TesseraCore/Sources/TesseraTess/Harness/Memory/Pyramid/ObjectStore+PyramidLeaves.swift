import Foundation
import TesseraCore

// The store slice of the memory pyramid (docs/ai/harness/memory-pyramid.md): his own store as leaves, read the way the
// night pass reads a day. A private thing is its shown label, walled, and adds nothing to a total, so under strict the
// pyramid reads exactly as if it never happened. A started
// workout that never finished, a deleted row and anything after `now` never become a leaf. Workouts with their
// working sets, cooks, tasks done and notes come first; money, health, body and the calendar wait for their own slice.

public extension MemoryPyramid {
    /// The most of a note's words a leaf keeps.
    static let noteCharacters = 280

    @MainActor
    static func leaves(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date) -> [PyramidLeaf] {
        let lastKg = BodyWeight.lastKg(in: store)
        func label(_ object: ObjectRecord) -> String? {
            ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
        }
        // Belt and braces over the shown label: a walled title, a secret word or a key never becomes leaf text, and
        // nor does anything the Door's strict scan would refuse ("ate 600 calories"), which would refuse the whole run.
        func plain(_ text: String) -> Bool {
            !ObjectPrivacy.isPrivateTitle(text, lastWeightKg: lastKg) && !SecretWords.mentions(text)
                && !looksLikeClaudeKey(text) && !PrivateFacts.isWalled(text, lastWeightKg: lastKg)
                && !PrivateFacts.isCalorieShaped(text)
        }
        func past(_ date: Date?) -> Date? {
            date.flatMap { $0 < now ? $0 : nil }
        }
        var leaves: [PyramidLeaf] = []

        // Working sets by workout. A private exercise's sets stay out of the text and the totals.
        var lifts: [UUID: [String]] = [:], sets: [UUID: Double] = [:], volume: [UUID: Double] = [:]
        let ledger = TrainingLedger(store: store, classes: classes)
        let exercises: [ClassDef] = store.exerciseGroups(root: classes[.exercise]).flatMap(\.exercises)
        for exercise in exercises where plain(exercise.name) {
            let own = ledger.sessions(of: exercise).filter { session in
                store.linkedClass("exercise", of: session.entry)?.id == exercise.id
            }
            for session in own {
                for set in session.sets {
                    let weight = PyramidStats.format(set.weight), reps = PyramidStats.format(set.reps)
                    let lift = "\(exercise.name) \(weight) kg x\(reps)"
                    // A weight that reads as his body weight is a body fact: the set stays out, text and totals.
                    guard plain(lift) else { continue }
                    lifts[session.workoutID, default: []].append(lift)
                    sets[session.workoutID, default: 0] += 1
                    volume[session.workoutID, default: 0] += set.volume
                }
            }
        }
        if let workoutClass = classes[.workout] {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted {
                guard store.value("endedAt", of: workout)?.dateValue != nil,
                      let at = past(store.value("startedAt", of: workout)?.dateValue) else { continue }
                let id = "workout-\(workout.id.uuidString)"
                guard label(workout) == nil, plain(workout.title) else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "workout", text: ObjectPrivacy.routineLabel,
                                              taint: .deviceOnly))
                    continue
                }
                let done = lifts[workout.id] ?? []
                let text = done.isEmpty ? workout.title : "\(workout.title): \(done.joined(separator: ", "))"
                leaves.append(PyramidLeaf(id: id, at: at, kind: "workout", text: text, stats: [
                    "workouts": 1, "sets": sets[workout.id] ?? 0, "volumeKg": volume[workout.id] ?? 0,
                ]))
            }
        }

        if let cookClass = classes[.cook] {
            for cook in store.objects(of: cookClass) where !cook.isDeleted {
                guard let at = past(store.value("cookedAt", of: cook)?.dateValue) else { continue }
                let recipe = store.linkedObjects("recipe", of: cook).first
                let name = recipe?.title ?? cook.title
                let id = "cook-\(cook.id.uuidString)"
                let walled = plain(name) ? nil : ObjectPrivacy.recipeLabel
                if let shown = label(cook) ?? recipe.flatMap(label) ?? walled {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "cook", text: shown, taint: .deviceOnly))
                } else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "cook", text: "Cooked \(name)",
                                              stats: ["cooks": 1]))
                }
            }
        }

        if let taskClass = classes[.task] {
            for task in store.objects(of: taskClass) where !task.isDeleted {
                guard let at = past(store.value("doneAt", of: task)?.dateValue) else { continue }
                let id = "task-\(task.id.uuidString)"
                if let shown = label(task) ?? (plain(task.title) ? nil : ObjectPrivacy.taskLabel) {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "task", text: shown, taint: .deviceOnly))
                } else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "task", text: "Did \(task.title)",
                                              stats: ["tasks": 1]))
                }
            }
        }

        if let noteClass = classes[.note] {
            for note in store.objects(of: noteClass) where !note.isDeleted {
                guard let at = past(note.createdAt) else { continue }
                let body = store.value("body", of: note)?.stringValue ?? ""
                let words = String((body.isEmpty ? note.title : body).prefix(noteCharacters))
                let id = "note-\(note.id.uuidString)"
                if let shown = label(note) ?? (plain(note.title) && plain(words) ? nil : ObjectPrivacy.noteLabel) {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "note", text: shown, taint: .deviceOnly))
                } else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "note", text: words, stats: ["notes": 1]))
                }
            }
        }
        return leaves
    }
}
