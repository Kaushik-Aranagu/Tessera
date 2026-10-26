import SwiftUI
import TesseraCore

/// Together round 13 (sheet 183, switch twinsV2): under Next, one ink line when two things look the same, with two ink
/// words. No accent, no card, no pill. Core finds the pair and refuses private, money and walled things; the guard
/// here asks the same question of both again.
enum TwinsOfferSwitch {
    static let choiceID = "twinsV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

struct TwinsOfferLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var joined = 0
    @State private var apart = 0

    var body: some View {
        let _ = model.revision
        if TwinsOfferSwitch.isOn, let offer = visibleOffer {
            VStack(alignment: .leading, spacing: 0) {
                Text(offer.sentence)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44, alignment: .leading)
                HStack(spacing: Theme.Spacing.l) {
                    Button("Join") { join(offer) }
                        .accessibilityHint("Joins the two into the older one")
                    Button("Keep apart") { keepApart(offer) }
                        .accessibilityHint("Never offers this pair again")
                }
                .buttonStyle(LandingInkLinkStyle())
            }
            .padding(.top, Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .transition(.opacity)
            .tesseraFeedback(.made, trigger: joined)
            .tesseraFeedback(.selection, trigger: apart)
        }
    }

    private var visibleOffer: TwinOffer? {
        guard let offer = Twins.next(engine: model.engine),
              let first = model.store.object(id: offer.keep), let second = model.store.object(id: offer.other),
              ObjectPrivacy.shownLabel(of: first, in: model.store, classes: model.classes) == nil,
              ObjectPrivacy.shownLabel(of: second, in: model.store, classes: model.classes) == nil
        else { return nil }
        return offer
    }

    private func join(_ offer: TwinOffer) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            guard let record = try? model.engine.perform(JoinTwins(keep: offer.keep, other: offer.other), by: .user)
                .record
            else { return }
            joined += 1
            TessVoice.shared.say("Joined", undo: record, holds: .seconds(600))
        }
    }

    private func keepApart(_ offer: TwinOffer) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            guard let record = try? model.engine.perform(KeepTwinsApart(first: offer.keep, second: offer.other),
                                                         by: .user).record
            else { return }
            apart += 1
            TessVoice.shared.say("Kept apart", undo: record)
        }
    }
}
