import Foundation
@testable import Tessera
import Testing

/// G38: a masked export says so, and restoring one warns first.
@MainActor
struct ExportFileTests {
    private func file(_ json: String) -> Data {
        Data(json.utf8)
    }

    @Test func aMaskedFileWarnsBeforeRestore() {
        let masked = file(#"{"format":"tessera-export","version":1,"masked":true}"#)
        #expect(ExportFile.isMasked(masked))
        #expect(ExportFile.restoreStep(for: masked) == .warn(ExportFile.restoreWarning))
    }

    @Test func anUnmaskedOrOlderFileRestoresStraightOn() {
        #expect(ExportFile.restoreStep(for: file(#"{"format":"tessera-export","masked":false}"#)) == .restore)
        #expect(ExportFile.restoreStep(for: file(#"{"format":"tessera-export","version":1}"#)) == .restore)
        #expect(!ExportFile.isMasked(file("not json")))
    }

    @Test func theRowStaysHiddenUntilCoresFlagIsWired() {
        #expect(!ExportFile.ready)
    }
}
