import SwiftUI
import TesseraCore
import UIKit

// What Deck (the Training landing, sheets 258 and 283) writes on the blackboard and shows in the masthead and the
// widget. Built from the same facts as the doors; nothing here draws. Private routines read "Private workout".

/// One day of the week on the board: its letter, a chalk tick when trained, a chalk line under today.
struct BoardDay: Equatable, Identifiable {
    let id: Int
    let letter: String
    let done: Bool
    let isToday: Bool
    /// The first lift of the day's finished workout, so the day's row on the This week page opens that lift; nil on
    /// a day with nothing done or a private workout.
    var liftID: UUID?
    var liftName: String?
}

/// A best written small along the bottom of the board; tapping its number opens the lift.
struct BoardBest: Equatable, Identifiable {
    let id: UUID
    let lift: String
    let number: String
}

/// Everything the blackboard says (sheet 258 "Plan" fill).
struct TrainingBoard: Equatable {
    /// "Push A today" / "Rest today" / "Push A done": the large top line; tap opens today's workout.
    var headline: String
    /// "Bench Press opens at 80 kg.": the detail line under it.
    var detail: String
    var week: [BoardDay]
    var bests: [BoardBest]
    /// The split the headline belongs to, for a later colored chalk (241); the board stays near-white for now.
    var split: TrainingSplit?

    /// The headline cut on whole words to at most `limit` characters (the board never wraps or ellipsizes).
    static func fitted(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        for form in FitLine.cuts(text) where form.count <= limit {
            return form
        }
        return String(text.prefix(limit))
    }
}

/// Deck's masthead and widget content.
struct TrainingDeckFacts: Equatable {
    /// The widget's Big line in Deck's face (Barlow Condensed 600, 50 pt caps) cut on whole words to its 262 pt
    /// slot, trailing small words dropped: never "...".
    static func deckBig(_ text: String, width: CGFloat = 262) -> String {
        let font = UIFont(name: "BarlowCondensed-SemiBold", size: 50) ?? .systemFont(ofSize: 50, weight: .semibold)
        func fits(_ form: String) -> Bool {
            (form.uppercased() as NSString).size(withAttributes: [.font: font]).width <= width
        }
        var words = text.split(separator: " ").map(String.init)
        let small: Set = ["and", "the", "an", "of", "to", "in", "on", "or", "for", "with", "at"]
        while words.count > 1, !fits(words.joined(separator: " ")) || small.contains(words.last!.lowercased()) {
            words.removeLast()
        }
        return words.joined(separator: " ")
    }

    let board: TrainingBoard
    /// The vertical switcher: the plan's routines by name (private ones as "Private workout").
    let routineWords: [String]
    /// Two needs lines for each across word: Today, This week, This month.
    let needs: [[String]]
    let widget: [WidgetItem]

    static let across = ["Today", "This week", "This month"]

    /// Days trained this week as the widget's big number with its word.
    static func weekNumber(done: Int) -> (big: String, unit: String) {
        ("\(done)", done == 1 ? "day" : "days")
    }

    /// The longest form that fits a needs line (about 20 characters at 15 pt in 150 pt); the last form otherwise.
    static func pick(_ forms: [String], limit: Int = 20) -> String {
        let usable = forms.filter { !$0.isEmpty }
        return usable.first { $0.count <= limit } ?? usable.last ?? ""
    }

    /// "2 to go" or "Week done" or "No plan days": never a counter.
    static func leftWords(done: Int, perWeek: Int) -> String {
        guard perWeek > 0 else { return done > 0 ? "Trained this week" : "No plan days" }
        let left = max(perWeek - done, 0)
        return left == 0 ? "Week done" : "\(left) to go"
    }
}

@MainActor
extension TrainingDeckFacts {
    /// The board's week: a letter per day, done or not, and (for a done day) the first lift of its first finished,
    /// non-private workout, so the day's row can open that lift.
    static func boardDays(_ week: [WeekDay], today: Date, letters: [String], store: ObjectStore,
                          calendar: Calendar) -> [BoardDay]
    {
        func shown(_ title: String) -> String {
            ObjectPrivacy.routineTitle(title, in: store)
        }
        return week.enumerated().map { index, slot in
            // The day's first finished, non-private workout names the lift its row opens.
            let lift = slot.done.lazy
                .filter { shown($0.title) != ObjectPrivacy.routineLabel }
                .compactMap { summary in
                    summary.workout.orderedChildren.lazy.filter { !$0.isDeleted }
                        .compactMap { store.linkedClass("exercise", of: $0) }
                        .first { !ObjectPrivacy.isPrivateWord($0.name, in: store) }
                }
                .first
            return BoardDay(id: index, letter: letters[calendar.component(.weekday, from: slot.day) - 1],
                            done: !slot.done.isEmpty, isToday: slot.day == today,
                            liftID: lift?.id, liftName: lift.map { TrainingWallFacts.lift($0.name) })
        }
    }

    static func load(_ model: AppModel, wall: TrainingWallFacts, now: Date = AppClock.now,
                     dark: Bool = false, calendar: Calendar = .current) -> TrainingDeckFacts
    {
        let store = model.store
        func shown(_ title: String) -> String {
            ObjectPrivacy.routineTitle(title, in: store)
        }
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan) ?? 0
        let week = model.ledger.week(containing: now, plan: plan, now: now,
                                     sessionsPerWeek: perWeek > 0 ? perWeek : nil, calendar: calendar)
        let today = TesseraDay(calendar: calendar).today(now)
        let letters = calendar.veryShortWeekdaySymbols
        let days = boardDays(week, today: today, letters: letters, store: store, calendar: calendar)
        let doneDays = days.filter(\.done).count

