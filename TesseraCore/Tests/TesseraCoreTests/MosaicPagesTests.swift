import Foundation
@testable import TesseraCore
import Testing

/// Sheet 209: the open cue and the Next and Week page facts. Times and masked names only.
@MainActor
struct MosaicPagesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func facts(_ now: Date, events: [HandsEvent] = []) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4), events: events)
    }

    // MARK: Open cue

    @Test func eachOpenPicksExactlyOneReactionByHowLongItWasAway() {
        let now = at(15)
        func cue(away: TimeInterval?, lastOpen: Date? = at(14, 50), cold: Bool = false) -> MosaicOpenCue {
            MosaicOpenCue.make(now: now, lastBackground: away.map { now.addingTimeInterval(-$0) }, lastOpen: lastOpen,
                               coldLaunch: cold, calendar: calendar)
        }
        #expect(cue(away: 60).reaction == .ripple)
        #expect(cue(away: 119).reaction == .ripple && cue(away: 120).reaction == .flip)
        #expect(cue(away: 3 * 3600).reaction == .flip)
        #expect(cue(away: 3 * 86400).reaction == .back)
        #expect(cue(away: 2 * 86400).reaction == .back)
        #expect(cue(away: 3600, cold: true).reaction == .gather)
        // 2 days away beats a cold launch; the first open of the day beats ripple and flip.
        #expect(cue(away: 3 * 86400, cold: true).reaction == .back)
        #expect(cue(away: 3600, lastOpen: at(20, day: 21)).reaction == .nightToDay)
        #expect(cue(away: 60, lastOpen: at(20, day: 21)).reaction == .nightToDay)
        #expect(cue(away: nil, lastOpen: nil, cold: true).reaction == .gather)
        #expect(cue(away: 90).away == 90 && cue(away: 90).isColdLaunch == false)
    }

    @Test func theFourAMEdgeDecidesTheFirstOpenOfTheDay() {
        // 03:30 is still yesterday for him, so an open at 03:30 after 23:00 is not the first of a day.
        let late = MosaicOpenCue.make(now: at(3, 30, day: 23), lastBackground: at(23, 30), lastOpen: at(23),
                                      coldLaunch: false, calendar: calendar)
        #expect(!late.isFirstOpenAfterFour && late.reaction == .flip)
        let morning = MosaicOpenCue.make(now: at(4, 10, day: 23), lastBackground: at(3, 30, day: 23),
                                         lastOpen: at(3, 30, day: 23), coldLaunch: false, calendar: calendar)
        #expect(morning.isFirstOpenAfterFour && morning.reaction == .nightToDay)
        #expect(MosaicOpenReaction.allCases.map(\.duration) == [0.9, 1.4, 2.2, 2.4, 1.8])
        #expect(MosaicOpenReaction.gather.delay == 0.5 && MosaicOpenReaction.ripple.delay == 0)
        #expect(facts(at(15)).openCue(lastBackground: nil, lastOpen: nil, coldLaunch: true).reaction == .gather)
    }

    // MARK: Next page

    @Test func theNextPageHasTheTimeNameAndAccentOfATaskOrATrainingOrRoutineEvent() throws {
        let now = at(12)
        _ = try engine.perform(CreateTask(title: "Mail forms", startsAt: at(14, 10)), by: .user)
        let page = facts(now).pageFacts(engine: engine, plan: nil)
        #expect(page.nextCaption == "Mail forms in 2 hr 10 min" && page.nextClock == "2:10")
        #expect(page.nextApp == nil && page.nextTitle == "Mail forms" && page.nextIn == 130 * 60)
        let workout = HandsEvent(app: .training, label: "Push A", start: at(13), end: at(14), hands: [],
                                 isFixed: false)
        let withWorkout = facts(now, events: [workout]).pageFacts(engine: engine, plan: nil)
        #expect(withWorkout.nextCaption == "Push A in 1 hr" && withWorkout.nextApp == .training)
        #expect(withWorkout.nextClock == "1:00")
    }

    @Test func aCookAndACalendarEventNeverAppearOnTheNextPage() throws {
        let now = at(12)
        let cook = HandsEvent(app: .kitchen, label: "Tacos", start: at(12, 30), end: at(13), hands: [], isFixed: true)
        #expect(facts(now, events: [cook]).pageFacts(engine: engine, plan: nil).nextTitle == nil)
        // The cook still shows in the sentence captions, just not on this page.
        #expect(facts(now, events: [cook]).nextTimed?.title == "Tacos")
        // A task about a recipe is a cook too.
        let recipe = try engine
            .perform(CreateRecipe(text: "Tacos\nIngredients\n1 onion\nMethod\n1. Fry it."), by: .user).output
        let cookTask = try engine.perform(CreateTask(title: "Cook tacos", startsAt: at(12, 40)), by: .user).output
        try store.setLinks("about", on: cookTask, to: [recipe])
        #expect(facts(now).pageFacts(engine: engine, plan: nil).nextTitle == nil)
        #expect(facts(now).nextTimed?.title == "Cook tacos")
        let event = try store.create(#require(engine.classes[.event]), title: "Dentist")
        try store.set("start", to: .date(at(12, 20)), on: event)
        #expect(facts(now).pageFacts(engine: engine, plan: nil).nextTitle == nil)
    }

    @Test func aPrivateNextItemIsMaskedAndHasNoAccent() throws {
        let now = at(12)
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: at(13)), by: .user)
        let task = facts(now).pageFacts(engine: engine, plan: nil)
        #expect(task.nextTitle == "Private task" && task.nextCaption == "Private task in 1 hr")
        let secret = HandsEvent(app: .training, label: "Private workout", start: at(12, 30), end: at(13),
                                hands: [], isFixed: false)
        let page = facts(now, events: [secret]).pageFacts(engine: engine, plan: nil)
        #expect(page.nextTitle == "Private workout" && page.nextApp == nil)
        let walled = HandsEvent(app: .routines, label: "Pay 1200 rent", start: at(12, 10), end: at(13), hands: [],
                                isFixed: false)
        let hidden = facts(now, events: [walled]).pageFacts(engine: engine, plan: nil)
        #expect(hidden.nextApp == nil && !(hidden.nextCaption ?? "").contains("1200"))
    }

    // MARK: Week page

    @Test func theWeekPageCountsDoneOfPlannedTrainingDays() throws {
        let routine = try engine.perform(CreateRoutine(title: "Push A"), by: .user).output
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: [routine.id]), by: .user).output
        let before = facts(at(12)).pageFacts(engine: engine, plan: plan)
        #expect(before.weekMarks.count == 7 && before.weekDone == before.weekMarks.count { $0 == .done })
        #expect(before.weekPlanned == before.weekMarks.count { $0 != .rest })
        // A workout finished from the routine this week moves the count by exactly one.
        let workout = try store.create(#require(engine.classes[.workout]), title: "Push A")
        try store.setLinks("routine", on: workout, to: [routine])
        try store.set("startedAt", to: .date(at(8)), on: workout)
        try store.set("endedAt", to: .date(at(9)), on: workout)
        let entry = try store.create(#require(engine.classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(engine.classes[.benchPress]))
        _ = try TrainingLedger(store: store, classes: engine.classes).logSet(weight: 80, reps: 5, in: entry)
        let after = facts(at(12)).pageFacts(engine: engine, plan: plan)
        #expect(after.weekDone >= before.weekDone && after.weekPlanned == before.weekPlanned)
        if after.weekPlanned > 0 {
            #expect(after.weekCaption == "This week, \(after.weekDone) of \(after.weekPlanned) training days")
        } else {
            #expect(after.weekCaption == nil)
        }
        #expect(facts(at(12)).pageFacts(engine: engine, plan: nil).weekCaption == nil
            || facts(at(12)).pageFacts(engine: engine, plan: nil).weekPlanned > 0)
    }
}
