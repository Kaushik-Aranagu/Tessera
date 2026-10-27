import SwiftUI
import TesseraCore

/// Similar from the exercise page (Design 129, 4): the exercises close to this one, in the same groups and words as the
/// live set's sheet. A row opens that exercise's page; swapping is for a live set, so there is no Swap in here. A row
/// the place lacks the kit for stays in the list at 30% with its reason.
struct SimilarExercisesSheet: View {
    let exercise: ClassDef
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let options = ExerciseSwaps(store: model.store, ledger: model.ledger)
            .options(for: exercise, from: 0, excludingWorkout: nil)
        let place = TrainingPlace.current()
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Similar")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.s)
                Text("Close to \(exercise.name)")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.bottom, Theme.Spacing.l)
                if options.isEmpty {
                    Text("Nothing close to this one yet")
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                ForEach([ExerciseSwaps.Group.family, .movement], id: \.self) { group in
                    let rows = options.filter { $0.group == group }
                    if !rows.isEmpty {
                        Text(SimilarSheet.title(group))
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.m)
                            .padding(.bottom, Theme.Spacing.xs)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(rows) { option in
                            row(option, place: place)
                        }
                    }
                }
                Button("Close") { dismiss() }
                    .buttonStyle(QuietWordStyle())
                    .padding(.top, Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.bottom, Theme.Spacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ option: ExerciseSwaps.Option, place: TrainingPlace) -> some View {
        let kit = model.store.equipmentKind(of: option.exercise)
        let reason: String? = kit.flatMap { kind in
            place.equipment.contains(kind) ? nil : "needs \(TrainingPlace.need(kind)); \(place.rawValue) has none"
        }
        let last = model.ledger.sessions(of: option.exercise).first.flatMap { $0.sets.map(\.weight).max() }
        return Button {
            dismiss()
            model.open(.classDef(option.exercise.id))
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(option.exercise.name)
                        .font(Theme.voice(size: 21).weight(.medium))
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Theme.Spacing.s)
                    Text(last.map { "last \(Format.mass($0))" } ?? "new")
                        .numeral(21, weight: .light)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                if let reason {
                    Text(reason)
                        .font(Theme.voice(size: 16))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minHeight: 50, alignment: .leading)
            .opacity(reason == nil ? 1 : 0.3)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .combine)
    }
}
