import SwiftUI
import TesseraCore

// Ask the page (Design 166, behind the `askPageV2` Review switch, default Off): press a page's title and Tess answers
// one question about that object, "what is this, and what happened to it?", from Core's `Describe`, on the phone only.
// A walled object (private, or a class that can carry money, body or health values) answers "That stays on this phone."

enum AskPageSwitch {
    nonisolated static let choiceID = "askPageV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// What Tess says, pure so the rule is tested without drawing.
enum AskAnswer: Equatable {
    case stays
    case answer(sentence: String, story: [String], changes: Int)

    static let staysWords = "That stays on this phone"

    /// A private object, or one Describe has no sentence for (money, body, health), stays on the phone. Otherwise the
    /// sentence, then what changed (newest first) and how many changes there are in all.
    static func make(sentence: String?, isPrivate: Bool, story: [String], changes: Int) -> AskAnswer {
        guard !isPrivate, let sentence, !sentence.isEmpty else { return .stays }
        return .answer(sentence: sentence, story: story, changes: changes)
    }

    /// "1 change", "3 changes".
    static func changesWords(_ count: Int) -> String {
        "\(count) \(count == 1 ? "change" : "changes")"
    }
}

/// Press the title (the header) and the answer opens as a sheet in Tess's voice.
struct AskPageHook: ViewModifier {
    let object: ObjectRecord
    @Environment(AppModel.self) private var model
    @State private var asking = false

    func body(content: Content) -> some View {
        if AskPageSwitch.isOn {
            content
                .onLongPressGesture(minimumDuration: 0.45) { asking = true }
                .accessibilityAction(named: "Ask Tess about this") { asking = true }
                .sheet(isPresented: $asking) {
                    AskSheet(answer: answer)
                        .presentationDetents([.medium])
                        .paperSheet()
                }
        } else {
            content
        }
    }

    private var answer: AskAnswer {
        let store = model.store
        let isPrivate = ObjectPrivacy.shownLabel(of: object, in: store, classes: model.classes) != nil
        let sentence = Describe.sentence(object, in: store, classes: model.classes)
        let lines = Describe.story(object, engine: model.engine, calendar: .current, now: AppClock.now).map(\.text)
        let count = Describe.storyCount(object, engine: model.engine)
        return AskAnswer.make(sentence: sentence, isPrivate: isPrivate, story: lines, changes: count)
    }
}

private struct AskSheet: View {
    let answer: AskAnswer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                switch answer {
                case .stays:
                    Text(AskAnswer.staysWords)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                case let .answer(sentence, story, changes):
                    Text(sentence)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                    if !story.isEmpty {
                        Text(AskAnswer.changesWords(changes))
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .padding(.top, Theme.Spacing.s)
                        ForEach(story, id: \.self) { line in
                            Text(line)
                                .textRole(.body)
                                .foregroundStyle(Theme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
    }
}
