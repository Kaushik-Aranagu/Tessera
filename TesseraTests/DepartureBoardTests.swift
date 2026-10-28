@testable import Tessera
import Testing

struct DepartureBoardTests {
    @Test func aSameLetterDoesNotMove() {
        #expect(DepartureSteps.sequence(from: "a", to: "a").isEmpty)
    }

    /// A changed letter flips once, straight to the new letter: the board shows only the letters of the two words.
    @Test func aChangedLetterFlipsOnceStraightToTheNewLetter() {
        #expect(DepartureSteps.sequence(from: " ", to: "c") == ["c"])
        #expect(DepartureSteps.sequence(from: "d", to: "e") == ["e"])
        #expect(DepartureSteps.sequence(from: "a", to: "é") == ["é"])
        for old in "Tuesday, Oct 27" {
            for new in "Tue, Oct 27" where old != new {
                #expect(DepartureSteps.sequence(from: old, to: new) == [new])
            }
        }
    }

    @Test func theDelayIsLineTimesFivePlusIndexTimes14() {
        #expect(DepartureSteps.delay(line: 0, index: 0) == 0)
        #expect(DepartureSteps.delay(line: 2, index: 3) == 182)
    }

    @Test func runsAreSeparatedByASpaceCell() {
        let line = [DepartureSegment(text: "Training", kind: .app(.training)),
                    DepartureSegment(text: "is", kind: .plain),
                    DepartureSegment(text: "3", kind: .number)]
        #expect(String(DepartureSteps.flat(line)) == "Training is 3")
        #expect(DepartureSteps.starts(line) == [0, 9, 12, 14])
    }
}
