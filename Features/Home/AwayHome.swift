import SwiftUI
import TesseraCore

/// Away (sheet 187, for the Oct 26-28 trip): an occasion he marks away quiets Home for its days. Today leads with the
/// trip's line ("Trip, day 2 of 3. Packing is done.") and Next and the plan step back. Never automatic: only his tap
/// on the occasion's page sets it, with Undo. Words only, never money. Behind Review › Home and live › "Away".
enum AwayHome {
    static let choiceID = "awayV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }
}

/// The word on an occasion's page that quiets Home for it, or brings Home back.
struct AwayWord: View {
    let occasion: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        let isAway = model.store.value("away", of: occasion) == .bool(true)
        Button(isAway ? "Home as usual" : "Quiet Home for this trip") { set(!isAway) }
            .buttonStyle(LandingWordStyle())
            .accessibilityHint(isAway ? "Home goes back to normal" : "Home shows only this trip on its days")
    }

    private func set(_ on: Bool) {
        guard let record = try? model.engine.perform(SetAway(occasion: occasion.id, on: on), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        TessVoice.shared.say(on ? "Home is quiet for the trip." : "Home as usual.", undo: record)
    }
}
