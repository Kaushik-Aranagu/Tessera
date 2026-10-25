import SwiftUI

/// The brief's one line at y 612 (landing contract §1, §3): Figtree 15 in ink 2 with one name in ink at 600. Like
/// `FitLine`, it takes its written forms longest first and shows the longest that fits; it never wraps and never
/// ellipsizes. VoiceOver reads the first (full) form.
struct LandingBrief: View {
    struct Form: Equatable {
        let text: String
        /// The one name set in ink 600; nil for none.
        var key: String?
    }

    let forms: [Form]

    init(forms: [Form]) {
        self.forms = forms
    }

    init(_ text: String, key: String? = nil) {
        forms = [Form(text: text, key: key)]
    }

    /// The written forms, then the last cut back a whole word at a time (as `FitLine`), so large type never meets an
    /// ellipsis.
    private var all: [Form] {
        guard let last = forms.last else { return [] }
        let cuts = FitLine.cuts(last.text).dropFirst().map { cut in
            Form(text: cut, key: last.key.flatMap { cut.contains($0) ? $0 : nil })
        }
        return forms + cuts
    }

    var body: some View {
        if !forms.isEmpty {
            let all = all
            ViewThatFits(in: .horizontal) {
                ForEach(Array(all.enumerated()), id: \.offset) { _, form in
                    line(form).fixedSize(horizontal: true, vertical: false)
                }
                line(all[all.count - 1]).lineLimit(1).minimumScaleFactor(0.5)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(forms[0].text)
        }
    }

    private func line(_ form: Form) -> Text {
        var text = AttributedString(form.text)
        if let key = form.key, let range = text.range(of: key) {
            text[range].foregroundColor = Theme.Colors.ink
            text[range].font = .custom("Figtree", size: 15, relativeTo: .callout).weight(.semibold)
        }
        return Text(text)
            .font(.custom("Figtree", size: 15, relativeTo: .callout))
            .foregroundStyle(Theme.Colors.inkSecondary)
    }
}
