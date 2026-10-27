import Foundation
@testable import Tessera
import TesseraCore
import Testing

@Suite("Workout mode: plate math")
struct PlateMathTests {
    let math = GreedyPlateMath()

    @Test("185 lb on a 45 lb bar is 45 + 25 each side")
    func pounds185() {
        let load = math.load(target: 185, bar: 45, inventory: .pounds)
        #expect(load.perSide == [45, 25])
        #expect(load.isExact)
        #expect(load.line == "each side 45 + 25")
    }

    @Test("The bar alone")
    func barOnly() {
        let load = math.load(target: 45, bar: 45, inventory: .pounds)
        #expect(load.isBarOnly)
        #expect(load.line == "bar only")
    }

    @Test("Below the bar is the bar, not negative")
    func belowBar() {
        let load = math.load(target: 30, bar: 45, inventory: .pounds)
        #expect(load.perSide.isEmpty)
        #expect(load.achieved == 45)
        #expect(load.short == 0)
    }

    @Test("A heavy load repeats the biggest plate")
    func heavy() {
        let load = math.load(target: 315, bar: 45, inventory: .pounds)
        #expect(load.perSide == [45, 45, 45])
    }

    @Test("Every 5 lb step from 45 to 400 is exact in pounds")
    func everyFiveLb() {
        for target in stride(from: 45.0, through: 400, by: 5) {
            let load = math.load(target: target, bar: 45, inventory: .pounds)
            #expect(load.isExact, "target \(target)")
            #expect(load.achieved == target)
        }
    }

    @Test("Kilograms: 100 kg on a 20 kg bar is 25 + 15 each side")
    func kilograms100() {
        let load = math.load(target: 100, bar: 20, inventory: .kilograms)
        #expect(load.perSide == [25, 15])
        #expect(load.isExact)
    }

    @Test("Fractional plates: 62.5 kg uses 20 + 1.25")
    func fractional() {
        let load = math.load(target: 62.5, bar: 20, inventory: .kilograms)
        #expect(load.perSide == [20, 1.25])
        #expect(load.achieved == 62.5)
    }

    @Test("A load the plates cannot make stops under it and says how short")
    func notExact() {
        let load = math.load(target: 47, bar: 45, inventory: .pounds)
        #expect(load.perSide.isEmpty)
        #expect(!load.isExact)
        #expect(abs(load.short - 2) < 0.001)
    }

    @Test("A smaller inventory is respected")
    func smallInventory() {
        let inventory = PlateInventory(unit: .pounds, plates: [10, 5], bar: 45)
        let load = math.load(target: 135, bar: 45, inventory: inventory)
        #expect(load.perSide == [10, 10, 10, 10, 5])
        #expect(load.isExact)
    }
}

