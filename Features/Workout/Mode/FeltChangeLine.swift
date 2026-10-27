import SwiftUI

/// When Felt changes the next weight (sheet 345): the old number stays greyed and a chalk strike runs through it (280
/// ms),
/// then the new weight is written after it in accent (420 ms), so the line reads "Next, bench press, 185 190 lb × 5"
/// with 185 struck. Under Reduce Motion both numbers just appear. Runs again for each new answer.
struct FeltChangeLine: View {
    let prefix: String
    let old: String
    let new: String
    let suffix: String

    static let strikeDuration = 0.28
    static let writeDuration = 0.42

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var strike = 0.0
    @State private var write = 0.0

    var body: some View {
        HStack(spacing: 6) {
            Text(prefix).foregroundStyle(Chalk.white)
            Text(old)
                .foregroundStyle(Chalk.faint)
                .overlay(alignment: .leading) {
                    // The chalk strike, drawn left to right through the old number.
                    GeometryReader { proxy in
                        Rectangle().fill(Chalk.white.opacity(0.8))
                            .frame(width: proxy.size.width * strike, height: 2.4)
                            .position(x: proxy.size.width * strike / 2, y: proxy.size.height / 2)
                    }
                }
            Text(new)
                .foregroundStyle(Chalk.blue)
                .mask(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle().frame(width: proxy.size.width * write)
                    }
                }
            Text(suffix).foregroundStyle(Chalk.white)
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(prefix) \(new) \(suffix), was \(old)")
        .onAppear { run() }
        .onChange(of: new) { _, _ in run() }
    }

    private func run() {
        guard !reduceMotion else {
            strike = 1
            write = 1
            return
        }
        strike = 0
        write = 0
        withAnimation(.easeInOut(duration: Self.strikeDuration)) { strike = 1 }
        withAnimation(.easeOut(duration: Self.writeDuration).delay(Self.strikeDuration)) { write = 1 }
    }
}
