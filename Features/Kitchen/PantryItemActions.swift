import SwiftUI
import TesseraCore

extension PantryRoomItem {
    /// Offer only operations this source can actually perform. A typed shopping row can be checked off, not pinned.
    var moves: [PantryMove] {
        switch source {
        case .stock: [.toggle, .usedUp, .notNow, .pin]
        case .toGet: [.usedUp]
        case .added: []
        }
    }

    func title(for move: PantryMove) -> String {
        switch move {
        case .toggle: isLow ? "Back in" : "Running low"
        case .usedUp:
            if case .toGet = source {
                "Got it"
            } else {
                "Used up"
            }
        case .notNow: "Not now"
        case .pin: isPinned ? "Unpin" : "Pin"
        }
    }
}

/// Direct mutations belong only to a full, unambiguous target. Compact rows disclose actions without changing stock.
struct PantryRowControl<Content: View>: View {
    let item: PantryRoomItem
    let targetHeight: CGFloat
    let direct: Bool
    let perform: (PantryMove, PantryRoomItem) -> Void
    let openActions: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var holdoff = TapHoldoff()
    @State private var held = false
    @GestureState private var pinTouch = false

    var body: some View {
        Group {
            if direct {
                button
                    .rowSwipe(item.moves.contains(.notNow) ? .both : .leading) { event in
                        switch event {
                        case let .pulled(pull):
                            offset = pull
                            holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                        case let .committed(side):
                            perform(side == .leading ? .usedUp : .notNow, item)
                        case .ended:
                            holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { offset = 0 }
                        default: break
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: GestureTuning.holdOpen,
                                         maximumDistance: CGFloat(GestureTuning.holdSlop))
                            .sequenced(before: LongPressGesture(minimumDuration: .infinity,
                                                                maximumDistance: CGFloat(GestureTuning.holdSlop)))
                            .updating($pinTouch) { _, touching, _ in touching = true }
                            .onChanged { phase in
                                guard case .second(true, _) = phase, !held, item.moves.contains(.pin) else { return }
                                held = true
                                holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
                                perform(.pin, item)
                            }
                    )
            } else {
                button
            }
        }
        .onChange(of: pinTouch) { _, touching in
            if !touching, held {
                held = false
                holdoff.moved(at: ProcessInfo.processInfo.systemUptime)
            }
        }
        .accessibilityActions {
            ForEach(item.moves, id: \.self) { move in
                Button(item.title(for: move)) { perform(move, item) }
            }
            Button("Item actions", action: openActions)
        }
    }

    private var button: some View {
        Button {
            guard !held, holdoff.allowsTap(at: ProcessInfo.processInfo.systemUptime) else { return }
            if direct, item.moves.contains(.toggle) {
                perform(.toggle, item)
            } else {
                openActions()
            }
        } label: {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: targetHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(PantryTargetButtonStyle())
        .offset(x: offset)
        .accessibilityLabel(item.spoken)
        .accessibilityHint(direct && item.moves.contains(.toggle)
            ? "Tap to change stock. Item actions are also available." : "Opens item actions")
        .accessibilityIdentifier("pantry.row.\(item.id.uuidString)")
    }
}

/// Keep a native button's accessibility/keyboard action while checking physical taps against its actual target.
/// SwiftUI's adaptive hit reach must not select an adjacent row or a row beyond its column clip.
private struct PantryTargetButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PantryTargetButton(configuration: configuration)
    }
}

private struct PantryTargetButton: View {
    let configuration: PrimitiveButtonStyleConfiguration
    @State private var size: CGSize = .zero

    var body: some View {
        configuration.label
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture(coordinateSpace: .local).onEnded { event in
                guard PantryTouch.accepts(event.location, in: size) else { return }
                configuration.trigger()
            })
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { configuration.trigger() }
    }
}

/// A full-sized route to the same engine actions when the columns are too dense for direct gestures.
struct PantryItemActions: View {
    let items: [PantryRoomItem]
    @State var selectedID: UUID?
    let perform: (PantryMove, PantryRoomItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private var selected: PantryRoomItem? {
        items.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                if selected != nil {
                    Button { selectedID = nil } label: {
                        Text("Choose a thing").frame(minHeight: PantryTouch.minimum).contentShape(Rectangle())
                    }
                }
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Text("Done").frame(minWidth: PantryTouch.minimum, minHeight: PantryTouch.minimum)
                        .contentShape(Rectangle())
                }
            }
            .font(Theme.voice(size: 17))
            .foregroundStyle(Theme.Colors.Accent.kitchenText)
            if let item = selected {
                Text(item.name)
                    .font(Theme.voice(size: 28).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityIdentifier("pantry.itemTitle")
                ForEach(item.moves, id: \.self) { move in
                    Button {
                        dismiss()
                        perform(move, item)
                    } label: {
                        Text(item.title(for: move))
                            .frame(maxWidth: .infinity, minHeight: PantryTouch.minimum, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("pantry.action.\(move)")
                }
            } else {
                Text("Choose a thing")
                    .font(Theme.voice(size: 28).weight(.semibold))
                    .foregroundStyle(Theme.Colors.ink)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            Button { selectedID = item.id } label: {
                                Text(item.spoken)
                                    .frame(maxWidth: .infinity, minHeight: PantryTouch.minimum, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityIdentifier("pantry.choose.\(item.id.uuidString)")
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .font(Theme.voice(size: 19))
        .foregroundStyle(Theme.Colors.Accent.kitchenText)
        .buttonStyle(.plain)
        .padding(Theme.Spacing.gutter)
        .background { ThemedBackground() }
    }
}
