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
    /// The foot's object for Start: "set 1, 185 lb".
    var start = ""
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

    /// The warm-up: no warm-up sets are logged (they are not history), so the page shows the usual one from the
    /// opening weight, half of it for 10, rounded to 2.5 kg. A seam: Core has no warm-up prescription yet.
    static let ramp: [(share: Double, reps: Int)] = [(0.5, 10)]
    static let rampFrom = 40.0

    static func rounded(_ kilograms: Double) -> Double {
        (kilograms / 2.5).rounded() * 2.5
    }

    /// "80" and "kg", or "Body" for a bodyweight set.
    static func weightText(_ kilograms: Double) -> (number: String, unit: String) {
        kilograms <= 0 ? ("Body", "") : (Format.shown(kilograms), Format.unit.symbol)
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

    /// "180 lb, 4 sets of 5": the last session. Reps that differ are listed: "180 lb, 5, 5, 5 and 4". Different
    /// weights are listed set by set.
    static func lastTime(_ sets: [Entry]) -> String {
        guard let first = sets.first else { return "" }
        func load(_ kilograms: Double) -> String {
            let text = weightText(kilograms)
            return text.unit.isEmpty ? text.number : "\(text.number) \(text.unit)"
        }
        guard sets.allSatisfy({ $0.weight == first.weight }) else {
            return sets.map { "\(load($0.weight)), \(repsText($0.reps))" }.joined(separator: " and ")
        }
        if sets.allSatisfy({ $0.reps == first.reps }) {
            return "\(load(first.weight)), \(sets.count) \(sets.count == 1 ? "set" : "sets") of \(repsText(first.reps))"
        }
        let reps = sets.map { repsText($0.reps) }
        return "\(load(first.weight)), " + reps.dropLast().joined(separator: ", ") + " and " + (reps.last ?? "")
    }

    /// The foot's object for a lift: "set 1, 185 lb" (the first working set).
    static func startObject(_ lines: [SetLine]) -> String {
        guard let set = lines.first(where: { $0.label == "Set 1" }) ?? lines.first else { return "" }
        return "set 1, " + (set.unit.isEmpty ? set.weight : "\(set.weight) \(set.unit)")
    }

    /// "first lift", "second lift", ... "lift 7".
    static func ordinal(_ index: Int) -> String {
        let words = ["first", "second", "third", "fourth", "fifth", "sixth"]
        return words.indices.contains(index) ? "\(words[index]) lift" : "lift \(index + 1)"
    }

    /// "three days ago", "a week ago", "three weeks ago"; nil from a month on (the date reads instead).
    static func ago(_ date: Date, now: Date, calendar: Calendar) -> String? {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        let words = ["zero", "one", "two", "three", "four", "five", "six"]
        switch days {
        case ...0: return "today"
        case 1: return "yesterday"
        case 2 ..< 7: return "\(words[days]) days ago"
        case 7 ..< 14: return "a week ago"
        case 14 ..< 30: return "\(words[min(days / 7, 4)]) weeks ago"
        default: return nil
        }
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

    /// Today: the source workout, its rows, the sets each lift plans, and where each lift sits ("Push A, first lift").
    private struct TodayPage {
        var rows: [RankedRow] = []
        var planned: [UUID: Int] = [:]
        var position: [UUID: String] = [:]
    }

    /// Today's source (the workout running, tonight's, the routine, or the one finished today). A private workout is
    /// one row and nothing else.
    private static func today(model: AppModel, now: Date, calendar: Calendar) -> TodayPage {
        let store = model.store
        let source: ObjectRecord? = model.session?.workout ?? model.tonightWorkout(around: now)
            ?? model.triedRoutine() ?? model.todaysRoutine(now: now) ?? model.finishedToday(now: now).first?.workout
        var page = TodayPage()
        let name = source.map { ObjectPrivacy.routineTitle($0.title, in: store) } ?? ""
        if name == ObjectPrivacy.routineLabel {
            page.rows = [RankedRow(id: "page#private", title: name, isPrivate: true)]
            return page
        }
        for (index, slot) in (source?.orderedChildren.filter { !$0.isDeleted } ?? []).enumerated() {
            guard let exercise = store.linkedClass("exercise", of: slot),
                  !ObjectPrivacy.isPrivateWord(exercise.name, in: store) else { continue }
            let count = max(Int(store.number("targetSets", of: slot) ?? 3), 1)
            page.planned[exercise.id] = count
            page.position[exercise.id] = "\(name), \(DeckSets.ordinal(index))"
            let sessions = model.ledger.sessions(of: exercise)
            let logged = sessions.first.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
            let open = sessions.first { !calendar.isDate($0.date, inSameDayAs: now) }?.sets.first ?? logged?.sets.first
            let text = DeckSets.weightText(open?.weight ?? 0)
            let doneCount = logged?.sets.count ?? 0
            var sub = open.map { "\(count) sets of \(DeckSets.repsText($0.reps))" } ?? "\(count) sets"
            if doneCount > 0, doneCount < count {
                sub = "\(doneCount) of \(count) sets"
            }
            page.rows.append(RankedRow(
                id: "\(TrainingWallTarget.exercise(exercise.id).id)#t\(index)", title: exercise.name,
                value: open == nil ? "" : text.number, unit: open == nil ? "" : text.unit, sub: sub,
                state: doneCount >= count ? .done : .none
            ))
        }
        return page
    }

    /// This week, Monday first: only the days with something on them, a workout done or one planned. Today's row is
    /// titled "Today"; a done day says its minutes, a planned day "Plan". Never "missed".
    private static func week(model: AppModel, now: Date, calendar: Calendar) -> DeckDoorPage {
        let store = model.store
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan) ?? 0
        let days = model.ledger.week(containing: now, plan: plan, now: now,
                                     sessionsPerWeek: perWeek > 0 ? perWeek : nil, calendar: calendar)
        var rows: [RankedRow] = []
        var done = 0
        var planned = 0
        for (index, day) in days.enumerated() {
            let isToday = calendar.isDate(day.day, inSameDayAs: now)
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: day.day) - 1]
            let title = isToday ? "Today" : weekday
            let id = "week#\(index)"
            if let first = day.done.first {
                done += 1
                let name = ObjectPrivacy.routineTitle(first.title, in: store)
                let minutes = first.duration.map { Int(($0 / 60).rounded()) } ?? 0
                rows.append(RankedRow(id: id, title: title, value: minutes > 0 ? "\(minutes)" : "",
                                      unit: minutes > 0 ? "min" : "", sub: "\(name), done", state: .done,
                                      isPrivate: name == ObjectPrivacy.routineLabel))
            } else if let routine = day.planned, !day.isRest {
                planned += 1
                let name = ObjectPrivacy.routineTitle(routine.title, in: store)
                rows.append(RankedRow(id: id, title: title, value: isToday ? "" : "Plan", sub: name,
                                      isPrivate: name == ObjectPrivacy.routineLabel))
            }
        }
        return DeckDoorPage(line: "\(done) of \(done + planned) done", rows: rows)
    }

    /// Library: the workouts of every plan, their lifts as the sub and their usual minutes as the value; a private
    /// one is "Private workout". Nil when no routine exists (the caller keeps the lift list).
    private static func workouts(model: AppModel, wall _: TrainingWallFacts) -> DeckDoorPage? {
        let store = model.store
        var seen: Swift.Set<UUID> = []
        let routines = model.objects(of: .plan).flatMap { store.linkedObjects("routines", of: $0) }
            .filter { !$0.isDeleted && seen.insert($0.id).inserted }
        guard !routines.isEmpty else { return nil }
        let rows: [RankedRow] = routines.map { routine in
            let id = TrainingWallTarget.routine(routine.id).id
            let title = ObjectPrivacy.routineTitle(routine.title, in: store)
            guard title != ObjectPrivacy.routineLabel else {
                return RankedRow(id: id, title: title, sub: "Kept on the phone", isPrivate: true)
            }
            let slots = routine.orderedChildren.filter { !$0.isDeleted }
            let lifts = slots.compactMap { store.linkedClass("exercise", of: $0) }
                .filter { !ObjectPrivacy.isPrivateWord($0.name, in: store) }
                .prefix(4).map { TrainingWallFacts.lift($0.name) }
            let minutes = TrainingPage.estimatedMinutes(sets: NowPage.plannedSets(slots, store: store))
            return RankedRow(id: id, title: title, value: "\(minutes)", unit: "min", sub: lifts.joined(separator: ", "))
        }
        return DeckDoorPage(line: "\(rows.count) \(rows.count == 1 ? "workout" : "workouts")", rows: rows)
    }

    /// A lift's item page: facts and sets.
    private static func item(_ lift: Lift, today: TodayPage, now: Date, calendar: Calendar) -> DeckItem {
        let logged = lift.sessions.first.flatMap { calendar.isDate($0.date, inSameDayAs: now) ? $0 : nil }
        let before = lift.sessions.first { !calendar.isDate($0.date, inSameDayAs: now) }
        func sets(_ session: TrainingLedger.Session?) -> [DeckSets.Entry] {
            session?.sets.map { DeckSets.Entry(weight: $0.weight, reps: $0.reps) } ?? []
        }
        let count = today.planned[lift.exercise.id] ?? before?.sets.count ?? logged?.sets.count ?? 3
        let lines = DeckSets.lines(last: sets(before), today: sets(logged), planned: count)
        func fact(_ kilograms: Double?, _ label: String) -> ItemFact {
            guard let kilograms else { return ItemFact(number: "\u{2014}", label: label) }
            let text = DeckSets.weightText(kilograms)
            return ItemFact(number: text.number, unit: text.unit, label: label)
        }
        let open = (before ?? logged)?.sets.first?.weight
        let estimate = lift.best.flatMap { $0.e1RM > 0 ? $0.e1RM : nil }
        let day = lift.last.formatted(.dateTime.month(.abbreviated).day())
        return DeckItem(
            title: lift.exercise.name,
            line: today.position[lift.exercise.id] ?? "Last \(day)",
            facts: [fact(open, today.planned[lift.exercise.id] == nil ? "Last" : "Today"),
                    fact(lift.best?.weight, "Best"), fact(estimate, "Est. 1 rep")],
            sets: SetsBody(lines: lines, lastTime: DeckSets.lastTime(sets(before))),
            start: DeckSets.startObject(lines)
        )
    }

    static func load(model: AppModel, wall: TrainingWallFacts, now: Date = AppClock.now,
                     calendar: Calendar = .current) -> DeckPages
    {
        let store = model.store
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

        let today = today(model: model, now: now, calendar: calendar)

        // Bests: the newest bests first, every one in gold. A best from the last month says how long ago in words.
        let bests = lifts.compactMap { lift -> (Lift, TrainingLedger.LoggedSet, Date)? in
            guard let best = lift.best, best.weight > 0,
                  let when = lift.sessions.first(where: { $0.sets.contains { $0.id == best.id } })?.date
            else { return nil }
            return (lift, best, when)
        }.sorted { $0.2 > $1.2 }
        let bestRows = bests.map { lift, best, when in
            let text = DeckSets.weightText(best.weight)
            let reps = Int(best.reps.rounded())
            let whenText = DeckSets.ago(when, now: now, calendar: calendar) ?? day(when)
            return RankedRow(id: "best:\(lift.exercise.id.uuidString)#b", title: lift.exercise.name, value: text.number,
                             unit: text.unit, sub: "\(reps) \(reps == 1 ? "rep" : "reps"), \(whenText)", state: .best)
        }
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let fresh = bests.filter { $0.2 >= monthStart }.count

        // Library: the workouts; the lift list when no routine exists yet.
        let library = workouts(model: model, wall: wall) ?? DeckDoorPage(
            line: wall.doors.first { $0.id == "library" }?.label ?? "Nothing logged yet",
            rows: lifts.map { lift in
                let best = lift.best.map { DeckSets.weightText($0.weight) }
                return RankedRow(id: "\(TrainingWallTarget.exercise(lift.exercise.id).id)#l",
                                 title: lift.exercise.name, value: best?.number ?? "", unit: best?.unit ?? "",
                                 sub: "Last \(day(lift.last))")
            }
        )

        // Plan: the routines, today's first (Core has no block, deload or goal facts yet).
        let routines = model.plan.map { store.linkedObjects("routines", of: $0) }?.filter { !$0.isDeleted } ?? []
        let planRows: [RankedRow] = routines.map { routine in
            let title = ObjectPrivacy.routineTitle(routine.title, in: store)
            guard title != ObjectPrivacy.routineLabel else {
                return RankedRow(id: TrainingWallTarget.routine(routine.id).id, title: title, isPrivate: true)
            }
            let slots = routine.orderedChildren.filter { !$0.isDeleted }
            let minutes = TrainingPage.estimatedMinutes(sets: NowPage.plannedSets(slots, store: store))
            return RankedRow(id: TrainingWallTarget.routine(routine.id).id, title: title, value: "\(minutes)",
                             unit: "min", sub: "\(slots.count) \(slots.count == 1 ? "lift" : "lifts")")
        }

        func line(_ id: String, _ fallback: String) -> String {
            let door = wall.doors.first { $0.id == id }
            return door?.label ?? door?.lines.first ?? fallback
        }
        var pages = DeckPages()
        pages.doors["today"] = DeckDoorPage(line: line("today", "Nothing planned today"), rows: today.rows)
        pages.doors["week"] = week(model: model, now: now, calendar: calendar)
        pages.doors["library"] = library
        pages.doors["bests"] = DeckDoorPage(
            line: bestRows.isEmpty ? "None yet" : (fresh == 0 ? "None new" : "\(fresh) new since \(day(monthStart))"),
            rows: bestRows
        )
        pages.doors["plan"] = DeckDoorPage(line: line("plan", "No plan yet"), rows: planRows)
        for lift in lifts {
            pages.items[TrainingWallTarget.exercise(lift.exercise.id).id] = item(lift, today: today, now: now,
                                                                                 calendar: calendar)
        }
        return pages
    }
}
