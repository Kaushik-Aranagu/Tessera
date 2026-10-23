import SwiftUI
import TesseraCore

/// Settings > Privacy (179, walledPageV2): what stays on this phone, as live sentences from Core's `PrivacyPage`.
/// Counts, never names. Nothing on the page can turn a wall off: it has no switch and no key, only a way back.
struct PrivacyWordsPage: View {
    @Environment(AppModel.self) private var shown
    @Environment(\.realModel) private var realModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    /// His own store even while Sample data is on: the page tells the truth about his things.
    private var model: AppModel {
        realModel ?? shown
    }

    var body: some View {
        let _ = model.revision
        let sentences = PrivacyPage.lines(
            engine: model.engine,
            claudeOn: model.asksClaude,
            backupLine: BackupKeeper.lastLine(copies: BackupKeeper.localCopies(), now: AppClock.now)
        )
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Settings")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Settings")
                }
                Text("kept on this phone")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text("Privacy")
                    .textRole(.hero)
                    .wordFit("Privacy")
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)
                ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                    Text(sentence)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, index == 0 ? Theme.Spacing.xl : Theme.Spacing.l)
                        .entrance(min(index + 2, 5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
