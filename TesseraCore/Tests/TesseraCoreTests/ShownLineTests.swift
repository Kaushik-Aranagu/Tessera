import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Kaushik, Oct 26: no full stop on a line he sees, unless it is part of a note or a document.
struct ShownLineTests {
    @Test func theClosingStopGoesAndASecondSentenceTakesItsOwnLine() {
        #expect(ShownLine.unstopped("Push A done.") == "Push A done")
        #expect(ShownLine.unstopped("Push A done. Bench best.") == "Push A done\nBench best")
        #expect(ShownLine.unstopped("Push A done. Bench best.", between: ", ") == "Push A done, Bench best")
        #expect(ShownLine.unstopped("  All quiet.  ") == "All quiet")
        // What isn't a full stop stays: a question, an ellipsis, a decimal, a stop inside a word.
        #expect(ShownLine.unstopped("Rest today?") == "Rest today?")
        #expect(ShownLine.unstopped("Thinking...") == "Thinking...")
        #expect(ShownLine.unstopped("2.5 km at 6.30 pace.") == "2.5 km at 6.30 pace")
        #expect(ShownLine.unstopped("Bring snacks, e.g. nuts.") == "Bring snacks, e.g. nuts")
        #expect(ShownLine.isUnstopped("Push A done") && !ShownLine.isUnstopped("Push A done."))
        // A stop after an abbreviation or a single letter is no sentence break (QA on #1451).
        #expect(ShownLine.unstopped("Dentist with Dr. Lin at 3.") == "Dentist with Dr. Lin at 3")
        #expect(ShownLine.unstopped("Flight to St. Louis. Pack tonight.") == "Flight to St. Louis\nPack tonight")
        #expect(ShownLine.unstopped("The U.S. Open is on.") == "The U.S. Open is on")
        #expect(ShownLine.unstopped("Mrs. Rao called. Mr. Rao too.") == "Mrs. Rao called\nMr. Rao too")
    }

    @MainActor
    @Test func tessFixedLinesAndAModelsWhyShowWithNoStop() {
        for line in [TessRun.tooManySteps, TessRun.cannotThink, TessRun.keyLine, TessRun.noAnswer,
                     DirectorPlaybook.neutralWhy]
        {
            #expect(ShownLine.isUnstopped(line) && !line.contains(". "), "\(line)")
        }
        // A model's closing stop is let through the line check and dropped before it shows.
        #expect(DirectorPlaybook.line("A calm ring suits the morning.") == "A calm ring suits the morning")
        for line in ["A calm ring suits the morning.", "A calm ring suits the morning"] {
            #expect(TessLineCheck.check(line, slot: .detail, numbers: [], names: [], rulesLine: nil, isDone: false,
                                        dayLabel: nil, hero: nil) == .pass)
        }
    }
}
