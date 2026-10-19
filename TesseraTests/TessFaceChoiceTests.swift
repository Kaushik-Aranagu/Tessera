import Foundation
@testable import Tessera
import Testing

/// The "Tess has eyes" review switch (key review.tessFace): off by default, and an unknown stored value reads Off.
struct TessFaceChoiceTests {
    private func suite(_ name: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func tessHasNoEyesUntilTheSwitchSaysSo() throws {
        let defaults = try suite("TessFaceChoiceTests.default")
        #expect(!Choice.tessHasEyes(defaults: defaults))
        defaults.set("Eyes", forKey: "review.tessFace")
        #expect(Choice.tessHasEyes(defaults: defaults))
        defaults.set("Eyes and mouth", forKey: "review.tessFace")
        #expect(Choice.tessHasEyes(defaults: defaults))
        defaults.set("Off", forKey: "review.tessFace")
        #expect(!Choice.tessHasEyes(defaults: defaults))
        defaults.removePersistentDomain(forName: "TessFaceChoiceTests.default")
    }

    @Test func anUnknownValueReadsOff() throws {
        let defaults = try suite("TessFaceChoiceTests.unknown")
        defaults.set("Googly", forKey: "review.tessFace")
        #expect(!Choice.tessHasEyes(defaults: defaults))
        defaults.removePersistentDomain(forName: "TessFaceChoiceTests.unknown")
    }
}
