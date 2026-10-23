import SwiftUI

/// Settings v2 (sheet 154): "‹ Home", the title, one sentence under it, section labels in sentence case, and each
/// row's value word in ink 2. Behind Settings › Review › "Settings v2" (default Off: Settings exactly as today).
/// Every row and gesture of the page stays (131 §2b); only the words and their ink change.
enum SettingsV2 {
    static let choiceID = "settingsV2"

    static let backWord = "‹ Home"
    static let backLabel = "Back to Home"
    static let sentence = "How Tessera works for you."
    static let title = "Settings"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    /// The value word's ink: ink 2 in v2, full ink as today.
    @MainActor static var valueInk: Color {
        isOn ? Theme.Colors.inkSecondary : Theme.Colors.ink
    }
}

/// A label word that keeps its case: label size and face through `.data`, ink 2 at rest, ink on press.
struct SettingsV2WordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.data)
            .fontWeight(.semibold)
            .foregroundStyle(configuration.isPressed ? Theme.Colors.ink : Theme.Colors.inkSecondary)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Today's label word, or v2's sentence-case one.
    @ViewBuilder
    func settingsWordStyle() -> some View {
        if SettingsV2.isOn {
            buttonStyle(SettingsV2WordStyle())
        } else {
            buttonStyle(.labelWord)
        }
    }
}

/// A small section label in v2: sentence case, ink 2, a header for VoiceOver.
struct SettingsV2Label: View {
    let text: String
    var body: some View {
        Text(text)
            .textRole(.data)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}