        // Bests from the lifts that have them, newest lifts first.
        var bests: [BoardBest] = []
        for exercise in ExerciseLibraryList.groups(model).flatMap(\.exercises) {
            guard !ObjectPrivacy.isPrivateWord(exercise.name, in: store),
                  let best = model.ledger.bestSet(of: exercise), best.weight > 0 else { continue }
            bests.append(BoardBest(id: exercise.id, lift: TrainingWallFacts.lift(exercise.name),
                                   number: Format.mass(best.weight)))
        }
        bests = Array(bests.prefix(3))

        let headline: String
        var split: TrainingSplit?
        switch wall.day {
        case let .ready(name, _, _):
            headline = "\(name) today"
            split = TrainingSplit(name: name)
        case let .running(name, _):
            headline = "\(name) under way"
            split = TrainingSplit(name: name)
        case let .done(name, _):
            headline = "\(name) done"
        case .rest:
            headline = "Rest today"
        case .nothing:
            headline = "No plan yet"
        }
        let detail = wall.brief?.text ?? TrainingDeckFacts.leftWords(done: doneDays, perWeek: perWeek)
        let board = TrainingBoard(headline: TrainingBoard.fitted(headline, limit: 24),
                                  detail: TrainingBoard.fitted(detail, limit: 38),
                                  week: days, bests: bests, split: split)

        var routineWords: [String] = []
        for routine in plan.map({ store.linkedObjects("routines", of: $0) })?.filter({ !$0.isDeleted }) ?? [] {
            let name = shown(routine.title)
            if !routineWords.contains(name) {
                routineWords.append(name)
            }
        }

        // The month so far, from finished workouts day by day.
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        var monthCount = 0
        var cursor = today
        while cursor >= monthStart {
            monthCount += model.finishedWorkouts(on: cursor).count
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let left = leftWords(done: doneDays, perWeek: perWeek)
        let state = wall.stateLine
        let bestLine = bests.first.map { "\($0.lift) best \($0.number)" } ?? "No bests yet"
        // Needs lines are 150 pt wide: each takes the longest of its own written forms that fits about 20
        // characters, so a sentence is never cut mid-thought ("Rest today. Next").
        let briefForms = wall.brief.map { [$0.text, $0.name] } ?? []
        let needs: [[String]] = [
            [pick(state), pick(briefForms + [left])],
            [doneDays == 0 ? "Nothing yet" : "\(doneDays) \(doneDays == 1 ? "day" : "days") trained", left],
            [monthCount == 0 ? "Nothing yet" : "\(monthCount) this month", pick([bestLine, bests.first?.lift ?? ""])],
        ]

        var widget: [WidgetItem] = []
        switch wall.day {
        case let .ready(name, minutes, lifts):
            let when = model.tonightWorkout(around: now) != nil ? "Tonight" : "Today"
            widget.append(WidgetItem(id: "today", header: when, big: name,
                                     middle: "About \(minutes) min, \(lifts) \(lifts == 1 ? "lift" : "lifts")",
                                     small: wall.brief?.text ?? "Tap to open it",
                                     bigColor: TrainingSplit(name: name)?.color(dark: dark), strikeable: false,
                                     middleShort: "\(minutes) min", smallShort: wall.brief?.name))
        case let .running(name, done):
            widget.append(WidgetItem(id: "today", header: "Under way", big: name,
                                     middle: done > 0 ? "\(done) \(done == 1 ? "lift" : "lifts") done" : "Just started",
                                     small: "Tap to pick it up", strikeable: false))
        case let .done(name, next):
            widget.append(WidgetItem(id: "today", header: "Today", big: name, middle: "Done",
                                     small: next.map { "Next is \($0)" } ?? "", strikeable: false))
        case let .rest(next, _):
            widget.append(WidgetItem(id: "today", header: "Today", big: "Rest",
                                     middle: next.map { "Next is \($0)" } ?? "A rest day counts too",
                                     small: "", strikeable: false, middleShort: next ?? "Rest"))
        case .nothing:
            break
        }
        let number = weekNumber(done: doneDays)
        widget.append(WidgetItem(id: "week", header: "This week", big: number.big, bigIsNumber: true, unit: number.unit,
                                 middle: left, small: bestLine, strikeable: false))
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let finished = model.finishedWorkouts(on: yesterday)
            if let first = finished.first {
                widget.append(WidgetItem(id: "yesterday",
                                         header: "Yesterday",
                                         big: shown(first.title),
                                         middle: "\(first.exercisesDone) \(first.exercisesDone == 1 ? "lift" : "lifts"), \(first.sets) sets",
                                         small: "Tap for the week", strikeable: false))
            } else {
                widget.append(WidgetItem(id: "yesterday", header: "Yesterday", big: "Rest",
                                         middle: "Walks come in from Health", small: "", strikeable: false))
            }
        }
        // Deck's Big line is Barlow Condensed in caps (283 v3); numbers stay Outfit.
        widget = widget.map { item in
            var item = item
            item.face = .deck
            // Deck blue unless the item is a split (241: Push clay, Pull teal, Legs plum).
            if item.bigColor == nil {
                item.bigColor = Theme.Colors.Accent.training
            }
            if !item.bigIsNumber {
                item.big = Self.deckBig(item.big)
            }
            return item
        }
        return TrainingDeckFacts(board: board, routineWords: routineWords, needs: needs, widget: widget)
    }
}
