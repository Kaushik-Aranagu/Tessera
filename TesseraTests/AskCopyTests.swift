@testable import Tessera
import Testing

/// The Ask keeps his words only when the engine says so (Core's `TessCapture.keepsWords`): Claude unreachable, a
/// walled phrase offline, a bad key. The view never matches Tess's words.
struct AskCopyTests {
    @Test func theEnginesFlagDecides() {
        #expect(AskCopy.keepsDraft(true))
        #expect(!AskCopy.keepsDraft(false))
    }
}
