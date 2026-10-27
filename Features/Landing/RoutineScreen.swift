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

    init(_ run: RoutineRun, name: String, totalMinutes: Int, now: Date) {
        title = name
        dusk = run.dusk
        finished = run.finished
        paused = run.isPaused
        pauseWord = run.isPaused ? "Resume" : "Pause"
        let tended = run.tended.count
        topRight = tended == 0 ? "about \(totalMinutes) min to bed" : "\(tended) of \(run.steps.count) tended"
        summary = "Tended, \(tended) of \(run.steps.count) steps"
        rail = run.steps.map { step in
            let state: Color? = run.tended.contains(step.id) ? RoutineScreen.tendedGreen
                : run.skipped.contains(step.id) ? RoutineScreen.slate : nil
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
        line = "\(step.title), \(beat.step + 1) of \(run.steps.count)"
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

    static let tendedGreen = Color(hex: 0x6FAE7A)
    static let slate = Color(hex: 0x8A93A6)
}
