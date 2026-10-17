import Foundation
@testable import TesseraCore
import Testing

/// The Home lines lens (docs/ai/first-features.md 1a, fixtures H1 to H12; Design 41's slots).
@MainActor
struct HomeLinesTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    /// A wall-clock moment in Los Angeles, Thursday 15 October 2026.
    static func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: hour, minute: minute))!
    }

    func text(_ fact: HomeFact, now: Date = at(21, 40)) -> String {
        HomeLines.line(for: fact, now: now, calendar: Self.calendar).text
    }

    // MARK: The nine rules rows

    @Test func workoutDone() {
        // H1, H11, H12: "{Routine} done." plus the record when there is one.
        let done = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, exercisesDone: 6,
                            exercisesPlanned: 6, records: ["Bench"], endedAt: Self.at(20, 5))
        let line = HomeLines.line(for: done, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Push A done. Bench best.") // "best", never "record" (Design G3)
        #expect(line.widgetLine == "Push A done. Bench best." && line.widgetMeta == "8:05 pm")
        #expect(line.hero == "Push A done" && line.context == "8:05 pm" && line.contextShort == line.context)
        #expect(line.detail == "6 exercises, 22 sets, 1 new best.")
        // The facts' numbers, then every digit in the rules words (8:05 gives 8 and 5), each once.
        #expect(line.numbers == [6, 22, 8, 5, 1] && line.names == ["Push A", "Bench"] && !line.fixed)
        let plain = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 20, exercisesDone: 6,
                             exercisesPlanned: 6)
        #expect(text(plain) == "Push A done.")
        let two = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 20, exercisesDone: 6,
                           exercisesPlanned: 6, records: ["Bench", "Press"])
        #expect(text(two) == "Push A done. 2 bests." && two.factNumbers == [6, 6, 20, 2])
        #expect(HomeLines.line(for: two).widgetLine == "Push A done. 2 bests.")
        #expect(HomeLines.detail(for: two) == "6 exercises, 20 sets, 2 new bests.")
    }

    @Test func workoutDoneWithNothingLogged() {
        // H10: matches ProcessTable's overnight line.
        let empty = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 0, exercisesDone: 0,
                             exercisesPlanned: 6, endedAt: Self.at(15, 10))
        let line = HomeLines.line(for: empty, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Push A, no sets." && line.hero == "Push A, no sets")
        // Only when, and never Claude's to comment on.
        #expect(line.context == "this afternoon" && line.fixed)
    }

    @Test func workoutRunningAndPaused() {
        // H3, H4: the exercise in focus and the set he is on; weight and reps stay one tap down.
        let running = HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .running, exercise: "Squat", step: 3,
                               exercisesDone: 1, exercisesPlanned: 5, startedAt: Self.at(21, 32))
        let live = HomeLines.line(for: running, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(live.text == "Squat, set 3." && live.hero == "Legs, squat set 3")
        #expect(live.context == "now" && live.fixed) // no network while he lifts
        #expect(live.numbers == [3, 1, 5, 0])
        let paused = HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, exercise: "Row", step: 2,
                              sets: 5, exercisesDone: 2, exercisesPlanned: 5, startedAt: Self.at(20, 30),
                              lastTouchedAt: Self.at(21, 0))
        let rest = HomeLines.line(for: paused, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(rest.text == "Row paused at set 2." && rest.hero == "Pull B, paused at row")
        #expect(rest.context == "paused 40 min ago" && rest.contextShort == "paused 40 min")
        #expect(rest.detail == "2 exercises, 5 sets." && !rest.fixed)
        // Paused before any exercise was started: the routine alone.
        let fresh = HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, startedAt: Self.at(21, 39))
        let line = HomeLines.line(for: fresh, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Pull B paused." && line.hero == "Pull B, paused")
        #expect(line.context == "paused just now" && line.contextShort == "paused just now") // under 2 min (G11)
        let now = HomeLines.line(for: fresh, now: Self.at(21, 39), calendar: Self.calendar)
        #expect(now.context == "paused just now" && now.contextShort == "paused just now")
    }

    @Test func routinePlannedToday() {
        // H5, H6: "this evening" from 17:00 to 21:00, "today" the rest of his day.
        let legs = HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .planned)
        #expect(text(legs, now: Self.at(18, 10)) == "Legs this evening.")
        #expect(text(legs, now: Self.at(23)) == "Legs tonight.")
        #expect(text(legs, now: Self.at(9)) == "Legs today.")
        let line = HomeLines.line(for: legs, now: Self.at(18, 10), calendar: Self.calendar)
        #expect(line.hero == "Legs" && line.context == "this evening" && line.detail == nil && line.numbers.isEmpty)
        // H2: days since the same routine, for Claude's "first in 9 days", licensed as a digit.
        let back = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .planned, sinceLastDays: 9)
        #expect(HomeLines.line(for: back, now: Self.at(9), calendar: Self.calendar).numbers == [9])
    }

    @Test func restDay() {
        // H7: the existing RestDay line, a stop on the row, none on the hero.
        let rest = HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned)
        let line = HomeLines.line(for: rest, now: Self.at(12), calendar: Self.calendar)
        // The day label above already names the day (Builder B's #366): "today", with the weekday as widget meta.
        #expect(line.text == "Rest day." && line.hero == "Rest day" && line.context == "today")
        // Widgets have no day label: "Rest day." with the weekday as the meta (home-lines.md §2, Design 54).
        #expect(line.widgetLine == "Rest day." && line.widgetMeta == "Thursday")
        #expect(HomeLines.weekday(now: Self.at(12), calendar: Self.calendar) == "Thursday")
        #expect(line.objectID == nil && line.detail == nil)
        // At 01:00 Friday his day is still Thursday (QA on #334).
        #expect(HomeLines.weekday(now: Self.at(1).addingTimeInterval(86400), calendar: Self.calendar) == "Thursday")
        // Tomorrow's look ahead (Design 44, Research G12).
        let tomorrow = HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned, tomorrow: true)
        let ahead = HomeLines.line(for: tomorrow, now: Self.at(22), calendar: Self.calendar)
        #expect(ahead.text == "Rest day." && ahead.hero == "Rest day tomorrow" && ahead.context == "tomorrow")
        let pull = HomeFact(id: UUID(), kind: .workout, title: "Pull A", state: .planned, tomorrow: true)
        let next = HomeLines.line(for: pull, now: Self.at(22), calendar: Self.calendar)
        #expect(next.text == "Pull A tomorrow." && next.hero == "Pull A" && next.context == "tomorrow, first")
        #expect(next.widgetLine == "Pull A tomorrow, first.")
    }

    @Test func cookingAndShopping() {
        // H8, H9.
        let chili = HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .paused, step: 3, steps: 8,
                             startedAt: Self.at(19))
        let cook = HomeLines.line(for: chili, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(cook.text == "Chili, on step 3." && cook.hero == "Chili, step 3" && cook.detail == "Step 3 of 8.")
        #expect(cook.context == "paused 3 h ago" && cook.contextShort == "paused 3 h" && cook.numbers == [3, 8])
        // A finished cook stays on Home like a done workout (Research G1).
        let done = HomeFact(id: UUID(), kind: .cook, title: "Tacos", state: .done, startedAt: Self.at(20, 30),
                            endedAt: Self.at(21, 40))
        let served = HomeLines.line(for: done, now: Self.at(22), calendar: Self.calendar)
        #expect(served.text == "Tacos done." && served.hero == "Tacos done" && served.context == "9:40 pm")
        #expect(served.detail == nil && served.widgetLine == "Tacos done." && served.widgetMeta == "9:40 pm")
        // A paused shop is him at home, not at the store (Research G2).
        let home = HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .paused, step: 2,
                            lastTouchedAt: Self.at(12, 45))
        #expect(HomeLines.line(for: home, now: Self.at(14, 10), calendar: Self.calendar).context == "paused 1 h ago")
        let live = HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .running, step: 1, steps: 8)
        #expect(HomeLines.line(for: live).context == "now")
        let shop = HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 4,
                            startedAt: Self.at(21, 20))
        let line = HomeLines.line(for: shop, now: Self.at(21, 40), calendar: Self.calendar)
        #expect(line.text == "Groceries: 4 left." && line.hero == "Groceries, 4 left" && line.detail == "4 items left.")
        #expect(line.context == "at the store")
        let basket = HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 0)
        #expect(text(basket) == "Groceries: all in the basket." && HomeLines
            .detail(for: basket) == "All in the basket.")
        #expect(text(HomeFact(id: Groceries.listID, kind: .shop, title: "Groceries", state: .running, step: 1))
            == "Groceries: 1 left.")
    }

    @Test func timedTaskKeepsHisWords() {
        let task = HomeFact(id: UUID(), kind: .task, title: "Call the bank about the card", state: .planned,
                            startsAt: Self.at(18, 30))
        let line = HomeLines.line(for: task, now: Self.at(12), calendar: Self.calendar)
        #expect(line.text == "Call the bank about the card" && line.hero == line.text)
        #expect(line.context == "6:30 pm" && line.detail == nil && line.numbers == [6, 30])
    }

    @Test func aPlannedCookCarriesWhatIsStillToBuy() {
        // Product (72954ac): groceries never notify; the planned cook's line carries the count.
        let tacos = HomeFact(id: UUID(), kind: .cook, title: "Tacos", state: .planned, toBuy: 2)
        let line = HomeLines.line(for: tacos, now: Self.at(18, 30), calendar: Self.calendar)
        // A cook is an evening thing: "tonight" from 17:00, "today" before (Kitchen lead, G8); a time reads the time.
        #expect(line.text == "Tacos tonight, 2 to buy." && line.hero == "Tacos tonight")
        #expect(line.widgetLine == "Tacos tonight, 2 to buy.")
        let timed = HomeFact(id: UUID(), kind: .cook, title: "Tacos", state: .planned, toBuy: 2,
                             startsAt: Self.at(19))
        #expect(HomeLines.line(for: timed, now: Self.at(9), calendar: Self.calendar).hero == "Tacos, 7 pm")
        #expect(line.context == "2 to buy" && line.detail == nil && line.numbers == [2])
        #expect(text(tacos, now: Self.at(21, 30)) == "Tacos tonight, 2 to buy.")
        let stocked = HomeFact(id: UUID(), kind: .cook, title: "Tacos", state: .planned, toBuy: 0)
        // At zero the context is the day word again; the row keeps "nothing to buy" (Kitchen K87, C8 and B6).
        let zero = HomeLines.line(for: stocked, now: Self.at(9), calendar: Self.calendar)
        #expect(zero.context == HomeLines.dayWord(Self.at(9), calendar: Self.calendar), "\(zero.context ?? "-")")
        #expect(zero.text.hasSuffix("nothing to buy."), "\(zero.text)")
        #expect(zero.context != "nothing to buy")
        // Tomorrow's stocked cook says tomorrow, never today's word (QA on #780).
        var ahead = stocked
        ahead.tomorrow = true
        #expect(HomeLines.line(for: ahead, now: Self.at(21), calendar: Self.calendar).context == "tomorrow")
    }

    @Test func theCapsTheCheckerEnforces() {
        // home-lines.md section 1: context 6 words and 32 characters with no stop; detail one sentence, 14 words,
        // 80 characters, with its stop. Every rules line fits its own cap.
        #expect(HomeLines.fitsContext("this evening, your usual slot"))
        #expect(!HomeLines.fitsContext("this evening, your usual slot."))
        #expect(!HomeLines.fitsContext("paused twenty one minutes ago at the bench"))
        #expect(!HomeLines.fitsContext("a very long context line past 32"))
        #expect(HomeLines.fitsDetail("1 exercise, 2 sets, 1 new best."))
        #expect(!HomeLines.fitsDetail("1 exercise, 2 sets") && !HomeLines.fitsDetail("Done. Two sentences."))
        #expect(!HomeLines.fitsDetail("One two three four five six seven eight nine ten eleven twelve thirteen "
                + "fourteen fifteen."))
        let facts = [
            HomeFact(id: UUID(), kind: .workout, title: "Incline Push Day B", state: .done, sets: 22, exercisesDone: 6,
                     exercisesPlanned: 6, records: ["Bench", "Press", "Row"], endedAt: Self.at(20, 5)),
            HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, exercise: "Incline", step: 2,
                     sets: 5, exercisesDone: 2, exercisesPlanned: 5, lastTouchedAt: Self.at(19)),
            HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .paused, step: 3, steps: 12,
                     lastTouchedAt: Self.at(19)),
            HomeFact(id: UUID(), kind: .cook, title: "Tacos", state: .planned, toBuy: 12),
            HomeFact(id: UUID(), kind: .shop, title: "Groceries", state: .running, step: 14),
            HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned),
        ]
        for line in HomeLines.lines(for: facts, now: Self.at(21, 40), calendar: Self.calendar) {
            #expect(line.context.map(HomeLines.fitsContext) ?? true, "\(line.context ?? "")")
            #expect(line.contextShort.map(HomeLines.fitsContext) ?? true, "\(line.contextShort ?? "")")
            #expect(line.detail.map(HomeLines.fitsDetail) ?? true, "\(line.detail ?? "")")
        }
    }

    @Test func rowLinesStayWithinSixWords() {
        let facts = [
            HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, exercisesDone: 6,
                     exercisesPlanned: 6, records: ["Bench"]),
            HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 22, records: ["Bench", "Press"]),
            HomeFact(id: UUID(), kind: .workout, title: "Pull B", state: .paused, exercise: "Incline", step: 2),
            HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .running, exercise: "Squat", step: 3),
            HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .planned),
            HomeFact(id: UUID(), kind: .cook, title: "Chili", state: .paused, step: 3, steps: 8),
            HomeFact(id: UUID(), kind: .shop, title: "Groceries", state: .running, step: 4),
            HomeFact(id: nil, kind: .rest, title: RestDay.line, state: .planned),
        ]
        for line in HomeLines.lines(for: facts, now: Self.at(18), calendar: Self.calendar) {
            #expect(line.text.split(separator: " ").count <= HomeLines.rowWords, "\(line.text)")
            #expect(!line.text.contains("…") && !line.text.contains("kg") && !line.text.contains("×"))
        }
    }

    @Test func agoWords() {
        #expect(HomeLines.ago(30) == "just now" && HomeLines.ago(90) == "just now")
        #expect(HomeLines.ago(21 * 60) == "21 min ago" && HomeLines.ago(2 * 3600 + 300) == "2 h ago")
        #expect(HomeLines.ago(119 * 60) == "2 h ago" && HomeLines.ago(60 * 60) == "1 h ago") // rounded (G6)
    }

    @Test func gapsFromHisTuesday() {
        // G4: no SO FAR until a set is in; G5: every set logged reads "all sets in"; G7: long names shorten.
        let first = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .running, exercise: "Bench", step: 1,
                             sets: 0, exercisesDone: 1, exercisesPlanned: 6)
        let line = HomeLines.line(for: first, now: Self.at(17, 52), calendar: Self.calendar)
        #expect(line.detail == nil && line.widgetLine == "Push A, bench set 1." && line.fixed)
        let empty = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .done, sets: 0, endedAt: Self.at(15))
        #expect(HomeLines.line(for: empty).detail == nil)
        let allIn = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .running, sets: 18, exercisesDone: 6,
                             exercisesPlanned: 6)
        let done = HomeLines.line(for: allIn, now: Self.at(19, 58), calendar: Self.calendar)
        #expect(done.text == "Push A, all sets in." && done.hero == "Push A, all sets in")
        #expect(done.widgetWords == "Push A, all sets in")
        #expect(ExerciseWords.short("Dumbbell Lateral Raise") == "Lateral raise")
        #expect(ExerciseWords.short("Bulgarian Split Squat") == "Split squat")
        // QA F1 on #369: no two catalog lifts share a short name, so an incline best is never a "Press best".
        #expect(ExerciseWords.short("Incline Dumbbell Press") == "Incline DB press")
        let shorts = ExerciseLibrary.seeds.map { ExerciseWords.short($0.name) }
        let meant: Set = ["Pulldown", "Lateral raise", "Leg curl", "Calf raise"]
        let clashes = Dictionary(grouping: shorts, by: { $0 }).filter { $0.value.count > 1 && !meant.contains($0.key) }
        #expect(clashes.isEmpty, "\(clashes.keys.sorted())")
        // Running: no meta (Design's low); a planned session with a time wins over the rest day (Product 96db137).
        let running = HomeFact(id: UUID(), kind: .workout, title: "Legs", state: .running, exercise: "Squat", step: 3)
        #expect(HomeLines.line(for: running).widgetMeta == nil)
        let timed = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .planned, startsAt: Self.at(19))
        let planned = HomeLines.line(for: timed, now: Self.at(18, 10), calendar: Self.calendar)
        #expect(planned.hero == "Push A, 7 pm" && planned.text == "Push A, 7 pm." && planned
            .context == "this evening")
        #expect(planned.widgetLine == "Push A, 7 pm this evening." || planned.widgetLine == "Push A, 7 pm.")
        #expect(ExerciseWords.short("Deadlift") == "Deadlift" && ExerciseWords.short("Face Pull") == "Face pull")
        // Design 54: a paused hero drops its paused context into the meta.
        let paused = HomeFact(id: UUID(), kind: .workout, title: "Push A", state: .paused, exercise: "Incline", step: 2,
                              sets: 9, lastTouchedAt: Self.at(18, 35))
        let rest = HomeLines.line(for: paused, now: Self.at(19, 15), calendar: Self.calendar)
        #expect(rest.widgetLine == "Push A, paused at incline." && rest.widgetMeta == "40 min")
        #expect(HomeLine.quiet == "All quiet.")
    }

    // MARK: From the store

    @Test func aRunningListReachesHomeWithItsNameAndCount() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        for text in ["Socks", "Charger", "Passport", "Adapter", "Shirt", "Book"] {
            try engine.perform(AddListItem(list: list.id, text: text), by: .user)
        }
        try engine.perform(StartListRun(list: list.id), by: .user)
        let process = try #require(ProcessTable(engine: engine).running())
        let fact = try #require(HomeFacts(engine: engine).fact(process: process))
        #expect(fact.kind == .list && fact.state == .running && fact.step == 6)
        let line = HomeLines.line(for: fact)
        #expect(line.context == "Packing" && line.detail == "6 left." && line.text == "Packing: 6 left.")
        let context = try #require(line.context), detail = try #require(line.detail)
        #expect(HomeLines.fitsContext(context) && HomeLines.fitsDetail(detail))
        // A walled name reads "Private list", never the words.
        let secret = try engine.perform(CreateList(name: "Lexapro refills"), by: .user).output
        try engine.perform(AddListItem(list: secret.id, text: "pills"), by: .user)
        try engine.perform(StartListRun(list: secret.id), by: .user)
        let other = try #require(ProcessTable(engine: engine).running())
        let masked = try #require(HomeFacts(engine: engine).fact(process: other))
        #expect(masked.title == "Private list")
    }

    @Test func factsFromTheStore() throws {
        // A paused Push A at bench set 2, a cook on step 1, and a shop with 2 left, read as Home would.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let facts = HomeFacts(engine: engine)
        let table = ProcessTable(engine: engine)

        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        let workout = try engine.perform(StartRoutine(routine: push.id), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let running = try #require(table.running())
        try engine.perform(SuspendProcess(process: running.id), by: .user)
        let pausedProcess = try #require(table.process(for: workout))
        let paused = try #require(facts.fact(process: pausedProcess))
        #expect(paused.kind == .workout && paused.state == .paused && paused.step == 2)
        #expect(paused.exercise == ExerciseWords.short(store.linkedClass("exercise", of: entry)?.name ?? ""))
        let line = HomeLines.line(for: paused)
        #expect(line.text == "\(paused.exercise ?? "") paused at set 2." && !line.text.contains("80"))
        #expect(line.objectID == workout.id)

        let recipe = try engine.perform(CreateRecipe(text: RecipeParserTests.carbonara), by: .user).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        let cookProcess = try #require(table.running())
        let cooking = try #require(facts.fact(process: cookProcess))
        #expect(cooking.kind == .cook && cooking.state == .running && cooking.step == 1 && (cooking.steps ?? 0) > 1)
        #expect(HomeLines.line(for: cooking).text == "\(recipe.title), on step 1.")

        try engine.perform(AddGroceries(lines: ["milk", "eggs"]), by: .user)
        try engine.perform(StartShop(), by: .user)
        let shopProcess = try #require(table.running())
        let shop = try #require(facts.fact(process: shopProcess))
        #expect(shop.kind == .shop && shop.step == 2)
        #expect(HomeLines.line(for: shop).text == "Groceries: 2 left.")

        // The planned routine and the rest day.
        let next = try #require(TrainingLedger(store: store, classes: classes).nextRoutine(in: plan))
        let planned = facts.fact(planned: next, now: Self.at(18))
        #expect(HomeLines.line(for: planned, now: Self.at(18), calendar: Self.calendar).text
            == "\(store.displayTitle(of: next)) this evening.")
        #expect(planned.sinceLastDays == nil) // never run
        // A planned cook counts the recipe's unbought rows.
        try engine.perform(AddRecipeToGroceries(recipe: recipe.id), by: .user)
        let dinner = try engine.perform(CreateTask(title: "cook \(recipe.title)"), by: .user).output
        let tonight = facts.fact(plannedCook: dinner, recipe: recipe)
        #expect(tonight.kind == .cook && tonight.state == .planned && (tonight.toBuy ?? 0) > 0)
        #expect(HomeLines.line(for: tonight, now: Self.at(18), calendar: Self.calendar).text
            == "\(recipe.title) tonight, \(tonight.toBuy ?? 0) to buy.")
        // A captured cook carries startsAt and about, never due: the hero keeps its time (#700).
        let timed = try engine.perform(CreateTask(title: "Cook tacos", startsAt: Self.at(19), about: [recipe.id]),
                                       by: .tess).output
        let timedFact = facts.fact(plannedCook: timed, recipe: recipe)
        #expect(timedFact.startsAt == Self.at(19))
        #expect(HomeLines.line(for: timedFact, now: Self.at(9), calendar: Self.calendar).hero
            == "\(recipe.title), 7 pm")
        // A date-only due (midnight) never prints a clock.
        let midnight = Self.calendar.startOfDay(for: Self.at(9))
        let dateOnly = try engine.perform(CreateTask(title: "Cook tacos", due: midnight, about: [recipe.id]),
                                          by: .tess).output
        #expect(facts.fact(plannedCook: dateOnly, recipe: recipe).startsAt == nil)
        // A finished cook from the store.
        try engine.perform(FinishCooking(cook: cook.id), by: .user)
        let finished = facts.cooksFinished(on: .now)
        #expect(finished.count == 1)
        #expect(HomeLines.line(for: facts.fact(doneCook: finished[0])).text == "\(recipe.title) done.")
        // On a day with nothing planned (the 13th; the paused workout above sits on today), the rest line shows.
        let quietDay = Self.at(18).addingTimeInterval(-2 * 86400) // the 13th, 18:00
        let restFact = try #require(facts.rest(next: next, now: quietDay))
        #expect(HomeLines.line(for: restFact).text == "Rest day.")
        // A session scheduled for that day wins over the rest day (Product 96db137).
        let workoutClass = try #require(classes[.workout])
        let scheduled = store.create(workoutClass, title: "Push A")
        try store.set("scheduledFor", to: .date(quietDay.addingTimeInterval(3600)), on: scheduled)
        #expect(facts.rest(next: next, now: quietDay) == nil)
        #expect(facts.plannedSession(on: quietDay)?.id == scheduled.id)
        #expect(HomeLines.line(for: facts.fact(scheduled: scheduled), now: quietDay, calendar: Self.calendar).hero
            == "Push A, 7 pm")
    }

    @Test func aFinishedWorkoutFromTheStoreNamesItsRecord() throws {
        // Two Push A sessions: the second beats the first on bench, so the line says "Bench record."
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        let push = try #require(store.linkedObjects("routines", of: plan).first)
        for (day, weight) in [(1, 60.0), (3, 70.0)] {
            let time = Self.at(18).addingTimeInterval(Double(day) * 86400)
            let workout = try engine.perform(StartRoutine(routine: push.id, time: time), by: .user).output
            let entry = try #require(workout.orderedChildren.first)
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: 5, time: time), by: .user)
            try engine.perform(FinishWorkoutEarly(workout: workout.id, time: time.addingTimeInterval(1800)), by: .user)
        }
        let summaries = ledger.finishedWorkouts(on: Self.at(18).addingTimeInterval(3 * 86400), calendar: Self.calendar)
        let summary = try #require(summaries.first)
        let done = HomeFacts(engine: engine).fact(done: summary)
        let line = HomeLines.line(for: done, now: Self.at(21).addingTimeInterval(3 * 86400), calendar: Self.calendar)
        #expect(line.text == "\(done.title) done. \(done.records[0]) best.")
        #expect(line.context == "6:30 pm" && line.detail?.hasSuffix("1 set, 1 new best.") == true)
        #expect(!line.text.contains("70") && !line.numbers.contains(70))
        #expect(done.sinceLastDays == 2 && line.numbers.contains(2))
    }
}