@Suite("Workout mode: state")
struct WorkoutModeStateTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func sets(_ weight: Double, _ reps: Int, count: Int) -> [WorkoutModeState.PlannedSet] {
        (0 ..< count).map { _ in .init(weight: weight, reps: reps) }
    }

    func state() -> WorkoutModeState {
        WorkoutModeState(
            title: "Push A", unit: .pounds, startedAt: t0,
            lifts: [
                .init(id: "w", name: "Warm up", restSeconds: 30, sets: sets(45, 10, count: 1), isWarmUp: true),
                .init(id: "b", name: "Bench press", restSeconds: 150, sets: sets(185, 5, count: 3), history: .init(
                    lastTime: [.init(weight: 185, reps: 5), .init(weight: 185, reps: 5), .init(weight: 185, reps: 5)],
                    best: .init(weight: 205, reps: 3), bestDate: t0.addingTimeInterval(-21 * 86400),
                    bestEstimate: 225.5
                )),
                .init(id: "p", name: "Press", restSeconds: 120, sets: sets(95, 8, count: 2)),
            ]
        )
    }

    @Test("It opens on the first lift with sets left, on a set")
    func opens() {
        let state = state()
        #expect(state.focus == 0)
        #expect(state.phase == .set)
        #expect(state.liftsLeft == 3)
    }

    @Test("Dragging moves the sets left 5 lb a step, never under zero")
    func drag() {
        var state = state()
        state.select(lift: 1)
        let r1 = state.drag(steps: 2)
        #expect(r1)
        #expect(state.current.sets.map(\.weight) == [195, 195, 195])
        state.drag(steps: -100)
        #expect(state.current.sets.map(\.weight) == [0, 0, 0])
        let r2 = state.drag(steps: -1)
        #expect(!r2)
    }

    @Test("Dragging leaves done sets alone")
    func dragKeepsDone() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        state.endRest(at: t0)
        state.drag(steps: 1)
        #expect(state.current.sets.map(\.weight) == [185, 190, 190])
    }

    @Test("Logging a set starts that lift's rest from an end date")
    func logStartsRest() {
        var state = state()
        state.select(lift: 1)
        let now = t0.addingTimeInterval(60)
        let r3 = state.logSet(at: now)
        #expect(r3)
        #expect(state.phase == .rest(endsAt: now.addingTimeInterval(150), total: 150, lift: 1))
        #expect(state.restRemaining(at: now.addingTimeInterval(50)) == 100)
        let r4 = state.logSet(at: now)
        #expect(!r4)
    }

    @Test("A rest that ends turns back to a set; a finished lift turns the dial to the next")
    func autoTurn() {
        var state = state()
        let now = t0
        state.logSet(at: now)
        #expect(state.lifts[0].isComplete)
        state.tick(at: now.addingTimeInterval(29))
        #expect(state.focus == 0)
        state.tick(at: now.addingTimeInterval(31))
        #expect(state.phase == .set)
        #expect(state.focus == 1)
    }

    @Test("Tap to start now ends the rest early")
    func endRestEarly() {
        var state = state()
        state.logSet(at: t0)
        state.endRest(at: t0.addingTimeInterval(5))
        #expect(state.phase == .set)
        #expect(state.focus == 1)
    }

    @Test("Rest now from a set, and 30 s more during one")
    func restAndExtend() {
        var state = state()
        state.select(lift: 1)
        state.rest(at: t0)
        #expect(state.restRemaining(at: t0) == 150)
        state.rest(at: t0)
        #expect(state.restRemaining(at: t0) == 180)
    }

    @Test("Felt: Easy adds 5 lb to the sets left with a receipt, and the word sits beside the set")
    func feltEasy() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        let receipt = state.apply(felt: .easy)
        #expect(receipt?.text == "Easy, +5 lb on the 2 sets left")
        #expect(state.lifts[1].sets.map(\.weight) == [185, 190, 190])
        #expect(state.lifts[1].sets[0].done?.felt == .easy)
        #expect(state.lifts[1].sets[0].done?.weight == 185)
    }

    @Test("Felt: Hard takes 5 off, Right leaves it")
    func feltHardRight() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        state.apply(felt: .hard)
        #expect(state.lifts[1].sets.map(\.weight) == [185, 180, 180])
        var other = self.state()
        other.select(lift: 1)
        other.logSet(at: t0)
        let r5 = other.apply(felt: .right)
        #expect(r5?.setsChanged == 0)
        #expect(other.lifts[1].sets.map(\.weight) == [185, 185, 185])
    }

    @Test("Felt in kg moves 2.5")
    func feltKg() {
        var state = WorkoutModeState(title: "Pull", unit: .kilograms, startedAt: t0, lifts: [
            .init(id: "r", name: "Row", restSeconds: 90, sets: sets(60, 8, count: 3)),
        ])
        state.logSet(at: t0)
        state.apply(felt: .easy)
        #expect(state.lifts[0].sets.map(\.weight) == [60, 62.5, 62.5])
    }

    @Test("Felt only asks during a rest")
    func feltNeedsRest() {
        var state = state()
        let r6 = state.apply(felt: .easy)
        #expect(r6 == nil)
    }

    @Test("Lighter takes 10 lb off the sets left")
    func lighter() {
        var state = state()
        state.select(lift: 1)
        let receipt = state.lighter()
        #expect(state.current.sets.map(\.weight) == [175, 175, 175])
        #expect(receipt?.text == "Lighter, -10 lb on the 3 sets left")
    }

    @Test("Undo takes the set back inside 10 s only")
    func undo() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        #expect(!state.canUndo(at: t0.addingTimeInterval(11)))
        #expect(state.canUndo(at: t0.addingTimeInterval(9)))
        let r7 = state.undo(at: t0.addingTimeInterval(9))
        #expect(r7)
        #expect(state.phase == .set)
        #expect(state.lifts[1].setsLeft == 3)
    }

    @Test("The last set ends the workout; no rest")
    func lastSet() {
        var state = WorkoutModeState(title: "A", unit: .pounds, startedAt: t0, lifts: [
            .init(id: "x", name: "X", restSeconds: 60, sets: sets(100, 5, count: 1)),
        ])
        state.logSet(at: t0.addingTimeInterval(120))
        #expect(state.isDone)
        #expect(state.elapsed(at: t0.addingTimeInterval(999)) == 120)
        #expect(state.finishLine(at: t0) == "Finished, 2 min, 1 set, about 500 lb")
    }

    @Test("Finish compares with the last same workout")
    func finishCompare() {
        var state = WorkoutModeState(title: "Push A", unit: .pounds, startedAt: t0, lifts: [
            .init(id: "x", name: "X", restSeconds: 60, sets: sets(100, 10, count: 1)),
        ])
        state.logSet(at: t0.addingTimeInterval(60))
        #expect(state.finishLine(at: t0, lastVolume: 800).hasSuffix("200 lb more than last Push A"))
    }

    @Test("Done about counts the rest left, each set left and its rest, none after the very last set")
    func doneAbout() {
        var state = WorkoutModeState(title: "A", unit: .pounds, startedAt: t0, lifts: [
            .init(id: "x", name: "X", restSeconds: 60, sets: sets(100, 5, count: 2)),
            .init(id: "y", name: "Y", restSeconds: 30, sets: sets(50, 5, count: 1)),
        ])
        state.setSeconds = 40
        // X1 (40 + 60), X2 (40 + 60), Y1 (40, no rest) = 240
        #expect(state.doneAbout(at: t0) == t0.addingTimeInterval(240))
        state.logSet(at: t0)
        // 60 s of rest left, X2 (40 + 60), Y1 (40) = 200
        #expect(state.doneAbout(at: t0) == t0.addingTimeInterval(200))
    }

    @Test("The clock rounds to five minutes and reads Done about")
    func band() {
        let state = state()
        let band = state.band(at: t0.addingTimeInterval(12 * 60))
        #expect(band.timeIn == "12 min in")
        #expect(band.lifts == "3 of 3 lifts to go")
        #expect(band.clock == "12:00")
        #expect(band.doneAbout.hasPrefix("Done about "))
        let rounded = WorkoutModeState.roundedToFive(t0.addingTimeInterval(7 * 60 + 40))
        #expect(rounded.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 300) == 0)
    }

    @Test("Epley and the estimated max")
    func epley() {
        let value = WorkoutModeState.epley(weight: 185, reps: 5)
        #expect(abs((value ?? 0) - 215.8333) < 0.001)
        #expect(WorkoutModeState.epley(weight: 0, reps: 5) == nil)
        var state = state()
        state.select(lift: 1)
        #expect(abs((state.estimatedMax ?? 0) - 215.8333) < 0.001)
    }

    @Test("The scoreboard in a set: header, numerals, last time's same set")
    func scoreboardSet() {
        var state = state()
        state.select(lift: 1)
        state.drag(steps: 1)
        let board = state.scoreboard(at: t0)
        #expect(board.header == "SET 1 OF 3")
        #expect(board.trailing == "BEST 205")
        #expect(board.main == "190")
        #expect(board.unit == "lb")
        #expect(board.multiplier == "× 5")
        #expect(board.info1 == "Bench press, 5 reps")
        #expect(board.info2 == "Last time 185 × 5, now +5 lb")
        #expect(!board.isRest)
    }

    @Test("First time with a lift says so")
    func firstTime() {
        let state = state()
        #expect(state.scoreboard(at: t0).info2 == "First time with this lift")
    }

    @Test("The scoreboard in a rest: countdown, next set, tap to start")
    func scoreboardRest() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        let board = state.scoreboard(at: t0.addingTimeInterval(10))
        #expect(board.isRest)
        #expect(board.header == "REST")
        #expect(board.main == "2:20")
        #expect(board.info1 == "Next, bench press, 185 lb × 5")
        #expect(board.info2 == "Tap to start now")
    }

    @Test("The board draws plates for the set, and the next set's load in a rest")
    func boardPlates() {
        var state = state()
        state.select(lift: 1)
        #expect(state.board(at: t0).plates?.perSide == [45, 25])
        #expect(state.board(at: t0).loadNext == nil)
        state.logSet(at: t0)
        let board = state.board(at: t0.addingTimeInterval(1))
        #expect(board.loadNext == "then bench press 185, each side 45 + 25")
        #expect(board.chips.map(\.text) == ["185×5", "185×5", "185×5"])
        #expect(board.chips.map(\.state) == [.done, .current, .left])
    }

    @Test("A stack lift shows a pin, not plates")
    func stack() {
        let state = WorkoutModeState(title: "A", unit: .pounds, startedAt: t0, lifts: [
            .init(id: "c", name: "Cable row", equipment: .stack, restSeconds: 90, sets: sets(100, 10, count: 3)),
        ])
        #expect(state.board(at: t0).plates == nil)
    }

    @Test("The summary ledger keeps the Felt word and the best with an estimated max")
    func summary() {
        var state = state()
        state.select(lift: 1)
        state.logSet(at: t0)
        state.apply(felt: .easy)
        let summary = state.summary(at: t0)
        #expect(summary.rows.map(\.felt) == ["Easy", "", ""])
        #expect(summary.rows.map(\.state) == [.done, .current, .left])
        #expect(summary.footer == "Best 205, 3 weeks ago, est. max 226")
    }

    @Test("Display lines never end in a full stop")
    func noStops() {
        var state = state()
        state.select(lift: 1)
        var lines = [state.scoreboard(at: t0).info1, state.scoreboard(at: t0).info2]
        state.logSet(at: t0)
        lines += [state.apply(felt: .easy)?.text ?? "", state.scoreboard(at: t0).info1, state.band(at: t0).doneAbout]
        lines.append(state.board(at: t0).loadNext ?? "")
        lines.append(state.finishLine(at: t0))
        #expect(lines.allSatisfy { !$0.hasSuffix(".") && !$0.contains("...") })
    }
}

