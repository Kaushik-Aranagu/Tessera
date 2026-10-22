import SwiftUI
import TesseraCore

/// Training's plan, one level below the TRAINING page (docs/design/plans.md): two sibling pages on x, WEEK and
/// MONTH, under a painted carriage that follows the swipe. One screen tall each; dabs, not cards or calendars.
/// Without a plan it still shows what was trained, and counts without an "of".
struct PlansView: View {
    /// The plan to show; nil shows the newest plan, if there is one.
    var plan: ObjectRecord?

    enum Page: Int, CaseIterable, Identifiable {
        case week, month

        var id: Int {
            rawValue
        }

        var title: String {
            self == .week ? "Week" : "Month"
        }
    }

    /// Where Plans was left this session (spatial memory).
    @MainActor private static var remembered = Page.week.rawValue

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var position = ScrollPosition(id: PlansView.remembered)
    @State private var progress = Double(PlansView.remembered)

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let data = PlanData(model: model, plan: plan, now: now)

        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            CarriageRail(titles: Page.allCases.map(\.title), progress: progress, spread: .packed(28),
                         carriage: CGSize(width: 50, height: 4)) { show($0) }
                .padding(.horizontal, Theme.Spacing.gutter)
                .entrance(0)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Page.allCases) { page in
                        fitted(page, data: data, now: now)
                            .containerRelativeFrame(.horizontal)
                            .clipped()
                            .id(page.rawValue)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition($position)
            .onAppear { position.scrollTo(id: Self.remembered) }
            .onScrollGeometryChange(for: Double.self) { geometry in
                geometry.containerSize.width > 0 ? geometry.contentOffset.x / geometry.containerSize.width : 0
            } action: { _, new in
                progress = new
            }
            .onChange(of: position.viewID(type: Int.self)) { _, new in
                if let new {
                    Self.remembered = new
                }
            }
        }
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func fitted(_ page: Page, data: PlanData, now: Date) -> some View {
        let content = Group {
            switch page {
            case .week: WeekPage(data: data, now: now)
            case .month: MonthPage(data: data, now: now)
            }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, HomeSpatialView.dockClearance)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if typeSize.isAccessibilitySize {
            ScrollView(.vertical) { content }.scrollIndicators(.hidden)
        } else {
            content
        }
    }

    private func show(_ index: Int) {
        withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { position.scrollTo(id: index) }
    }
}

// MARK: - Shared

extension RoutinePaint {
    var color: Color {
        switch self {
        case .vermilion: Theme.Colors.live
        // Pull's routine colour is violet; Tess's cobalt stays hers.
        case .cobalt: Theme.Colors.routines[3]
        case .cadmium: Theme.Colors.now
        case .sage: Theme.Colors.health
        }
    }
}

/// Context line and the two-line hero every plan page opens with.
struct PlanHeading: View {
    let context: String
    let headline: String
    var spoken: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(context)
                .font(PageType.voice)
                .foregroundStyle(Theme.Colors.context)
                .entrance(1)
            Text(headline)
                .textRole(.hero)
                .wordFit(headline)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(spoken ?? headline.replacingOccurrences(of: "\n", with: " "))
                .siblingParallax()
                .entrance(2, hero: true)
        }
    }
}
