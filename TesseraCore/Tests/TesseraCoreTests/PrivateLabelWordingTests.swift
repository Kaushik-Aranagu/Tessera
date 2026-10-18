@testable import TesseraCore
@testable import TesseraTess
import Testing

/// QA on #895: a masked label is no title to send to Claude.
@MainActor
struct PrivateLabelWordingTests {
    @Test func planWordingDropsTheWorkoutAndListLabelsAsTitles() {
        #expect(PlanPack.isPrivate(ObjectPrivacy.routineLabel, lastWeightKg: nil))
        #expect(PlanPack.isPrivate(ObjectPrivacy.listLabel, lastWeightKg: nil))
        #expect(!PlanPack.isPrivate("Push Day A", lastWeightKg: nil))
    }
}
