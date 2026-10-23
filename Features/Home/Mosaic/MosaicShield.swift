import SwiftUI

/// The frames of what must stay readable on Home (the sentence, the caption, the Next rows, the apps menu), in window
/// space. Builder A's mosaic layer caps the field behind each so the text never sits on bright pixels (sheet 202).
struct MosaicShieldKey: PreferenceKey {
    static let defaultValue: [CGRect] = []

    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value += nextValue()
    }
}

extension View {
    /// Reports this view's window-space frame as a text shield.
    func mosaicShield() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: MosaicShieldKey.self, value: [proxy.frame(in: .global)])
            }
        }
    }
}
