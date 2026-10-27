import Foundation
import Observation
import SwiftUI
import TesseraCore
import UIKit

/// The cook, as the clock page sees it: the recipe's steps on the clock, where the bead is on each track, and the
/// timers. Everything that must survive leaving the page is written through Core's own actions (`GoToCookStep`'s
/// resume point, `StartKitchenTimer`, `StopKitchenTimer`, `FinishCooking`); what Core has no field for yet (the second
/// track's place, which step owns which timer) rides in the process's resume point `extras`, written by `SaveContext`.
/// What Core must provide to replace that is listed in the hand-off notes (`Kitchen Timer.step`, per-track resume).
@MainActor @Observable
final class CookClockSession {
    /// A timer as the page draws it.
    struct Line: Identifiable, Equatable {
        let id: UUID
        let label: String
        let endsAt: Date
        let startedAt: Date
        /// The step it belongs to, nil for a timer he spoke ("Bread").
        let step: Int?

        var total: TimeInterval {
            max(1, endsAt.timeIntervalSince(startedAt))
        }

        func remaining(at now: Date) -> TimeInterval {
            max(0, endsAt.timeIntervalSince(now))
        }

        /// `endsAt` on the real clock, for the system's own countdown text (the app clock may be shifted in a demo).
        var realEnd: Date {
            endsAt.addingTimeInterval(-AppClock.now.timeIntervalSince(Date()))
        }

        func isDone(at now: Date) -> Bool {
            endsAt <= now
        }
    }

    /// One thing the page shows once, a receipt in Tess's line with its UNDO.
    struct Receipt: Equatable {
        let id = UUID()
        let text: String
        let undo: OpRecord?
        let heldFor: Duration

        static func == (lhs: Receipt, rhs: Receipt) -> Bool {
            lhs.id == rhs.id
        }
    }

    let model: AppModel
    let cookID: UUID
    let recipeID: UUID
    let steps: [RecipeBook.Step]
    let plan: CookClockPlan
    let parallel: Bool
    let isPrivate: Bool
    let recipeName: String
    let serves: Int?

    /// The step each live track is on: one, or two with a lane open. `lead` indexes it.
    private(set) var tracks: [Int]
    private(set) var lead = 0
    /// Which steps have had their timer started, so going back and forward never starts a second (PS: one timer per
    /// timed step).
    private var started: Set<Int> = []
    private var timerOfStep: [Int: UUID] = [:]
    private(set) var lastStepChange: Date = AppClock.now
    private(set) var receipt: Receipt?
    /// Bumped once per moment, for the view's haptic cue: (haptic, count).
    private(set) var cue = HapticCue()
    /// Timers that have ended and are held (flared) until he stops them.
    private(set) var flared: Set<UUID> = []
    /// The timer whose end plays the flare's one overlay (the soonest of a moment), and how many more wait behind "+N".
    private(set) var overlay: UUID?
    private(set) var overlayWaiting = 0
    /// The one ring, played once per ended line: the ids that have rung.
    private(set) var rung: Set<UUID> = []
    private var announced: Set<UUID> = []
    private var armed: Task<Void, Never>?

    var speaker: any CookSpeaking = TessSpeech.shared
    var announce: (String) -> Void = { UIAccessibility.post(notification: .announcement, argument: $0) }

