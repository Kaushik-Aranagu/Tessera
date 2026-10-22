import SwiftUI

private typealias Paint = WorkoutPaint

/// Typing a weight in place (docs/design/audit-build-1.md, row 1): the 72 Light numeral becomes the field, a cobalt
/// writing line draws out under it, and Tess's context line sits below. Return or SET commits, leaving the field
/// commits too, and the numeral then rolls to the nearest weight the gym can load.
struct WeightField: View {
    @Binding var weight: Double
    /// Every loadable weight, ascending.
    let detents: [Double]
    let unit: String
    @Binding var isTyping: Bool
    /// "81 isn't loadable; 80", shown for 2 s under the numeral after a snap.
    var onSnapped: (String) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var text = ""
    @State private var lineDrawn = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("", text: $text, prompt: Text(Format.kilograms(weight)).foregroundStyle(Paint.secondary))
                    .numeral(80)
                    .foregroundStyle(Paint.cream)
                    .tint(Paint.cobalt)
                    .keyboardType(.decimalPad)
                    .submitLabel(.done)
                    .focused($focused)
                    .onSubmit(commit)
                    .fixedSize()
                    .overlay(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Paint.cobalt)
                            .frame(height: 1.5)
                            .scaleEffect(x: lineDrawn ? 1 : 0, anchor: .leading)
                            .offset(y: 4)
                    }
                    .accessibilityLabel("Weight in kilograms")
                Text(unit).font(Theme.voice).foregroundStyle(Paint.secondary).fixedSize()
                Button("Set", action: commit)
                    .buttonStyle(.labelWord(Paint.cobalt))
                    .fixedSize()
            }
            Text("Goes to the nearest weight the gym can load.")
                .font(Theme.voice)
                .foregroundStyle(Paint.tess)
        }
        .onAppear {
            // Empty, with the current weight as the prompt: the first digit starts the new number.
            text = ""
            focused = true
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { lineDrawn = true }
        }
        .onChange(of: focused) { _, isFocused in
            if !isFocused, isTyping {
                commit()
            }
        }
    }

    private func commit() {
        let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        // Nearest load; a tie goes lighter (Core's snap order: detents ascend).
        if let typed = Double(cleaned), let nearest = detents.min(by: { abs($0 - typed) < abs($1 - typed) }) {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { weight = nearest }
            if abs(nearest - typed) > 0.001 {
                onSnapped("\(Format.kilograms(typed)) isn't loadable; \(Format.kilograms(nearest))")
            }
        }
        focused = false
        withTesseraAnimation(reduceMotion: reduceMotion) { isTyping = false }
    }
}
