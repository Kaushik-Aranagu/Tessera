import SwiftUI

/// "Sample data", plain words at a page's top while the switch is on (Design on #1199): ink-secondary, sentence case,
/// no pill and no colour. A tap opens the switch in Settings › Review › Shown.
struct SampleDataWord: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var openLink

    var body: some View {
        if model.isSample {
            Button {
                SampleData.shared.jumpsToSwitch = true
                openLink(.review)
            } label: {
                Text("Sample data")
                    // Label size with its case kept: sentence case, never caps (Design on #1199).
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44, alignment: .bottomLeading)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityHint("Opens the Sample data switch")
        }
    }
}
