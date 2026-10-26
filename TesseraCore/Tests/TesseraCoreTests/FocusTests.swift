import Foundation
@testable import TesseraCore
import Testing

/// M4 slices 4, 8 and 9: quiet interrupts, the focus block and the first-step splitter.
@MainActor
struct FocusTests {
    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSince1970: 1_792_000_000)

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func running(_ engine: ActionEngine) throws -> ProcessSnapshot {
        try #require(ProcessTable(engine: engine).running())
    }

    // MARK: Focus block

    @Test func aFocusBlockIsAProcessWithOneCheckInAndAWrapUp() throws {
        let engine = try engine()
        let task = try engine.perform(CreateTask(title: "Reply to the landlord"), by: .user).output
        try engine.perform(StartFocusBlock(task: task.id, minutes: 20, time: start), by: .user)
        let process = try running(engine)
        let block = try #require(FocusBlock(process, store: store, classes: engine.classes))
        #expect(block.minutes == 20 && process.ownerApp == "Focus")
        #expect(block.phase(at: start.addingTimeInterval(5 * 60)) == .running(minutesLeft: 15))
        #expect(block.phase(at: start.addingTimeInterval(10 * 60)) == .checkInDue)
        #expect(block.checkInLine == "Halfway on Reply to the landlord. Still with it?")
        // One check-in only.
        try engine.perform(FocusCheckIn(process: process.id, time: start.addingTimeInterval(10 * 60)), by: .user)
        let after = try #require(FocusBlock(running(engine), store: store, classes: engine.classes))
        #expect(after.checkedIn && after.phase(at: start.addingTimeInterval(12 * 60)) == .running(minutesLeft: 8))
        #expect(after.phase(at: start.addingTimeInterval(21 * 60)) == .over)
        #expect(after
            .wrapUpLine(endedAt: start.addingTimeInterval(20 * 60)) ==
            "Focus done. 20 minutes on Reply to the landlord")
    }

    @Test func theBlockLengthIsKeptInBounds() throws {
        let engine = try engine()
        let task = try engine.perform(CreateTask(title: "Write the report"), by: .user).output
        try engine.perform(StartFocusBlock(task: task.id, minutes: 1, time: start), by: .user)
        #expect(try FocusBlock(running(engine), store: store, classes: engine.classes)?.minutes == 5)
    }

    @Test func aPrivateTaskNeverReadsItsWordsInTheCheckIn() throws {
        let engine = try engine()
        let task = try engine.perform(CreateTask(title: "Call the therapist"), by: .user).output
        try engine.perform(StartFocusBlock(task: task.id, time: start), by: .user)
        let block = try #require(FocusBlock(running(engine), store: store, classes: engine.classes))
        #expect(!block.checkInLine.lowercased().contains("therapist"))
    }

    // MARK: First step

    @Test(arguments: [
        ("Write the report", "Write one sentence of the report"), (
            "Call the plumber",
            "Find the number for the plumber"
        ),
        ("Reply to Priya", "Open the thread for to Priya"), (
            "Clean the oven",
            "Set a 2-minute timer and start on the oven"
        ),
        ("Buy stamps", "Put it on your list: stamps"), ("Laundry", "Spend 2 minutes on Laundry"),
    ])
    func theStepIsTwoMinutesOfTheFirstMove(_ title: String, _ expected: String) {
        #expect(FirstStep.step(for: title) == expected)
    }

    @Test func aTaskUntouchedForThreeDaysGetsOneOfferADay() throws {
        let engine = try engine()
        let old = try engine.perform(CreateTask(title: "Write the report"), by: .user).output
        old.updatedAt = start.addingTimeInterval(-4 * 86400)
        let fresh = try engine.perform(CreateTask(title: "Buy stamps"), by: .user).output
        fresh.updatedAt = start.addingTimeInterval(-86400)
        let steps = FirstStep(store: store, classes: engine.classes)
        let offer = try #require(steps.offer(now: start))
        #expect(offer.task == old.id && offer.step == "Write one sentence of the report")
        // Once a day: not again today.
        #expect(steps.offer(now: start, lastOfferedOn: start.addingTimeInterval(-3600)) == nil)
        // Accepting adds a 2-minute task about it.
        let step = try engine.perform(AcceptFirstStep(task: old.id, time: start), by: .user).output
        #expect(store.number("length", of: step) == 120 && step.title == "Write one sentence of the report")
    }

    @Test func aPrivateTaskGetsNoOffer() throws {
        let engine = try engine()
        let secret = try engine.perform(CreateTask(title: "Pay the therapist 120"), by: .user).output
        secret.updatedAt = start.addingTimeInterval(-9 * 86400)
        #expect(FirstStep(store: store, classes: engine.classes).offer(now: start) == nil)
    }

    // MARK: Quiet interrupts

    @Test func nothingIsHeldWhenNothingRuns() throws {
        let engine = try engine()
        let quiet = QuietInterrupts(store: store, classes: engine.classes)
        #expect(!quiet.maskActive() && !quiet.shouldHold(.low) && !quiet.shouldHold(.normal))
    }

    @Test func aFocusBlockHoldsLowAndNormalButNeverATimer() throws {
        let engine = try engine()
        let task = try engine.perform(CreateTask(title: "Write the report"), by: .user).output
        try engine.perform(StartFocusBlock(task: task.id, time: start), by: .user)
        let quiet = QuietInterrupts(store: store, classes: engine.classes)
        #expect(quiet.maskActive() && quiet.shouldHold(.low) && quiet.shouldHold(.normal) && !quiet.shouldHold(.timer))
    }

    @Test func aWorkoutAndACookAlsoMask() throws {
        let engine = try engine()
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user)
        #expect(QuietInterrupts(store: store, classes: engine.classes).maskActive())
    }

    @Test func heldNoticesComeOutAsOneDigestAndThePrivateOnesAreNeverNamed() throws {
        let engine = try engine()
        let quiet = QuietInterrupts(store: store, classes: engine.classes)
        for title in ["Pay rent reminder", "Water the plants", "Lexapro refill", "Call mom", "Check the oven"] {
            try engine.perform(HoldNotice(title: title, priority: .low), by: .system)
        }
        #expect(quiet.waitingCount == 5)
        let line = try #require(quiet.digestLine())
        #expect(line == "5 things waited: Pay rent reminder, Water the plants, something private, and 2 more")
        let released = try engine.perform(ReleaseHeldNotices(), by: .system).output
        #expect(released == line && quiet.waitingCount == 0)
        // Nothing waiting: nothing released, nothing logged.
        let before = engine.history(limit: 50).count
        #expect(try engine.perform(ReleaseHeldNotices(), by: .system).output == nil)
        #expect(engine.history(limit: 50).count == before)
    }

    @Test func theSafetyNetFiresAfterTheExpectedEndButNeverPastThreeHours() {
        let begin = start
        #expect(QuietInterrupts.fallbackTime(blockStart: begin, expectedEnd: begin.addingTimeInterval(3600))
            == begin.addingTimeInterval(5400))
        #expect(QuietInterrupts.fallbackTime(blockStart: begin, expectedEnd: begin.addingTimeInterval(5 * 3600))
            == begin.addingTimeInterval(3 * 3600))
    }
}
