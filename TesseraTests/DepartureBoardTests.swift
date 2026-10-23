@testable import Tessera
import Testing

struct DepartureBoardTests {
    @Test func aSameLetterDoesNotMove() {
        #expect(DepartureSteps.sequence(from: "a", to: "a").isEmpty)
    }

    @Test func aStepRunsForwardAlongTheStripAndEndsOnTheNewLetter() {
        let steps = DepartureSteps.sequence(from: " ", to: "c")
        #expect(steps == ["a", "b", "c"])
    }

    @Test func noMoreThanNineStepsAndTheLastIsTheTarget() {
        for target in DepartureSteps.strip {
            for start in DepartureSteps.strip {
                let steps = DepartureSteps.sequence(from: start, to: target)
                #expect(steps.count <= DepartureSteps.maxSteps)
                if start != target {
                    #expect(steps.last == target)
                }
            }
        }
    }

    @Test func aLetterOffTheStripLandsAtOnce() {
        #expect(DepartureSteps.sequence(from: "a", to: "é") == ["é"])
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
