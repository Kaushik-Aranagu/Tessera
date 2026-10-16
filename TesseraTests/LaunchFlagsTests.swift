@testable import Tessera
import Testing

/// Every demo and test launch flag reads through LaunchFlags, which exists only on the simulator.
struct LaunchFlagsTests {
    @Test func flagsReadOnTheSimulator() {
        #expect(LaunchFlags.allowed) // unit tests run on the simulator
        #expect(LaunchFlags.has("-queueScript", in: ["app", "-queueScript"]))
        #expect(!LaunchFlags.has("-queueScript", in: ["app"]))
        #expect(LaunchFlags.value(after: "-demoTime", in: ["app", "-demoTime", "18:10"]) == "18:10")
        #expect(LaunchFlags.value(after: "-demoTime", in: ["app", "-demoTime"]) == nil)
    }
}
