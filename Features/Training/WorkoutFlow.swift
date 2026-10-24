import Foundation
import Observation
import SwiftUI
import TesseraCore

/// What a warm-up is (sheet 230): a name, a countdown and one line of how. Core has no warm-up object yet, so the
/// source is a seam: `SampleWarmUps` answers until Core's lands (listed in the report as a Core need).
struct WarmUp: Equatable, Sendable {
    let name: String
    let seconds: Int
    let note: String
}

protocol WarmUpSource: Sendable {
    /// The warm-up for a routine, or nil when it has none.
    func warmUp(forRoutine title: String, firstLift: String?) -> WarmUp?
}

struct SampleWarmUps: WarmUpSource {
    func warmUp(forRoutine _: String, firstLift: String?) -> WarmUp? {
        let next = firstLift.map { " \($0) is next." } ?? ""
        return WarmUp(name: "Rower, easy", seconds: 480,
                      note: "Keep it easy, about 22 strokes a minute.\(next)")
    }
}

/// One row of the session wheel.
struct LiftRow: Identifiable, Equatable {
    enum State: Equatable {
        case done, skipped, current, upcoming
    }

    let id: UUID
    let classID: UUID?
    let name: String
    let state: State
    let doneReps: [Int]
    let sets: Int
    let plannedReps: Int
    var marks: [StackMarkSpec]

    var info: String {
        TrainingWords.rowInfo(done: doneReps, sets: sets, plannedReps: plannedReps)
    }
}

/// The live workout's state of the sheet-230 screen, apart from `WorkoutSession` (which owns the sets and the op log):
/// the warm-up, skipped lifts, the 5 s confirmation of a whole set, the 10 s Undo and the brief. One per workout,
/// kept in `WorkoutFlows` so leaving mid-workout and coming back (Pick up Push A) finds it as it was.
@MainActor
@Observable
final class WorkoutFlow {
    /// A set just logged and the plates and number travelling to the trail.
    struct Moment: Equatable, Identifiable {
        let id = UUID()
        let entryID: UUID
        let number: Int
        let reps: Int
    }

    /// "Set 1, 5 reps." with the 5 scrolling; any change restarts the 5 s.
    struct Confirmation: Equatable {
        let setID: UUID
        let number: Int
        var reps: Int
        var kept = false
        var token = 0
        let loggedAt: Date
    }

    /// A line in the brief slot, with what Undo takes back.
    struct Brief: Identifiable {
        let id = UUID()
        let text: String
        var short: String?
        let undo: (() -> Void)?
    }

    enum Stage: Equatable {
        case warmUp(endsAt: Date)
        case set
        case rest(endsAt: Date)
        case done
    }

    static let confirmSeconds = 5.0
    static let undoSeconds = 10.0

    let session: WorkoutSession
    let warmUp: WarmUp?
    private(set) var warmUpEndsAt: Date?
    private(set) var warmedUp = false
    private(set) var skipped: Set<UUID> = []
    var moment: Moment?
    var confirmation: Confirmation?
    var brief: Brief?
    /// The weight at the start of the set under way (kg): "was 185" shows against it.
    var weightWasKilograms: Double?
    /// Bumped when the unit turns, so the digits redraw (Format.unit is not observable).
    private(set) var unitTick = 0
    /// How many sets this screen has logged: the trail's arrival and the set count roll on it.
    private(set) var shownSetNumber = 1

    init(session: WorkoutSession, source: WarmUpSource = SampleWarmUps()) {
        self.session = session
        let started = session.entries.contains { !session.setRows(of: $0).isEmpty }
        let first = session.entries.first.flatMap { session.exerciseClass(of: $0)?.name }
        warmUp = started ? nil : source.warmUp(forRoutine: session.workout.title, firstLift: first)
        if warmUp != nil {
            warmUpEndsAt = AppClock.now.addingTimeInterval(Double(warmUp?.seconds ?? 0))
        } else {
            warmedUp = false
        }
        weightWasKilograms = session.weight
        shownSetNumber = session.currentSetNumber
    }

    // MARK: Stage

    var isWarmingUp: Bool {
        warmUp != nil && !warmedUp && warmUpEndsAt != nil
    }