@Suite("Workout mode: warm-up")
struct WarmUpModeTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func state() -> WorkoutModeState {
        WorkoutModeState(title: "Push A", unit: .pounds, startedAt: t0, lifts: [
            .init(id: "w", name: "Warm up", equipment: .stack, restSeconds: 30,
                  sets: [.init(weight: 0, reps: 0)], isWarmUp: true,
                  warmUp: WarmUpPlan(name: "Rower", minutes: 8, note: "Keep it easy")),
            .init(id: "b", name: "Bench press", restSeconds: 150, sets: [.init(weight: 185, reps: 5)]),
        ])
    }

    @Test("The warm-up reads as minutes on the scoreboard, with its note")
    func scoreboard() {
        let board = state().scoreboard(at: t0)
        #expect(board.header == "WARM UP")
        #expect(board.main == "8" && board.unit == "min")
        #expect(board.info1 == "Rower" && board.info2 == "Keep it easy")
    }

    @Test("Done about counts the warm-up's minutes")
    func doneAbout() {
        var lone = state()
        lone.setSeconds = 40
        // warm-up 480 + 30 rest, bench 40 and no rest after the last set
        #expect(lone.doneAbout(at: t0) == t0.addingTimeInterval(550))
    }

    @Test("No warm-up source gives no warm-up lift")
    func none() {
        #expect(!state().lifts[1].isWarmUp)
    }
}

