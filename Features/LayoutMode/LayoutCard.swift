import SwiftUI

/// The raised-glass card a tapped pane opens: its frame, what it holds in this room, how it is touched, and what it
/// does on
/// the next room and on the next level (Design 283 v8).
struct LayoutCard: View {
    let place: LayoutPlace
    let room: LayoutRoom
    let level: LayoutLevel
    let tint: Color
    let look: LayoutGlassLook

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
    }

    private var isEmpty: Bool {
        level == .landing && room.emptyPlaces.contains(place.name)
    }

    private var rows: [(String, String)] {
        var list: [(String, String)] = [
            ("Holds", room.holds(place.name, level)),
            ("Touch", (level == .door ? LayoutCopy.touch[place.name] : nil) ?? LayoutCopy.touch[place.name] ?? "None"),
            ("Next room", LayoutCopy.nextRoom[place.name] ?? "Stays"),
        ]
        if room != .bridge {
            let table = level == .door ? LayoutCopy.backUp : LayoutCopy.toDoor
            list.append((level == .door ? "Back up" : "Door page", table[place.name] ?? "Stays"))
        }
        return list
    }

    private var tryLine: String? {
        if place.name == "Dial",
           level == .landing
        {
            return "Tap again to open \(room == .bridge ? "a room" : "a door")"
        }
        if place.name == "Nav word" {
            return "Tap again to go \(level == .door ? "up" : "back")"
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(place.name)
                .font(Theme.Typography.face(Theme.activeFonts.ui, size: 19, relativeTo: .title3, serif: false)
                    .weight(.bold))
                .foregroundStyle(tint)
                .accessibilityAddTraits(.isHeader)
            Text(LayoutCopy.frame(place) + (isEmpty ? ", empty" : ""))
                .font(LayoutFont.number(11.5))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.bottom, 3)
            ForEach(rows, id: \.0) { row in
                (Text(row.0 + "  ").font(LayoutFont.label(13.5, relativeTo: .footnote))
                    .foregroundStyle(Theme.Colors.ink)
                    + Text(row.1).font(LayoutFont.body()).foregroundStyle(Theme.Colors.inkSecondary))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
            }
            if let tryLine {
                Text(tryLine)
                    .font(LayoutFont.label(13.5, relativeTo: .footnote))
                    .foregroundStyle(tint)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background { glass }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("layout.card")
    }

    /// 26 pt radius, a 10 pt blur under a 78% page, then the raised glass of the panes.
    private var glass: some View {
        ZStack {
            if reduceTransparency {
                shape.fill(Theme.Colors.paper)
            } else {
                shape.fill(.ultraThinMaterial)
                shape.fill(Theme.Colors.paper.opacity(0.78))
            }
            RaisedGlass(shape: shape, tint: tint, look: look)
        }
    }
}
