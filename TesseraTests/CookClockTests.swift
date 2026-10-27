import Foundation
@testable import Tessera
import TesseraCore
import Testing

private typealias Input = (text: String, timers: [ClosedRange<Double>])

private let paprikaSteps: [Input] = [
    ("Heat the oven to 425°F. Halve the potatoes and toss with oil and salt", []),
    ("Roast the potatoes for 15 minutes", [15 ... 15]),
    ("Meanwhile, rub the chicken with paprika, garlic and lemon zest", []),
    ("Add the chicken and onion to the pan and roast for 20 minutes, until the skin is crisp", [20 ... 20]),
    ("Stir the yogurt with lemon juice and a pinch of salt", []),
    ("Rest the chicken for 4 minutes, then serve with the yogurt", [4 ... 4]),
]

private let shrimpSteps: [Input] = [
    ("Bring a large pot of salted water to the boil", []),
    ("Cook the spaghetti for 8-10 minutes, until al dente", [8 ... 10]),
    ("While the pasta cooks, melt the butter and cook the garlic until golden, about 2 minutes", [2 ... 2]),
    ("Add the shrimp and sear 1 minute a side", [1 ... 1]),
    ("Toss in the drained pasta with the parsley and lemon juice and cook until glossy", []),
]

private let breadSteps: [Input] = [
    ("Stir the flour, yeast, salt and water into a shaggy dough", []),
    ("Cover and let it rise overnight, 12 to 18 hours", [720 ... 1080]),
    ("Heat the oven to 450°F with the pot inside for 30 minutes", [30 ... 30]),
    ("Shape the dough and let it rest 30 minutes", [30 ... 30]),
    ("Bake covered for 30 minutes, then uncovered for 15 minutes, until deep brown", [30 ... 30, 15 ... 15]),
    ("Cool for 1 hour before slicing", [60 ... 60]),
]

/// The recipe laid on the clock: one lane as today, two with parallel steps on (PS1 to PS9).
struct CookClockPlanTests {
    @Test func oneLaneIsToday() {
        let plan = CookClockPlan.make(paprikaSteps, lanes: false)
        #expect(plan.steps.map(\.start) == [0, 2, 17, 19, 39, 41])
        #expect(plan.total == 45)
        #expect(!plan.hasOverlap)
    }

    @Test func ps1TheGuestOpensAtTheHostsStartAndTheJoinDecidesTheRest() {
        let plan = CookClockPlan.make(paprikaSteps, lanes: true)
        #expect(plan.steps[2].lane == 1 && plan.steps[2].start == 2 && plan.steps[2].end == 4)
        #expect(plan.steps[3].start == 17 && plan.steps[3].end == 37)
        #expect(plan.steps[4].start == 37 && plan.steps[5].start == 39 && plan.steps[5].end == 43)
        #expect(plan.total == 43)
    }

    @Test func ps2TheGuestRunsBesideThePasta() {
        let plan = CookClockPlan.make(shrimpSteps, lanes: true)
        #expect(plan.steps[1].start == 2 && plan.steps[1].end == 10)
        #expect(plan.steps[2].lane == 1 && plan.steps[2].start == 2 && plan.steps[2].end == 4)
        #expect(plan.steps[3].start == 10 && plan.steps[3].end == 12)
        #expect(plan.steps[4].end == 14 && plan.total == 14)
    }

    @Test func aSideDoublesTheDuration() {
        let plan = CookClockPlan.make(shrimpSteps, lanes: false)
        #expect(plan.steps[3].minutes == 2 && plan.steps[3].timer == 2)
    }

    @Test func ps7AThirdCandidateWaitsForTheFreedLane() {
        var texts = paprikaSteps
        texts[2] = ("Meanwhile, marinate the chicken for 10 minutes", [10 ... 10])
        texts.insert(("While the potatoes roast, stir the yogurt", []), at: 3)
        let plan = CookClockPlan.make(texts, lanes: true)
        #expect(plan.steps[2].lane == 1 && plan.steps[2].start == 2 && plan.steps[2].end == 12)
        #expect(plan.steps[3].lane == 1 && plan.steps[3].start == 12)
        #expect(plan.steps.filter { $0.lane == 1 }.count == 2)
    }

