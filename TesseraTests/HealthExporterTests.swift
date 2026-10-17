@testable import Tessera
import TesseraCore
import Testing

struct HealthExporterTests {
    @Test func finishingEarlyReachesHealthLikeANormalFinish() {
        #expect(HealthExporter.exports("finishWorkout"))
        #expect(HealthExporter.exports("finishWorkoutEarly"))
        #expect(HealthExporter.exports(FinishWorkoutEarly.descriptor.name))
    }

    @Test func otherActionsAreNotExported() {
        #expect(!HealthExporter.exports(StartWorkout.descriptor.name))
        #expect(!HealthExporter.exports("logSet"))
    }
}