    func finishWarmUp() {
        warmedUp = true
        warmUpEndsAt = nil
    }

    func isSkipped(_ entry: ObjectRecord) -> Bool {
        skipped.contains(entry.id)
    }

    private func isSettled(_ entry: ObjectRecord) -> Bool {
        session.isFinished(entry) || skipped.contains(entry.id)
    }

    var everyLiftSettled: Bool {
        let all = session.entries
        return !all.isEmpty && all.allSatisfy(isSettled)
    }

    func stage(at now: Date) -> Stage {
        if let end = warmUpEndsAt, isWarmingUp {
            return .warmUp(endsAt: end)
        }
        if moment == nil, case let .rest(end) = session.phase(at: now) {
            return .rest(endsAt: end)
        }
        if everyLiftSettled {
            return .done
        }
        return .set
    }

    /// The lift the screen is on: moves past a finished or skipped one.
    func advanceIfNeeded() {
        guard let entry = session.currentEntry, isSettled(entry) else { return }
        let all = session.entries
        let order = Array(all.indices.dropFirst(session.currentIndex + 1)) +
            Array(all.indices.prefix(session.currentIndex))
        if let next = order.first(where: { !isSettled(all[$0]) }) {
            session.select(entryAt: next)
            shownSetNumber = session.currentSetNumber
            weightWasKilograms = session.weight
        }
    }

    // MARK: Rows

    func rows() -> [LiftRow] {
        let all = session.entries
        return all.enumerated().map { index, entry in
            let done = session.setRows(of: entry).map { Int($0.reps) }
            let sets = max(session.targetSets(of: entry), done.count)
            let planned = Int(session.targetReps(of: entry))
            let state: LiftRow.State = if skipped.contains(entry.id) {
                .skipped
            } else if session.isFinished(entry) {
                .done
            } else if index == session.currentIndex {
                .current
            } else {
                .upcoming
            }
            let focusSet = done.count
            let marks = (0 ..< sets).map { setIndex in
                StackMarkSpec(reps: planned, lifted: setIndex < done.count ? done[setIndex] : 0,
                              isFocus: state == .current && setIndex == focusSet)
            }
            return LiftRow(id: entry.id, classID: session.exerciseClass(of: entry)?.id,
                           name: session.exerciseClass(of: entry)?.name ?? "Lift", state: state, doneReps: done,
                           sets: sets, plannedReps: planned, marks: marks)
        }
    }

    var liftsToGo: Int {
        session.entries.count { !isSettled($0) }
    }

    var nextLiftName: String? {
        let all = session.entries
        let order = Array(all.indices.dropFirst(session.currentIndex + 1)) +
            Array(all.indices.prefix(session.currentIndex))
        return order.first { !isSettled(all[$0]) }.flatMap { session.exerciseClass(of: all[$0])?.name }
    }

    // MARK: Logging

    /// The foot's "Log set N": logs the full target in one go (no per-rep logging), and starts the moment.
    @discardableResult
    func logWholeSet(reps planned: Double? = nil) -> Bool {
        guard let entry = session.currentEntry else { return false }
        let before = session.setRows(of: entry).count
        session.reps = planned ?? session.targetReps(of: entry)
        session.logSet()
        guard let row = session.setRows(of: entry).last, session.setRows(of: entry).count > before else { return false }
        let reps = Int(row.reps)
        moment = Moment(entryID: entry.id, number: row.number, reps: reps)
        confirmation = Confirmation(setID: row.id, number: row.number, reps: reps, loggedAt: AppClock.now)
        brief = nil
        return true
    }

    /// The scrolling 5 moved: write it to the set, and the 5 s start again.
    func setConfirmedReps(_ reps: Int) {
        guard var current = confirmation else { return }
        let clamped = min(max(reps, 1), Int(session.targetRepsOfCurrent) + 10)
        current.reps = clamped
        current.kept = false
        current.token += 1
        confirmation = current
        _ = try? session.model.engine.perform(EditSet(set: current.setID, reps: Double(clamped)), by: .user)
        session.refreshAfterExternalWrite()
        // A set logged after this one keeps its own number.
        shownSetNumber = session.currentSetNumber
    }