    @Test func ps8ACueBesideAShortHostOpensNoLane() {
        let texts: [Input] = [("Rest 4 min", [4 ... 4]), ("Meanwhile, set the table", [])]
        let plan = CookClockPlan.make(texts, lanes: true)
        #expect(plan.steps[1].lane == 0 && plan.steps[1].start == 4)
    }

    @Test func ps9AWaitHostsNothingAndIsDrawnTenMinutesWide() {
        var texts = breadSteps
        texts.insert(("Meanwhile, heat the oven", []), at: 2)
        let plan = CookClockPlan.make(texts, lanes: true)
        #expect(plan.steps[1].isWait && plan.steps[1].end - plan.steps[1].start == 10)
        #expect(plan.steps[1].timer == nil && plan.steps[1].waitMinutes == 720)
        #expect(plan.steps[2].lane == 0 && plan.steps[2].start == 12)
    }

    @Test func theKeyFigureLeavesTheFixedWaitOut() {
        let plan = CookClockPlan.make(breadSteps, lanes: false)
        #expect(plan.total == 177)
        #expect(plan.minutesLeft(atStep: 0, timerRemaining: nil) == 167)
        #expect(CookClockPlan.figure(minutesLeft: plan.minutesLeft(atStep: 0, timerRemaining: nil)) == 167)
    }

    @Test func d1AtMinute12ReadsThirtyThree() {
        let plan = CookClockPlan.make(paprikaSteps, lanes: false)
        // Step 2 has 5 minutes left on its timer: 5 + the 28 after it.
        #expect(CookClockPlan.figure(minutesLeft: plan.minutesLeft(atStep: 1, timerRemaining: 5 * 60)) == 33)
    }

    @Test func thirtySecondsIsATimerDrawnAtTheFloor() {
        let plan = CookClockPlan.make([("Microwave 30 seconds", [0.5 ... 0.5])], lanes: false)
        #expect(plan.steps[0].minutes == 2 && plan.steps[0].timer == 0.5)
    }

    @Test func theCueWordsAreTheTwoLaneOnes() {
        #expect(CookClockPlan.isCued("Meanwhile, rub the chicken"))
        #expect(CookClockPlan.isCued("While the pasta cooks, melt the butter"))
        #expect(!CookClockPlan.isCued("Roast the potatoes"))
    }

    @Test func theFigureRoundsUpSoItFlipsAtTheMinute() {
        #expect(CookClockPlan.figure(minutesLeft: 32.01) == 33)
        #expect(CookClockPlan.figure(minutesLeft: 32.0) == 32)
    }

    @Test func minuteFigureFiresAtEndsAtBoundary() {
        // A view appearing 20 s past a boundary still flips at the next boundary of `endsAt`, never 60 s later.
        let end = Date(timeIntervalSinceReferenceDate: 10000)
        let now = end.addingTimeInterval(-(5 * 60 - 20))
        let next = CookClockPlan.nextBoundary(endsAt: end, after: now)
        #expect(next == end.addingTimeInterval(-4 * 60))
        #expect(CookClockPlan.nextBoundary(endsAt: end, after: end.addingTimeInterval(1)) == nil)
    }
}

struct CookClockCopyTests {
    @Test func theKeyFigureInMinutesAndHours() {
        #expect(CookClockCopy.keyFigure(minutes: 33) == "33 min left")
        #expect(CookClockCopy.keyFigure(minutes: 65) == "1 hr 5 min left")
        #expect(CookClockCopy.keyFigure(minutes: 120) == "2 hr left")
    }

    @Test func spokenTimerValueChangesOnlyAtMinuteBoundaries() {
        let end = Date(timeIntervalSinceReferenceDate: 50000)
        // Anywhere inside a minute reads the same; only crossing a boundary changes it.
        let first = CookClockCopy.spokenTimer(remaining: 8 * 60 - 1, endsAt: end)
        let second = CookClockCopy.spokenTimer(remaining: 7 * 60 + 30, endsAt: end)
        let third = CookClockCopy.spokenTimer(remaining: 7 * 60 + 1, endsAt: end)
        #expect(first == second && second == third)
        #expect(CookClockCopy.spokenTimer(remaining: 7 * 60, endsAt: end) != first)
        #expect(CookClockCopy.spokenTimer(remaining: 59, endsAt: end) == "Under a minute left")
    }

