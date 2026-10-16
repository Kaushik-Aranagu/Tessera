import SwiftUI
import TesseraCore

/// The day stroke's colours, morning to evening, per look (themes.md, theme-contrast-fixes.md B3/B7). Dark looks
/// use the look's own `daySpectrum`. Light looks (Porcelain, Celadon) darken the sky and amber stops to reach 3:1 on
/// white; those two values are for this stroke only and never become text colours. Plein keeps its own stroke.
enum HomeStroke {
    /// Line widths, behind one place while Design tunes them (ink-line.md).
    static let day: CGFloat = 6
    static let now: CGFloat = 7.5
    static let session: CGFloat = 4
    static let carriage = CGSize(width: 40, height: 2)
    static let underAmount: CGFloat = 2

    static var gradient: Gradient {
        let look = ThemeStore.shared.paintLook
        if look.field == .plein {
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
            if let value = LaunchFlags.value(after: "-homePage"),
               let page = Page.allCases.first(where: { value == "\($0)" })
            {
                return page.rawValue
            }
        #endif
        return Page.today.rawValue
    }()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var position = ScrollPosition(id: HomeSpatialView.remembered)
    @State private var progress = Double(HomeSpatialView.remembered)
    @State private var settled = false
    @State private var presented: HomeLink?
    @State private var pagerIdle = true
    @State private var rowGrabbed = false
    @Namespace private var linkZoom
    /// The glass tab lens (42): where it sits in tab units while held, and the page it was held from.
    @State private var lens: Double?
    @State private var lensFrom = 0
    /// Whether the lens has crossed a word since it formed; a hold with no slide is a cancel.
    @State private var lensSlid = false
    /// The pages' scale while the lens is up: 1 at rest, 0.78 held.
    @State private var deckScale: CGFloat = 1
    @State private var lensTicks = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            PaintedRail(titles: Page.allCases.map(\.title), progress: progress, lens: lens,
                        onSelect: { show($0) }, onHold: holdLens, onSlide: slideLens, onRelease: releaseLens,
                        onCancel: cancelLens)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.s)
                .tesseraFeedback(.selection, trigger: lensTicks)

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
            .scrollDisabled(rowGrabbed || lens != nil)
            // While the lens is held, the deck below stands in for the pager.
            .opacity(deckScale < 1 || lens != nil ? 0 : 1)
            .overlay {
                if deckScale < 1 || lens != nil {
                    deck
                }
            }
            .environment(\.homePagerIdle, pagerIdle)
            .environment(\.homeRowGrabbed, rowGrabbed)
            .environment(\.homeRowGrab) { rowGrabbed = $0 }
            // Opens where Home was left (TODAY the first time) without a visible jump.
            .scrollPosition($position)
            .onAppear {
                position.scrollTo(id: Self.remembered)
                #if DEBUG
                    // `-openLink notes|recipes|groceries|review` opens that screen the way its Home word does.
                    if let value = LaunchFlags.value(after: "-openLink"),
                       let link = HomeLink.allCases.first(where: { value == "\($0)" })
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
        // Leaving the app mid-hold never strands the deck.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, lens != nil {
                cancelLens()
            }
        }
        .onDisappear {
            if lens != nil {
                cancelLens()
            }
        }
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

    // MARK: The lens

    /// The four real pages side by side at `deckScale`, 14 pt apart, following the lens 1:1 in tab units; the one
    /// under the lens at full strength, its neighbours live at 55%.
    private var deck: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // One page, one place: the deck settles on the word under the lens, not between pages.
            let spot = (lens ?? progress).rounded()
            ZStack {
                deckGround
                ForEach(Page.allCases) { sibling in
                    let offset = CGFloat(Double(sibling.rawValue) - spot) * (width * deckScale + 14)
                    fitted(content(for: sibling))
                        .environment(\.inHomeDeck, true)
                        .frame(width: width, height: proxy.size.height)
                        .background { ThemedBackground() }
                        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                        .scaleEffect(deckScale)
                        .offset(x: offset)
                        .opacity(sibling.rawValue == Int(spot.rounded()) ? 1 : 0.55)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Obsidian's #0A0A0C; the other looks their own ground darkened 4%.
    @ViewBuilder
    private var deckGround: some View {
        if ThemeStore.shared.paintLook.isDark {
            Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255).ignoresSafeArea()
        } else {
            ThemedBackground().overlay(Color.black.opacity(0.04)).ignoresSafeArea()
        }
    }

    private func holdLens(_ spot: Double) {
        lensFrom = Int(progress.rounded())
        lensSlid = false
        lensTicks += 1
        withTesseraAnimation(.spring(response: 0.32, dampingFraction: 0.72), reduceMotion: reduceMotion) {
            lens = spot
        }
        // Reduce Motion: no shrink; the lens and the ticks still play.
        guard !reduceMotion else { return }
        withAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.36)) { deckScale = 0.78 }
    }

    private func slideLens(_ spot: Double) {
        guard let old = lens else { return }
        if Int(old.rounded()) != Int(spot.rounded()) {
            lensTicks += 1
            lensSlid = true
            withTesseraAnimation(.spring(response: 0.3, dampingFraction: 0.82), reduceMotion: reduceMotion) {
                lens = spot
            }
        } else {
            lens = spot
        }
    }

    /// Let go: the page under the lens opens and the deck grows back; the lens melts into the ink line.
    private func releaseLens() {
        guard let spot = lens else { return }
        // A hold with no slide is a cancel: back to the page it was held from, no page change.
        let target = lensSlid ? Int(spot.rounded()) : lensFrom
        var settle = Transaction()
        settle.disablesAnimations = true
        withTransaction(settle) {
            position.scrollTo(id: target)
            progress = Double(target)
        }
        Self.remembered = target
        if reduceMotion {
            withTesseraAnimation(reduceMotion: true) { lens = nil }
            return
        }
        withAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.48)) {
            lens = Double(target)
            deckScale = 1
        } completion: {
            withAnimation(.easeOut(duration: 0.28)) { lens = nil }
        }
    }

    /// The touch was taken away mid-hold: put everything back where it was, with no page change.
    private func cancelLens() {
        lensSlid = false
        releaseLens()
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
                    // The words alone, in ink (no-dots.md).
                    Text(link.title)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
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
/// The tab words over the pages (docs/design/home-first-review.md, 42). A tap swaps the page; a swipe on the pages
/// stretches the ink carriage. Hold the row 260 ms and a Liquid Glass lens forms under the finger: the pages shrink
/// to 78% side by side, the lens and the pages follow the finger with one tick per word, and letting go opens the
/// page under the lens. A hold with no slide is a cancel.
private struct PaintedRail: View {
    let titles: [String]
    /// 0 … titles.count − 1, fractional while paging.
    let progress: Double
    /// The lens, while held: where it sits in tab units.
    let lens: Double?
    var onSelect: (Int) -> Void
    var onHold: (Double) -> Void
    var onSlide: (Double) -> Void
    var onRelease: () -> Void
    var onCancel: () -> Void

    @State private var widths: [Int: CGFloat] = [:]
    @State private var pressedAt: Date?
    @State private var holdTask: Task<Void, Never>?
    @State private var travelled: CGFloat = 0
    /// True while a finger is on the row; resets on its own when the system cancels the touch (Control Center, a
    /// call, Siri, backgrounding), which never calls onEnded.
    @GestureState private var touching = false

    private static let holdDelay: Duration = .milliseconds(260)

    var body: some View {
        let current = Int(progress.rounded())
        let lensWord = lens.map { Int($0.rounded()) }
        VStack(spacing: Theme.Spacing.xs) {
            GeometryReader { proxy in
                let cell = proxy.size.width / CGFloat(max(titles.count, 1))
                ZStack(alignment: .leading) {
                    if let lens {
                        // The one Liquid Glass surface on the page: the navigation layer.
                        let index = Int(lens.rounded())
                        let width = (widths[index] ?? 60) * 1.12 + 20
                        Capsule()
                            .fill(.clear)
                            .frame(width: width, height: 40)
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .offset(x: cell * (CGFloat(lens) + 0.5) - width / 2)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                    HStack(spacing: 0) {
                        ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                            word(title, at: index, lit: index == (lensWord ?? current), swollen: lensWord == index,
                                 selected: index == current)
                        }
                    }
                }
                .frame(height: 44)
                .contentShape(Rectangle())
                .gesture(touch(cell: cell))
                .onChange(of: touching) { _, down in
                    // A touch that ended without onEnded (cancelled): let go of everything.
                    guard !down, pressedAt != nil else { return }
                    holdTask?.cancel()
                    pressedAt = nil
                    if lens != nil {
                        onCancel()
                    }
                }
            }
            .frame(height: 44)
            .tesseraAnimation(Theme.Motion.snappy, value: current)
            .tesseraAnimation(.spring(response: 0.2, dampingFraction: 0.8), value: lensWord)
            .tesseraAnimation(.spring(response: 0.32, dampingFraction: 0.72), value: lens == nil)

            GeometryReader { proxy in
                let cell = proxy.size.width / CGFloat(max(titles.count, 1))
                // A thin ink carriage at rest; it turns live only while the pages move (ink-line.md). It fades while
                // the lens is up.
                let paging = abs(progress - progress.rounded()) > 0.01
                Rectangle()
                    .fill(paging ? Theme.Colors.live : Theme.Colors.ink)
                    .frame(width: HomeStroke.carriage.width, height: HomeStroke.carriage.height)
                    .offset(x: cell * (CGFloat(progress) + 0.5) - HomeStroke.carriage.width / 2)
                    .opacity(lens == nil ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: paging)
                    .animation(.easeOut(duration: 0.28), value: lens == nil)
            }
            .frame(height: HomeStroke.carriage.height)
            .accessibilityHidden(true)
        }
    }

    private func word(_ title: String, at index: Int, lit: Bool, swollen: Bool, selected: Bool) -> some View {
        let traits: AccessibilityTraits = selected ? [.isButton, .isSelected] : .isButton
        return Text(title)
            .textRole(.label)
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(lit ? Theme.Colors.ink : Theme.Colors.muted)
            .scaleEffect(swollen ? 1.12 : 1)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[index] = $0 }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel(title)
            .accessibilityAddTraits(traits)
            .accessibilityAction { onSelect(index) }
    }

    /// One touch: a quick tap selects the word; held 260 ms it becomes the lens and slides.
    private func touch(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                let position = min(max(Double(value.location.x / cell - 0.5), 0), Double(titles.count - 1))
                if pressedAt == nil {
                    pressedAt = .now
                    travelled = 0
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(for: Self.holdDelay)
                        guard !Task.isCancelled, travelled < 10 else { return }
                        onHold(position)
                    }
                }
                travelled = max(travelled, abs(value.translation.width), abs(value.translation.height))
                if lens != nil {
                    onSlide(position)
                }
            }
            .onEnded { value in
                holdTask?.cancel()
                defer { pressedAt = nil }
                if lens != nil {
                    onRelease()
                } else if travelled < 10 {
                    let index = Int((value.location.x / cell).rounded(.down))
                    onSelect(min(max(index, 0), titles.count - 1))
                }
            }
    }
}

// MARK: - Shared bits

/// Each page's hero travels at 70% of the page while paging (30% parallax). Reduce Motion: none.
private struct SiblingParallax: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.inHomeDeck) private var inDeck

    func body(content: Content) -> some View {
        // In the lens deck the pages are drawn outside the pager: no parallax.
        let amount: CGFloat = reduceMotion || inDeck ? 0 : 0.3
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

extension EnvironmentValues {
    /// True for the copies of Home's pages drawn in the tab lens deck.
    @Entry var inHomeDeck = false
}
