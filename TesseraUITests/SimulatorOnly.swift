import XCTest

/// UI tests drive the real app with demo flags; on his phone they would tap through his real data. They run on the
/// simulator only (docs/research/debug-paths.md).
class SimulatorOnlyTestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        #if !targetEnvironment(simulator)
            throw XCTSkip("UI tests run on the simulator only, never on a phone with real data.")
        #endif
    }
}
