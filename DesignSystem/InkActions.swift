import SwiftUI

// Ink actions (docs/design/no-buttons.md): nothing gets a shape around it to be a button, a card or a bar.
// An action is type, paint and motion. The stroke word (the primary action) is `PaintKey` in Paint.swift.

// MARK: - The stroke

/// A dry brushstroke as a filled, tapered shape with rough ends (no round caps). `seed` keeps its wobble stable.
struct InkStroke: Shape {
    var seed: Int = 0

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        guard w > 0, h > 0 else { return Path() }
        let wobble: [CGFloat] = [0.06, -0.04, 0.05, -0.07, 0.03, -0.02, 0.06, -0.05]
        func jitter(_ i: Int) -> CGFloat {
            wobble[(i + seed) % wobble.count] * h
        }
        var path = Path()
        // Top edge, left to right, with a ragged start.
        path.move(to: CGPoint(x: rect.minX + w * 0.01, y: rect.minY + h * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.035, y: rect.minY + h * 0.12 + jitter(0)))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.06 + jitter(1)),
                      control1: CGPoint(x: rect.minX + w * 0.2, y: rect.minY + jitter(2)),
                      control2: CGPoint(x: rect.minX + w * 0.4, y: rect.minY + h * 0.1 + jitter(3)))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.015, y: rect.minY + h * 0.3 + jitter(4)),
                      control1: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + jitter(5)),
                      control2: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.1))
        // Tapered, dry tail.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.03, y: rect.minY + h * 0.72 + jitter(6)))
        // Bottom edge back, right to left.
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.45, y: rect.maxY - h * 0.04 + jitter(7)),
                      control1: CGPoint(x: rect.maxX - w * 0.2, y: rect.maxY + jitter(0)),
                      control2: CGPoint(x: rect.minX + w * 0.65, y: rect.maxY - h * 0.12))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.02, y: rect.maxY - h * 0.2 + jitter(2)),
                      control1: CGPoint(x: rect.minX + w * 0.25, y: rect.maxY + jitter(3)),
                      control2: CGPoint(x: rect.minX + w * 0.08, y: rect.maxY - h * 0.05))
        path.closeSubpath()
        return path
    }
}

// MARK: - Label word (secondary actions)

/// +15, SKIP, UNDO, EDIT: Label 16/700 uppercase in the secondary colour. On touch the ink goes full and a 1.5 pt
/// hairline draws out from the centre beneath it; it fires on release and the line fades.
struct LabelActionStyle: ButtonStyle {
    var color: Color = Theme.Colors.inkSecondary

    func makeBody(configuration: Configuration) -> some View {
        LabelActionBody(configuration: configuration, color: color)
    }

    private struct LabelActionBody: View {
        let configuration: Configuration
        let color: Color
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .textRole(.labelStrong)
                .foregroundStyle(color.opacity(configuration.isPressed ? 1 : 0.85))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(color)
                        .frame(height: 1.5)
                        .scaleEffect(x: configuration.isPressed ? 1 : 0, anchor: .center)
                        .opacity(configuration.isPressed ? 1 : 0)
                        .offset(y: 5)
                        .animation(MotionPolicy.resolve(configuration.isPressed ? Theme.Motion.house
                                       : .easeOut(duration: 0.3), reduceMotion: reduceMotion),
                        value: configuration.isPressed)
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, new in new }
        }
    }
}

extension ButtonStyle where Self == LabelActionStyle {
    static var labelWord: LabelActionStyle {
        LabelActionStyle()
    }

    static func labelWord(_ color: Color) -> LabelActionStyle {
        LabelActionStyle(color: color)
    }
}

// MARK: - Value word wash

/// Inline values and glyph-only controls (− + ✕): on touch a soft cobalt wash blooms behind, with no edge.
struct ValueWashStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Ellipse()
                    .fill(Theme.Colors.tess.opacity(configuration.isPressed ? 0.22 : 0))
                    .padding(-10)
                    .blur(radius: 5)
                    .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
            }
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == ValueWashStyle {
    static var valueWash: ValueWashStyle {
        ValueWashStyle()
    }
}

// MARK: - The Tess horizon

/// Replaces every Tess bar: a full-bleed band of glass at the bottom with no top edge (it fades in over its top
/// 55%), and one hairline writing line from the soul to the right gutter. Content sits on the line.
struct TessHorizon<Leading: View, Content: View>: View {
    var height: CGFloat = 150
    var isFocused = false
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let dark = colorScheme == .dark
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.55)],
                                   startPoint: .top, endPoint: .bottom)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                leading()
                    .frame(width: 52)
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .bottom) {
                        // The writing line: the only edge.
                        Rectangle()
                            .fill((dark ? Color(hex: 0xF3ECE0) : Theme.Colors.ink)
                                .opacity(isFocused ? 0.6 : (dark ? 0.3 : 0.28)))
                            .frame(height: 0.5)
                            .padding(.leading, isFocused ? -8 : 0)
                            .offset(y: 6)
                            .allowsHitTesting(false)
                    }
            }
            .padding(.leading, 24)
            .padding(.trailing, Theme.Spacing.gutter)
            .padding(.bottom, 18)
        }
        .frame(height: height)
        .animation(Theme.Motion.house, value: isFocused)
    }
}

// MARK: - Veil

private struct Veil: ViewModifier {
    let edge: VerticalEdge
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(
                            stops: edge == .top
                                ? [.init(color: .black, location: 0), .init(color: .black, location: 0.85),
                                   .init(color: .clear, location: 1)]
                                : [.init(color: .clear, location: 0), .init(color: .black, location: 0.15),
                                   .init(color: .black, location: 1)],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
            }
            .overlay(alignment: edge == .top ? .bottom : .top) {
                (colorScheme == .dark ? Color.white.opacity(0.12) : Theme.Colors.ink.opacity(0.14))
                    .frame(height: 1 / displayScale)
            }
    }
}

extension View {
    /// A panel that slides over content: attached to one screen edge, fading on its open side, one hairline seam.
    func veil(edge: VerticalEdge) -> some View {
        modifier(Veil(edge: edge))
    }
}
