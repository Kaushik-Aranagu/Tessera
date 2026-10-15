import SwiftData
import SwiftUI

@main
struct PilotApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PilotSchema.makeContainer())
    }
}
