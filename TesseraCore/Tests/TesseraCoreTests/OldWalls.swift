@testable import TesseraCore
import Testing

/// Runs a suite with the walls Claude had before his Oct 27 call (`ClaudeSees.everything` off), so the old wall code
/// is still held to its own tests. `ClaudeSeesTests` holds what goes now.
struct OldWalls: SuiteTrait, TestTrait, TestScoping {
    func provideScope(for _: Test, testCase _: Test.Case?,
                      performing function: @Sendable () async throws -> Void) async throws
    {
        try await ClaudeSees.$everything.withValue(false) {
            try await function()
        }
    }
}

extension Trait where Self == OldWalls {
    static var oldWalls: Self {
        OldWalls()
    }
}
