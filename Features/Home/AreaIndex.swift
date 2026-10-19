import SwiftUI
import TesseraCore

// Sheet 73 A, "No tab row: the index" (docs/design/area-index.md): the top of a tab page carries one word, the
// area's name. Pull the page down past its top, or tap the name, and a glass sheet lists all four areas as 40 pt
// words with the live line each is holding; let go on a row (or tap one) and its word flies up into the name.

/// Each area's live line, from the sources Home already reads: at most 6 words and 32 characters, no stop.
@MainActor
enum AreaLines {
    static func lines(_ model: AppModel, now: Date, calendar: Calendar = .current) -> [HomeSpatialView.Page: String] {
        [.review: review(model, now: now, calendar: calendar), .today: today(model, now: now),
         .training: training(model, now: now), .kitchen: kitchen(model, now: now)]
    }

    /// "This week, 3 of 6 sessions".
    static func review(_ model: AppModel, now: Date, calendar: Calendar) -> String {
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let week = model.ledger.week(containing: now, plan: plan, now: now, sessionsPerWeek: perWeek,
                                     calendar: calendar)
        let done = week.reduce(0) { $0 + $1.done.count }
        guard let perWeek else { return capped("This week, \(done) \(done == 1 ? "session" : "sessions")") }
        return capped("This week, \(done) of \(perWeek) sessions")
    }

    /// Whatever the hero is holding: a running workout, else the current task, else the quiet line.
    static func today(_ model: AppModel, now: Date) -> String {
        let facts = HomeFacts(engine: model.engine)
        if model.session != nil, let process = model.processes.running(), let fact = facts.fact(process: process) {
            return capped(HomeLines.line(for: fact, now: now).hero)
        }
        if let task = model.currentTask(around: now) {
            return capped(taskTitle(task.title, id: task.id, model: model))
        }
        return "Nothing on"
    }

    /// "Push Day A is on": the routine on, or the one next; the quiet line when nothing is.
    static func training(_ model: AppModel, now: Date) -> String {
        if let session = model.session {
            return capped("\(session.shownTitle) is on")
        }
        if let workout = model.tonightWorkout(around: now) ?? model.todaysRoutine(now: now) {
            // Through the masking accessor: a private routine reads "Private workout".
            return capped("\(ObjectPrivacy.routineTitle(model.store.displayTitle(of: workout), in: model.store)) is on")
        }
        return "Nothing on"
    }

    /// "Tacos, 7 pm": tonight's cook; the quiet line when nothing is planned.
    static func kitchen(_ model: AppModel, now: Date) -> String {
        guard let recipeClass = model.classDef(.recipe) else { return "Nothing cooking tonight" }
        for item in model.schedule(around: now) {
            guard let task = model.object(item.id),
                  let recipe = model.store.linkedObjects("about", of: task).first(where: { object in
                      !object.isDeleted && object.classDef.map { ClassResolver.isSubclass($0, of: recipeClass) } == true
                  }) else { continue }
            let title = RecipeCopy.shownTitle(recipe.title, isPrivate: RecipeCopy.isPrivate(recipe.title, model: model))
            return capped("\(title), \(HouseTime.clock(item.start))")
        }
        return "Nothing cooking tonight"
    }

    /// A task's title as the room may see it: "Private task" for a private one.
    static func taskTitle(_ title: String, id: UUID, model: AppModel) -> String {
        guard let record = model.object(id) else { return title }
        return ObjectPrivacy.label(of: record, in: model.store, classes: model.classes) ?? title
    }

    /// The context cap: 6 words and 32 characters, whole words only.
    static func capped(_ text: String) -> String {
        var words = text.split(separator: " ").prefix(6).map(String.init)
        while words.count > 1, words.joined(separator: " ").count > 32 {
            words.removeLast()
        }
        let line = words.joined(separator: " ")
        return line.count > 32 ? String(line.prefix(32)) : line
    }
}

/// The one word at the top of a tab page: Label 15/700, +0.08 em, ink. It rolls 1:1 with the pager (up or down to the
/// next word) and is a button that opens the index.
struct AreaName: View {
    let titles: [String]
    let progress: Double
    let namespace: Namespace.ID
    /// Whether the index is open: the matched word then belongs to the sheet's row.
    let indexShown: Bool
    let current: Int
    /// Whether the word flies into place (off under Reduce Motion and Low Power: the word just swaps).
    let flies: Bool
    let onTap: () -> Void

    private let height: CGFloat = 22

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                ForEach(titles.indices, id: \.self) { index in
                    let distance = Double(index) - progress
                    word(titles[index], index: index)
                        .offset(y: CGFloat(distance) * height)
                        .opacity(max(0, 1 - abs(distance) * 1.4))
                }
            }
            .frame(height: height, alignment: .leading)
            .clipped()
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The bar word never outgrows its row at accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        // Read after the page's own front heading (focus lands there after a pick); still reachable by swipe.
        .accessibilitySortPriority(-1)
        .accessibilityLabel("\(titles[min(max(current, 0), titles.count - 1)]), area")
        .accessibilityHint("Double tap to show all areas")
    }

    @ViewBuilder
    private func word(_ title: String, index: Int) -> some View {
        let text = Text(title.uppercased())
            .textRole(.labelStrong)
            .tracking(1.2)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize()
        if index == current, flies {
            text.matchedGeometryEffect(id: "areaWord", in: namespace, isSource: !indexShown)
        } else {
            text
        }
    }
}

