import SwiftUI

/// A structural rule (under headers). Row separators use `RowSeparator`, which follows the concept.
struct Hairline: View {
    var color: Color = Theme.Colors.hairline
    var body: some View {
        Rectangle().fill(color).frame(height: Theme.Stroke.hairline)
    }
}

/// Mono caps label ("NOW", "17:45 – 18:40") at the label size.
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.Colors.inkSecondary
    var body: some View {
        Text(Choice.fontIsNew() ? text : text.uppercased())
            .textRole(.label)
            .tracking(Choice.fontIsNew() ? 0 : 1.2)
            .foregroundStyle(color)
    }
}

/// The soft Close word: ink secondary at rest, full ink on press with a short ease (the press response `.plain` loses).
struct CloseWordStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 1 : 0.8)
            .foregroundStyle(configuration.isPressed ? Theme.Colors.ink : Theme.Colors.inkSecondary)
            .tesseraAnimation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