    init?(model: AppModel, cookID: UUID) {
        guard let cook = model.store.object(id: cookID),
              let recipe = model.store.linkedObjects("recipe", of: cook).first else { return nil }
        self.model = model
        self.cookID = cookID
        recipeID = recipe.id
        let book = RecipeBook(store: model.store, classes: model.classes)
        steps = book.steps(of: recipe)
        guard !steps.isEmpty else { return nil }
        parallel = Choice.parallelStepsIsOn()
        plan = CookClockPlan.make(steps.map { ($0.text, $0.timers) }, lanes: parallel)
        isPrivate = ObjectPrivacy.cookTitle(cook, in: model.store) == ObjectPrivacy.recipeLabel
        recipeName = ObjectPrivacy.cookTitle(recipe, in: model.store)
        serves = CookLog(store: model.store, classes: model.classes).serves(of: cook)
        let resume = Self.resume(of: cookID, model: model)
        let first = min(max(resume?.index ?? 0, 0), steps.count - 1)
        tracks = [first]
        if let other = resume?.extras["track2"].flatMap(Int.init), steps.indices.contains(other), parallel {
            tracks.append(other)
            lead = resume?.extras["lead"] == "1" ? 1 : 0
        }
        started = Set((resume?.extras["started"] ?? "").split(separator: ",").compactMap { Int($0) })
        for pair in (resume?.extras["timers"] ?? "").split(separator: ",") {
            let parts = pair.split(separator: ":")
            if parts.count == 2, let step = Int(parts[0]), let id = UUID(uuidString: String(parts[1])) {
                timerOfStep[step] = id
            }
        }
        // A brand-new cook arrives on a timed first step: its timer starts as the bead lands (PS3).
        if resume == nil || (resume?.extras["started"] == nil && tracks == [0]) {
            arrive(at: tracks[0], quietly: true)
        }
        opensLaneIfCued(at: tracks[0])
        reconcileFlares(at: AppClock.now, live: false)
    }

    // MARK: Reading

    var current: Int {
        tracks[min(lead, tracks.count - 1)]
    }

    var other: Int? {
        tracks.count > 1 ? tracks[1 - min(lead, 1)] : nil
    }

    var isLast: Bool {
        current == steps.count - 1 && other == nil
    }

    var isFirstStep: Bool {
        current == 0
    }

    func text(of step: Int) -> String {
        guard steps.indices.contains(step) else { return "" }
        return isPrivate ? ObjectPrivacy.recipeLabel : CookUnits.withFahrenheit(steps[step].text)
    }

    /// The running timers of this cook, soonest first.
    var timers: [Line] {
        _ = model.revision
        return CookLog(store: model.store, classes: model.classes).timers()
            .filter { $0.cook?.id == cookID }
            .map { timer in
                let name = KitchenTimerAlerts.hidesLabel(timer.label, cook: timer.cook, in: model.store)
                    ? "Timer" : timer.label
                let step = timerOfStep.first { $0.value == timer.id }?.key
                return Line(id: timer.id, label: name, endsAt: timer.endsAt, startedAt: timer.startedAt, step: step)
            }
    }

    /// The timer of the step a track is on, if it has one.
    func timer(ofStep step: Int) -> Line? {
        timers.first { $0.step == step }
    }

    /// Timers that are his own words and belong to no step, under the key row.
    var spokenTimers: [Line] {
        timers.filter { $0.step == nil }
    }

    /// The lines of the stroke: lead track's timer first, the other's, then nothing else (never three on the clock).
    var trackTimers: [Line] {
        let all = timers
        var picks: [Line] = []
        for track in [current] + (other.map { [$0] } ?? []) {
            if let line = all.first(where: { $0.step == track }) {
                picks.append(line)
            }
        }
        return picks
    }

    /// The key figure from the clock's join, never a sum (PS3, Open 5).
    func minutesLeft(at now: Date) -> Double {
        let remaining = timer(ofStep: current)?.remaining(at: now)
        var left = plan.minutesLeft(atStep: current, timerRemaining: remaining)
        if let other, let line = timer(ofStep: other) {
            // The join: the clock ends when the later track does.
            left = max(left, line.remaining(at: now) / 60 + max(0, plan.total - plan.steps[other].end))
        }
        return left
    }

    /// The soonest end among the timers still running, for the figure's boundary and the idle rule.
    func runningTimer(at now: Date) -> Bool {
        timers.contains { !$0.isDone(at: now) }
    }

