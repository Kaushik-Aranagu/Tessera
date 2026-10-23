import SwiftUI
import TesseraCore

/// The rows of the apps list (sheet 205), pure so they test without a screen: each app in the edge order with the one
/// line it has to say today, or a quiet line when it has nothing. Core masks private things and keeps Money to a due
/// word before the clause gets here. Core's AppSummaryLine replaces the clause here when it lands.
@MainActor
enum AppsListRows {
    struct Row: Identifiable, Equatable {
        let app: HomeApp
        let summary: String
        let opens: HomeSentence.Opens
        var id: HomeApp {
            app
        }
    }

    static let quiet = "Nothing planned"

    static func home(_ app: AppSummaryApp) -> HomeApp {
        switch app {
        case .training: .training
        case .kitchen: .kitchen
        case .routines: .routines
        case .tasks: .tasks
        case .notes: .notes
        case .lists: .lists
        case .money: .money
        }
    }

    /// One row per app from Core's lines, in Core's order. A private top item already reads "Private" there.
    static func make(_ lines: [AppSummaryLine]) -> [Row] {
        lines.map { Row(app: home($0.app), summary: $0.text.isEmpty ? quiet : $0.text, opens: $0.opens) }
    }

    /// A fact that fits one short line: cut at a word edge, never with an ellipsis.
    static func fit(_ text: String, limit: Int = 38) -> String {
        guard text.count > limit else { return text }
        let head = String(text.prefix(limit))
        if let space = head.lastIndex(of: " ") {
            return String(head[..<space]).trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:"))
        }
        return head
    }

    /// The app that sits `offset` rows from `index` in a ring: the list wraps round.
    static func wrapped(_ index: Int, _ offset: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (((index + offset) % count) + count) % count
    }
}

/// The apps menu under Next (sheet 205): a label "Apps" in ink 3 and a scroller of three 40 pt rows (more at large
/// text) that snaps to the
/// middle one and wraps round, with no ticks, dots or dividers. The middle row is the pick: its name swells 1.3x in its
/// accent on the house spring and its one-line fact is revealed from the right with a clip, sliding 14 pt. The others
/// show the name only, in ink 3. One tick per change. Tap the middle row to open it; tap another to bring it to the
/// middle. Reduce Motion: no swell and no slide.
struct AppsListSlot: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var door: HomeV2Door?
    @State private var middle = 0
    @State private var drag: CGFloat = 0
    @State private var ticks = 0
    /// The rows, read once per change in the model and not on every drag frame.
    @State private var rows: [AppsListRows.Row] = []
    /// 40 pt at the default size; the rows grow with the text.
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Apps")
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkTertiary)
                .accessibilityAddTraits(.isHeader)
            ZStack(alignment: .top) {
                // Five rows are laid out so the ring has a row to bring in on each side while it moves.
                if !rows.isEmpty {
                    ForEach(-2 ... 2, id: \.self) { offset in
                        let row = rows[AppsListRows.wrapped(middle, offset, count: rows.count)]
                        line(row, isMiddle: offset == 0, offset: offset)
                            .offset(y: (CGFloat(offset) + 1) * rowHeight + drag)
                    }
                }
            }
            .frame(height: rowHeight * 3, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { drag = $0.translation.height.clamped(to: -rowHeight * 2 ... rowHeight * 2) }
                    .onEnded { value in
                        let steps = Int((-value.predictedEndTranslation.height / rowHeight).rounded())
                        settle(by: max(-2, min(2, steps)), count: rows.count)
                    }
            )
        }
        .tesseraFeedback(.selection, trigger: ticks)
        .onChange(of: model.revision, initial: true) {
            rows = AppsListRows.make(AppSummaryLines.lines(engine: model.engine, plan: model.plan, now: AppClock.now))
        }
        .accessibilityElement(children: .contain)
        .accessibilityAdjustableAction { direction in
            settle(by: direction == .increment ? 1 : -1, count: rows.count)
        }
        .fullScreenCover(item: $door) { door in
            HomeV2DoorPage(door: door)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { self.door = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
                }
        }
    }

    private func line(_ row: AppsListRows.Row, isMiddle: Bool, offset: Int) -> some View {
        Button {
            if isMiddle {
                open(row)
            } else {
                settle(by: offset, count: rows.count)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(row.app.rawValue)
                    .font(Theme.voice(size: isMiddle && !reduceMotion ? 18 * 1.3 : 18)
                        .weight(isMiddle ? .semibold : .regular))
                    .foregroundStyle(isMiddle ? row.app.accent : Theme.Colors.inkTertiary)
                    .fixedSize()
                if isMiddle {
                    Spacer(minLength: Theme.Spacing.s)
                    Text(AppsListRows.fit(row.summary))
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.8)
                        .id(row.app)
                        .transition(reduceMotion ? .identity : .reveal)
                }
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMiddle ? "\(row.app.rawValue), \(row.summary)" : row.app.rawValue)
        .accessibilityHint(isMiddle ? "Opens \(row.app.rawValue)" : "Brings it to the middle")
    }

    /// A tap on the middle row: the object its line names, else the app.
    private func open(_ row: AppsListRows.Row) {
        if case let .object(id) = row.opens {
            model.path.append(Route.object(id))
        } else {
            door = .app(row.app)
        }
    }

    private func settle(by steps: Int, count: Int) {
        defer {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { drag = 0 }
        }
        guard steps != 0, count > 0 else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            middle = AppsListRows.wrapped(middle, steps, count: count)
            drag = 0
        }
        ticks += 1
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

/// A fact revealed from the right with a clip, sliding 14 pt (no fade).
private struct RevealRight: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: (1 - progress) * 14)
            .mask(alignment: .trailing) {
                Rectangle().scaleEffect(x: max(progress, 0.001), anchor: .trailing)
            }
    }
}

private extension AnyTransition {
    static var reveal: AnyTransition {
        .modifier(active: RevealRight(progress: 0), identity: RevealRight(progress: 1))
    }
}