/// The glass sheet: from the top to 580 with 40 pt bottom corners, rows from 96, 104 pt apart, REVIEW, TODAY,
/// TRAINING, KITCHEN. The area you are in is ink, the others 42% ink, the one under the finger takes its area's
/// colour (72% mix, Today ink at weight 700) and scales to 1.06.
struct AreaIndexSheet: View {
    let titles: [String]
    let lines: [String]
    let current: Int
    /// 0 closed … 1 open.
    let progress: Double
    let picked: Int?
    let pulling: Bool
    /// Reduce Motion or Low Power: a 150 ms crossfade, with no drop, stagger or flight.
    let calm: Bool
    let namespace: Namespace.ID
    let onPick: (Int) -> Void
    let onClose: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    /// The areas you are not in rest at 42% ink, and at 70% under Increase Contrast.
    private var restInk: Double {
        contrast == .increased ? 0.7 : 0.42
    }

    static let height: CGFloat = 580
    static let firstRow: CGFloat = 96
    static let rowPitch: CGFloat = 104

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            glass
            VStack(spacing: 0) {
                ForEach(titles.indices, id: \.self) { index in
                    row(index)
                        .opacity(rowOpacity(index))
                }
                Spacer(minLength: 0)
                Text(pulling ? "Let go to open" : "Tap one to open")
                    .font(PageType.small)
                    .foregroundStyle(Theme.Colors.ink.opacity(restInk))
                    .frame(height: 52)
            }
            .padding(.top, Self.firstRow)
            .frame(height: Self.height, alignment: .top)
            .offset(y: calm ? 0 : -40 * (1 - progress))
        }
        .opacity(progress > 0.001 ? 1 : 0)
        .allowsHitTesting(progress > 0.9)
        // Closed, the rows are not read (opacity 0 alone leaves them in the accessibility tree).
        .accessibilityHidden(progress < 0.5)
        // VoiceOver's way out: closes without changing the area (HomeSpatialView returns focus to the bar word).
        .accessibilityAction(.escape, onClose)
    }

    private var glass: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40, style: .continuous)
            .fill(.clear)
            .glassEffect(.regular, in: UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40,
                                                              style: .continuous))
            .frame(height: Self.height)
            .ignoresSafeArea(edges: .top)
            .opacity(progress)
            .offset(y: calm ? 0 : -40 * (1 - progress))
    }

    /// Rows form with a 40 ms stagger as the sheet opens; Reduce Motion crossfades them together.
    private func rowOpacity(_ index: Int) -> Double {
        guard !calm else { return progress }
        return min(max((progress - 0.08 * Double(index)) / 0.6, 0), 1)
    }

    private func row(_ index: Int) -> some View {
        let isPicked = picked == index
        let isCurrent = current == index
        return Button { onPick(index) } label: {
            VStack(alignment: .leading, spacing: 4) {
                word(index, picked: isPicked, current: isCurrent)
                Text(lines.indices.contains(index) ? lines[index] : "")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink.opacity(isCurrent || isPicked ? 0.7 : restInk))
                    .lineLimit(1)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .frame(maxWidth: .infinity, minHeight: Self.rowPitch, alignment: .topLeading)
            .padding(.top, 16)
            .frame(height: Self.rowPitch, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(titles[index]), \(lines.indices.contains(index) ? lines[index] : "")")
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func word(_ index: Int, picked: Bool, current: Bool) -> some View {
        let color: Color = picked ? Self.areaColour(index) : Theme.Colors.ink.opacity(current ? 1 : restInk)
        let text = Text(titles[index].uppercased())
            .font(.system(size: 40, weight: picked && index == 1 ? .bold : .semibold))
            .tracking(-0.8)
            .foregroundStyle(color)
            .scaleEffect(picked ? 1.06 : 1, anchor: .leading)
            .tesseraAnimation(.spring(response: 0.25, dampingFraction: 0.8), value: picked)
        if picked, !calm {
            text.matchedGeometryEffect(id: "areaWord", in: namespace, isSource: true)
        } else {
            text
        }
    }

    /// Review violet, Today ink (cobalt is Tess's voice only), Training's colour, Kitchen's green; 72% with ink.
    static func areaColour(_ index: Int) -> Color {
        let ink = Theme.Colors.ink
        switch index {
        case 0: return ink.mix(with: Theme.Colors.context, by: 0.72)
        case 2: return ink.mix(with: Theme.Colors.training, by: 0.72)
        case 3: return ink.mix(with: Theme.Colors.health, by: 0.72)
        default: return ink
        }
    }
}

extension EnvironmentValues {
    /// Low Power, fed once at the root (RootView) from `PowerState.isLowPower` (App/PowerState.swift) so no second
    /// read of the system flag exists.
    @Entry var lowPowerMotion = false
}
