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
        #expect(TrainingPage.planPhrase(lanes: [lane(3)]) == "1 exercise, about 10 min")
    }

    @MainActor @Test func theKickerTokenFollowsTheFontChoice() {
        let defaults = UserDefaults.standard
        let before = defaults.object(forKey: "review.font")
        defer { before == nil ? defaults.removeObject(forKey: "review.font") : defaults.set(before, forKey: "review.font") }

        defaults.set("As before", forKey: "review.font")
        let old = Theme.Typography.kickerSpec
        #expect(old.size == 14 && old.weight == .semibold && old.uppercase && old.tracking == 0.12)
        #expect(old.family == .ui, "the UI face, never the mono label face")

        // Design 116: Figtree 500 in sentence case, +0.02 em.
        defaults.set("Figtree and Outfit", forKey: "review.font")
        let new = Theme.Typography.kickerSpec
        #expect(new.size == 14 && new.weight == .medium && !new.uppercase && new.tracking == 0.02)
    }

    @Test func fractionsAreDrawnAsDigits() {
        #expect(Fractions.digits("1½") == "1\u{202F}1/2")
        #expect(Fractions.digits("½") == "1/2")
        #expect(Fractions.digits("2⅓ cups") == "2\u{202F}1/3 cups")
        #expect(Fractions.digits("6½") == "6\u{202F}1/2")
        #expect(Fractions.digits("12") == "12")
    }
}

struct KeepUnitsTests {
    @Test func aNumberAndItsUnitKeepTheirSpace() {
        #expect("about 40 min".keepingUnits == "about 40\u{00A0}min")
        #expect("serves 4, 39 min".keepingUnits == "serves 4, 39\u{00A0}min")
        #expect("1 h 35 min".keepingUnits == "1\u{00A0}h 35\u{00A0}min")
        #expect("Hold, 30 min left".keepingUnits == "Hold, 30\u{00A0}min left")
        #expect("5 exercises".keepingUnits == "5 exercises")
    }
}
