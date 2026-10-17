@testable import Tessera
import Testing

/// QA carry on K88: the list engine's flag lines never print on an object page; his own words do, as written.
struct ObjectNotesTests {
    @Test func flagLinesAreHidden() {
        #expect(ObjectNotes.shown("#reusable") == nil)
        #expect(ObjectNotes.shown("#pick-one\npicked: 2026-10-17T18:00:00Z") == nil)
        #expect(ObjectNotes.shown("For the Lisbon trip\n#reusable") == "For the Lisbon trip")
        #expect(ObjectNotes.shown("Bring the blue one\n\nand socks") == "Bring the blue one\n\nand socks")
        #expect(ObjectNotes.shown(nil) == nil)
    }

    @Test func hisOwnHashWordsStay() {
        #expect(ObjectNotes.shown("#tbt photo") == "#tbt photo")
    }

    @Test func onlyTheExactPickedStampIsHidden() {
        #expect(ObjectNotes.shown("picked: 2026-10-17T18:00:00Z") == nil)
        #expect(ObjectNotes.shown("picked: the blue one") == "picked: the blue one")
    }
}