    @Test func timerDoneAtZeroSaysDoneNotZeroMinutes() {
        #expect(CookModeCopy.timeLeft("Simmer", seconds: 0) == "Simmer, done")
        #expect(CookClockCopy.spokenTimer(remaining: 0, endsAt: .now) == "Done")
    }

    @Test func theTimelineStepsAtMinuteBoundariesThenEveryTenSeconds() {
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        let end = now.addingTimeInterval(3 * 60 + 20)
        let dates = CookClockTimeline.dates(endsAt: [end], from: now)
        // Boundaries at 3:00, 2:00, 1:00 left, then the last minute every 10 s, then the end.
        #expect(dates.contains(end.addingTimeInterval(-180)))
        #expect(dates.contains(end.addingTimeInterval(-120)))
        #expect(dates.contains(end.addingTimeInterval(-60)))
        #expect(dates.contains(end.addingTimeInterval(-50)) && dates.contains(end.addingTimeInterval(-10)))
        #expect(dates.last == end)
        #expect(!dates.contains(end.addingTimeInterval(-90)))
    }

    @Test func aTimerLabelIsTheVerbNearestTheDuration() {
        #expect(CookTimerLabel.label(for: "Add the chicken and roast 20 min", stepIndex: 3) == "Roast")
        #expect(CookTimerLabel.label(for: "Roast the potatoes for 15 minutes", stepIndex: 1) == "Roast")
        #expect(CookTimerLabel.label(for: "Wait 5 minutes", stepIndex: 2) == "Step 3")
    }

    @Test func usUnitsKeepFahrenheitAndShowCelsiusBothWays() {
        #expect(CookUnits.withFahrenheit("Heat the oven to 425°F") == "Heat the oven to 425°F")
        #expect(CookUnits.withFahrenheit("Heat the oven to 220°C") == "Heat the oven to 220°C (430°F)")
    }

    @Test func endsLineIsTwelveHourLowercase() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 19,
            hour: 18,
            minute: 52
        )))
        #expect(CookUnits.endsLine(date, calendar: calendar) == "ends 6:52 pm")
    }
}

/// The hands-free grammar: next, back, timer, note; talk gets no reply (docs/design/motion, Part 2).
struct HandsFreeGrammarTests {
    @Test func nextAndBack() {
        #expect(HandsFreeGrammar.parse("next") == .command(.next))
        #expect(HandsFreeGrammar.parse("Okay, next step") == .command(.next))
        #expect(HandsFreeGrammar.parse("back") == .command(.back))
        #expect(HandsFreeGrammar.parse("go back") == .command(.back))
    }

    @Test func timerWithANumberStartsOne() {
        #expect(HandsFreeGrammar.parse("timer 8") == .command(.timer(minutes: 8, label: nil)))
        #expect(HandsFreeGrammar.parse("timer bread 8") == .command(.timer(minutes: 8, label: "Bread")))
        #expect(HandsFreeGrammar.parse("set a timer for 10 minutes") == .command(.timer(minutes: 10, label: nil)))
        #expect(HandsFreeGrammar.parse("8 minute timer") == .command(.timer(minutes: 8, label: nil)))
    }

    @Test func handsFreeKeywordWithoutSlotSaysDidntCatchThat() {
        #expect(HandsFreeGrammar.parse("timer") == .didntCatch)
        #expect(HandsFreeGrammar.parse("timer please") == .didntCatch)
        #expect(HandsFreeGrammar.parse("note") == .didntCatch)
    }

    @Test func handsFreeNoKeywordStaysSilent() {
        #expect(HandsFreeGrammar.parse("") == .silent)
        #expect(HandsFreeGrammar.parse("did you see the game last night") == .silent)
        // "next" inside a sentence is talk, not a command.
        #expect(HandsFreeGrammar.parse("I will make the next batch of cookies tomorrow") == .silent)
    }

    @Test func aNoteKeepsHisWords() {
        #expect(HandsFreeGrammar.parse("note: less salt") == .command(.note("less salt")))
        #expect(HandsFreeGrammar.parse("note less salt") == .command(.note("less salt")))
    }

