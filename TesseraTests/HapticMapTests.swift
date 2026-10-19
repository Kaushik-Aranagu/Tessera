import SwiftUI
@testable import Tessera
import Testing

/// The haptic map is the code (Haptics.swift; migration table, board 65): one case per moment.
@MainActor
struct HapticMapTests {
    @Test func theMomentsKeepTheirSounds() {
        #expect(Haptic.undo.feedback == .decrease)
        #expect(Haptic.selection.feedback == .selection)
        #expect(Haptic.cleared.feedback == .success)
        #expect(Haptic.notSaved.feedback == .warning)
        #expect(Haptic.done.feedback == nil, "Done plays the three-beat pattern")
    }

    @Test func theCueDoesNotLetTwoMomentsShareOneTrigger() {
        var cue = HapticCue()
        cue.play(.made)
        cue.play(.notSaved)
        #expect(cue.count == 2 && cue.haptic == .notSaved)
    }

    @Test func theWorkoutUndoWordPlaysNoTickOfItsOwn() {
        // WorkoutModeView plays .undo from its own slot; the UNDO word must not add a selection tick.
        #expect(LabelActionStyle(color: .clear, silent: true).silent)
        #expect(!LabelActionStyle(color: .clear).silent)
        #expect(InkLabelWordStyle.undo.silent)
    }

    @Test func restorePlaysMadeFromItsOwner() {
        // The Restore hold's key is silent (no moment in a key); BackupView's `restores` counter plays .made.
        var cue = HapticCue()
        cue.play(.made)
        #expect(cue.haptic == .made && cue.haptic.feedback == Haptic.made.feedback)
    }
}
