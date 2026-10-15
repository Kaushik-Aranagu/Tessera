import SwiftUI

struct TodayView: View {
    enum Section: String, CaseIterable, Identifiable {
        case now = "Now"
        case next = "Next"
        case later = "Later"

        var id: Self {
            self
        }

        var symbolName: String {
            switch self {
            case .now: "bolt.fill"
            case .next: "arrow.forward.circle"
            case .later: "tray"
            }
        }
    }

    var date: Date = .now

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.textSecondary)

                ForEach(Section.allCases) { section in
                    TodaySectionCard(section: section)
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Today")
    }
}

private struct TodaySectionCard: View {
    let section: TodayView.Section

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Label(section.rawValue, systemImage: section.symbolName)
                .font(Theme.Typography.sectionTitle)
            Text("Nothing here yet")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.surface, in: .rect(cornerRadius: Theme.Radius.m))
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
}
