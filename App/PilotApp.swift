import SwiftData
import SwiftUI

@main
struct PilotApp: App {
    private let container: ModelContainer

    init() {
        container = PilotSchema.makeContainer()
        do {
            try SystemCatalog.seed(in: container.mainContext)
        } catch {
            assertionFailure("Seeding system classes failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