    /// The idle rule (G218): awake while a timer runs or within 45 minutes of the last step change; the edge is
    /// exclusive, so at 45:00 the screen may sleep.
    func keepsAwake(at now: Date) -> Bool {
        runningTimer(at: now) || now.timeIntervalSince(lastStepChange) < 45 * 60
    }

    func touched(at now: Date = AppClock.now) {
        lastStepChange = now
    }

    // MARK: Moving the bead

    /// Moves the lead track forward one step (the vertical swipe, the voice word "next", VoiceOver's action).
    @discardableResult
    func next() -> Bool {
        guard let target = following(of: current) else {
            // A guest track with nothing after its last step closes when the bead leaves it.
            guard parallel, tracks.count > 1, lane(of: current) == 1 else { return false }
            tracks.remove(at: min(lead, tracks.count - 1))
            lead = 0
            lastStepChange = AppClock.now
            cue.play(.pickedUp)
            persist()
            return true
        }
        move(to: target, announceLine: true)
        return true
    }

    /// Moves the lead track back one step. On step 1 it does nothing and the line reads "Step 1 of 6."
    @discardableResult
    func back() -> Bool {
        guard let target = preceding(of: current) else {
            say(CookModeCopy.step(current, of: steps.count), undo: nil)
            return false
        }
        move(to: target, announceLine: true, starting: false)
        return true
    }

    /// Touching the other line hands the lead to it; the first track's step does not move (PS4).
    func lead(_ track: Int) {
        guard tracks.indices.contains(track), lead != track else { return }
        lead = track
        cue.play(.selection)
        persist()
    }

    private func lane(of step: Int) -> Int {
        plan.steps[step].lane
    }

    private func following(of step: Int) -> Int? {
        let lane = parallel ? lane(of: step) : 0
        return (step + 1 ..< steps.count).first { !parallel || self.lane(of: $0) == lane }
    }

    private func preceding(of step: Int) -> Int? {
        let lane = parallel ? lane(of: step) : 0
        return (0 ..< step).reversed().first { !parallel || self.lane(of: $0) == lane }
    }

    private func move(to target: Int, announceLine: Bool, starting: Bool = true) {
        tracks[min(lead, tracks.count - 1)] = target
        lastStepChange = AppClock.now
        // His Next is a medium impact; the bead's own soft one is not added on top (one haptic per moment).
        cue.play(.pickedUp)
        if starting {
            arrive(at: target, quietly: false)
        }
        opensLaneIfCued(at: target)
        persist()
        if announceLine {
            let line = CookModeCopy.step(target, of: steps.count)
            announce(line)
        }
    }

    /// The step's own timer starts as the bead reaches it, once (one timer per timed step).
    private func arrive(at step: Int, quietly: Bool) {
        guard steps.indices.contains(step), !started.contains(step),
              let minutes = plan.steps[step].timerMinutes else { return }
        started.insert(step)
        let label = CookTimerLabel.label(for: steps[step].text, stepIndex: step)
        let run = StartKitchenTimer(label: label, minutes: minutes, cook: cookID, time: AppClock.now)
        if let result = try? model.engine.perform(run, by: .user) {
            timerOfStep[step] = result.output.id
            model.touch()
            armEnd()
        }
        _ = quietly
    }

    /// With parallel steps on, a guest step opens its lane the moment the bead reaches its host (PS1, PS2).
    private func opensLaneIfCued(at step: Int) {
        guard parallel, tracks.count == 1, plan.steps.indices.contains(step) else { return }
        let host = plan.steps[step]
        guard host.lane == 0, host.isTimed, !host.isWait,
              let guest = plan.steps.first(where: { $0.lane == 1 && $0.start == host.start && $0.index > step })
        else { return }
        tracks.append(guest.index)
        arrive(at: guest.index, quietly: false)
    }

    /// Where the bead sits in the plan, for the clock column: minutes from the start, by step and the timer.
    func beadMinute(onTrack track: Int, at now: Date) -> Double {
        let step = plan.steps[tracks[track]]
        guard let line = timer(ofStep: step.index) else { return step.start }
        let spent = line.total - line.remaining(at: now)
        return step.start + min(step.minutes, spent / 60)
    }

