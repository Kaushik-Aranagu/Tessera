import SwiftUI
import TesseraCore
import TesseraTess

/// The Tasks app (sheet 140): its Review switch and the facts its landing and rail read. Accent is ink, so the page
/// carries no hue; its one underline (Do it) is ink too. Off leaves the app as it was.
enum TasksApp {
    nonisolated static let choiceID = "tasksApp"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    /// "from Tuesday": a carried task names the day it came from, never "overdue", "late" or "missed".
    nonisolated static func fromWord(_ date: Date, calendar: Calendar = .current) -> String {
        "from \(TesseraDay.weekdayName(of: date, calendar: calendar))"
    }
}

/// What the Tasks landing and rail show, read once per redraw.
@MainActor
struct TasksFront {
    struct Line: Identifiable, Equatable {
        let id: UUID
        /// "Private task" for a private one.
        let title: String
        let when: Date?
        let carried: Bool

        /// The right-hand word of a row: "from Tuesday" when carried, else the time, else nothing.
        func value(calendar: Calendar = .current) -> String {
            guard let when else { return "" }
            return carried ? TasksApp.fromWord(when, calendar: calendar) : HouseTime.clock(when, calendar: calendar)
        }
    }

    let now: Date
    /// Now: the picker's first task.
    let lead: Line?
    /// "First, two minutes: ..." when Core offers one for the lead.
    let firstStep: String?
    /// After that: the next two tasks.
    let after: [Line]
    let today: [Line]
    let soon: [Line]
    let later: [Line]

    init(model: AppModel, now: Date = AppClock.now) {
        self.now = now
        let list = TaskList(store: model.store, classes: model.classes)
        let todayItems = list.today(now)
        func line(_ item: TaskList.Item) -> Line {
            Line(id: item.id, title: AreaLines.taskTitle(item.title, id: item.id, model: model),
                 when: item.when, carried: item.isCarriedOver)
        }
        today = todayItems.filter { !$0.isDone }.map(line)
        soon = list.upcoming(now).map(line)
        later = list.later().map(line)

        let ranked = NowPicker(engine: model.engine).pick(at: now, next: 8, plan: model.plan)
        let tasks = ([ranked.now].compactMap(\.self) + ranked.next).filter { $0.kind == .task }
        func picked(_ item: NowItem) -> Line {
            if let found = todayItems.first(where: { $0.id == item.object.id }) {
                return line(found)
            }
            return Line(id: item.object.id,
                        title: AreaLines.taskTitle(item.title, id: item.object.id, model: model),
                        when: item.startsAt, carried: false)
        }
        lead = tasks.first.map(picked)
        after = tasks.dropFirst().prefix(2).map(picked)
        if let first = tasks.first,
           let offer = FirstStep(store: model.store, classes: model.classes).offer(now: now),
           offer.task == first.object.id
        {
            firstStep = offer.step
        } else {
            firstStep = nil
        }
    }

    func lines(in place: String) -> [Line] {
        switch place {
        case "now": lead.map { [$0] } ?? []
        case "today": today
        case "soon": soon
        default: later
        }
    }
}

/// Finish and "not now", as Home's queue does them: Core's SetTaskDone and MoveTask, then Tess says it with a 10 s
/// Undo.
@MainActor
enum TasksActions {
    /// Finishes it; Tess says "done" only when the engine took it (QA on #1267). Returns whether it landed.
    @discardableResult
    static func finish(_ line: TasksFront.Line, model: AppModel) -> Bool {
        guard let record = try? model.engine.perform(SetTaskDone(task: line.id, done: true), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again")
            return false
        }
        model.touch()
        TessVoice.shared.say("\(line.title), done", undo: record)
        return true
    }

    /// Tomorrow for a dated task, next week for an undated one (09:00 of his day seven days on).
    @discardableResult
    static func notNow(_ line: TasksFront.Line, model: AppModel) -> Bool {
        let day = TesseraDay()
        let target: Date? = line.when == nil
            ? day.adding(days: 7, to: day.start(of: AppClock.now)).addingTimeInterval(5 * 3600)
            : nil
        guard let record = try? model.engine.perform(MoveTask(task: line.id, to: target, time: AppClock.now), by: .user)
            .record
        else {
            TessVoice.shared.say("Didn't save that. Try again")
            return false
        }
        model.touch()
        let moved = model.store.object(id: line.id).flatMap { model.store.value("startsAt", of: $0)?.dateValue }
        let when = line.when == nil ? "next week"
            : moved.map { TessCaptureEngine.when($0, context: TessContext(now: AppClock.now)) } ?? "tomorrow"
        TessVoice.shared.say("\(line.title), \(when)", undo: record)
        return true
    }
}
