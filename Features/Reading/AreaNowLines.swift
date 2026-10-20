import SwiftUI
import TesseraCore

/// The quiet lines Money and Reading put on Now, under the hero, only when areas are shown. Each is Tess-initiated,
/// so it follows Core's quiet hours and makes no sound or haptic of its own (amendment 5):
/// - the evening slot (7 pm to 11 pm, nothing running, no timed item current): "Dune, p 142" with RESUME, from
///   `Bookshelf.eveningPick`. A tap resumes the book's process and opens its page at the drum.
/// - "Groceries total?" while Core's `ShopReceipt.nowPrompt` allows it (not 23:00 to 07:00, nothing running).
struct AreaNowLines: View {
    let now: Date
    /// A task is happening now (its start passed, its end not yet).
    let timedItemCurrent: Bool
    /// Books already shown by the ledger above, so a book never shows twice.
    let shownSubjects: Set<UUID>
    @Environment(AppModel.self) private var model

    /// The book the evening slot offers, or nil.
    @MainActor
    static func evening(model: AppModel, now: Date, timedItemCurrent: Bool, shownSubjects: Set<UUID>,
                        calendar: Calendar = .current) -> (book: ObjectRecord, line: String, spoken: String)?
    {
        guard AreasShown.isOn else { return nil }
        let shelf = Bookshelf(store: model.store, classes: model.classes)
        guard let pick = shelf.eveningPick(at: now, calendar: calendar,
                                           somethingRuns: model.processes.running() != nil,
                                           timedItemCurrent: timedItemCurrent),
            !shownSubjects.contains(pick.book.id) else { return nil }
        let isPrivate = ObjectPrivacy.label(of: pick.book, in: model.store, classes: model.classes) != nil
        let page = shelf.page(of: pick.book)
        return (pick.book, ReadingCopy.resumeLine(title: pick.book.title, page: page, isPrivate: isPrivate),
                ReadingCopy.spokenResume(title: pick.book.title, page: page, isPrivate: isPrivate))
    }

    var body: some View {
        let _ = model.revision
        let evening = Self.evening(model: model, now: now, timedItemCurrent: timedItemCurrent,
                                   shownSubjects: shownSubjects)
        let total = AreasShown.isOn && ShopReceipt(store: model.store, classes: model.classes)
            .nowPrompt(at: now, somethingRuns: model.processes.running() != nil) != nil
        if evening != nil || total {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if let evening {
                    Button { resume(evening.book) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                            Text(evening.line)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Theme.Spacing.m)
                            Text("Resume")
                                .textRole(.labelStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(evening.spoken)
                    .accessibilityHint("Opens the book at its page")
                    .transition(.opacity)
                }
                if total {
                    ShopTotalLine()
                }
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    /// RESUME: the book's process runs, and its page opens at the drum. A refusal ("Workout running.") is said by
    /// the model and the page still opens.
    private func resume(_ book: ObjectRecord) {
        if let process = model.processes.process(for: book) {
            model.resume(process)
        }
        model.open(.object(book.id))
    }
}
