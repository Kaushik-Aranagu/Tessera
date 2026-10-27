import SwiftUI
import TesseraCore

/// Routine mode's whole screen as data (sheet 329): the step and move count, the move big, the cue in Tess's voice, the
/// breath in words, the time left, the step's moves with their times, the evening's steps down the right edge, and what
/// the thumb does. Pure, so it tests.
struct RoutineScreen: Equatable {
    struct MoveRow: Equatable, Identifiable {
        enum State { case done, current, upcoming }
        let id: Int
        let title: String
        let time: String
        let state: State
    }

    var title = ""
    /// Top right: "1 of 5 tended", or when none yet, how long the evening is.
    var topRight = ""
    /// "Stretch, 2 of 5".
    var line = ""
    /// "then sink": what comes after this move; nil on the last.
    var then: String?
    /// The step's total minutes, on the right of the top line.
    var stepMinutes: String?
    var move = ""
    var cue: String?
    /// "breathe in" or "breathe out" (words only), nil when the move has none.
    var breath: String?
    var secondsLeft = 0
    var moves: [MoveRow] = []
    var rail: [GalleyRailItem] = []
    var verb = "Next"
    var pauseWord = "Pause"
    var paused = false
    var dusk = 0.0
    var finished = false
    /// Sheet 335: how bright the whole screen is. 1 until the last step; there the sky and the words dim together to
    /// 62% as the countdown runs, and "Evening tended" stays at 62%.
    var brightness = 1.0
    /// The end: "Tended, 4 of 5 steps".
    var summary = ""

    init(_ run: RoutineModeRun, name: String, totalMinutes: Int, now: Date) {
        title = name
        dusk = run.dusk
        finished = run.finished
        paused = run.isPaused
        pauseWord = run.isPaused ? "Resume" : "Pause"
        let tended = run.tended.count
        topRight = tended == 0 ? "about \(totalMinutes) min to bed" : "\(tended) of \(run.steps.count) tended"
        summary = "Tended, \(tended) of \(run.steps.count) steps"
        rail = run.steps.map { step in
            // Done steps are dimmed ink, not green; a step left for tomorrow is dimmer still.
            let state: Color? = run.tended.contains(step.id) ? RoutineScreen.tended
                : run.skipped.contains(step.id) ? RoutineScreen.skippedInk : nil
            return GalleyRailItem(id: step.id, label: step.title, detail: "\(step.minutes)",
                                  current: run.beat?.step == step.id, done: run.tended.contains(step.id), color: state)
        }
        if run.finished, run.steps.indices.contains(run.steps.count - 1), run.tended.contains(run.steps.count - 1) {
            brightness = RoutineScreen.dimmest
        }
        guard let beat = run.beat else { return }
        if beat.step == run.steps.count - 1 {
            let left = run.secondsLeft(at: now)
            let fraction = 1 - min(max(left / TimeInterval(max(beat.seconds, 1)), 0), 1)
            brightness = 1 - (1 - RoutineScreen.dimmest) * fraction
        }
        let step = run.steps[beat.step]
        // The header counts moves ("Tidy, 1 of 3"); a step with no moves counts the evening's steps.
        if let count = run.moveCount {
            line = "\(step.title), \(count.at) of \(count.of)"
        } else {
            line = "\(step.title), \(beat.step + 1) of \(run.steps.count)"
        }
        then = run.then
        stepMinutes = "\(step.minutes) min"
        move = beat.title
        cue = beat.cue
        secondsLeft = Int(run.secondsLeft(at: now).rounded(.up))
        breath = run.breath(at: now).map { "breathe \($0)" }
        if beat.isMove {
            moves = step.beats.enumerated().map { offset, beatIndex in
                let other = run.beats[beatIndex]
                let state: MoveRow.State = beatIndex < run.index ? .done : beatIndex == run.index ? .current : .upcoming
                return MoveRow(id: offset, title: other.title, time: GalleyCookWords.clock(TimeInterval(other.seconds)),
                               state: state)
            }
        }
    }

    /// The dimmest the last step and the closing screen get (62% brightness).
    static let dimmest = 0.62

    /// The routine's ink (sheet 329 and 335): F4EEF2 on the dusk.
    static let ink = Color(hex: 0xF4EEF2)
    static let tended = ink.opacity(0.5)
    static let skippedInk = ink.opacity(0.32)
}
