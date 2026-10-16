import SwiftUI

/// Fields that take several lines keep Return as a newline, so one ink word above the keyboard ends the writing
/// (Kaushik, install 1: "no way to be done with the text"). No button shape: the label word, trailing.
struct KeyboardDoneWord: ViewModifier {
    let done: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done", action: done)
                    .buttonStyle(.labelWord)
                    .accessibilityHint("Puts the keyboard away.")
            }
        }
    }
}

extension View {
    func keyboardDoneWord(_ done: @escaping () -> Void) -> some View {
        modifier(KeyboardDoneWord(done: done))
    }
}
