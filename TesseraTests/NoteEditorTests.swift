@testable import Tessera
import Testing

/// QA N1: opening a note and leaving it must not rewrite it. The editor compares against the note as opened
/// (split then joined), so that round trip has to be stable.
struct NoteEditorTests {
    @Test(arguments: ["Garage gym\n\nRubber floor, a second bench.", "Trailing space \nRest", "One line", ""])
    func openingAndLeavingChangesNothing(body: String) {
        let opened = NotesEditorCopy.split(body)
        let asOpened = NotesEditorCopy.join(heading: opened.heading, rest: opened.rest)
        let reopened = NotesEditorCopy.split(asOpened)
        #expect(NotesEditorCopy.join(heading: reopened.heading, rest: reopened.rest) == asOpened)
    }
}

/// QA N1 (second pass): the blank line after the heading survives a split and join.
struct NoteJoinTests {
    @Test func splitAndJoinAreExactInverses() {
        for body in ["Garage gym\n\nRubber floor, a second bench.", "One line", "Title\nRest\n\nMore"] {
            let parts = NotesEditorCopy.split(body)
            #expect(NotesEditorCopy.join(heading: parts.heading, rest: parts.rest) == body)
        }
    }
}
