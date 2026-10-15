import SwiftUI
import TesseraCore

/// Paint used only on Home that has no Theme token yet (docs/design/home-v1.md, materials.md).
enum HomePaint {
    /// The day stroke runs through the day: morning sky → sage → violet → amber → vermilion evening.
    static let daySky = Color(hex: 0x9EC3D6)
    static let daySage = Color(hex: 0x8FB58A)
    static let dayViolet = Color(hex: 0x7A5C8E)
    static let dayAmber = Color(hex: 0xE0A35C)
    static let dayVermilion = Color(hex: 0xC8452F)
    /// The wet tip at now.
    static let wetTip = Color(hex: 0xE0A35C)

    static var dayGradient: Gradient {
        Gradient(colors: [daySky, daySage, dayViolet, dayAmber, dayVermilion])
    }
}

/// Home: three sibling pages on x, REVIEW · TODAY · TRAINING. Paged, stops at the edges, opens on TODAY and keeps
/// its page for the session. Each page fits one screen; y lives only inside bounded windows and z is a tap on any
/// name.
struct HomeSpatialView: View {
    enum Page: Int, CaseIterable, Identifiable {
        case review, today, training, kitchen

        var id: Int {
            rawValue
        }

        var title: String {
            switch self {
            case .review: "Review"
            case .today: "Today"
            case .training: "Training"
            case .kitchen: "Kitchen"
            }
        }
    }

    /// Space kept free at the bottom of every page for the dock (Ask Tess + What's running) in BottomChrome.
    static let dockClearance: CGFloat = 104

    /// Where Home was left this session (spatial memory).
    @MainActor private static var remembered = Page.today.rawValue

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var position = ScrollPosition(id: HomeSpatialView.remembered)
    @State private var progress = Double(HomeSpatialView.remembered)
    @State private var presented: HomeLink?
    @Namespace private var linkZoom

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            PaintedRail(titles: Page.allCases.map(\.title), progress: progress) { show($0) }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.s)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Page.allCases) { sibling in
                        fitted(content(for: sibling))
                            .containerRelativeFrame(.horizontal)
                            // The hero's parallax stays inside its own page.
                            .clipped()
                            .id(sibling.rawValue)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            // Opens where Home was left (TODAY the first time) without a visible jump.
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
        .toolbarVisibility(.hidden, for: .navigationBar)
        // Each of these screens keeps its own NavigationStack, so it zooms out of the word that opened it (full
        // screen, swipe down to close) instead of being pushed inside Home's stack.
        .fullScreenCover(item: $presented) { link in
            link.destination
                .overlay(alignment: .topTrailing) {
                    Button("Close") { presented = nil }
                        .buttonStyle(InkLabelWordStyle())
                        .padding(.trailing, Theme.Spacing.gutter - 8)
                }
                .navigationTransition(.zoom(sourceID: link, in: linkZoom))
        }
        .environment(\.openHomeLink) { presented = $0 }
        .environment(\.homeLinkZoom, linkZoom)
    }

    @ViewBuilder
    private func content(for sibling: Page) -> some View {
        switch sibling {
        case .review:
            ReviewPage()
                .frame(maxHeight: .infinity, alignment: .top)
                .overlay(alignment: .bottomLeading) { HomeLinkLine(links: [.review, .notes]) }
        case .today: NowPage(onShow: show)
        case .training: TrainingPage()
        case .kitchen: KitchenPage()
        }
    }

    /// One screen tall. At accessibility type sizes the page may scroll rather than truncate (reflow wins).
    @ViewBuilder
    private func fitted(_ page: some View) -> some View {
        let padded = page
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Self.dockClearance)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if typeSize.isAccessibilitySize {
            ScrollView(.vertical) { padded }
                .scrollIndicators(.hidden)
        } else {
            padded
        }
    }

    private func show(_ index: Int) {
        withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { position.scrollTo(id: index) }
    }

    private func show(_ sibling: Page) {
        show(sibling.rawValue)
    }
}

