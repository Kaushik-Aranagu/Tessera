import SwiftUI

/// The Thread (build sheet §2.2): one line down the left gutter from the subtitle to the last sentence, and the
/// page's only drawn line. Each sentence hangs from it by a short stitch. Solid ink for what ran today, dashed for
/// what is ahead, and one rose stitch at the step that is running (none when nothing runs). It never counts a streak
/// and nothing can fall off it. Each row draws its own length of line, so the rows need no measuring.
enum ThreadKind {
    case ran, ahead, running
}

enum ThreadMetrics {
    /// Where a sentence starts, to the right of the line.
    static let inset: CGFloat = 20
    static let rowGap: CGFloat = 14
    static let stitch: CGFloat = 10
    static let width: CGFloat = 1.5
}

struct ThreadRow<Content: View>: View {
    let kind: ThreadKind
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.leading, ThreadMetrics.inset)
            .padding(.vertical, ThreadMetrics.rowGap)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .leading) {
                ThreadSegment(kind: kind, accent: accent)
                    .accessibilityHidden(true)
            }
    }
}

private struct ThreadSegment: View {
    let kind: ThreadKind
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    private var ink: Color {
        Theme.Colors.ink.opacity(kind == .ran ? 0.6 : 0.4)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ThreadLine()
                .stroke(ink, style: StrokeStyle(lineWidth: ThreadMetrics.width,
                                                dash: kind == .ran ? [] : [3, 4]))
                .frame(width: ThreadMetrics.width)
            Capsule()
                .fill(kind == .running ? accent : ink)
                .frame(width: ThreadMetrics.stitch, height: kind == .running ? 2.5 : ThreadMetrics.width)
                // Reduce Motion: the stitch simply appears; otherwise the rose one draws out of the line.
                .scaleEffect(x: kind == .running && !reduceMotion && !drawn ? 0.01 : 1, anchor: .leading)
                .opacity(kind == .running && reduceMotion && !drawn ? 0 : 1)
                .padding(.top, ThreadMetrics.rowGap + 12)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .tesseraAnimation(Theme.Motion.house, value: drawn)
        .onAppear { drawn = true }
    }
}

private struct ThreadLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
