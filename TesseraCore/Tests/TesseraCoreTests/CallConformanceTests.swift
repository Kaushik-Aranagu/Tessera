import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Sheet 288, section 6: Tess's calls inherit one template and pass one suite. Every call on every place in every room
/// is real, agrees with its tool on money, takes only its tool's arguments, binds from the frame when he needn't say
/// anything, and a device-only call never reaches Claude. Every Tess tool sits on some place, so none escapes.
@MainActor
struct CallConformanceTests {
    static let rooms = ["bridge", "log", "lookout", "deck", "galley", "watch", "purse"]

    @Test func everyCallOnEveryPlacePassesTheSuite() {
        var checked = 0
        for room in Self.rooms {
            for place in ElementPlace.allCases {
                for call in ElementCatalog.calls(room: room, place: place) {
                    let failed = CallConformance.failures(call, room: room, place: place)
                    #expect(failed.isEmpty, "\(room) \(place.rawValue) \(call.name): \(failed)")
                    checked += 1
                }
            }
        }
        #expect(checked > 50)
    }

    @Test func everyTessToolIsRegisteredOnAPlace() {
        #expect(CallConformance.unregistered.isEmpty, "\(CallConformance.unregistered)")
    }

    @Test func theSuiteCatchesACallThatBreaksARule() {
        // A money tool offered as an any-rung call, with an argument the tool doesn't take.
        let leak = ElementCall("logSpend", phrases: ["spent"], inputs: [CallInput("amount", from: .asked),
                                                                         CallInput("payee", from: .asked)],
                               reaction: .keystoneTakes)
        let failed = CallConformance.failures(leak, room: "purse", place: .actionWord)
        #expect(failed.contains("reach") && failed.contains("inputs"))
        // A name that is no tool, no proposed tool and not the shell.
        let made = ElementCall("madeUp", phrases: ["zap"], reaction: .tessLine)
        #expect(CallConformance.failures(made, room: "deck", place: .widget) == ["real"])
    }
}
