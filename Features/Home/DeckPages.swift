import SwiftUI
import TesseraCore

// Sheet 284 for the Deck: what each door's Page (level 1) and each lift's item page (level 2) say. Read once per
// revision from the same sources as the landing (TrainingLedger, the plan, the wall); nothing here draws. Private
// workouts read only "Private workout"; a private word never reaches a row.

/// One door's page: the second line of its Door title and its rows in rank order.
struct DeckDoorPage: Equatable {
    var line: String
    var rows: [RankedRow]
}

/// A lift's item page: its title and one line, its three facts and its sets.
struct DeckItem: Equatable {
    var title: String
    var line: String
    var facts: [ItemFact]
    var sets: SetsBody
}

/// Every door page and lift page of the Deck.
struct DeckPages: Equatable {
    var doors: [String: DeckDoorPage] = [:]
    /// Keyed by the lift's target id ("x:<uuid>"): a row id with its "#..." suffix cut.
    var items: [String: DeckItem] = [:]

    /// The key a row id looks its lift up by.
    static func itemKey(_ rowID: String) -> String {
        String(rowID.prefix { $0 != "#" })
    }

    /// The row ids that open the rest of a list ("more:library", "more:bests"): the old page, not an item.
    static func moreID(_ door: String) -> String {
        "more:\(door)"
    }

    static func isMore(_ id: String) -> Bool {
        id.hasPrefix("more:")
    }
}

// MARK: - The sets of a lift (pure)

enum DeckSets {
    /// A set as stored: kilograms and reps.
    struct Entry: Equatable {
        var weight: Double
        var reps: Double
    }

    /// The warm-up ramp: no warm-up sets are logged (they are not history), so the page shows the usual two from the
    /// opening weight, 50% for 8 and 70% for 5, rounded to 2.5 kg. A seam: Core has no warm-up prescription yet.
    static let ramp: [(share: Double, reps: Int)] = [(0.5, 8), (0.7, 5)]
    static let rampFrom = 40.0

    static func rounded(_ kilograms: Double) -> Double {
        (kilograms / 2.5).rounded() * 2.5
    }

    /// "80" and "kg", or "BW" for a bodyweight set.
    static func weightText(_ kilograms: Double) -> (number: String, unit: String) {
        kilograms <= 0 ? ("BW", "") : (Format.shown(kilograms), Format.unit.symbol)
    }

    static func repsText(_ reps: Double) -> String {
        String(Int(reps.rounded()))
    }

    /// Warm-up and working sets: the sets logged today are done, the first one still to do is next. A working set
    /// shows what last time did at that place (else the opening weight); `planned` working sets at most six.
    static func lines(last: [Entry], today: [Entry], planned: Int) -> [SetLine] {
        let working = min(max(planned, today.count, 1), 6)
        guard let open = last.first ?? today.first else { return [] }
        var out: [SetLine] = []
        if open.weight >= rampFrom {
            for (index, part) in ramp.enumerated() {
                let text = weightText(rounded(open.weight * part.share))
                out.append(SetLine(id: "warm\(index)", label: "Warm-up", weight: text.number, unit: text.unit,
                                   reps: "\(part.reps)", state: today.isEmpty ? .todo : .done))
            }
        }
        for index in 0 ..< working {
            let logged = today.indices.contains(index) ? today[index] : nil
            let prescribed = last.indices.contains(index) ? last[index] : open
            let set = logged ?? prescribed
            let text = weightText(set.weight)
            out.append(SetLine(id: "set\(index)", label: "Set \(index + 1)", weight: text.number, unit: text.unit,
                               reps: repsText(set.reps), state: logged == nil ? .todo : .done))
        }
        if let next = out.firstIndex(where: { $0.state == .todo }) {
            out[next].state = .next
        }
        return out
    }

    /// "80 kg x 5, 5, 5, 4": the last session's sets. One weight is said once.
    static func lastTime(_ sets: [Entry]) -> String {
        guard let first = sets.first else { return "" }
        let times = "\u{00D7}"
        if sets.allSatisfy({ $0.weight == first.weight }) {
            let text = weightText(first.weight)
            let head = text.unit.isEmpty ? text.number : "\(text.number) \(text.unit)"
            return "\(head) \(times) " + sets.map { repsText($0.reps) }.joined(separator: ", ")
        }
        return sets.map { "\(weightText($0.weight).number) \(times) \(repsText($0.reps))" }.joined(separator: ", ")
    }

