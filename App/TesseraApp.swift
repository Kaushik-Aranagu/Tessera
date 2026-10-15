import SwiftData
import SwiftUI

@main
struct TesseraApp: App {
    private let container: ModelContainer

    init() {
        container = TesseraSchema.makeContainer()
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
