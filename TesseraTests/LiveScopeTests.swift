import SwiftUI
@testable import Tessera
import Testing
import UIKit

/// The scope the shell sets (docs/design/live-visibility.md): a page that is not current, or is covered, is not live,
/// and `alwaysLive` still overrides it for the before/after measurement.
@MainActor
struct LiveScopeTests {
    @MainActor
    private final class Box {
        var live: Bool?
    }

    private struct Probe: View {
        let box: Box
        @Environment(\.isLive) private var live

        var body: some View {
            Color.clear.onChange(of: live, initial: true) { _, now in box.live = now }
        }
    }

    /// Hosts `content` in a window long enough for `onAppear` and the first update to run.
    private func host(_ content: some View) async {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.rootViewController = UIHostingController(rootView: content)
        window.makeKeyAndVisible()
        try? await Task.sleep(for: .milliseconds(300))
        window.isHidden = true
    }

    private func isLive(scope: Bool, outer: Bool = true, switchState: LiveSwitch) async -> Bool? {
        let feature = LiveFeatures.landingGlyph
        let registry = LiveRegistry.shared
        let before = registry.switchState(for: feature)
        registry.set(switchState, for: feature)
        defer { registry.set(before, for: feature) }
        let box = Box()
        await host(Probe(box: box).liveRegion(feature).liveScope(scope).liveScope(outer))
        return box.live
    }

    @Test func coveredPageIsNotLive() async {
        #expect(await isLive(scope: false, switchState: .auto) == false)
    }

    @Test func pageUnderACoveredParentIsNotLive() async {
        #expect(await isLive(scope: true, outer: false, switchState: .auto) == false)
    }

    @Test func currentPageIsLive() async {
        #expect(await isLive(scope: true, switchState: .auto) == true)
    }

    @Test func alwaysLiveIgnoresTheScope() async {
        #expect(await isLive(scope: false, switchState: .alwaysLive) == true)
    }

    @Test func dataOnlyIsNeverLive() async {
        #expect(await isLive(scope: true, switchState: .dataOnly) == false)
    }
}
