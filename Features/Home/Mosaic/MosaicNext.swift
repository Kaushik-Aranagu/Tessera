import SwiftUI
import TesseraCore

/// Next (sheet 199): the label, then three rows at 40 pt in Figtree 20, the third in ink 2. The rows are Home's own
/// queue rows (swipe right strikes in ink and finishes the task, swipe left is Not now; the Tess line with Undo is
/// unchanged). A tap grows a row to about 78 pt on the house spring and shows why Tess ranks it here; one open at a
/// time. Tapping the why opens the thing.
struct MosaicNext: View {
    /// Called with the finished row's frame in the page's coordinate space.
    let finished: (CGRect) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rows = OneOpenRow()
    @State private var ticks = 0

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let queue = QueueEntry.split(model: model, schedule: model.schedule(around: now), current: nil, now: now)
        let entries = Array((queue.next + queue.later).prefix(3)).map(masked)
        let picks = NowPage.rank(model: model, now: now, incumbent: nil)
        VStack(alignment: .leading, spacing: 0) {
            if entries.isEmpty {
                Text("Nothing else today.")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Next")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    MosaicNextRow(entry: entry,
                                  ink: index == 2 ? 0.62 : 1,
                                  why: why(of: entry, in: picks),
                                  isOpen: rows.isOpen(entry.id),
                                  toggle: { toggle(entry.id) },
                                  finished: finished)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tesseraFeedback(.selection, trigger: ticks)
        .onChange(of: entries.map(\.id)) { _, ids in
            // A row that finished or moved away takes its open state with it.
            if let open = rows.open, !ids.contains(open) {
                rows.close()
            }
        }
    }

    /// A private thing reads by its label, never its title.
    private func masked(_ entry: QueueEntry) -> QueueEntry {
        guard let object = model.store.object(id: entry.id),
              let label = ObjectPrivacy.label(of: object, in: model.store, classes: model.classes) else { return entry }
        return QueueEntry(id: entry.id, title: label, time: entry.time, isWorkout: entry.isWorkout)
    }

    /// Core's reason for the pick; none for a private thing or one the ranker did not score.
    private func why(of entry: QueueEntry, in picks: [Pick]) -> String? {
        guard entry.title != ObjectPrivacy.taskLabel,
              let object = model.store.object(id: entry.id),
              ObjectPrivacy.label(of: object, in: model.store, classes: model.classes) == nil else { return nil }
        let why = picks.first { $0.item.id == entry.id }?.why
        return why?.isEmpty == false ? why : nil
    }

    private func toggle(_ id: UUID) {
        ticks += 1
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            rows.tap(id)
        }
    }
}

/// One Next row: Home's queue row at 40 pt, and under it, while open, the why.
private struct MosaicNextRow: View {
    let entry: QueueEntry
    let ink: Double
    let why: String?
    let isOpen: Bool
    let toggle: () -> Void
    let finished: (CGRect) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame: CGRect = .zero

    private var showsWhy: Bool {
        isOpen && why != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QueueRow(entry: entry, isNext: false, ink: ink,
                     titleFont: Theme.voice(size: 20),
                     // With no why to show, a tap opens the thing as it does on Home.
                     tapped: why == nil ? nil : toggle,
                     finished: { finished(frame) },
                     strikesInInk: true)
                .frame(minHeight: HomeMosaic.rowHeight)
            if showsWhy, let why {
                Button { model.open(.object(entry.id)) } label: {
                    Text(why)
                        .font(Theme.voice(size: 16))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: HomeMosaic.openRowHeight - HomeMosaic.rowHeight,
                               alignment: .topLeading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens \(entry.title)")
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -6)))
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(HomeMosaicPage.space)) } action: { frame = $0 }
        .accessibilityAction(named: isOpen ? "Hide why" : "Show why") {
            if why != nil {
                toggle()
            }
        }
    }
}
