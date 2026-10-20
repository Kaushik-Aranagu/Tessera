import SwiftUI

/// About, at the foot of Settings: one plain line per source (Product's ruling). No credits on exercise pages.
struct AboutPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    var body: some View {
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
                Text("About")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                Text(ExerciseCredits.line)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.xxl)
                HStack(spacing: Theme.Spacing.l) {
                    Link("Workout Guide", destination: ExerciseCredits.sourceURL)
                    Link("Everkinetic", destination: ExerciseCredits.upstreamURL)
                    Link("CC BY-SA 4.0", destination: ExerciseCredits.licenseURL)
                }
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.top, Theme.Spacing.m)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, 200)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
