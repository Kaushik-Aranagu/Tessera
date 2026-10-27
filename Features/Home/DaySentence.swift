import SwiftUI
import TesseraCore

/// The day sentence (sheet 135 part 1): Core's HomeSentence clauses as one paragraph at the title step, wrapping,
/// never cut. Each clause's key word is in its app's accent and the rest is ink; a tap on a key word opens what it
/// names (the object, or the app). Money says only what is due, never an amount; private things read "Private
/// workout" or "Private recipe" (Core masks them before they reach here). Behind Review › Together › Day sentence.
struct DaySentence: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openHomeLink) private var openLink

    var body: some View {
        let _ = model.revision
        let clauses = HomeSentence.compose(HomeSentence.inputs(engine: model.engine,
                                                               plan: model.plan,
                                                               now: AppClock.now))
        // Sheet 139 part 5: "3 done today." in plain ink after the clauses; a quiet day gives way to it.
        let doneToday = FinishMoments.isOn
            ? FinishMoments.tasksClause(
                done: TaskList(store: model.store, classes: model.classes).todayCounts(AppClock.now).done
            ) : nil
        let words = clauses.isEmpty && doneToday != nil ? [] : Self.words(clauses)
        // Words flow as a paragraph; a key word is its own door (a link inside one Text can only take one colour).
        LandingWrap(spacing: 7, lineSpacing: 2) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                if let index = word.clause, let app = word.app {
                    Button { open(clauses[index]) } label: {
                        Text(word.text).foregroundStyle(app.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(word.text).foregroundStyle(Theme.Colors.ink)
                }
            }
            if let doneToday {
                ForEach(Array(doneToday.split(separator: " ").enumerated()), id: \.offset) { _, word in
                    Text(String(word)).foregroundStyle(Theme.Colors.ink)
                }
            }
        }
        .textRole(.title)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([clauses.isEmpty && doneToday != nil ? nil : HomeSentence.text(clauses), doneToday]
            .compactMap(\.self).joined(separator: ". "))
        .accessibilityActions {
            ForEach(Array(clauses.enumerated()), id: \.offset) { _, clause in
                if let range = clause.keyWord {
                    Button((clause.text as NSString).substring(with: NSRange(location: range.lowerBound,
                                                                             length: range.count)))
                    {
                        open(clause)
                    }
                }
            }
        }
    }

    /// The paragraph as words: a word inside a clause's key word carries the clause and its app.
    struct Word {
        let text: String
        let clause: Int?
        let app: HomeApp?
    }

    static func words(_ clauses: [HomeSentence.Clause]) -> [Word] {
        guard !clauses.isEmpty else {
            return HomeSentence.quietDay.split(separator: " ").map { Word(text: String($0), clause: nil, app: nil) }
        }
        var words: [Word] = []
        for (index, clause) in clauses.enumerated() {
            var offset = 0
            for part in clause.text.split(separator: " ", omittingEmptySubsequences: false) {
                let length = part.utf16.count
                let inKey = clause.keyWord.map { $0.overlaps(offset ..< offset + max(length, 1)) } ?? false
                if !part.isEmpty {
                    let app = inKey ? clause.app.flatMap(HomeApp.init(appID:)) : nil
                    words.append(Word(text: String(part), clause: app == nil ? nil : index, app: app))
                }
                offset += length + 1
            }
        }
        return words
    }

    private func open(_ clause: HomeSentence.Clause) {
        Self.open(clause, model: model, openLink: openLink)
    }

    /// What a clause's key word opens; shared with the mosaic page's sentence lines.
    static func open(_ clause: HomeSentence.Clause, model: AppModel, openLink: (HomeLink) -> Void) {
        switch clause.opens {
        case let .object(id):
            model.path.append(Route.object(id))
        case let .app(app):
            switch HomeApp(appID: app) {
            case .kitchen: openLink(.recipes)
            case .money: openLink(.money)
            case .notes: openLink(.notes)
            case .lists: openLink(.lists)
            default: break
            }
        }
    }
}

extension HomeApp {
    init?(appID: AppID) {
        switch appID {
        case .training: self = .training
        case .kitchen: self = .kitchen
        case .money: self = .money
        case .notes: self = .notes
        case .lists: self = .lists
        case .routines: self = .routines
        }
    }
}
