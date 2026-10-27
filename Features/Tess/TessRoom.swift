import SwiftUI
import TesseraCore

// Sheet 215: her room. A swipe up on her opens it from her corner as a circle clip (not a sheet): "Watching today", and
// today's log with each time and its Undo word ("Reversed" for money). Titles are masked by their shown labels (Core
// builds the sentences). A swipe down or "Back to Home" closes it.

/// A circle growing from a point: the room's reveal.
struct TessCircleReveal: Shape {
    var center: CGPoint
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let reach = hypot(max(center.x, rect.width - center.x), max(center.y, rect.height - center.y))
        let radius = reach * progress
        return Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
}

struct TessRoom: View {
    var entries: [RoomLogEntry]
    var watching: String
    var undo: (RoomLogEntry) -> String?
    var close: () -> Void

    @State private var reversed: [UUID: String] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tess")
                .font(Theme.voice(size: 34).weight(.medium))
                .foregroundStyle(Theme.Colors.ink)
            Text(watching)
                .font(TessFont.inLayer)
                .foregroundStyle(Theme.Colors.inkSecondary)
            if entries.isEmpty {
                Text("Nothing yet today")
                    .font(TessFont.inLayer)
                    .foregroundStyle(Theme.Colors.inkTertiary)
            }
            Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(entries) { entry in
                    GridRow {
                        Text(TessTimeMarker.clock(entry.time).replacingOccurrences(of: " am", with: "")
                            .replacingOccurrences(of: " pm", with: ""))
                            .font(Font.custom("Outfit", size: 16, relativeTo: .body).weight(.light))
                            .foregroundStyle(Theme.Colors.inkTertiary)
                            .frame(width: 62, alignment: .leading)
                        (Text(entry.sentence + " ")
                            + Text(reversed[entry.id] ?? entry.undoWord)
                            .underline(reversed[entry.id] == nil)
                            .foregroundStyle(reversed[entry.id] == nil ? Theme.Colors.ink : Theme.Colors.inkTertiary))
                            .font(TessFont.inLayer)
                            .foregroundStyle(Theme.Colors.ink)
                            .onTapGesture {
                                guard reversed[entry.id] == nil else { return }
                                reversed[entry.id] = undo(entry) ?? entry.undoWord
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(entry.sentence). \(entry.undoWord)")
                            .accessibilityAddTraits(.isButton)
                    }
                }
            }
            Spacer(minLength: 0)
            Button(action: close) {
                Text("Back to Home")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Colors.paper.ignoresSafeArea())
        .pullGesture { down in
            if down {
                close()
            }
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Tess's room")
    }
}
