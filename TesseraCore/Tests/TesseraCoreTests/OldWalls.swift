@testable import TesseraCore
import Testing

/// Runs a suite with the walls Claude had before his Oct 27 calls (`ClaudeSees.everything` and `moneyWrites` off), so
/// the old wall code is still held to its own tests. `ClaudeSeesTests` and `ClaudeMoneyWritesTests` hold what goes now.
struct OldWalls: SuiteTrait, TestTrait, TestScoping {
    func provideScope(for _: Test, testCase _: Test.Case?,
                      performing function: @Sendable () async throws -> Void) async throws
    {
        try await ClaudeSees.$everything.withValue(false) {
            try await ClaudeSees.$moneyWrites.withValue(false) {
                try await function()
            }
        }
    }
}

extension Trait where Self == OldWalls {
    static var oldWalls: Self {
        OldWalls()
    }
}
