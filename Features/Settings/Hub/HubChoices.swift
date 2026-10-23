import Foundation
import TesseraCore

/// The bridge between Core's feature flags and choices (sheet 203) and the app's `ReviewChoices`: the pure pieces the
/// Settings hub and Developer mode use, so they test without a screen. Ids stay the same as before.
@MainActor
enum HubChoices {
    /// One Settings change that can be taken back: the switch and the value it had.
    struct Undo {
        let id: String
        let value: String
    }

    /// What the phone amounts to now, as Core's `FeatureState`: the flags that are Off and the multi-value switches
    /// the choices name.
    static func state(_ choices: ReviewChoices = .shared) -> FeatureState {
        var state = FeatureState()
        for flag in FeatureFlags.all {
            guard let choice = ReviewChoices.all.first(where: { $0.id == flag.id }) else { continue }
            if choices.value(of: choice) == "Off" {
                state.off.insert(flag.id)
            }
        }
        for choice in FeatureChoices.all {
            for option in choice.options {
                for id in option.values.keys {
                    if let row = ReviewChoices.all.first(where: { $0.id == id }) {
                        state.values[id] = choices.value(of: row)
                    }
                }
            }
        }
        return state
    }

    /// Choosing one option of a conflict: sets what it names (the other turns off), returning what to put back.
    @discardableResult
    static func choose(_ optionID: String, in choiceID: String, choices: ReviewChoices = .shared) -> [Undo] {
        let before = state(choices)
        let after = FeatureChoices.choosing(optionID, in: choiceID, state: before)
        var undo: [Undo] = []
        for flag in FeatureFlags.all {
            let was = !before.off.contains(flag.id), now = !after.off.contains(flag.id)
            guard was != now, let row = ReviewChoices.all.first(where: { $0.id == flag.id }) else { continue }
            undo.append(Undo(id: flag.id, value: was ? "On" : "Off"))
            choices.set(row, to: now ? "On" : "Off")
        }
        for (id, value) in after.values where before.values[id] != value {
            guard let row = ReviewChoices.all.first(where: { $0.id == id }) else { continue }
            undo.append(Undo(id: id, value: before.values[id] ?? row.defaultValue))
            choices.set(row, to: value)
        }
        return undo
    }

    /// Puts changes back, last first.
    static func restore(_ undo: [Undo], choices: ReviewChoices = .shared) {
        for item in undo.reversed() {
            if let row = ReviewChoices.all.first(where: { $0.id == item.id }) {
                choices.set(row, to: item.value)
            }
        }
    }

    /// The option that reads now for a conflict (Core's rule).
    static func selected(_ choiceID: String, choices: ReviewChoices = .shared) -> FeatureChoice.Option? {
        FeatureChoices.selected(choiceID, in: state(choices))
    }

    /// The flag ids the main page already carries, so Developer mode lists only the rest.
    static let onMainPage: Set<String> = [
        "homeAppsList", "homeV2", "homeMosaic", "homeMosaicMoods", "homeMosaicMoments", "trainingAutoName",
        "restTimer", "finishNudge", "cookTimerVoice", "handsFreeCook", "walledPageV2", "backupsV2", "undoLogV2",
    ]
}