    // MARK: Timers

    /// A timer he spoke or tapped ("Bread", 8 min), on its own line outside the stroke.
    func startSpoken(label: String?, minutes: Double) {
        let name = label ?? "Timer"
        let run = StartKitchenTimer(label: name, minutes: minutes, cook: cookID, time: AppClock.now)
        guard let result = try? model.engine.perform(run, by: .user) else {
            say("Didn't catch that", undo: nil)
            return
        }
        model.touch()
        armEnd()
        let shown = KitchenTimerAlerts.hidesLabel(name, cook: model.store.object(id: cookID), in: model.store)
            ? "Timer" : name
        say("\(shown), \(minutes.formatted(.number.precision(.fractionLength(0 ... 1)))) min",
            undo: result.record, held: .seconds(4))
    }

    /// Stop (drag left, the Stop action, a tap on the flared stack): fades, "Simmer stopped." with UNDO, no haptic.
    func stop(_ line: Line) {
        guard let result = try? model.engine.perform(StopKitchenTimer(timer: line.id), by: .user) else { return }
        flared.remove(line.id)
        if overlay == line.id {
            overlay = nil
            overlayWaiting = 0
        }
        model.touch()
        let text = CookModeCopy.timerStopped(line.label)
        say(text, undo: result.record, held: .seconds(10))
        announce(text)
    }

    // MARK: Ending

