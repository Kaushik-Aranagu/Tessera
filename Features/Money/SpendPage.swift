import SwiftUI
import TesseraCore

/// One spend (ship list screen 6, sheet money-reading-grammar third panel): the amount as typed is the hero; one
/// context line, the word in ink then the day and the house clock ("lunch, Thu Oct 15, 1:10 pm"); the typed text and
/// the currency one level deeper as plain lines; what it's about (the shop, Groceries) as links; DELETE SPEND as an
/// ink-line word with a 10 s UNDO. Its own page, so the amount shows here even though a spend is masked everywhere
/// else (Money amendment 2). The word edits in place, never a form.
struct SpendPage: View {
    let spendID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing = false
    @State private var word = ""
    @FocusState private var wordFocused: Bool

    var body: some View {
        let _ = model.revision
        Group {
            if let spend = model.object(spendID), !spend.isDeleted {
                page(spend)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    BackWord(title: "Money") { dismiss() }
                    Text("Spend gone.")
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { AreaTessLine() }
    }

    private func page(_ spend: ObjectRecord) -> some View {
        let store = model.store
        let typed = store.value("typed", of: spend)?.stringValue ?? spend.title
        let note = store.value("note", of: spend)?.stringValue ?? ""
        let currency = store.value("currency", of: spend)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        let spentAt = store.value("spentAt", of: spend)?.dateValue ?? spend.createdAt
        let amount = MoneyAmount.parse(typed)?.amount ?? 0
        let about = store.linkedObjects("about", of: spend).filter { !$0.isDeleted }
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: "Money") { dismiss() }
                    .entrance(0)
                // The amount as the hero, its currency a small word that swipes to an "about" estimate (sheet 115).
                MeasureView(measure: .money(amount, currency: currency), size: Theme.concept.scale.hero.size,
                            weight: .medium)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0, hero: true)
                wordLine(note: note, spentAt: spentAt)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1)

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Typed as \(typed).")
                    Text(MoneyCopy.currencyLine(currency))
                }
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .padding(.top, Theme.Spacing.xl)
                .entrance(2)

                if !about.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("About")
                            .textRole(.labelStrong)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(about) { object in
                            let name = ObjectMask.label(of: object, in: store, classes: model.classes)
                                ?? store.displayTitle(of: object)
                            NavigationLink(value: Route.object(object.id)) {
                                Text(name)
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.ink)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(HandleButtonStyle())
                            .accessibilityLabel("Link, \(name)")
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(3)
                }

                Button(MoneyCopy.deleteName("spend")) { delete(spend) }
                    .buttonStyle(InkLabelWordStyle())
                    .frame(minHeight: 44)
                    .padding(.top, Theme.Spacing.xxl)
                    .accessibilityLabel(MoneyCopy.deleteName(spend.title))
                    .entrance(4)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }

    /// The word, a value word that edits in place, then the day and the clock in the context colour.
    @ViewBuilder
    private func wordLine(note: String, spentAt: Date) -> some View {
        let when = MoneyCopy.spendContext(note: "", spentAt: spentAt)
        if editing {
            TextField("", text: $word, prompt: Text("lunch").foregroundStyle(Theme.Colors.inkSecondary))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .focused($wordFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.never)
                .onSubmit { retag(note: note) }
                .onChange(of: wordFocused) { _, focused in
                    if !focused {
                        retag(note: note)
                    }
                }
                .frame(minHeight: 44)
                .accessibilityLabel("What it was for")
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Button {
                    word = note
                    editing = true
                    wordFocused = true
                } label: {
                    Text(note.isEmpty ? "Add a word" : note)
                        .textRole(note.isEmpty ? .body : .bodyStrong)
                        .foregroundStyle(note.isEmpty ? Theme.Colors.tess : Theme.Colors.ink)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.valueWash)
                .accessibilityLabel(note.isEmpty ? "Add a word" : "\(note), what it was for")
                .accessibilityHint("Edits the word")
                Text(", \(when)")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
            }
        }
    }

    /// "13.00 lunch with sam, changed." with UNDO 10 s (a change).
    private func retag(note: String) {
        guard editing else { return }
        editing = false
        let words = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard words != note else { return }
        guard let record = try? model.engine.perform(EditSpend(spend: spendID, note: words), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(record.receipt ?? "Spend, changed.", undo: record, holds: .seconds(10))
    }

    /// "12.40 lunch, deleted." with UNDO 10 s; the page folds back.
    private func delete(_ spend: ObjectRecord) {
        let title = spend.title
        guard let record = try? model.engine.perform(DeleteObject(object: spend.id), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(MoneyCopy.deleted(title), undo: record, holds: .seconds(10))
        dismiss()
    }
}