    /// The item's one line under its title: what is next, or that everything is done, or that nothing is logged.
    static func line(for lines: [SetLine], hasHistory: Bool) -> String {
        if let next = lines.first(where: { $0.state == .next }) {
            let unit = next.unit.isEmpty ? "" : " \(next.unit)"
            return "Next: \(next.label.lowercased()), \(next.weight)\(unit) \u{00D7} \(next.reps)"
        }
        if !lines.isEmpty, lines.allSatisfy({ $0.state == .done }) {
            return "All sets done"
        }
        return hasHistory ? "Nothing planned" : "No sets logged yet"
    }
}

// MARK: - Loading

@MainActor
extension DeckPages {
    private struct Lift {
        let exercise: ClassDef
        let sessions: [TrainingLedger.Session]
        let best: TrainingLedger.LoggedSet?

        var last: Date {
            sessions.first?.date ?? .distantPast
        }
    }

    static func load(model: AppModel, wall: TrainingWallFacts, deck: TrainingDeckFacts, now: Date = AppClock.now,
                     calendar: Calendar = .current) -> DeckPages
    {
        let store = model.store
        func shown(_ title: String) -> String {
            ObjectPrivacy.routineTitle(title, in: store)
        }
        func day(_ date: Date) -> String {
            date.formatted(.dateTime.month(.abbreviated).day())
        }

        // Lifts with history, newest first; private words never reach a row.
        let lifts: [Lift] = ExerciseLibraryList.groups(model).flatMap(\.exercises).compactMap { exercise in
            guard !ObjectPrivacy.isPrivateWord(exercise.name, in: store) else { return nil }
            let sessions = model.ledger.sessions(of: exercise)
            guard !sessions.isEmpty else { return nil }
            return Lift(exercise: exercise, sessions: sessions, best: model.ledger.bestSet(of: exercise))
        }.sorted { $0.last > $1.last }

        // Today: the workout running, tonight's, the routine, or the one finished today.
        let source: ObjectRecord? = model.session?.workout ?? model.tonightWorkout(around: now)
            ?? model.triedRoutine() ?? model.todaysRoutine(now: now) ?? model.finishedToday(now: now).first?.workout
        let privateToday = source.map { shown($0.title) == ObjectPrivacy.routineLabel } ?? false
        var planned: [UUID: Int] = [:]
        var todayRows: [RankedRow] = []
        if privateToday {
            todayRows = [RankedRow(id: "page#private", title: ObjectPrivacy.routineLabel, isPrivate: true)]
        } else if let source {
            for (index, slot) in source.orderedChildren.filter({ !$0.isDeleted }).enumerated() {
                guard let exercise = store.linkedClass("exercise", of: slot),
                      !ObjectPrivacy.isPrivateWord(exercise.name, in: store) else { continue }
                let count = max(Int(store.number("targetSets", of: slot) ?? 3), 1)
                planned[exercise.id] = count
                let sessions = model.ledger.sessions(of: exercise)
                let logged = sessions.first.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
                let open = sessions.first { !calendar.isDate($0.date, inSameDayAs: now) }?.sets.first
                    ?? logged?.sets.first
                let text = DeckSets.weightText(open?.weight ?? 0)
                let doneCount = logged?.sets.count ?? 0
                let reps = open.map { DeckSets.repsText($0.reps) }
                var sub = reps.map { "\(count) sets of \($0)" } ?? "\(count) sets"
                if doneCount > 0, doneCount < count {
                    sub = "\(doneCount) of \(count) sets"
                }
                todayRows.append(RankedRow(
                    id: "\(TrainingWallTarget.exercise(exercise.id).id)#t\(index)", title: exercise.name,
                    value: open == nil ? "" : text.number, unit: open == nil ? "" : text.unit, sub: sub,
                    state: doneCount >= count ? .done : .none
                ))
            }
        }

        // The week: today first, then the days that follow, then the days gone by.
        let weekdays = calendar.weekdaySymbols
        let week = deck.board.week
        let todayAt = week.firstIndex { $0.isToday } ?? 0
        let weekOrder = Array(week[todayAt...] + week[..<todayAt])
        let weekRows: [RankedRow] = weekOrder.map { day in
            let name = weekdays[(calendar.firstWeekday - 1 + day.id) % 7]
            let sub = day.isToday ? (day.done ? "Today, trained" : "Today")
                : (day.done ? (day.liftName.map { "Trained, \($0)" } ?? "Trained") : "")
            return RankedRow(
                id: day.liftID.map { "\(TrainingWallTarget.exercise($0).id)#w\(day.id)" } ?? "week#\(day.id)",
                title: name, sub: sub, state: day.done ? .done : .none
            )
        }

        // Library: the lifts by how lately he did them, the best beside each.
        let libraryAll = lifts.map { lift in
            let best = lift.best.map { DeckSets.weightText($0.weight) }
            return RankedRow(id: "\(TrainingWallTarget.exercise(lift.exercise.id).id)#l", title: lift.exercise.name,
                             value: best?.number ?? "", unit: best?.unit ?? "", sub: "Last \(day(lift.last))")
        }
        // Bests: the newest bests first; one set in the last month is new, in gold.
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let bests = lifts.compactMap { lift -> (Lift, TrainingLedger.LoggedSet, Date)? in
            guard let best = lift.best, best.weight > 0,
                  let when = lift.sessions.first(where: { $0.sets.contains { $0.id == best.id } })?.date else { return nil }
            return (lift, best, when)
        }.sorted { $0.2 > $1.2 }
        let bestRows = bests.map { lift, best, when in
            let text = DeckSets.weightText(best.weight)
            return RankedRow(id: "best:\(lift.exercise.id.uuidString)#b", title: lift.exercise.name, value: text.number,
                             unit: text.unit, sub: "\(DeckSets.repsText(best.reps)) reps, \(day(when))",
                             state: when >= monthAgo ? .best : .none)
        }

        // Plan: the routines, today's first.
        let routines = model.plan.map { store.linkedObjects("routines", of: $0) }?.filter { !$0.isDeleted } ?? []
        var planRows: [RankedRow] = routines.map { routine in
            let title = shown(routine.title)
            guard title != ObjectPrivacy.routineLabel else {
                return RankedRow(id: TrainingWallTarget.routine(routine.id).id, title: title, isPrivate: true)
            }
            let slots = routine.orderedChildren.filter { !$0.isDeleted }
            let minutes = TrainingPage.estimatedMinutes(sets: NowPage.plannedSets(slots, store: store))
            return RankedRow(id: TrainingWallTarget.routine(routine.id).id, title: title, value: "\(minutes)",
                             unit: "min", sub: "\(slots.count) \(slots.count == 1 ? "lift" : "lifts")")
        }
        if let source, let first = routines.firstIndex(where: { $0.title == source.title }), first > 0 {
            planRows.insert(planRows.remove(at: first), at: 0)
        }

        func line(_ id: String, _ fallback: String) -> String {
            let door = wall.doors.first { $0.id == id }
            return door?.label ?? door?.lines.first ?? fallback
        }
        let trained = week.filter(\.done).count
        var pages = DeckPages()
        pages.doors["today"] = DeckDoorPage(line: line("today", "Nothing planned today"), rows: todayRows)
        pages.doors["week"] = DeckDoorPage(line: "\(trained) trained", rows: weekRows)
        pages.doors["library"] = DeckDoorPage(line: line("library", "Nothing logged yet"), rows: libraryAll)
        pages.doors["bests"] = DeckDoorPage(
            line: bestRows.isEmpty ? "None yet" : "\(bestRows.count) \(bestRows.count == 1 ? "lift" : "lifts")",
            rows: bestRows
        )
        pages.doors["plan"] = DeckDoorPage(line: line("plan", "No plan yet"), rows: planRows)

        // Each lift's item page.
        for lift in lifts {
            let exercise = lift.exercise
            let logged = lift.sessions.first.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
            let before = lift.sessions.first { !calendar.isDate($0.date, inSameDayAs: now) }
            func sets(_ session: TrainingLedger.Session?) -> [DeckSets.Entry] {
                session?.sets.map { DeckSets.Entry(weight: $0.weight, reps: $0.reps) } ?? []
            }
            let count = planned[exercise.id] ?? before?.sets.count ?? logged?.sets.count ?? 3
            let lines = DeckSets.lines(last: sets(before), today: sets(logged), planned: count)
            let open = (before ?? logged)?.sets.first.map { DeckSets.weightText($0.weight) }
            let best = lift.best.map { DeckSets.weightText($0.weight) }
            pages.items[TrainingWallTarget.exercise(exercise.id).id] = DeckItem(
                title: exercise.name,
                line: DeckSets.line(for: lines, hasHistory: true),
                facts: [
                    ItemFact(number: open?.number ?? "None", unit: open?.unit ?? "", label: "Opens at"),
                    ItemFact(number: "\(min(max(count, 1), 6))", unit: "sets", label: "Planned"),
                    ItemFact(number: best?.number ?? "None", unit: best?.unit ?? "", label: "Best"),
                ],
                sets: SetsBody(lines: lines, lastTime: DeckSets.lastTime(sets(before)))
            )
        }
        return pages
    }
}
