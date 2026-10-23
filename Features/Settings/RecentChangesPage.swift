import SwiftUI
import TesseraCore

/// Settings > Review > Recent changes (164, undoLogV2): the last 20 changes as sentences with their times, each with
/// the same Undo word as the page foot. Private and money changes read Core's generic words, never a name or amount.
struct RecentChangesPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var putBacks = 0
    @State private var refusals = 0

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let entries = UndoLog.recent(engine: model.engine, now: now, limit: 20)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Review")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Review")
                }
                Text("what changed")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text(UndoWords.recentTitle)
                    .textRole(.hero)
                    .wordFit(UndoWords.recentTitle)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)
                if entries.isEmpty {
                    Text(UndoWords.empty)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    ForEach(entries) { entry in
                        row(entry, now: now)
                            .padding(.top, Theme.Spacing.l)
                    }
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
        .tesseraFeedback(.undo, trigger: putBacks)
        .tesseraFeedback(.notNow, trigger: refusals)
    }

    private func row(_ entry: UndoEntry, now: Date) -> some View {
        // The time sits above its sentence; at accessibility sizes the Undo word goes under, never beside.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        return layout {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(UndoWords.when(entry, now: now))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                Text(entry.sentence)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(UndoWords.undo) {
                switch UndoRun.perform(entry, model: model) {
                case .putBack: putBacks += 1
                case .blocked: refusals += 1
                case .gone: break
                }
            }
            .buttonStyle(InkLabelWordStyle.undo)
            .accessibilityHint(entry.isMoney ? "Reverses that change" : "Puts that change back")
        }
        .accessibilityElement(children: .contain)
    }
}