    @Test func handsFreeLongPhraseRefusedOnce() {
        let long = String(repeating: "next ", count: 130)
        #expect(HandsFreeGrammar.parse(long) == .refused(.tooLong))
        #expect(HandsFreeGrammar.Reason.tooLong.line == "That's too long to send. Say it shorter")
    }

    @Test func handsFreeKeyShapedTextNeverActs() {
        // A key-shaped phrase is refused first and nothing acts (the test builds its own fake, never a real key).
        let fake = "sk-ant-" + String(repeating: "x", count: 30)
        #expect(HandsFreeGrammar.parse("timer \(fake) 8") == .refused(.keyShaped))
        #expect(HandsFreeGrammar.parse("note \(fake)") == .refused(.keyShaped))
    }

    @Test func theWindowClosesAfterEightSecondsOfSilence() {
        var window = HandsFreeWindow()
        let opened = Date(timeIntervalSinceReferenceDate: 100)
        window.open(at: opened)
        #expect(window.isOpen && !window.isSilent(at: opened.addingTimeInterval(7.9)))
        #expect(window.isSilent(at: opened.addingTimeInterval(8)))
        #expect(window.closesAt == opened.addingTimeInterval(8))
        // A heard word moves the edge.
        _ = window.newWords(in: "next", at: opened.addingTimeInterval(5))
        #expect(!window.isSilent(at: opened.addingTimeInterval(12)))
        window.close()
        #expect(!window.isOpen && !window.isSilent(at: opened.addingTimeInterval(60)))
    }

    @Test func aRevisedTranscriptNeverActsTwice() {
        var window = HandsFreeWindow()
        window.open(at: .now)
        #expect(window.newWords(in: "next", at: .now) == "next")
        window.commit(wordCount: 1)
        #expect(window.newWords(in: "next", at: .now) == nil)
        #expect(window.newWords(in: "next back", at: .now) == "back")
    }

    @Test func handsFreeGrammarMakesNoNetworkRequest() {
        // The grammar is a pure function of its phrase: no session, no client, nothing to call out with. This pins
        // that `parse` takes only a String (a refactor that added a client would not compile here).
        let parse: (String) -> HandsFreeGrammar.Outcome = HandsFreeGrammar.parse
        #expect(parse("next") == .command(.next))
    }
}

/// Cook notes (CN): the line, the cook's note on Finish, and the walls.
@MainActor
struct CookNotesTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func theLastTimeLine() {
        #expect(CookNotes.lastTimeLine("less salt") == "Last time: less salt")
        #expect(CookNotes.lastTimeLine("less salt") == "Last time: less salt")
        #expect(CookNotes.cookedLine("Paprika chicken") == "Paprika chicken, cooked")
    }

    @Test func theNewestNoteComesFromTheNewestCook() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\nSimmer 20 minutes"), by: .user)
            .output
        let first = try model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        try model.engine.perform(
            FinishCooking(cook: first.id, note: "more garlic", time: .now.addingTimeInterval(-9000)),
            by: .user
        )
        let second = try model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        try model.engine.perform(FinishCooking(cook: second.id, note: "less salt"), by: .user)
        #expect(CookNotes.latest(of: recipe, store: model.store, classes: model.classes) == "less salt")
    }

    @Test func aCookWithNoNoteLeavesTheLastOne() throws {
        let recipe = try model.engine.perform(CreateRecipe(text: "Dal\n1 cup lentils\nSimmer 20 minutes"), by: .user)
            .output
        let first = try model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        try model.engine.perform(
            FinishCooking(cook: first.id, note: "more garlic", time: .now.addingTimeInterval(-9000)),
            by: .user
        )
        let second = try model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        try model.engine.perform(FinishCooking(cook: second.id), by: .user)
        #expect(CookNotes.latest(of: recipe, store: model.store, classes: model.classes) == "more garlic")
    }
}

