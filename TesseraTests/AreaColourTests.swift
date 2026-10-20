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
        /// Colours compare by their resolved components (a dynamic Color is not reliably Equatable).
        func rgb(_ color: Color) -> [Float] {
            let resolved = color.resolve(in: EnvironmentValues())
            return [resolved.red, resolved.green, resolved.blue]
        }
        #expect(rgb(Theme.Colors.area(.training)) == rgb(Theme.Colors.training))
        #expect(rgb(Theme.Colors.area(.kitchen)) == rgb(Theme.Colors.health))
        #expect(rgb(Theme.Colors.area(.review)) == rgb(Theme.Colors.context))
        #expect(rgb(Theme.Colors.areaLean(.kitchen)) != rgb(Theme.Colors.areaLean(.training)))
    }
}
