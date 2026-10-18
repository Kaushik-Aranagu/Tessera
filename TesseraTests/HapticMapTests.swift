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
}
