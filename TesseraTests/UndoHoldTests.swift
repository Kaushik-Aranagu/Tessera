@testable import Tessera
import Testing

/// UndoSlot ruling: UNDO is a flat 10 s under VoiceOver; otherwise a line keeps its own time.
@MainActor
struct UndoHoldTests {
    @Test func voiceOverStretchesAnyUndoToTen() {
        #expect(TessVoice.hold(undo: true, holds: .seconds(4), voiceOver: true) == .seconds(10))
        #expect(TessVoice.hold(undo: true, voiceOver: true) == .seconds(10))
    }

    @Test func withoutVoiceOverALineKeepsItsTime() {
        #expect(TessVoice.hold(undo: true, holds: .seconds(4), voiceOver: false) == .seconds(4))
        #expect(TessVoice.hold(undo: true, voiceOver: false) == .seconds(10))
        #expect(TessVoice.hold(undo: false, voiceOver: false) == .seconds(4))
    }

    @Test func aPlainLineIsNeverStretched() {
        #expect(TessVoice.hold(undo: false, voiceOver: true) == .seconds(4))
        #expect(TessVoice.hold(undo: false, holds: .seconds(6), voiceOver: true) == .seconds(6))
    }
}
