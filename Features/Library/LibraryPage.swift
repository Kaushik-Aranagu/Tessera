import SwiftUI
import TesseraCore

/// The Training library (Design 124, 129): Exercises | Workouts on a knob under the subtitle. Exercises are grouped
/// by the equipment he walks to, a row is a name and his last weight; Workouts are single sessions to try, a row is
/// a name and its time. A workout the place lacks the kit for stays in the list at 30% with one line saying why.
struct LibraryPage: View {
    /// Closes the library over Training.
    var close: () -> Void
    @Environment(AppModel.self) private var model

    enum Kind: String, CaseIterable, Hashable {
        case exercises = "Exercises", workouts = "Workouts"
    }

    enum Route: Hashable {
        case exercise(UUID)
        case workout(String)
    }

    @State private var kind: Kind = .exercises
    @State private var place = TrainingPlace.current()
    @State private var muscle: MuscleGroupWord?
    @State private var mineOnly = false
    @State private var group: ReadyWorkout.Group?
    @State private var triedOnly = false
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: close) {
                        Text("‹ Training")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Training")
                    .padding(.bottom, Theme.Spacing.m)
                    Text("Library")
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, Theme.Spacing.s)
                        .entrance(0, hero: true)
                    Text(subtitle)
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.context)
                        .padding(.bottom, Theme.Spacing.m)
                        .entrance(1)
                    knobs
                        .padding(.bottom, Theme.Spacing.m)
                    filters
                        .padding(.bottom, Theme.Spacing.l)
                    switch kind {
                    case .exercises: exercises
                    case .workouts: workouts
                    }
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, 180)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .background { ThemedBackground() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .onAppear { model.purgeStaleTried() }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .exercise(id):
                    if let classDef = model.classDef(id: id) {
                        ExercisePage(exercise: classDef)
                            .environment(\.pageBackTitle, "Library")
                    }
                case let .workout(id):
                    if let workout = ReadyWorkouts.workout(id: id) {
                        ReadyWorkoutPage(workout: workout, leave: close)
                    }
                }
            }
        }
    }

    // MARK: Header

    private var subtitle: String {
        "\(ExerciseLibrary.seeds.count + LibraryExtras.all.count) exercises, \(ReadyWorkouts.all.count) workouts"
    }

    private var knobs: some View {
        VStack(alignment: .leading, spacing: 0) {
            KnobWords(values: Kind.allCases, selection: $kind, word: \.rawValue,
                      spoken: "Library, \(kind.rawValue), adjustable")
            KnobWords(values: TrainingPlace.allCases, selection: $place, word: \.rawValue,
                      spoken: "Place, \(place.rawValue), adjustable")
                .onChange(of: place) { _, new in TrainingPlace.set(new) }
        }
    }

    private var filters: some View {
        WordFlow(spacing: Theme.Spacing.l) {
            switch kind {
            case .exercises:
                filterWord("Mine", isOn: mineOnly) { mineOnly.toggle() }
                filterWord("All", isOn: muscle == nil && !mineOnly) { muscle = nil; mineOnly = false }
                ForEach(MuscleGroupWord.allCases, id: \.self) { word in
                    filterWord(word.rawValue, isOn: muscle == word) { muscle = muscle == word ? nil : word }
                }
            case .workouts:
                // "Tried" is pinned first, in the hot colour: the ones he has tried before.
                filterWord("Tried", isOn: triedOnly, hot: true) { triedOnly.toggle() }
                filterWord("All", isOn: group == nil && !triedOnly) { group = nil; triedOnly = false }
                ForEach(ReadyWorkout.Group.allCases, id: \.self) { word in
                    filterWord(word.name, isOn: group == word) { group = group == word ? nil : word }
                }
            }
        }
    }

    private func filterWord(_ word: String, isOn: Bool, hot: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(word)
                .textRole(.label)
                .foregroundStyle(hot ? Theme.Colors.live.opacity(isOn ? 1 : 0.7) : Theme.Colors.ink
                    .opacity(isOn ? 1 : 0.5))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Exercises

    @ViewBuilder
    private var exercises: some View {
        let _ = model.revision
        let items = LibraryItems.all(model: model).filter { $0.matches(muscle) && (!mineOnly || $0.isMine) }
        if items.isEmpty {
            Text(mineOnly ? "Nothing here yet. Log a set and it shows up." : "Nothing matches.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.inkSecondary)
        } else {
            ForEach(LibraryItems.sections(items), id: \.equipment) { section in
                Text(TrainingPlace.word(section.equipment))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.xs)
                    .accessibilityAddTraits(.isHeader)
                ForEach(section.items) { item in
                    Button { open(item) } label: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(Theme.voice(size: 21).weight(.medium))
                                .foregroundStyle(Theme.Colors.ink
                                    .opacity(place.equipment.contains(item.equipment) ? 1 : 0.3))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Theme.Spacing.s)
                            Text(item.lastWeight.map { "last \(Format.kilograms($0))" } ?? "new")
                                .numeral(21, weight: .light)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                        .frame(minHeight: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Opens \(item.name)")
                }
            }
        }
    }

    private func open(_ item: LibraryItem) {
        if let classDef = item.classDef {
            path.append(.exercise(classDef.id))
        } else if let extra = item.extra,
                  let adopted = try? LibraryAdopter.adopt(extra, store: model.store, classes: model.classes)
        {
            model.touch()
            path.append(.exercise(adopted.id))
        }
    }

    // MARK: Workouts

    @ViewBuilder
    private var workouts: some View {
        let tried = Set(TriedHistory.ids())
        let list = ReadyWorkouts.search(group: group).filter { !triedOnly || tried.contains($0.id) }
        if list.isEmpty {
            Text("Nothing tried yet. Try one today and it shows here.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.inkSecondary)
        }
        ForEach(list, id: \.id) { workout in
            let reason = place.reason(for: workout)
            Button { path.append(.workout(workout.id)) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(workout.title)
                            .font(Theme.voice(size: 21).weight(.medium))
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: Theme.Spacing.s)
                        Text("\(workout.minutes) min".keepingUnits)
                            .numeral(21, weight: .regular)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    if let reason {
                        Text(reason)
                            .font(Theme.voice(size: 16))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(minHeight: 56, alignment: .leading)
                .opacity(reason == nil ? 1 : 0.3)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens \(workout.title)")
        }
    }
}
