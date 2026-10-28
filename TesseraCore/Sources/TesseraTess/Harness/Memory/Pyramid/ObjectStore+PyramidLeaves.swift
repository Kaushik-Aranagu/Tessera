import Foundation
import TesseraCore

// The store slice of the memory pyramid (docs/ai/harness/memory-pyramid.md): his own store as leaves, read the way the
// night pass reads a day. A private thing is walled and adds nothing to a total, so under strict the pyramid reads
// exactly as if it never happened. Its words are its own while Claude sees everything (his Oct 27 ruling,
// `ClaudeSees`), so lab reads them; its shown label otherwise, and always when its words look like a key. A started
// workout that never finished, a deleted row and anything after `now` never become a leaf. Workouts with their
// working sets, cooks, tasks done, notes, money, his weigh-ins, sleep, steps, resting heart rate and the calendar.

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
        // A walled leaf's text: its own words while Claude sees everything, never a key; its label otherwise.
        func walledText(_ own: String, _ label: String) -> String {
            ClaudeSees.everything && !looksLikeClaudeKey(own) ? own : label
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
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "workout",
                                              text: walledText(workout.title, ObjectPrivacy.routineLabel),
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
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "cook", text: walledText("Cooked \(name)", shown),
                                              taint: .deviceOnly))
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
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "task",
                                              text: walledText("Did \(task.title)", shown), taint: .deviceOnly))
                } else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "task", text: "Did \(task.title)",
                                              stats: ["tasks": 1]))
                }
            }
        }

        if let noteClass = classes[.note] {
            // A weigh-in is a private note whose words read as his weight, as `BodyWeight` reads them.
            let exercises = BodyWeight.exerciseNames(in: store)
            for note in store.objects(of: noteClass) where !note.isDeleted {
                guard let at = past(note.createdAt) else { continue }
                let body = store.value("body", of: note)?.stringValue ?? ""
                let words = String((body.isEmpty ? note.title : body).prefix(noteCharacters))
                let id = "note-\(note.id.uuidString)"
                // A key anywhere in the note, even past the cut (a cut key may not look like one): only its label.
                let keyed = looksLikeClaudeKey(note.title) || looksLikeClaudeKey(body)
                if let shown = label(note)
                    ?? (plain(note.title) && plain(words) && !keyed ? nil : ObjectPrivacy.noteLabel)
                {
                    let kg = store.value("isPrivate", of: note) == .bool(true)
                        ? BodyWeight.kilograms(in: body.isEmpty ? note.title : body, exercises: exercises) : nil
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "note",
                                              text: keyed ? shown : walledText(words, shown), taint: .deviceOnly,
                                              stats: kg.map { ["weightKg": $0, "weighIns": 1] } ?? [:]))
                } else {
                    leaves.append(PyramidLeaf(id: id, at: at, kind: "note", text: words, stats: ["notes": 1]))
                }
            }
        }

        // Money: a spend or money in is always walled, so under strict it never happened, and its amount adds only to
        // its currency's total, which only lab reads. A currency with no total of its own adds to none.
        func code(_ typed: String?) -> String {
            let code = (typed ?? "").trimmingCharacters(in: .whitespaces).uppercased()
            return code.isEmpty ? "USD" : code
        }
        func money(_ key: String, _ amount: Decimal) -> [String: Double] {
            PyramidStats.shown.contains { $0.key == key } ? [key: Double(truncating: amount as NSDecimalNumber)] : [:]
        }
        func spoken(_ words: String?) -> String {
            (words ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let spendClass = classes[.spend] {
            for spend in store.objects(of: spendClass) where !spend.isDeleted {
                guard let at = past(store.value("spentAt", of: spend)?.dateValue) else { continue }
                // The typed digits, as the Month sums them: exact cents.
                let amount = MoneyAmount.parse(store.value("typed", of: spend)?.stringValue ?? "")?.amount
                    ?? store.number("amount", of: spend).flatMap { Decimal(string: String($0)) } ?? 0
                let currency = code(store.value("currency", of: spend)?.stringValue)
                let category = spoken(store.value("category", of: spend)?.stringValue)
                let note = spoken(store.value("note", of: spend)?.stringValue)
                let own = "Spent \(SpendLedger.shown(amount, currency: currency, grouped: true))"
                    + (category.isEmpty ? "" : " on \(category)") + (note.isEmpty ? "" : ": \(note)")
                leaves.append(PyramidLeaf(id: "spend-\(spend.id.uuidString)", at: at, kind: "spend",
                                          text: walledText(own, ObjectPrivacy.spendLabel), taint: .deviceOnly,
                                          stats: money("spent\(currency)", amount)))
            }
        }
        if let inflowClass = classes[.inflow] {
            for inflow in store.objects(of: inflowClass) where !inflow.isDeleted {
                guard let at = past(store.value("at", of: inflow)?.dateValue) else { continue }
                let amount = PoolBook.decimal(store.value("amountTyped", of: inflow)?.stringValue)
                let pool = store.linkedObjects("pool", of: inflow).first
                let currency = code(pool.flatMap { store.value("currency", of: $0)?.stringValue })
                let source = spoken(store.value("source", of: inflow)?.stringValue)
                let note = spoken(store.value("note", of: inflow)?.stringValue)
                let own = "Got \(SpendLedger.shown(amount, currency: currency, grouped: true))"
                    + (source.isEmpty ? "" : " from \(source)") + (note.isEmpty ? "" : ": \(note)")
                leaves.append(PyramidLeaf(id: "inflow-\(inflow.id.uuidString)", at: at, kind: "inflow",
                                          text: walledText(own, ObjectPrivacy.inflowLabel), taint: .deviceOnly,
                                          stats: money("earned\(currency)", amount)))
            }
        }

        // Health and the calendar: read-only mirrors, always walled, so strict never reads them and their totals are
        // lab's alone. Their words are their own while Claude sees everything, a plain name otherwise.
        func number(_ value: Double) -> String {
            Int(value.rounded()).formatted(.number.locale(Locale(identifier: "en_US")))
        }
        func health(_ key: SystemCatalog.Key, _ kind: String, _ label: String,
                    _ read: (ObjectRecord) -> (text: String, stats: [String: Double])?)
        {
            guard let healthClass = classes[key] else { return }
            for object in store.objects(of: healthClass) where !object.isDeleted {
                guard let at = past(store.value("date", of: object)?.dateValue), let found = read(object) else {
                    continue
                }
                leaves.append(PyramidLeaf(id: "\(kind)-\(object.id.uuidString)", at: at, kind: kind,
                                          text: walledText(found.text, label), taint: .deviceOnly, stats: found.stats))
            }
        }
        health(.sleepNight, "sleep", "A night's sleep") { night in
            guard let asleep = store.number("asleepMinutes", of: night), asleep > 0 else { return nil }
            let minutes = Int(asleep.rounded())
            return ("Slept \(minutes / 60) h \(minutes % 60) min", ["sleepHours": asleep / 60, "nights": 1])
        }
        health(.stepsDay, "steps", "Steps") { day in
            guard let count = store.number("count", of: day), count > 0 else { return nil }
            return ("Walked \(number(count)) steps", ["steps": count])
        }
        health(.restingHeartRate, "heart", "Resting heart rate") { day in
            guard let bpm = store.number("bpm", of: day), bpm > 0 else { return nil }
            return ("Resting heart rate \(number(bpm)) bpm", ["restingBpm": bpm, "heartDays": 1])
        }
        if let eventClass = classes[.event] {
            for event in store.objects(of: eventClass) where !event.isDeleted {
                guard store.value("cancelled", of: event) != .bool(true),
                      let at = past(store.value("start", of: event)?.dateValue) else { continue }
                leaves.append(PyramidLeaf(id: "event-\(event.id.uuidString)", at: at, kind: "event",
                                          text: walledText("On the calendar: \(event.title)", "Calendar event"),
                                          taint: .deviceOnly, stats: ["events": 1]))
            }
        }
        return leaves
    }
}
