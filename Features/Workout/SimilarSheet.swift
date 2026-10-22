import SwiftUI
import TesseraCore

/// Similar (Design 129, 4): the exercises close to the one in hand, for when it is busy. Groups in words, "Same
/// muscles, same pattern" then "Near"; a row is the name and his last weight ("last 30") or "new". A row the place
/// lacks the kit for, or that is marked busy, stays in the list at 30%. Pick one, then "Swap in" changes the routine
/// (with Undo) or "Just today" changes this session only. No muscle figure.
struct SimilarSheet: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var picked: UUID?

    var body: some View {
        let _ = model.revision
        let options = session.swapOptions()
        let place = TrainingPlace.current()
        let busy = session.busyExerciseIDs
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Similar")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.s)
                Text("Instead of \(session.currentExercise?.name ?? "this")")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.bottom, Theme.Spacing.l)
                if options.isEmpty {
                    Text("Nothing close to this one yet.")
                        .font(Theme.voice(size: 21))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                ForEach([ExerciseSwaps.Group.family, .movement], id: \.self) { group in
                    let rows = options.filter { $0.group == group }
                    if !rows.isEmpty {
                        Text(Self.title(group))
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.m)
                            .padding(.bottom, Theme.Spacing.xs)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(rows) { option in
                            row(option, place: place, busy: busy)
                        }
                    }
                }
                if let option = options.first(where: { $0.id == picked }) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text(startLine(option))
                            .font(Theme.voice(size: 21))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: Theme.Spacing.xl) {
                            Button("Swap in") { swap(option, forRoutine: true) }
                                .buttonStyle(HotWordStyle())
                            Button("Just today") { swap(option, forRoutine: false) }
                                .buttonStyle(QuietWordStyle())
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    static func title(_ group: ExerciseSwaps.Group) -> String {
        switch group {
        case .family: "Same muscles, same pattern"
        case .movement: "Near"
        }
    }

    private func row(_ option: ExerciseSwaps.Option, place: TrainingPlace, busy: Set<UUID>) -> some View {
        let kit = model.store.equipmentKind(of: option.exercise)
        let lacks = kit.map { !place.equipment.contains($0) } ?? false
        let faded = lacks || busy.contains(option.exercise.id)
        return Button {
            picked = option.id
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(option.exercise.name)
                    .font(Theme.voice(size: 21).weight(picked == option.id ? .semibold : .medium))
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Theme.Spacing.s)
                Text(lastWord(option))
                    .numeral(21, weight: .light)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .frame(minHeight: 50)
            .opacity(faded ? 0.3 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(picked == option.id ? .isSelected : [])
    }

    /// "last 30", or "new" when he has never done it.
    private func lastWord(_ option: ExerciseSwaps.Option) -> String {
        let last = model.ledger.sessions(of: option.exercise).first.flatMap { $0.sets.map(\.weight).max() }
        return last.map { "last \(Format.kilograms($0))" } ?? "new"
    }

    /// Where the swapped exercise starts: its own last weight, or a light guess marked "about".
    private func startLine(_ option: ExerciseSwaps.Option) -> String {
        guard let load = option.load else { return "\(option.exercise.name) starts where you set it." }
        return option.isEstimate
            ? "Starts at about \(Format.kilograms(load))."
            : "Starts at \(Format.kilograms(load)), where you left it."
    }

    /// "Swap in" changes the routine's slot as well as today (one Undo takes back both); "Just today" is this
    /// session only.
    private func swap(_ option: ExerciseSwaps.Option, forRoutine: Bool) {
        guard let entry = session.currentEntry, let from = session.currentExercise else { return }
        let slot = model.store.linkedObjects("slot", of: entry).first
        var records: [OpRecord] = []
        if forRoutine, let slot,
           let result = try? model.engine.perform(SwapSlotExercise(slot: slot.id, exercise: option.exercise.id),
                                                  by: .user)
        {
            records.append(result.record)
        }
        if let record = session.swap(to: option) {
            records.append(record)
        }
        let words = forRoutine && records.count > 1
            ? "\(option.exercise.name) is in for \(from.name)."
            : "\(option.exercise.name) today, instead of \(from.name)."
        model.touch()
        TessVoice.shared.say(words, takeBack: { [model] in
            for record in records.reversed() {
                model.engine.undo(record)
            }
            session.refreshAfterExternalWrite()
            model.touch()
        })
        dismiss()
    }
}