// MARK: - Entry points

/// The screens Home reaches that are not objects: Notes, Review, Groceries and Recipes.
enum HomeLink: Hashable, CaseIterable, Identifiable {
    case groceries, recipes, pasteRecipe, notes, review

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .groceries: "Groceries"
        case .recipes: "Recipes"
        case .pasteRecipe: "Paste a recipe"
        case .notes: "Notes"
        case .review: "The week"
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .groceries: GroceriesView()
        case .recipes: RecipeView(recipeID: nil)
        case .pasteRecipe: PasteRecipeView()
        case .notes: NotesView()
        case .review: ReviewView()
        }
    }
}

/// Kitchen: two names at hero-ish size, ink words with no shape around them; a tap zooms in.
private struct KitchenPage: View {
    @Environment(\.openHomeLink) private var open
    @Environment(\.homeLinkZoom) private var zoom

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Text("What we eat, and what we need.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.inkSecondary)
            ForEach([HomeLink.groceries, .recipes], id: \.self) { link in
                Button { open(link) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                        PaintDab(color: link == .groceries ? HomePaint.daySage : HomePaint.dayAmber,
                                 seed: link == .groceries ? 2 : 5)
                        Text(link.title)
                            .textRole(.title)
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(LinkZoomSource(link: link, zoom: zoom))
            }
            HomeLinkLine(links: [.pasteRecipe])
            Spacer(minLength: 0)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

/// A line of entry words ("The week · Notes") at the foot of a page.
private struct HomeLinkLine: View {
    let links: [HomeLink]
    @Environment(\.openHomeLink) private var open
    @Environment(\.homeLinkZoom) private var zoom

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                if index > 0 {
                    Text(" · ").textRole(.body).foregroundStyle(Theme.Colors.ink.opacity(0.6))
                }
                Button { open(link) } label: {
                    Text(link.title)
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .modifier(LinkZoomSource(link: link, zoom: zoom))
            }
        }
    }
}

/// Marks the word a Home link zooms out of, when Home provides the namespace.
private struct LinkZoomSource: ViewModifier {
    let link: HomeLink
    let zoom: Namespace.ID?

    func body(content: Content) -> some View {
        if let zoom {
            content.matchedTransitionSource(id: link, in: zoom)
        } else {
            content
        }
    }
}

extension EnvironmentValues {
    @Entry var openHomeLink: (HomeLink) -> Void = { _ in }
    @Entry var homeLinkZoom: Namespace.ID?
}

// MARK: - Sibling rail

/// Three label words (active in ink, the others muted) over a painted vermilion underline, 64×4 with an uneven
/// radius, that glides continuously with the swipe. Tapping a word pages there.
private struct PaintedRail: View {
    let titles: [String]
    /// 0 … titles.count − 1, fractional while paging.
    let progress: Double
    var onSelect: (Int) -> Void

    var body: some View {
        let current = Int(progress.rounded())
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Button { onSelect(index) } label: {
                        Text(title)
                            .textRole(.label)
                            .foregroundStyle(index == current ? Theme.Colors.ink : Theme.Colors.muted)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(index == current ? .isSelected : [])
                }
            }
            .tesseraAnimation(Theme.Motion.snappy, value: current)

