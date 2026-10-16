import SwiftUI
import TesseraCore

/// The day stroke's colours, morning to evening, per look (themes.md, theme-contrast-fixes.md B3/B7). Dark looks
/// use the look's own `daySpectrum`. Light looks (Porcelain, Celadon) darken the sky and amber stops to reach 3:1 on
/// white; those two values are for this stroke only and never become text colours. Plein keeps its own stroke.
enum HomeStroke {
    static var gradient: Gradient {
        let look = ThemeStore.shared.paintLook
        if look.name == Look.plein.name {
            return Gradient(colors: [Color(hex: 0x9EC3D6), Color(hex: 0x8FB58A), Color(hex: 0x7A5C8E),
                                     Color(hex: 0xE0A35C), Color(hex: 0xC8452F)])
        }
        guard !look.isDark else { return Gradient(colors: Theme.Colors.daySpectrum) }
        return Gradient(colors: [Color(hex: 0x509BD5), Theme.Colors.health, Theme.Colors.context,
                                 Color(hex: 0xC58700), Theme.Colors.live])
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

    /// Space kept free at the bottom of every page, on top of the 56 pt RootView keeps for the soul.
    static let dockClearance: CGFloat = 48

    /// Where Home was left this session (spatial memory).
    @MainActor private static var remembered: Int = {
        #if DEBUG
            // `-homePage review|today|training|kitchen` opens Home on that page (for recordings).
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "-homePage"), index + 1 < arguments.count,
               let page = Page.allCases.first(where: { arguments[index + 1] == "\($0)" })
            {
                return page.rawValue
            }
        #endif
        return Page.today.rawValue
    }()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var position = ScrollPosition(id: HomeSpatialView.remembered)
    @State private var progress = Double(HomeSpatialView.remembered)
    @State private var settled = false
    @State private var presented: HomeLink?
    @State private var pagerIdle = true
    @State private var rowGrabbed = false
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
            // Rows on a page only take a drag while the pager is at rest.
            .onScrollPhaseChange { _, phase in
                pagerIdle = phase == .idle
                // A swipe by hand means the pager is live, even if the restored page never applied.
                if phase != .idle {
                    settled = true
                }
            }
            .scrollDisabled(rowGrabbed)
            .environment(\.homePagerIdle, pagerIdle)
            .environment(\.homeRowGrabbed, rowGrabbed)
            .environment(\.homeRowGrab) { rowGrabbed = $0 }
            // Opens where Home was left (TODAY the first time) without a visible jump.
            .scrollPosition($position)
            .onAppear {
                position.scrollTo(id: Self.remembered)
                #if DEBUG
                    // `-openLink notes|recipes|groceries|review` opens that screen the way its Home word does.
                    let arguments = ProcessInfo.processInfo.arguments
                    if let index = arguments.firstIndex(of: "-openLink"), index + 1 < arguments.count,
                       let link = HomeLink.allCases.first(where: { arguments[index + 1] == "\($0)" })
                    {
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.5))
                            presented = link
                        }
                    }
                #endif
            }
            .onScrollGeometryChange(for: Double.self) { geometry in
                geometry.containerSize.width > 0 ? geometry.contentOffset.x / geometry.containerSize.width : 0
            } action: { _, new in
                // Until the pager has landed on the remembered page, its first offsets (0, mid-layout) are not a
                // swipe: ignoring them keeps the rail's ink and carriage on TODAY from the first frame.
                guard settled || abs(new - Double(Self.remembered)) < 0.01 else { return }
                settled = true
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
                // Its own row above the screen, so it never sits on a title.
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Close") { presented = nil }
                            .buttonStyle(InkLabelWordStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.gutter - 8)
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
                        PaintDab(color: Theme.Colors.classColor(.kitchen),
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
                            .lineLimit(1)
                            .fixedSize()
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

    /// Yesterday, today and tomorrow, each holding the schedule items that start on that day. His day runs to
    /// 04:00 (B2): at 01:00 the today lane is still the day that's ending.
    static func lanes(_ model: AppModel, now: Date, calendar: Calendar = .current) -> [DayLane] {
        let tesseraDay = TesseraDay(calendar: calendar)
        return (-1 ... 1).compactMap { offset in
            let day = tesseraDay.day(offset, after: now)
            let items = model.schedule(around: offset == 0 ? now : day)
                .filter { tesseraDay.day(of: $0.start) == day }
            let workouts = model.ledger.finishedWorkouts(onDay: day).compactMap { summary -> ClosedRange<Date>? in
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
        // His day runs to 04:00 (B3): at 01:00 "this afternoon" means the coming afternoon only if it's still his day.
        let tesseraDay = TesseraDay(calendar: calendar)
        if tesseraDay.isSameDay(date, now) {
            let part = partOfDay(date, calendar: calendar)
            return part == "night" ? "tonight \(atTime)" : "this \(part) \(atTime)"
        }
        if tesseraDay.isSameDay(date, tesseraDay.adding(days: 1, to: now)) {
            return "tomorrow \(atTime)"
        }
        return "\(date.formatted(.dateTime.weekday(.wide))) \(atTime)"
    }
}
