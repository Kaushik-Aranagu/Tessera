import SwiftUI
import TesseraCore

/// Three sibling views of the same exercise on x — HISTORY · REP MAXES · MUSCLES — with the painted carriage under
/// the active one, over a bounded window that fades at the bottom. The window claims horizontal swipes only inside
/// its own frame; each view scrolls vertically inside it.
struct ExerciseViews: View {
    enum Sibling: Int, CaseIterable, Identifiable {
        case history, repMaxes, muscles

        var id: Int {
            rawValue
        }

        var title: String {
            switch self {
            case .history: "History"
            case .repMaxes: "Rep maxes"
            case .muscles: "Muscles"
            }
        }
    }

    let digest: ExerciseDigest

    /// The view left open on each exercise this session (spatial memory).
    @MainActor private static var remembered: [UUID: Int] = [:]

    @State private var position = ScrollPosition(idType: Int.self)
    @State private var progress: Double = 0
    /// Bumped per view each time it becomes the active one, so its rows rise in again.
    @State private var arrivals: [Int: Int] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            CarriageRail(titles: Sibling.allCases.map(\.title), progress: progress) { show($0) }

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Sibling.allCases) { sibling in
                        page(sibling)
                            .containerRelativeFrame(.horizontal)
                            .id(sibling.rawValue)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition($position)
            .onScrollGeometryChange(for: Double.self) { geometry in
                geometry.containerSize.width > 0 ? geometry.contentOffset.x / geometry.containerSize.width : 0
            } action: { _, new in
                progress = new
            }
            .onChange(of: position.viewID(type: Int.self)) { _, new in
                guard let new else { return }
                Self.remembered[digest.exercise.id] = new
                arrivals[new, default: 0] += 1
            }
            .onAppear {
                let start = Self.remembered[digest.exercise.id] ?? 0
                position.scrollTo(id: start)
                progress = Double(start)
            }
            .fadesAtBottom()
        }
    }

    @ViewBuilder
    private func page(_ sibling: Sibling) -> some View {
        let token = arrivals[sibling.rawValue] ?? 0
        ScrollView(.vertical) {
            switch sibling {
            case .history: HistoryList(rows: digest.history, token: token)
            case .repMaxes: RepMaxGrid(maxes: digest.repMaxes, token: token)
            case .muscles: MuscleList(rows: digest.muscles, token: token)
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 40, for: .scrollContent)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(sibling.title)
    }

    private func show(_ index: Int) {
        withTesseraAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.3), reduceMotion: reduceMotion) {
            position.scrollTo(id: index)
        }
    }
}

// MARK: - History

/// One 52 pt row per session: the date, the session's sets as small brushstrokes, and the top set. Each row is a
/// handle back to that workout.
private struct HistoryList: View {
    let rows: [ExerciseDigest.HistoryRow]
    let token: Int
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        if rows.isEmpty {
            Text("No sessions yet. The first set you log starts the history.")
                .font(PageType.small)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Theme.Spacing.s)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Button { model.open(.object(row.workoutID)) } label: { label(row) }
                        .buttonStyle(HandleButtonStyle())
                        .modifier(ZoomSource(id: Route.object(row.workoutID), namespace: namespace))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(spoken(row))
                        .accessibilityHint("Opens that workout")
                        .accessibilityAddTraits(.isButton)
                        .riseIn(index, token: token)
                }
            }
        }
    }

    private func label(_ row: ExerciseDigest.HistoryRow) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(ExerciseWords.historyDate(row.date, now: AppClock.now, calendar: .current,
                                           zone: OpZones(store: model.store).zone(of: row.workoutID)))
                .font(PageType.small)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(width: 92, alignment: .leading)
            SetStrokes(count: row.setCount)
            Spacer(minLength: Theme.Spacing.s)
            Text(row.topSet)
                .font(Theme.numeral(21, weight: .regular))
                .foregroundStyle(Theme.Colors.ink)
                .glintOnce(row.isRecord)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func spoken(_ row: ExerciseDigest.HistoryRow) -> String {
        let date = ExerciseWords.historyDate(row.date, now: AppClock.now, calendar: .current,
                                             zone: OpZones(store: model.store).zone(of: row.workoutID))
        let sets = row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
        let top = row.topSet.replacingOccurrences(of: "×", with: "by")
        return "\(date), \(sets), top set \(top)" + (row.isRecord ? ", your best" : "")
    }
}