            GeometryReader { proxy in
                let cell = proxy.size.width / CGFloat(max(titles.count, 1))
                UnevenRoundedRectangle(
                    topLeadingRadius: 2, bottomLeadingRadius: 1.2,
                    bottomTrailingRadius: 2.4, topTrailingRadius: 1, style: .continuous
                )
                .fill(Theme.Colors.live)
                .frame(width: 64, height: 4)
                .rotationEffect(.degrees(-1.2))
                .blur(radius: 0.5)
                .offset(x: cell * (CGFloat(progress) + 0.5) - 32)
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Shared bits

/// Each page's hero travels at 70% of the page while paging (30% parallax). Reduce Motion: none.
private struct SiblingParallax: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let amount: CGFloat = reduceMotion ? 0 : 0.3
        // The phase is −1 … 1 as the hero's page slides out to either side, and exactly 0 at rest.
        content.scrollTransition(.interactive, axis: .horizontal) { effect, phase in
            effect.offset(x: -phase.value * amount * 390)
        }
    }
}

extension View {
    /// Apply to a sibling page's hero.
    func siblingParallax() -> some View {
        modifier(SiblingParallax())
    }
}

// MARK: - Data

/// Pure-ish helpers behind Home, kept out of the views so they can be tested.
@MainActor
enum HomeData {
    /// Upcoming items after the hero: not done, not the current task, and not already over.
    static func upcoming(_ schedule: [ScheduleItem], excluding current: ScheduleItem?, now: Date) -> [ScheduleItem] {
        schedule.filter { item in
            item.id != current?.id && !item.isDone && item.end > now && (item.isWorkout || item.start >= now)
        }
    }

    /// Yesterday, today and tomorrow, each holding the schedule items that start on that calendar day.
    static func lanes(_ model: AppModel, now: Date, calendar: Calendar = .current) -> [DayLane] {
        (-1 ... 1).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            let items = model.schedule(around: offset == 0 ? now : day)
                .filter { calendar.isDate($0.start, inSameDayAs: day) }
            let workouts = model.finishedWorkouts(on: day).compactMap { summary -> ClosedRange<Date>? in
                guard let end = summary.endedAt else { return nil }
                return min(summary.startedAt ?? end, end) ... end
            }
            return DayLane(offset: offset, date: day, items: items, workouts: workouts)
        }
    }

    /// When each workout finished (or, for one still running, when it started), skipping planned ones.
    static func trainingDates(_ model: AppModel) -> [(workout: ObjectRecord, date: Date)] {
        model.objects(of: .workout).compactMap { workout in
            if case let .date(date)? = model.store.value("endedAt", of: workout) {
                return (workout, date)
            }
            if model.session?.workout.id == workout.id,
               case let .date(date)? = model.store.value("startedAt", of: workout)
            {
                return (workout, date)
            }
            return nil
        }
    }
}

// MARK: - Spoken time

/// Times and counts in words for the italic context lines: "twenty to four", "this evening at six".
enum SpokenTime {
    static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en")
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }

    /// "four", "quarter past three", "twenty to four", "seventeen minutes past three".
    static func clock(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0, minute = parts.minute ?? 0
        func name(_ hour: Int) -> String {
            switch hour % 24 {
            case 0: "midnight"
            case 12: "noon"
            default: number((hour + 11) % 12 + 1)
            }
        }
        switch minute {
        case 0: return name(hour)
        case 15: return "quarter past \(name(hour))"
        case 30: return "half past \(name(hour))"
        case 45: return "quarter to \(name(hour + 1))"
        case let minute where minute < 30:
            return "\(number(minute))\(minute % 5 == 0 ? "" : " minutes") past \(name(hour))"
        default:
            let left = 60 - minute
            return "\(number(left))\(left % 5 == 0 ? "" : " minutes") to \(name(hour + 1))"
        }
    }

    /// "morning", "afternoon", "evening", "night".
    static func partOfDay(_ date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5 ..< 12: "morning"
        case 12 ..< 17: "afternoon"
        case 17 ..< 22: "evening"
        default: "night"
        }
    }

    /// "this evening at six", "tomorrow at half past seven", "Friday at nine".
    static func when(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let atTime = "at \(clock(date, calendar: calendar))"
        if calendar.isDate(date, inSameDayAs: now) {
            let part = partOfDay(date, calendar: calendar)
            return part == "night" ? "tonight \(atTime)" : "this \(part) \(atTime)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(
            date,
            inSameDayAs: tomorrow
        ) {
            return "tomorrow \(atTime)"
        }
        return "\(date.formatted(.dateTime.weekday(.wide))) \(atTime)"
    }
}
