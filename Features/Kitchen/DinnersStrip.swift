import SwiftUI
import TesseraCore

/// The week of dinners as a strip on Kitchen (sheet 114 section 1), behind the Review switch Week strip: the seven
/// day words Monday to Sunday on one line, a planned day in ink and an empty one in secondary ink, today carried by a
/// short hairline in the area lean under its word. Under it one 21 line: tonight's dinner, else the next one this
/// week, else "Nothing planned". The whole strip is one tap into Dinners.
struct DinnersStrip: View {
    let open: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let week = WeekOfDinners(store: model.store, classes: model.classes, now: now)
        let today = TesseraDay().today(now)
        Button(action: open) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                if !typeSize.isAccessibilitySize {
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            Text(day.word)
                                .textRole(.label)
                                .textCase(.uppercase)
                                .fontWeight(day.plan == nil ? .regular : .semibold)
                                .foregroundStyle(day.plan == nil ? Theme.Colors.inkSecondary : Theme.Colors.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .bottomLeading) {
                                    if day.id == today {
                                        Rectangle()
                                            .fill(Theme.Colors.areaLean(.kitchen))
                                            .frame(width: Theme.Spacing.xl, height: Theme.Stroke.hairline * 2)
                                            .offset(y: Theme.Spacing.xs)
                                    }
                                }
                        }
                    }
                }
                Text(DinnersStrip.line(week, today: today))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dinners, \(DinnersStrip.line(week, today: today))")
        .accessibilityHint("Opens the week of dinners")
    }

    /// "Tonight, tacos." / "Thu, chili." / "Nothing planned this week."
    static func line(_ week: WeekOfDinners, today: Date) -> String {
        if let tonight = week.days.first(where: { $0.id == today })?.plan, !tonight.isDone {
            return "Tonight, \(tonight.name)."
        }
        if let next = week.days.first(where: { $0.id > today && $0.plan != nil }), let plan = next.plan {
            return "\(next.word), \(plan.name)."
        }
        return "Nothing planned this week."
    }
}
