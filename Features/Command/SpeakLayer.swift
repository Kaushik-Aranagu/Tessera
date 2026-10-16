import SwiftUI

/// The Speak layer (speak.md): "Listening" in cobalt, the words as heard at Body 21 in inkSecondary and the bloom
/// breathing with the mic; then the voice ghost: the clean sentence, one cobalt line draining right to left, and the
/// Heard line. A refusal shows its line with the ink word that still works.
struct SpeakLayer: View {
    let listener: SpeechListener
    let ghost: (clean: String, heard: String)?
    let refusal: SpeechListener.Refusal?
    let drying: CGFloat
    let act: (SpeechListener.Refusal) -> Void
    let editGhost: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if let ghost {
                Text(ghost.clean)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle()
                    .fill(Theme.Colors.tess)
                    .frame(height: 2.5)
                    .scaleEffect(x: 1 - drying, anchor: .leading)
                Text("Heard: \(ghost.heard)")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(2)
            } else if let refusal {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(refusal.line)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                    Button(refusal.action) { act(refusal) }
                        .buttonStyle(.valueWash)
                        .font(Theme.voice)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Colors.ink)
                }
            } else {
                Text(listener.state == .asking ? "Tess needs the mic to hear you." : "Listening")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                Text(listener.heard)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: listener.heard)
                // The listening bloom: the soul's pigments breathing with the mic. A tap on it ends the listen.
                TessSoul(mode: .listening)
                    .scaleEffect(1.4 + listener.level * 0.15)
                    .animation(.easeOut(duration: 0.12), value: listener.level)
                    .frame(width: 64, height: 64)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { listener.stop(send: true) }
                    .accessibilityLabel("Stop listening")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture(perform: editGhost)
    }
}