    /// The 5 s ran out: "Set 1, 5 reps, kept."
    func keepConfirmation(token: Int) {
        guard var current = confirmation, current.token == token, !current.kept else { return }
        current.kept = true
        confirmation = current
    }

    /// The set the confirmation shows can still be taken back for 10 s from the log.
    func canUndoLog(at now: Date) -> Bool {
        guard let confirmation, session.canUndo else { return false }
        return now.timeIntervalSince(confirmation.loggedAt) < Self.undoSeconds
    }

    func undoLog() {
        session.undoLastSet()
        confirmation = nil
        moment = nil
        shownSetNumber = session.currentSetNumber
        weightWasKilograms = session.weight
    }

    /// The moment finished travelling: the set count rolls to the next set, and rest shows.
    func momentLanded() {
        moment = nil
        shownSetNumber = session.currentSetNumber
        weightWasKilograms = session.weight
    }

    // MARK: Skipping, swapping

    /// "Skip this lift": it strikes in ink 3 and the screen moves on. Returns its Undo.
    @discardableResult
    func skipLift() -> () -> Void {
        guard let entry = session.currentEntry else { return {} }
        let id = entry.id
        let wasIndex = session.currentIndex
        skipped.insert(id)
        advanceIfNeeded()
        return { [weak self] in
            guard let self else { return }
            skipped.remove(id)
            if let index = session.entries.firstIndex(where: { $0.id == id }), index != session.currentIndex {
                session.select(entryAt: index)
            } else if session.entries.indices.contains(wasIndex), wasIndex != session.currentIndex {
                session.select(entryAt: wasIndex)
            }
            shownSetNumber = session.currentSetNumber
        }
    }

    /// "Do it now" on a lift not done: it comes in front, the lift under way goes after it. Returns its Undo.
    func doItNow(_ entryID: UUID) -> (() -> Void)? {
        let all = session.entries
        guard let target = all.firstIndex(where: { $0.id == entryID }), target != session.currentIndex,
              let current = session.currentEntry else { return nil }
        let currentID = current.id
        let at = session.currentIndex
        skipped.remove(entryID)
        session.move(entryID: entryID, to: at)
        if let index = session.entries.firstIndex(where: { $0.id == entryID }) {
            session.select(entryAt: index)
        }
        shownSetNumber = session.currentSetNumber
        weightWasKilograms = session.weight
        return { [weak self] in
            guard let self else { return }
            if let index = session.entries.firstIndex(where: { $0.id == currentID }) {
                session.select(entryAt: index)
            }
            session.move(entryID: entryID, to: target)
            shownSetNumber = session.currentSetNumber
        }
    }

    // MARK: Brief

    /// Puts a line in the brief; with something to take back it holds 10 s with Undo, else 4 s.
    func say(_ text: String, short: String? = nil, undo: (() -> Void)? = nil) {
        let line = Brief(text: text, short: short, undo: undo)
        brief = line
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(undo == nil ? 4 : Self.undoSeconds))
            if self?.brief?.id == line.id {
                self?.brief = nil
            }
        }
    }

    // MARK: Weight and units

    func unitTurned() {
        unitTick += 1
    }

    // MARK: Finish

    /// Ends the workout with what is logged; skipped and unstarted lifts are marked skipped by Core.
    func finish() {
        let unfinished = session.entries.contains { !session.isFinished($0) }
        session.finish(early: unfinished)
    }
}

extension WorkoutSession {
    /// Planned reps of the lift on screen.
    var targetRepsOfCurrent: Double {
        currentEntry.map(targetReps(of:)) ?? 8
    }
}

/// One flow per running workout, so the screen can be left and picked up again.
@MainActor
enum WorkoutFlows {
    private static var flows: [UUID: WorkoutFlow] = [:]

    static func flow(for session: WorkoutSession) -> WorkoutFlow {
        if let flow = flows[session.workout.id], flow.session === session {
            return flow
        }
        let flow = WorkoutFlow(session: session)
        flows[session.workout.id] = flow
        return flow
    }

    static func drop(_ session: WorkoutSession) {
        flows[session.workout.id] = nil
    }
}
