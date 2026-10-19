import SwiftUI
@testable import Tessera
import Testing

/// Sheet 86, option C: an area's colour reads as ink with a lean, and a neutral page stays ink.
@MainActor
struct AreaColourTests {
    @Test func aNeutralPageDoesNotTintTheGround() {
        #expect(Theme.Colors.groundTint(.neutral) == .clear)
        #expect(Theme.Colors.groundTint(.kitchen) != .clear)
    }

    @Test func eachAreaLeansTowardItsOwnColour() {
        #expect(Theme.Colors.area(.training) == Theme.Colors.training)
        #expect(Theme.Colors.area(.kitchen) == Theme.Colors.health)
        #expect(Theme.Colors.area(.review) == Theme.Colors.context)
        #expect(Theme.Colors.areaLean(.kitchen) != Theme.Colors.areaLean(.training))
    }
}
