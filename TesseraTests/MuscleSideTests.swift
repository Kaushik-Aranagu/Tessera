import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Design brief 1 (sheet 107): which side of the body an exercise shows, the routine colours and the day's union.
@MainActor
struct MuscleSideTests {
    private func primaries(_ key: String) throws -> [(name: String, role: MuscleRole)] {
        let seed = try #require(ExerciseLibrary.seeds.first { $0.key == key })
        return seed.primary.map { (name: $0.name, role: MuscleRole.primary) }
    }

    @Test func theSideRuleFollowsDesignsTable() throws {
        // Front: more primaries on the front, or a tie.
        for key in ["benchPress", "inclineBenchPress", "dip", "dbLateralRaise", "barbellCurl", "backSquat",
                    "legPress"]
        {
            #expect(try !MuscleSide.showsBack(primaries(key)), "\(key) is a front figure")
        }
        // Back: more primaries on the back.
        for key in ["barbellRow", "latPulldown", "seatedCableRow", "facePull", "pullUp", "deadlift",
                    "romanianDeadlift", "lyingLegCurl"]
        {
            #expect(try MuscleSide.showsBack(primaries(key)), "\(key) is a back figure")
        }
    }

    /// Design's table lists pushdown as a front figure, but Triceps has a region only on the back, so the rule as
    /// written gives the back. Held here as the rule's answer until Design says which one moves.
    @Test func pushdownFollowsTheRuleNotTheTable() throws {
        #expect(try MuscleSide.showsBack(primaries("ropePushdown")))
    }

    @Test func calvesAndForearmsAreNotCountedOnTheBack() {
        #expect(!MuscleSide.showsBack([(name: "Calves", role: .primary)]))
        #expect(!MuscleSide.showsBack([(name: "Forearms", role: .primary), (name: "Biceps", role: .primary)]))
        // Secondary muscles never decide the side.
        #expect(!MuscleSide.showsBack([(name: "Chest", role: .primary), (name: "Lats", role: .secondary)]))
        #expect(!MuscleSide.showsBack([]))
    }

    /// `Color ==` is unreliable for resolved colours; compare what is drawn.
    private func rgb(_ color: Color) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue].map { Int(($0 * 255).rounded()) }
    }

    @Test func routinesWearTheirColourAndMixedOnesTheTrainingColour() {
        #expect(rgb(MuscleTint.colour(routineTitle: "Push A")) == rgb(Theme.Colors.live))
        #expect(rgb(MuscleTint.colour(routineTitle: "Pull B")) == rgb(Theme.Colors.tess))
        #expect(rgb(MuscleTint.colour(routineTitle: "Legs A")) == rgb(Theme.Colors.now))
        #expect(rgb(MuscleTint.colour(routineTitle: "Push Pull Legs")) == rgb(Theme.Colors.training))
        #expect(rgb(MuscleTint.colour(routineTitle: "Upper body")) == rgb(Theme.Colors.training))
        #expect(rgb(MuscleTint.colour(routineTitle: nil)) == rgb(Theme.Colors.training))
        // The three routine colours are three different colours.
        #expect(Set([rgb(Theme.Colors.live), rgb(Theme.Colors.tess), rgb(Theme.Colors.now)]).count == 3)
    }

    @Test func theDaysUnionIsPrimaryWhereverItIsPrimary() {
        let day = MuscleReading.union([
            [(name: "Chest", role: .primary), (name: "Triceps", role: .secondary)],
            [(name: "Triceps", role: .primary), (name: "Front Delts", role: .secondary)],
        ])
        #expect(day.first { $0.name == "Triceps" }?.role == .primary)
        #expect(day.first { $0.name == "Chest" }?.role == .primary)
        #expect(day.first { $0.name == "Front Delts" }?.role == .secondary)
        #expect(day.count == 3)
    }

    @Test func pushADaySaysWhatItWorks() throws {
        // Push A's five exercises, read from the seeded library.
        let keys = ["benchPress", "overheadPress", "inclineDbPress", "dbLateralRaise", "ropePushdown"]
        let day = try MuscleReading.union(keys.map(primaries))
        let words = MuscleWords.works(day.filter { $0.role == .primary }.map(\.name))
        #expect(words == "Works chest, shoulders and triceps")
    }

    @Test func theSpokenWordsNameThePrimaryMusclesOnly() {
        let muscles: MuscleReading.Muscles = [(name: "Chest", role: .primary), (name: "Triceps", role: .secondary)]
        #expect(MuscleReading.spoken(muscles) == "works chest")
        #expect(MuscleReading.spoken([]).isEmpty)
    }
}
