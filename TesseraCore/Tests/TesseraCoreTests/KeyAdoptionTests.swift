import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G687: a reinstalled phone must not read "Tess asks Claude" as yes while an old key sits in the Keychain.
struct KeyAdoptionTests {
    func adoption() throws -> KeyAdoption {
        try KeyAdoption(defaults: #require(UserDefaults(suiteName: "adoption-\(UUID().uuidString)")))
    }

    @Test func aFreshInstallHasNotAnsweredAndNothingIsAdopted() throws {
        let adoption = try adoption()
        #expect(adoption.state == .notAsked)
        #expect(KeyAdoption.question == "Use the Claude key still on this phone?")
    }

    @Test func hisAnswerIsKeptOnTheDevice() throws {
        let adoption = try adoption()
        adoption.answer(useIt: false)
        #expect(adoption.state == .declined)
        adoption.answer(useIt: true)
        #expect(adoption.state == .accepted)
    }
}
