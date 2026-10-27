import SwiftUI
import WidgetKit

// Surfaces v2 (Design 142): the day sentence on the Home Screen and the next clause on the Lock Screen. It reads only
// the snapshot the app writes to the App Group while the Review switch "Surfaces v2" is On; Off (or no snapshot) draws
// "Open Tessera." and nothing else.

struct DaySentenceEntry: TimelineEntry {
    let date: Date
    /// Nil when the switch is Off or the app has not written yet.
    let clauses: [SurfaceClause]?
}

struct DaySentenceProvider: TimelineProvider {
    func placeholder(in _: Context) -> DaySentenceEntry {
        DaySentenceEntry(date: .now, clauses: [
            SurfaceClause(app: "training", text: "Push A today", keyFrom: 0, keyTo: 6, at: nil),
        ])
    }

    func getSnapshot(in _: Context, completion: @escaping (DaySentenceEntry) -> Void) {
        completion(entry(at: .now))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<DaySentenceEntry>) -> Void) {
        let now = Date.now
        let clauses = SurfacesSnapshot.read()?.clauses
        let dates = SurfaceLine.changeDates(clauses ?? [], now: now)
        let entries = dates.map { DaySentenceEntry(date: $0, clauses: clauses) }
        // The app reloads timelines when it writes; this is the fallback if it does not run.
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60))))
    }

    private func entry(at date: Date) -> DaySentenceEntry {
        DaySentenceEntry(date: date, clauses: SurfacesSnapshot.read()?.clauses)
    }
}

struct DaySentenceWidget: Widget {
    static let kind = "TesseraDaySentence"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: DaySentenceProvider()) { entry in
            DaySentenceView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("The day in one sentence")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}

private struct DaySentenceView: View {
    let entry: DaySentenceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .systemLarge: large
        case .accessoryRectangular: rectangular
        default: inline
        }
    }

    private var clauses: [SurfaceClause] {
        entry.clauses ?? []
    }

    // MARK: Home Screen

    /// The small widget: the sentence's first clause.
    private var small: some View {
        Group {
            if let clause = SurfaceLine.first(clauses) {
                SentenceText(clauses: [clause])
            } else {
                plain
            }
        }
        .font(SurfaceType.words(20, .medium, relativeTo: .title3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// The medium widget: the whole sentence, each key word in its app's accent.
    private var medium: some View {
        Group {
            if clauses.isEmpty {
                plain
            } else {
                SentenceText(clauses: clauses)
            }
        }
        .font(SurfaceType.words(22, .medium, relativeTo: .title2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// The large widget: the sentence, then "Next".
    private var large: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                if clauses.isEmpty {
                    plain
                } else {
                    SentenceText(clauses: clauses)
                }
            }
            .font(SurfaceType.words(26, .medium, relativeTo: .title))
            Spacer(minLength: 0)
            if let next = SurfaceLine.next(clauses, now: entry.date) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next")
                        .font(SurfaceType.words(13, .medium, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        if let time = SurfaceLine.timeWord(next) {
                            Text(time)
                                .font(SurfaceType.numerals(22, relativeTo: .title3))
                                .foregroundStyle(SurfaceStyle.accent(next.app))
                        }
                        SentenceText(clauses: [next])
                            .font(SurfaceType.words(18, .regular, relativeTo: .body))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var plain: some View {
        Text(entry.clauses == nil ? SurfaceLine.notYet : SurfaceLine.quietDay)
            .foregroundStyle(.secondary)
    }

    // MARK: Lock Screen

    /// The next clause by clock time.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Next")
                .font(SurfaceType.words(12, .medium, relativeTo: .caption))
                .foregroundStyle(.secondary)
            if let next = SurfaceLine.next(clauses, now: entry.date) {
                if let time = SurfaceLine.timeWord(next) {
                    Text(time)
                        .font(SurfaceType.numerals(16, relativeTo: .callout))
                }
                Text(next.text)
                    .font(SurfaceType.words(14, .medium, relativeTo: .callout))
            } else {
                Text(entry.clauses == nil ? SurfaceLine.notYet : SurfaceLine.quietDay)
                    .font(SurfaceType.words(14, .medium, relativeTo: .callout))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var inline: some View {
        if let next = SurfaceLine.next(clauses, now: entry.date) {
            Text(SurfaceLine.inline(next))
        } else {
            Text(entry.clauses == nil ? SurfaceLine.notYet : SurfaceLine.quietDay)
        }
    }
}

/// The clauses as one paragraph: key words in the app's accent, the rest ink.
private struct SentenceText: View {
    let clauses: [SurfaceClause]

    var body: some View {
        clauses.enumerated().reduce(Text("")) { text, pair in
            let runs = SurfaceLine.runs(pair.element).reduce(Text("")) { line, run in
                let piece = Text(run.text)
                return Text(
                    "\(line)\(run.isKey ? piece.foregroundStyle(SurfaceStyle.accent(pair.element.app)) : piece)"
                )
            }
            return Text("\(text)\(pair.offset == 0 ? Text("") : Text(" "))\(runs)")
        }
    }
}