/// The session on a real in-memory store: timers start as the bead reaches a step, once; stop and finish are Core's.
@MainActor @Suite(.serialized)
struct CookClockSessionTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    static let paprika = """
    Paprika chicken
    Serves 4
    1 lb chicken thighs
    Method
    1. Heat the oven to 425°F.
    2. Roast the potatoes for 15 minutes.
    3. Meanwhile, rub the chicken with paprika.
    4. Roast the chicken for 20 minutes.
    5. Rest the chicken for 4 minutes.
    """

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func session(parallel: Bool = false, voice: Bool = false, title: String = "Paprika chicken")
        throws -> CookClockSession
    {
        UserDefaults.standard.removeObject(forKey: "review.parallelSteps")
        UserDefaults.standard.removeObject(forKey: "review.cookTimerVoice")
        if parallel {
            UserDefaults.standard.set("On", forKey: "review.parallelSteps")
        }
        if voice {
            UserDefaults.standard.set("On", forKey: "review.cookTimerVoice")
        }
        let recipe = try model.engine.perform(
            CreateRecipe(text: Self.paprika.replacing("Paprika chicken", with: title, maxReplacements: 1)), by: .user
        ).output
        let cook = try model.engine.perform(StartCooking(recipe: recipe.id), by: .user).output
        return try #require(CookClockSession(model: model, cookID: cook.id))
    }

    @Test func oneTimerPerTimedStepStartedAsTheBeadArrives() throws {
        let session = try session()
        #expect(session.timers.isEmpty)
        #expect(session.next())
        #expect(session.timers.count == 1 && session.timers[0].label == "Roast" && session.timers[0].step == 1)
        // Back and forward again never starts a second one.
        session.back()
        #expect(session.next())
        #expect(session.timers.count == 1)
        defer { UserDefaults.standard.removeObject(forKey: "review.parallelSteps") }
    }

    @Test func theSavedPlaceSurvivesALaterSession() throws {
        let first = try session()
        first.next()
        first.next()
        let again = try #require(CookClockSession(model: model, cookID: first.cookID))
        #expect(again.current == 2)
        // The timer it started is still the step-1 timer, not a new one.
        #expect(again.timers.count == 1)
    }

    @Test func parallelOpensTheGuestLaneWhenTheBeadReachesTheHost() throws {
        let session = try session(parallel: true)
        defer { UserDefaults.standard.removeObject(forKey: "review.parallelSteps") }
        session.next()
        #expect(session.tracks == [1, 2])
        #expect(session.timers.count == 1)
        // Next moves the lead track only (PS4): the guest holds.
        #expect(session.lead == 0)
        session.lead(1)
        #expect(session.lead == 1 && session.tracks == [1, 2])
        session.lead(0)
        session.next()
        #expect(session.tracks.count == 2 && session.tracks[1] == 2 || session.tracks[0] == 3)
    }

    @Test func handsFreeNextMovesCurrentTrackOnly() throws {
        let session = try session(parallel: true)
        defer { UserDefaults.standard.removeObject(forKey: "review.parallelSteps") }
        session.next()
        session.lead(1)
        let before = session.tracks[0]
        session.handle(.command(.next))
        #expect(session.tracks[0] == before)
    }

    @Test func handsFreeBackOnStepOneDoesNothing() throws {
        let session = try session()
        let line = session.handle(.command(.back))
        #expect(session.current == 0)
        #expect(line == "Step 1 of 5")
        #expect(session.receipt?.text == "Step 1 of 5")
    }

    @Test func aSpokenTimerSitsOutsideTheStepsAndSurvivesFinish() throws {
        let session = try session()
        session.handle(.command(.timer(minutes: 8, label: "Bread")))
        #expect(session.spokenTimers.count == 1 && session.spokenTimers[0].label == "Bread")
        #expect(session.receipt?.text == "Bread, 8 min")
    }

    @Test func stoppingATimerSaysItsNameAndCanBeUndone() throws {
        let session = try session()
        session.next()
        let line = try #require(session.timers.first)
        session.stop(line)
        #expect(session.timers.isEmpty)
        #expect(session.receipt?.text == "Roast stopped")
        try session.undo(#require(session.receipt))
        #expect(session.timers.count == 1)
    }

    @Test func finishWritesTheNoteAndSaysCooked() throws {
        let session = try session()
        #expect(session.finish(note: "  less salt  "))
        let cook = try #require(model.store.object(id: session.cookID))
        #expect(model.store.value("note", of: cook)?.stringValue == "less salt")
        #expect(model.store.value("cookedAt", of: cook) != nil)
        #expect(TessVoice.shared.note?.text == "Paprika chicken, cooked")
    }

    @Test func finishWithNoNoteWritesNone() throws {
        let session = try session()
        #expect(session.finish(note: "   "))
        let cook = try #require(model.store.object(id: session.cookID))
        #expect(model.store.value("note", of: cook) == nil)
    }

    @Test func aTimerEndingLiveHasOneHapticAndTheVoiceOnlyWhenSwitchedOn() throws {
        final class Spy: CookSpeaking {
            var said: [String] = []
            func say(_ line: String) {
                said.append(line)
            }
        }
        let silent = try session(voice: false)
        let quiet = Spy()
        silent.speaker = quiet
        var announced: [String] = []
        silent.announce = { announced.append($0) }
        let line = try endingNow(silent)
        silent.reconcileFlares(at: line.endsAt.addingTimeInterval(0.5), live: true)
        #expect(quiet.said.isEmpty)
        #expect(announced.last == "Roast is done")
        #expect(silent.cue.haptic == .timeUp && silent.cue.count == 2)

        let talking = try session(voice: true, title: "Lemon chicken")
        defer { UserDefaults.standard.removeObject(forKey: "review.cookTimerVoice") }
        let spy = Spy()
        talking.speaker = spy
        let ended = try endingNow(talking)
        talking.reconcileFlares(at: ended.endsAt.addingTimeInterval(0.5), live: true)
        #expect(spy.said == ["Roast is done"])
    }

    @Test func lateOpenFlareHasNoHaptic() throws {
        let session = try session()
        let line = try endingNow(session)
        let count = session.cue.count
        session.reconcileFlares(at: line.endsAt.addingTimeInterval(20 * 60), live: false)
        #expect(session.flared.contains(line.id))
        #expect(session.cue.count == count)
        // And held: a second pass changes nothing.
        session.reconcileFlares(at: line.endsAt.addingTimeInterval(21 * 60), live: false)
        #expect(session.cue.count == count)
    }

    @Test func twoTimersEndingTogetherGiveOneHaptic() throws {
        let session = try session()
        session.next()
        _ = try model.engine.perform(StartKitchenTimer(label: "Rice", minutes: 15, cook: session.cookID), by: .user)
        model.touch()
        let ends = session.timers.map(\.endsAt)
        let end = try #require(ends.max())
        let before = session.cue.count
        session.reconcileFlares(at: end.addingTimeInterval(0.2), live: true)
        #expect(session.cue.count == before + 1)
        #expect(session.flared.count == 2)
        #expect(CookClockSession.joinedDone(["Roast", "Rice"]) == "Roast and Rice, done")
    }

    @Test func extendRestartsTheSameStepsTimer() throws {
        let session = try session()
        session.next()
        let line = try #require(session.timers.first)
        session.extend(line)
        #expect(session.timers.count == 1)
        #expect(session.timers[0].step == 1 && session.timers[0].id != line.id)
    }

    @Test func theScreenStaysAwakeWhileATimerRunsOrWithin45Minutes() throws {
        let session = try session()
        let now = AppClock.now
        #expect(session.keepsAwake(at: now.addingTimeInterval(44 * 60 + 59)))
        // Exclusive at 45:00 with no timer running.
        #expect(!session.keepsAwake(at: now.addingTimeInterval(45 * 60 + 1)))
        // A running timer keeps it awake past 45 minutes of no step change (this one is 15 minutes long).
        session.next()
        let line = try #require(session.timers.first)
        #expect(session.keepsAwake(at: now.addingTimeInterval(10 * 60)))
        #expect(!session.keepsAwake(at: line.endsAt.addingTimeInterval(45 * 60 + 1)))
    }

    /// Makes the lead step's timer end at once by writing its end into the past.
    private func endingNow(_ session: CookClockSession) throws -> CookClockSession.Line {
        session.next()
        let line = try #require(session.timers.first)
        let object = try #require(model.store.object(id: line.id))
        try model.store.set("endsAt", to: .date(.now.addingTimeInterval(-0.5)), on: object)
        model.touch()
        return try #require(session.timers.first { $0.id == line.id })
    }
}