    /// Sleeps until the soonest ending timer, then lets the moment play. The page's timeline is paused when the
    /// scene is inactive, so this is cancelled with it.
    func armEnd() {
        armed?.cancel()
        let now = AppClock.now
        guard let soonest = timers.filter({ $0.endsAt > now }).map(\.endsAt).min() else { return }
        armed = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, soonest.timeIntervalSince(AppClock.now)) + 0.05))
            guard !Task.isCancelled, let self else { return }
            reconcileFlares(at: AppClock.now, live: true)
            armEnd()
        }
    }

    func pauseArming() {
        armed?.cancel()
    }

    /// Any timer past its end and not stopped is flared and held. When the app saw the end live (within 2 s of T0)
    /// the moment has its one `timeUp`, its announcement and, with the switch on, Tess's voice; opened late it plays
    /// the flare with no haptic (a buzz 20 minutes late would be a second alert for one event).
    func reconcileFlares(at now: Date, live: Bool) {
        let ended = timers.filter { $0.isDone(at: now) && !flared.contains($0.id) }
        guard !ended.isEmpty else { return }
        let sorted = ended.sorted { $0.endsAt < $1.endsAt }
        let saw = live && sorted.contains { now.timeIntervalSince($0.endsAt) <= 2 }
        for line in sorted {
            flared.insert(line.id)
        }
        // Two ending inside 600 ms are one moment: one haptic, one overlay (the soonest), the others behind "+N".
        let first = sorted[0].endsAt
        let together = sorted.filter { $0.endsAt.timeIntervalSince(first) <= 0.6 }
        overlay = sorted[0].id
        overlayWaiting = sorted.count - 1
        if saw {
            cue.play(.timeUp)
            let names = together.map(\.label)
            let spoken = Self.joinedDone(names)
            announce(spoken)
            if Choice.cookTimerVoiceIsOn() {
                speaker.say(spoken)
            }
        }
        for line in together where saw {
            rung.insert(line.id)
        }
    }

    /// "Roast is done." for one; "Roast and chicken, done." for two in one moment.
    static func joinedDone(_ names: [String]) -> String {
        guard names.count > 1 else { return CookModeCopy.timerDone(names.first ?? "Timer") }
        return "\(names.joined(separator: " and ")), done"
    }

    /// "5 more minutes" on a held timer: its own timer restarts, never a second one.
    func extend(_ line: Line, minutes: Double = 5) {
        guard (try? model.engine.perform(StopKitchenTimer(timer: line.id), by: .user)) != nil else { return }
        flared.remove(line.id)
        let run = StartKitchenTimer(label: line.label, minutes: minutes, cook: cookID, time: AppClock.now)
        if let result = try? model.engine.perform(run, by: .user) {
            if let step = line.step {
                timerOfStep[step] = result.output.id
            }
            persist()
            model.touch()
            armEnd()
        }
    }

    // MARK: Finish and notes

    /// Done: stops this cook's timers without a confirm, writes the Cook, and Tess says "Paprika chicken, cooked."
    /// with UNDO for 10 s. A note, when he wrote one, rides on the same write (`FinishCooking(note:)`).
    @discardableResult
    func finish(note: String?) -> Bool {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let clean = trimmed.flatMap { $0.isEmpty ? nil : String($0.prefix(280)) }
        guard let result = try? model.engine.perform(FinishCooking(cook: cookID, note: clean), by: .user) else {
            return false
        }
        model.touch()
        armed?.cancel()
        let line = CookNotes.cookedLine(recipeName)
        TessVoice.shared.say(line, undo: result.record, holds: .seconds(10))
        announce(line)
        return true
    }

    // MARK: Hands-free

    /// Acts on a heard phrase. Returns the line for Tess's receipt, nil when nothing was said (silent talk).
    @discardableResult
    func handle(_ outcome: HandsFreeGrammar.Outcome) -> String? {
        switch outcome {
        case .silent:
            return nil
        case .didntCatch:
            say("Didn't catch that", undo: nil)
            return "Didn't catch that"
        case let .refused(reason):
            say(reason.line, undo: nil)
            return reason.line
        case let .command(command):
            switch command {
            case .next:
                if !next() {
                    say("That's the last step", undo: nil)
                }
                return CookModeCopy.step(current, of: steps.count)
            case .back:
                _ = back()
                return CookModeCopy.step(current, of: steps.count)
            case let .timer(minutes, label):
                startSpoken(label: label, minutes: minutes)
                return "Timer"
            case let .note(text):
                pendingNote = text
                say("Note kept for next time", undo: nil)
                return text
            }
        }
    }

    /// A note he spoke, waiting for Finish.
    var pendingNote: String?

    // MARK: Receipts and the saved place

    func say(_ text: String, undo: OpRecord?, held: Duration = .seconds(4)) {
        let made = Receipt(text: text, undo: undo, heldFor: held)
        receipt = made
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: UIAccessibility.isVoiceOverRunning && undo != nil ? .seconds(10) : held)
            if self?.receipt?.id == made.id {
                self?.receipt = nil
            }
        }
    }

    func undo(_ receipt: Receipt) {
        guard let record = receipt.undo else { return }
        model.engine.undo(record)
        model.touch()
        self.receipt = nil
        cue.play(.undo)
    }

    private static func resume(of cook: UUID, model: AppModel) -> ResumePoint? {
        guard let object = model.store.object(id: cook) else { return nil }
        return ProcessTable(engine: model.engine).process(for: object)?.resumePoint
    }

    /// Writes the place: the lead track's step in `index` (so Now and the recipe page read the cook as before) and
    /// the rest in `extras`.
    private func persist() {
        guard let cook = model.store.object(id: cookID),
              let process = ProcessTable(engine: model.engine).process(for: cook) else { return }
        var extras: [String: String] = [:]
        if tracks.count > 1 {
            extras["track2"] = String(other ?? 0)
            extras["lead"] = String(lead)
        }
        extras["started"] = started.sorted().map(String.init).joined(separator: ",")
        extras["timers"] = timerOfStep.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value.uuidString)" }
            .joined(separator: ",")
        let step = current
        _ = try? model.engine.perform(
            SaveContext(process: process.id, resumePoint: ResumePoint(index: step, extras: extras),
                        nextStep: isPrivate ? ObjectPrivacy.recipeLabel : steps[step].text),
            by: .user
        )
        model.touch()
    }
}
