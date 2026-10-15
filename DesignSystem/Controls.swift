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
        Text(text.uppercased())
            .textRole(.label)
            .tracking(1.2)
            .foregroundStyle(color)
    }
}
