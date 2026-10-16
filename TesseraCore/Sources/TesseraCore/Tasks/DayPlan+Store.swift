import Foundation

@MainActor
public extension DayPlanner {
    /// The rules' input from his data: today's open tasks and Later, the day's workout, and whether the day is light
    /// (C1 to C3). Calendar events come from the app (none until the calendar is read).
    static func input(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], plan: ObjectRecord?, now: Date,
                      calendar: Calendar = .current, events: [PlanInput.Event] = []) -> PlanInput
    {
        var input = PlanInput(now: now, calendar: calendar)
        input.events = events
        let tasks = TaskList(store: store, classes: classes)
        let tesseraDay = TesseraDay(calendar: calendar)
        let dayStart = tesseraDay.start(of: now), dayEnd = tesseraDay.end(of: now)
        func task(_ item: TaskList.Item) -> PlanInput.Task {
            let record = item.task
            let startsAt = store.value("startsAt", of: record)?.dateValue
            let due = store.value("due", of: record)?.dateValue
            let midnight = due.map { calendar.dateComponents([.hour, .minute], from: $0) }
            let about = store.linkedObjects("about", of: record)
            let isCook = record.title.lowercased().hasPrefix("cook ")
                || about.contains { $0.classDef?.id == classes[.recipe]?.id }
            return PlanInput.Task(
                id: item.id, title: item.title,
                startsAt: startsAt.flatMap { $0 >= dayStart && $0 < dayEnd ? $0 : nil },
                due: due, dueIsDateOnly: midnight == DateComponents(hour: 0, minute: 0),
                minutes: store.value("length", of: record)?.numericValue.map { $0 / 60 },
                rolls: item.rolls, rolledFrom: store.value("rolledFrom", of: record)?.dateValue,
                updatedAt: record.updatedAt, isCook: isCook
            )
        }
        let today = tasks.today(now, calendar: calendar).filter { !$0.isDone }
        input.today = today.map(task)
        input.later = tasks.later().map(task)
        // The day's workout: under way today, else scheduled for today and not finished.
        let ledger = TrainingLedger(store: store, classes: classes)
        if let workoutClass = classes[.workout] {
            // Earliest first, so the choice never depends on store order (merge check on #290).
            let workouts = store.objects(of: workoutClass).sorted { lhs, rhs in
                let left = (store.value("startedAt", of: lhs) ?? store.value("scheduledFor", of: lhs))?.dateValue
                let right = (store.value("startedAt", of: rhs) ?? store.value("scheduledFor", of: rhs))?.dateValue
                return (left ?? .distantFuture, lhs.id.uuidString) < (right ?? .distantFuture, rhs.id.uuidString)
            }
            let started = workouts.first { workout in
                store.value("endedAt", of: workout) == nil
                    && store.value("startedAt", of: workout)?.dateValue.map { tesseraDay.isSameDay($0, now) } == true
            }
            let scheduled = workouts.first { workout in
                store.value("endedAt", of: workout) == nil && store.value("startedAt", of: workout) == nil
                    && store.value("scheduledFor", of: workout)?.dateValue.map { $0 >= dayStart && $0 < dayEnd } == true
            }
            if let workout = started ?? scheduled {
                input.workout = PlanInput.Workout(
                    id: workout.id, title: store.displayTitle(of: workout),
                    scheduledFor: store.value("scheduledFor", of: workout)?.dateValue,
                    startedAt: store.value("startedAt", of: workout)?.dateValue
                )
            }
        }
        let restDay = ledger.restDay(plan: plan, now: now, calendar: calendar)
        // No Workout object yet on a training day (his phone never sets scheduledFor): today's routine from the
        // rhythm, date-only, so it takes the first free hour from 17:00 (QA B1 on #290).
        if input.workout == nil, let plan, restDay == nil,
           ledger.finishedWorkouts(on: now, calendar: calendar).isEmpty,
           let routine = ledger.week(containing: now, plan: plan, now: now, calendar: calendar)
           .first(where: { $0.state == .today })?.planned
        {
            input.workout = PlanInput.Workout(id: routine.id, title: store.displayTitle(of: routine),
                                              scheduledFor: tesseraDay.day(of: now))
        }
        // Light (light-day.md): C1 squeezed week, C2 booked, C3 cut up. Done tasks count in both, so the cap doesn't
        // flip as he ticks things off (QA L1).
        let perWeek = plan.flatMap { store.number("sessionsPerWeek", of: $0) }.map { Int($0) }
        let week = tesseraDay.weekDays(containing: now)
        let todayKey = tesseraDay.day(of: now)
        let before = week.filter { $0 < todayKey }
            .reduce(0) { $0 + ledger.finishedWorkouts(onDay: $1, calendar: calendar).count }
        let daysLeft = week.count { $0 >= todayKey }
        let opens = calendar.date(bySettingHour: windowFloorHour, minute: 0, second: 0, of: todayKey) ?? todayKey
        let closes = calendar.date(bySettingHour: windowEndHour, minute: 0, second: 0, of: todayKey) ?? todayKey
        let window = opens ... max(opens, closes)
        let busy = events.filter { !$0.allDay && !$0.declined }.reduce(0.0) { total, event in
            let start = max(event.start, window.lowerBound), end = min(event.end, window.upperBound)
            return total + max(0, end.timeIntervalSince(start) / 60)
        }
        let taskMinutes = tasks.today(now, calendar: calendar).reduce(0.0) { total, item in
            total + (store.value("length", of: item.task)?.numericValue.map { $0 / 60 } ?? defaultTaskMinutes)
        }
        let fixed = events.count { !$0.allDay && !$0.declined && $0.end > window.lowerBound
            && $0.start < window.upperBound
        } + tasks.today(now, calendar: calendar).count { item in
            item.rolls == 0 && store.value("startsAt", of: item.task)?.dateValue.map { window.contains($0) } == true
        }
        input.lightReason = lightReason(trainingDay: plan != nil && restDay == nil, perWeek: perWeek,
                                        sessionsBeforeToday: before, daysLeft: daysLeft,
                                        bookedMinutes: busy + taskMinutes +
                                            (plan != nil && restDay == nil ? workoutMinutes : 0),
                                        fixedBlocks: fixed)
        return input
    }

    /// Today's rules plan from his data.
    static func plan(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], plan: ObjectRecord?, now: Date,
                     calendar: Calendar = .current, events: [PlanInput.Event] = []) -> DayPlan
    {
        self.plan(input(store: store, classes: classes, plan: plan, now: now, calendar: calendar, events: events))
    }
}
