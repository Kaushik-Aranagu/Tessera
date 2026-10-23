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
        var id: HomeApp {
            app
        }
    }

    static let quiet = "Nothing today"

    static func make(_ inputs: HomeSentence.Inputs) -> [Row] {
        AppEdges.order.map { app in
            let clause: HomeSentence.Clause? = switch app {
            case .training: inputs.training
            case .kitchen: inputs.kitchen
            case .money: inputs.money
            case .notes: inputs.notes
            case .lists: inputs.lists
            case .routines: inputs.routines
            case .tasks: nil
            }
            return Row(app: app, summary: clause?.text ?? quiet)
        }
    }

    /// The app that sits `offset` rows from `index` in a ring: the list wraps round.
    static func wrapped(_ index: Int, _ offset: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (((index + offset) % count) + count) % count
    }
}

/// The apps menu under Next (sheet 205): a label "Apps" in ink 3 and a scroller of three 40 pt rows that snaps to the
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

    static let rowHeight: CGFloat = 40

    var body: some View {
        let _ = model.revision
        let rows = AppsListRows.make(HomeSentence.inputs(engine: model.engine, plan: model.plan, now: AppClock.now))
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Apps")
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkTertiary)
                .accessibilityAddTraits(.isHeader)
            ZStack(alignment: .top) {
                // Five rows are laid out so the ring has a row to bring in on each side while it moves.
                ForEach(-2 ... 2, id: \.self) { offset in
                    let row = rows[AppsListRows.wrapped(middle, offset, count: rows.count)]
                    line(row, isMiddle: offset == 0, offset: offset)
                        .offset(y: (CGFloat(offset) + 1) * Self.rowHeight + drag)
                }
            }
            .frame(height: Self.rowHeight * 3, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { drag = $0.translation.height.clamped(to: -Self.rowHeight * 2 ... Self.rowHeight * 2) }
                    .onEnded { value in
                        let steps = Int((-value.predictedEndTranslation.height / Self.rowHeight).rounded())
                        settle(by: max(-2, min(2, steps)), count: rows.count)
                    }
            )
        }
        .tesseraFeedback(.selection, trigger: ticks)
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
                door = .app(row.app)
            } else {
                settle(by: offset, count: AppEdges.order.count)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(row.app.rawValue)
                    .font(Theme.voice(size: 18).weight(isMiddle ? .semibold : .regular))
                    .foregroundStyle(isMiddle ? row.app.accent : Theme.Colors.inkTertiary)
                    .scaleEffect(isMiddle && !reduceMotion ? 1.3 : 1, anchor: .leading)
                if isMiddle {
                    Spacer(minLength: Theme.Spacing.s)
                    Text(row.summary)
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .id(row.app)
                        .transition(reduceMotion ? .identity : .reveal)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Self.rowHeight, maxHeight: Self.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isMiddle ? "\(row.app.rawValue), \(row.summary)" : row.app.rawValue)
        .accessibilityHint(isMiddle ? "Opens \(row.app.rawValue)" : "Brings it to the middle")
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
