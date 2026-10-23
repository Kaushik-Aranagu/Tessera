import SwiftUI
import TesseraCore

/// Next (sheet 199): the label, then three rows at 40 pt in Figtree 20, the third in ink 2. The rows are Home's own
/// queue rows (swipe right strikes in ink and finishes the task, swipe left is Not now; the Tess line with Undo is
/// unchanged). The why sits at the right of each row (sheet 207); a tap opens the thing.
struct MosaicNextList: View {
    /// Called with the finished row's frame in window space.
    let finished: (CGRect) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// One rigid haptic when a done tile lands in the mosaic (sheet 207).
    @State private var landings = 0

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
                                  why: why(of: entry, in: picks).map { AppsListRows.fit($0, limit: 30) },
                                  finished: { frame in
                                      finished(frame)
                                      // The tile flies for 700 ms, then lands: the finished moment's rigid tap.
                                      Task { @MainActor in
                                          try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 700))
                                          landings += 1
                                      }
                                  })
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tesseraFeedback(.setLogged, trigger: landings)
    }

    /// A private thing reads by its label, never its title: Core's one rule (the shown label, which also covers walled
    /// and secret words in a title like "Lexapro refill", then the task label), the same everywhere.
    private func masked(_ entry: QueueEntry) -> QueueEntry {
        guard let object = model.store.object(id: entry.id),
              let label = ObjectPrivacy.shownLabel(of: object, in: model.store, classes: model.classes)
        else {
            return entry
        }
        return QueueEntry(id: entry.id, title: label, time: entry.time, isWorkout: entry.isWorkout)
    }

    /// Core's reason for the pick; none for a private thing or one the ranker did not score.
    private func why(of entry: QueueEntry, in picks: [Pick]) -> String? {
        guard entry.title != ObjectPrivacy.taskLabel,
              let object = model.store.object(id: entry.id),
              ObjectPrivacy.shownLabel(of: object, in: model.store, classes: model.classes) == nil else { return nil }
        let why = picks.first { $0.item.id == entry.id }?.why
        return why?.isEmpty == false ? why : nil
    }
}

/// One Next row (sheet 207): Home's queue row at 40 pt with the why at its right. Swipe right is Done, left is Not now;
/// a tap opens the thing.
private struct MosaicNextRow: View {
    let entry: QueueEntry
    let ink: Double
    let why: String?
    let finished: (CGRect) -> Void

    @State private var frame: CGRect = .zero

    var body: some View {
        QueueRow(entry: entry, isNext: false, ink: ink,
                 titleFont: Theme.voice(size: 20),
                 finished: { finished(frame) },
                 strikesInInk: true,
                 hand: QueueRow.HandStyle(why: why))
            .frame(minHeight: HomeMosaic.rowHeight)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }
}
