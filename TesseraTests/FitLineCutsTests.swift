import Foundation
@testable import Tessera
import Testing

/// Whole-word cuts (contract §7, AX5 QA): a shorter form never ends on a lone number, never separates a time from its
/// am or pm or a number from its unit, and never stops on a word that says nothing ("opens", "around", "this").
@MainActor
struct FitLineCutsTests {
    private static let samples = [
        "About 40 min, 5 lifts",
        "Starts around 6:10 pm",
        "Bench Press opens at 82.5 kg",
        "No rain for the next 12 hours",
        "Last one this week",
        "Cook at 6:45 pm tonight",
        "Rest today. Next is Saturday",
        "3 to go this week",
        "+10 lb on bench since Oct 1",
        "Across the lake and back",
    ]

    @Test func numberKeepsItsUnit() {
        #expect(FitLine.cuts("About 40 min, 5 lifts") == ["About 40 min, 5 lifts", "About 40 min"])
    }

    @Test func timeKeepsItsAmOrPm() {
        let forms = FitLine.cuts("Starts around 6:10 pm")
        #expect(!forms.contains("Starts around 6:10"))
        #expect(!forms.contains("Starts around"))
        #expect(forms.first == "Starts around 6:10 pm")
    }

    @Test func weakTrailingWordsAreDropped() {
        #expect(FitLine.cuts("Bench Press opens at 82.5 kg").dropFirst().first == "Bench Press")
        #expect(FitLine.cuts("Last one this week").contains("Last one"))
        #expect(!FitLine.cuts("Last one this week").contains("Last one this"))
    }

    @Test func numberIsCutWithItsNoun() {
        let forms = FitLine.cuts("No rain for the next 12 hours")
        #expect(forms.contains("No rain"))
        #expect(!forms.contains { $0.hasSuffix("12") || $0.hasSuffix("next") })
    }

    @Test func aLoneNumberIsNeverAForm() {
        #expect(FitLine.cuts("3 to go this week").allSatisfy { $0 != "3" })
    }

    @Test func noFormEndsOnALoneNumberOrABareTime() {
        for text in Self.samples {
            for form in FitLine.cuts(text).dropFirst() {
                let last = form.split(separator: " ").last.map(String.init) ?? ""
                #expect(!FitLine.isNumber(last), "\(form) ends on a number")
                #expect(!form.contains("...") && !form.contains("…"))
                if form.range(of: #"\d:\d\d"#, options: .regularExpression) != nil {
                    #expect(form.contains(" am") || form.contains(" pm"), "\(form) lost its am or pm")
                }
            }
        }
    }

    @Test func tokensGroupNumbersButNotBeforeSmallWords() {
        #expect(FitLine.tokens("About 40 min, 5 lifts") == ["About", "40 min,", "5 lifts"])
        #expect(FitLine.tokens("3 to go") == ["3", "to", "go"])
        #expect(FitLine.tokens("Opens at 82.5 kg") == ["Opens", "at", "82.5 kg"])
    }

    @Test func singleWordsStayWhole() {
        #expect(FitLine.cuts("Today") == ["Today"])
        #expect(FitLine.cuts("cook at 6:45 pm").first == "Cook at 6:45 pm")
    }
}
