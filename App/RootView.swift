import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            TodayView()
        }
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    RootView()
        .modelContainer(TesseraSchema.makeContainer(inMemory: true))
}
