import SwiftUI
import TesseraCore

/// The first launch's rest day, "Sunday, rest day.", in Tess's band with UNDO for 4 s (Design on Core's #641): he
/// didn't just do something, so no haptic, and never over a live workout (it waits until the workout ends).
struct RestReceipt: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content
            .onAppear(perform: show)
            .onChange(of: model.session == nil) { show() }
    }

    private func show() {
        guard let op = model.restReceipt, model.session == nil else { return }
        model.restReceipt = nil
        let weekday = RestWeekday.current(in: model.store) ?? RestWeekday.sunday
        TessVoice.shared.say(RestWeekday.receipt(for: weekday), undo: op, holds: .seconds(4))
    }
}