/// One 30 × 12 brushstroke per set, cycling vermilion, cobalt, cadmium, sage.
private struct SetStrokes: View {
    let count: Int

    var body: some View {
        let paints = [Theme.Colors.live, Theme.Colors.tess, Theme.Colors.now, Theme.Colors.health]
        HStack(spacing: 5) {
            ForEach(0 ..< min(count, 8), id: \.self) { index in
                Brushstroke()
                    .stroke(paints[index % paints.count], style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 30, height: 12)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Rep maxes

/// 1RM to 10RM in a 5 × 2 grid (2 columns at accessibility sizes), and the honest-e1RM note under it.
private struct RepMaxGrid: View {
    let maxes: [Int: Double]
    let token: Int
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.s, alignment: .leading),
                            count: typeSize.isAccessibilitySize ? 2 : 5)
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(Array(TrainingLedger.repMaxRange), id: \.self) { reps in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(reps)RM").textRole(.label).foregroundStyle(Theme.Colors.inkSecondary)
                        Text(ObjectCopy.cell(maxes[reps].map { Format.kilograms($0) }))
                            .font(Theme.numeral(24, weight: .regular))
                            .foregroundStyle(maxes[reps] == nil ? Theme.Colors.inkTertiary : Theme.Colors.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(maxes[reps].map { "\(reps) rep max, \(Format.kilograms($0)) kilograms" }
                        ?? "\(reps) rep max, none yet")
                    .riseIn(reps - 1, token: token, stagger: 0.02)
                }
            }
            .padding(.top, 6)

            Text("Warm-ups and sets over 12 reps don’t count here.")
                .font(PageType.small)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Muscles

/// One 56 pt row per muscle: a vermilion dab sized by role, the name, and the role in words. Each row links to the
/// muscle's page.
private struct MuscleList: View {
    let rows: [ExerciseDigest.MuscleRow]
    let token: Int
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if rows.isEmpty {
            Text("No muscles linked yet.")
                .font(PageType.small)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Theme.Spacing.s)
        } else {
            // Stopgap for the 196 pt MUSCLES window (Design): the figures pinned on the left, the rows scrolling on
            // their
            // own on the right, so neither hides the other.
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                figures
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            MuscleRowView(row: row, index: index).riseIn(index, token: token, stagger: 0.04)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .frame(height: Self.window)
        }
    }

    /// The MUSCLES window's height.
    private static let window: CGFloat = 196

    /// Both sides, side by side (no flip), about 70 pt wide and 150 tall each, pinned. VoiceOver reads them as one
    /// element.
    private var figures: some View {
        let muscles = rows.map { (name: $0.name, role: MuscleRole($0.role)) }
        let spoken = MuscleWords.works(rows.map(\.name))
        return HStack(spacing: Theme.Spacing.xs) {
            ForEach([false, true], id: \.self) { back in
                MuscleFigure(back: back, roles: MuscleFigureMap.roles(muscles, back: back),
                             onTap: { regionID in
                                 if let row = rows
                                     .first(where: { MuscleFigureMap.matches($0.name, regionID: regionID) })
                                 {
                                     model.open(.object(row.id))
                                 }
                             },
                             spoken: back ? "" : spoken)
                    .frame(width: 70, height: 154)
            }
        }
    }
}

private extension MuscleRole {
    init(_ role: ExerciseDigest.Role) {
        self = role == .primary ? .primary : .secondary
    }
}

private struct MuscleRowView: View {
    let row: ExerciseDigest.MuscleRow
    let index: Int
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        let primary = row.role == .primary
        Button { model.open(.object(row.id)) } label: {
            HStack(spacing: 0) {
                PaintDab(color: Theme.Colors.live,
                         size: primary ? CGSize(width: 30, height: 26) : CGSize(width: 22, height: 19),
                         seed: index)
                    .opacity(primary ? 1 : 0.7)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 0) {
                    Text(MuscleWords.shown(row.name))
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                    Text(ExerciseWords.role(row.role))
                        .font(PageType.small)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: Route.object(row.id), namespace: namespace))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(MuscleWords.shown(row.name)), \(ExerciseWords.role(row.role))")
        .accessibilityHint("Opens \(MuscleWords.shown(row.name))")
        .accessibilityAddTraits(.isButton)
    }
}
