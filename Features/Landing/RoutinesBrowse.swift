import SwiftUI
import TesseraCore

/// Routines: Browse, the index (Design 131 §2c), a rail page in the rose on the shared `RailPage`. Today is pinned
/// above the dial; the dial turns through the time of day he runs a routine (Morning, Midday, Evening, Night, Any
/// time); the knob at the right of the title is Kind (All, Daily, Workouts) and is remembered. A row is a routine's
/// name and one plain value. Tap opens the routine, swipe right starts it (Pick up when it already runs), a hold
/// shows its details. Writing is never in the rail: "New routine" is the one word at the foot, in plain ink.
struct RoutinesBrowsePage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        RoutinesRail(front: RoutinesFront(model: model, now: AppClock.now))
            .background { ThemedBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .background { EdgeSwipeBack() }
    }
}

private extension BrowseKind {
    /// Daily is a routine with a usual time; Workouts is Training's routines (every routine today). A routine may sit
    /// in All and in its kind; the kind never holds places.
    func includes(_ item: RoutinesFront.Item) -> Bool {
        switch self {
        case .all, .workouts: true
        case .daily: item.usual != nil
        }
    }
}

private struct RoutinesRail: View {
    let front: RoutinesFront
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("routines.browse.kind") private var kindRaw = BrowseKind.all.rawValue
    @State private var open: String
    @State private var haptic = HapticCue()
    @State private var detail: RoutineDetailTarget?

    init(front: RoutinesFront) {
        self.front = front
        // Opens on Today when anything is left today, else on the place of the next usual start.
        let kind = BrowseKind(rawValue: UserDefaults.standard.string(forKey: "routines.browse.kind") ?? "") ?? .all
        _open = State(initialValue: Self.opening(front, kind: kind).rawValue)
    }

    private var kind: BrowseKind {
        BrowseKind(rawValue: kindRaw) ?? .all
    }

    private var shown: [RoutinesFront.Item] {
        front.items.filter { kind.includes($0) }
    }

    var body: some View {
        RailPage(
            title: "Routines",
            subtitle: { _ in "Your routines, by the time you run them." },
            back: (title: cameFrom, action: { dismiss() }),
            titleTrailing: AnyView(knob),
            pinned: place(.today),
            accent: RoutinesFront.accent,
            places: RoutinePlace.dial.map(place),
            open: $open,
            sectionStyle: .none,
            sections: { id in
                [.init(label: nil, rows: items(in: RoutinePlace(rawValue: id) ?? .anyTime))]
            },
            empty: { RoutinesLandingWords.nothingIn(RoutinePlace(rawValue: $0) ?? .anyTime) },
            row: row
        )
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
            Button(RoutinesLandingWords.newRoutine) {
                // Making a routine lives on the plan's routines page today (its editor, reorder and drop).
                if let plan = model.plan {
                    model.open(.routines(plan.id))
                }
            }
            .buttonStyle(LandingWordStyle())
            .padding(.leading, Theme.Spacing.gutter)
            .accessibilityHint("Opens the routines page to make one")
        }
        .tesseraFeedback(haptic)
        .sheet(item: $detail) { target in
            RoutineDetailSheet(id: target.id)
                .presentationDetents([.medium])
        }
    }

    // MARK: Places

    private func place(_ place: RoutinePlace) -> RailPlace {
        RailPlace(id: place.rawValue, name: place.rawValue, count: items(in: place).count)
    }

    private func items(in place: RoutinePlace) -> [RoutinesFront.Item] {
        if place == .today {
            return front.todayIDs.compactMap { id in shown.first { $0.id == id } }
        }
        return shown.filter { $0.place == place }.sorted {
            ($0.usual?.startMinuteOfDay ?? 1440, $0.name) < ($1.usual?.startMinuteOfDay ?? 1440, $1.name)
        }
    }

    private static func opening(_ front: RoutinesFront, kind: BrowseKind) -> RoutinePlace {
        let shown = front.items.filter { kind.includes($0) }
        if front.todayIDs.contains(where: { id in shown.contains { $0.id == id } }) {
            return .today
        }
        let minute = RoutinesLandingWords.minuteOfDay(front.now)
        let next = shown.compactMap { item in item.usual.map { (item, ($0.startMinuteOfDay - minute + 1440) % 1440) } }
            .min { $0.1 < $1.1 }
        if let next {
            return next.0.place
        }
        return RoutinePlace.dial.first { place in shown.contains { $0.place == place } } ?? .morning
    }

    private var cameFrom: String {
        guard model.path.count >= 2 else { return "Routines" }
        return model.title(of: model.path[model.path.count - 2])
    }

    // MARK: Rows

    private func row(_ item: RoutinesFront.Item) -> some View {
        let runningHere = front.running?.routineID == item.id
        return StartSwipeRow(
            startWord: runningHere ? RoutinesLandingWords.pickUp : "Start",
            accent: RoutinesFront.accent,
            onStart: { start(item) },
            onOpen: { model.open(.object(item.id)) },
            onDetail: { detail = RoutineDetailTarget(id: item.id) }
        ) {
            // At accessibility sizes the value moves under the name; nothing is cut.
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
            layout {
                Text(item.name)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: Theme.Spacing.s)
                }
                Text(item.railValue)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.railValue)")
        .accessibilityHint("Opens \(item.name)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: runningHere ? RoutinesLandingWords.pickUp : "Start") { start(item) }
        .accessibilityAction(named: "Details") { detail = RoutineDetailTarget(id: item.id) }
    }

    private func start(_ item: RoutinesFront.Item) {
        if RoutinesStarter.start(item, running: front.running, model: model) {
            haptic.play(.pickedUp)
        }
    }

    // MARK: The knob

    /// Kind sits at the right of the title: tap turns it, a sideways swipe turns it either way. Placed beside the
    /// RailPage title (a back word row of 44 pt, then the title).
    private var knob: some View {
        Button {
            turn(kind.next)
        } label: {
            Text(kind.rawValue)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .contentTransition(.opacity)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .pageSwipe { next in turn(next ? kind.next : kind.previous) }
        .accessibilityLabel("Kind, \(kind.rawValue)")
        .accessibilityHint("Changes which routines show")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: turn(kind.next)
            case .decrement: turn(kind.previous)
            @unknown default: break
            }
        }
    }

    private func turn(_ next: BrowseKind) {
        haptic.play(.selection)
        withTesseraAnimation(reduceMotion: reduceMotion) { kindRaw = next.rawValue }
    }
}
