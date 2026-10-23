import Foundation
@testable import TesseraCore
import Testing

/// Sheet 204: cues → wires → one mood and a short queue of moments. Priority, queueing, quiet hours, inert weather.
struct MosaicSwitchboardTests {
    let now = Date(timeIntervalSince1970: 1_792_000_000)

    func cue(_ kind: MosaicCueKind, _ offset: TimeInterval = 0, key: String? = nil, claude: Bool = false) -> MosaicCue {
        MosaicCue(kind, at: now.addingTimeInterval(offset), key: key, needsClaude: claude)
    }

    func step(_ cues: [MosaicCue], from state: MosaicSwitchState = .init(), quiet: Bool = false, claude: Bool = false,
              weather: Bool = false) -> (state: MosaicSwitchState, directive: MosaicDirective)
    {
        MosaicSwitchboard.step(state, cues: cues, now: now, quiet: quiet, asksClaude: claude, weatherOn: weather)
    }

    @Test func everyCueHasExactlyOneDefaultWire() {
        for kind in MosaicCueKind.allCases {
            #expect(MosaicWires.defaults.filter { $0.cue == kind }.count == 1, "\(kind)")
        }
        #expect(MosaicWires.wire(for: .newBest)?.changeover == .melt)
        #expect(MosaicWires.wire(for: .workoutStarts)?.effect == .mood(.running))
    }

    @Test func aMomentBeatsAMoodAndTheMoodWaits() {
        let result = step([cue(.workoutStarts), cue(.newBest)])
        #expect(result.directive.play?.name == .best)
        #expect(result.directive.mood == nil)
        let after = MosaicSwitchboard.handedBack(result.state, quiet: false)
        #expect(after.directive.play == nil)
        let mood = step([cue(.workoutStarts, key: "w2")], from: after.state)
        #expect(mood.directive.mood == MosaicMoodChange(mood: .running, changeover: .wave))
    }

    @Test func tessThenAppsThenClockThenWeather() {
        let result = step([cue(.beforeSunset), cue(.workoutStarts), cue(.suggestionReady)], weather: true)
        #expect(result.directive.play?.name == .tess)
        let moods = step([cue(.beforeSunset), cue(.workoutStarts), cue(.rain)], weather: true)
        #expect(moods.directive.mood?.mood == .running)
        let clock = step([cue(.beforeSunset), cue(.rain)], weather: true)
        #expect(clock.directive.mood?.mood == .golden)
    }

    @Test func aMomentNeverCutsIntoAnotherAndTheQueueHoldsThree() {
        var result = step([cue(.newBest, key: "a")])
        #expect(result.directive.play?.key == "a")
        result = step([cue(.timerEnds, 1, key: "b"), cue(.arrived, 2, key: "c"), cue(.checkedOff, 3, key: "d"),
                       cue(.announcement, 4, key: "e")], from: result.state)
        #expect(result.directive.play == nil)
        #expect(result.state.queue.count == 3)
        #expect(!result.state.queue.contains { $0.key == "b" })
        let next = MosaicSwitchboard.handedBack(result.state, quiet: false)
        #expect(next.directive.play?.key == "e")
    }

    @Test func anEventNeverPlaysTwice() {
        let first = step([cue(.timerEnds, key: "t1")])
        let done = MosaicSwitchboard.handedBack(first.state, quiet: false)
        #expect(step([cue(.timerEnds, key: "t1")], from: done.state).directive.play == nil)
    }

    @Test func inQuietHoursOnlyATimerAndAReminderPlayAndTheQueueClears() {
        let playing = step([cue(.newBest, key: "a"), cue(.arrived, key: "b")])
        #expect(playing.state.queue.count == 1)
        let night = step([cue(.reminderDue, key: "r"), cue(.checkedOff, key: "f"),
                          cue(.workoutStarts, key: "w")], from: playing.state, quiet: true)
        #expect(night.state.queue.map(\.key) == ["r"])
        #expect(night.directive.mood == nil)
        let handed = MosaicSwitchboard.handedBack(night.state, quiet: true)
        #expect(handed.directive.play?.name == .reminder)
    }

    @Test func weatherIsInertUntilWeatherKit() {
        #expect(step([cue(.snow), cue(.rain)]).directive == MosaicDirective())
        #expect(step([cue(.snow)], weather: true).directive.play?.name == .snow)
    }

    @Test func aCueThatNeedsClaudeWaitsForAsksClaude() {
        #expect(step([cue(.suggestionReady, claude: true)]).directive == MosaicDirective())
        #expect(step([cue(.suggestionReady, claude: true)], claude: true).directive.play?.name == .tess)
    }

    @Test func noCueNamesHealthCalendarBodyCaloriesOrMoney() {
        let banned = ["health", "calendar", "body", "calor", "money", "spend", "weight", "sleep", "steps", "event"]
        for kind in MosaicCueKind.allCases {
            let name = kind.rawValue.lowercased()
            #expect(!banned.contains { name.contains($0) }, "\(kind)")
        }
        #expect(MosaicCueSource.allCases.count == 5)
    }

    @Test func existingMomentKindsMapToCues() {
        #expect(MosaicSwitchboard.cue(for: .timer, at: now, key: "k")?.kind == .timerEnds)
        #expect(MosaicSwitchboard.cue(for: .weather(.storm), at: now, key: "k")?.kind == .storm)
    }
}