@Suite("Workout mode: lock screen payload")
struct ModeLiveContentTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func resting(isPrivate: Bool) -> WorkoutModeState {
        let sets = (0 ..< 3).map { _ in WorkoutModeState.PlannedSet(weight: 185, reps: 5) }
        var state = WorkoutModeState(
            title: isPrivate ? "Private workout" : "Push A",
            unit: .pounds,
            startedAt: t0,
            lifts: [
                .init(id: "b", name: "Bench press", restSeconds: 150, sets: sets),
            ]
        )
        state.isPrivate = isPrivate
        state.logSet(at: t0)
        return state
    }

    @Test("A rest shows the word, the lines and a countdown end date")
    func rest() {
        let content = ModeLiveContent.workout(resting(isPrivate: false), at: t0)
        #expect(content.word == "Bench")
        #expect(content.top == "Rest, then bench")
        #expect(content.next == "185 lb × 5, each side 45 + 25")
        #expect(content.timerEnd == t0.addingTimeInterval(150))
    }

    @Test("A private workout carries only Rest, the time and Private workout: no lift, weight or count")
    func privatePayload() throws {
        let content = ModeLiveContent.workout(resting(isPrivate: true), at: t0)
        #expect(content.word == "Rest")
        #expect(content.top == "Rest")
        #expect(content.quiet == "Private workout")
        #expect(content.timerEnd != nil)
        let json = try String(decoding: JSONEncoder().encode(content), as: UTF8.self)
        for banned in ["Bench", "bench", "185", "lb", "Set", "set"] {
            #expect(!json.contains(banned), "payload leaked \(banned)")
        }
    }

    @Test("A private workout on a set shows no lift either")
    func privateSet() throws {
        var state = resting(isPrivate: true)
        state.endRest(at: t0)
        let json = try String(decoding: JSONEncoder().encode(ModeLiveContent.workout(state, at: t0)), as: UTF8.self)
        #expect(!json.contains("Bench") && !json.contains("185"))
    }
}

