import SwiftUI
import TesseraCore

/// Today (sheet 211): the title, one fact line, then the day in order at 40 pt a line, name left and time right
/// (Outfit 300). His things are in ink, the sun in ink 3. Core supplies the lines already masked, so a private item
/// reads by its shown label. Calendar text is drawn here and goes nowhere else.
struct TodayRoomView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var today: TodayFacts?

    static let rowHeight: CGFloat = 40

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Home")
                        .font(Theme.voice(size: 17))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Home")
                Text("Today")
                    .font(Theme.voice(size: 34).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)
                if let today {
                    Text(today.factLine)
                        .font(Theme.voice(size: 17))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                    ForEach(Array(today.lines.enumerated()), id: \.offset) { _, line in
                        row(line)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .onAppear(perform: load)
    }

    /// The name, then each shorter form with a trailing word dropped (at least one word stays), none ending on a stop
    /// word.
    static func forms(of name: String) -> [String] {
        let words = name.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [name] }
        let all = (1 ... words.count).reversed().map { words.prefix($0).joined(separator: " ") }
        // A shorter form never ends on a stop word ("at", "to", "for", ...).
        return all.enumerated().filter { $0.offset == 0 || !HomeBoard.endsOnStopWord($0.element) }.map(\.element)
    }

    /// What a line is, for the row where its name will not fit.
    static func classWord(of line: TodayLine) -> String {
        if line.isCalendar {
            return "Event"
        }
        return switch line.kind {
        case .sunrise: "Sunrise"
        case .sunset: "Sunset"
        case .item(.training?): "Workout"
        case .item(.routines?): "Routine"
        case .item: "Task"
        }
    }

    private func row(_ line: TodayLine) -> some View {
        let sun = line.kind == .sunrise || line.kind == .sunset
        let tint = sun || line.isPast ? Theme.Colors.inkTertiary : Theme.Colors.ink
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            // Fixed layout: never an ellipsis, a smaller face, a wrap or a taller row. The longest form that fits one
            // line at 19 (words cut from the end); when not even one word fits, the line's class word.
            ViewThatFits(in: .horizontal) {
                ForEach(Self.forms(of: line.name), id: \.self) { form in
                    Text(form).font(Theme.voice(size: 19)).lineLimit(1).fixedSize()
                }
                Text(Self.classWord(of: line)).font(Theme.voice(size: 19)).lineLimit(1).fixedSize()
            }
            .foregroundStyle(tint)
            Spacer(minLength: 8)
            Text(HouseTime.clock(line.time))
                .font(Theme.numeral(19, weight: .light))
                .foregroundStyle(tint)
        }
        .frame(minHeight: Self.rowHeight)
        .accessibilityElement(children: .combine)
    }

    private func load() {
        let now = AppClock.now
        let facts = MosaicFacts.make(engine: model.engine, now: now)
        today = TodayFacts.make(engine: model.engine, facts: facts)
    }
}
