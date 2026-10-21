import Foundation
@testable import Tessera
import Testing

/// Design item 115: the kicker row's words (the layout is checked on screen).
struct KickerRowTests {
    @Test func thePlanPhraseKeepsAboutAndPluralises() {
        let lane = { (sets: Int) in
            TrainingLane(id: UUID(), exercise: nil, name: "x", target: "", sets: sets, logged: 0)
        }
        #expect(TrainingPage.planPhrase(lanes: [lane(4), lane(3), lane(3), lane(3), lane(3)])
            == "5 exercises, about 40 min")
        #expect(TrainingPage.planPhrase(lanes: [lane(3)]) == "1 exercise, about 5 min")
    }

    @MainActor @Test func theKickerTokenIsSmallSemiboldUppercaseWithWideTracking() {
        let spec = Theme.Typography.kickerSpec
        #expect(spec.size == 14 && spec.weight == .semibold && spec.uppercase && spec.tracking == 0.12)
        #expect(spec.family == .ui, "the UI face, never the mono label face")
    }
}