@Suite("Workout mode: plate diff")
struct PlateDiffTests {
    @Test("Adding a plate on the outside keeps the rest and adds one")
    func adds() {
        let diff = PlateDiff.between([45], [45, 25])
        #expect(diff.kept == [.init(position: 0, plate: 45)])
        #expect(diff.added == [.init(position: 1, plate: 25)])
        #expect(diff.removed.isEmpty)
    }

    @Test("Removing the outer plate slides it off")
    func removes() {
        let diff = PlateDiff.between([45, 25], [45])
        #expect(diff.removed == [.init(position: 1, plate: 25)])
        #expect(diff.added.isEmpty)
    }

    @Test("A changed inner plate takes everything after it off and puts the new ones on, inside out")
    func swaps() {
        let diff = PlateDiff.between([45, 25, 5], [45, 35])
        #expect(diff.kept.map(\.plate) == [45])
        #expect(diff.removed.map(\.plate) == [25, 5])
        #expect(diff.added.map(\.plate) == [35])
    }

    @Test("Same load is empty, and the bar alone has nothing kept")
    func same() {
        #expect(PlateDiff.between([45, 25], [45, 25]).isEmpty)
        let bar = PlateDiff.between([45], [])
        #expect(bar.kept.isEmpty && bar.removed.count == 1)
    }
}
