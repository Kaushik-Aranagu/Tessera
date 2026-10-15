# Tessera — Design & Motion Playbook

Tessera should feel like a first-party Apple app built by a small, obsessive team: quiet, fast, tactile, and full of
small moments of delight. This is the bar every screen is held to. It is *not* a generic "AI app" (no gradient blobs,
no chat-bubble-first UI, no sparkle emoji everywhere).

## Principles

1. **Content first, chrome recedes.** Liquid Glass is for the *navigation layer* (tab bar, toolbars, floating
   controls, sheets) — never for content cards. Content sits on solid, calm surfaces.
2. **Everything is continuous.** Nothing pops in or out. Elements travel from where they were to where they're going
   (matched geometry, zoom transitions, glass morphing). The user should never lose track of an object.
3. **Motion has physics.** One house spring (`Theme.Motion.house`) for ~90% of motion, `.snappy` for direct manipulation, `.bouncy` only for celebrations — always via `MotionPolicy`.
   No linear or ease-in-out curves for UI movement. Durations live in `Theme.Motion` only.
4. **Touch is answered.** Every meaningful state change gets a haptic via `.sensoryFeedback` — light for selection,
   `.success`/`.impact(weight:)` for completion, never for scrolling.
5. **Numbers and symbols animate.** `.contentTransition(.numericText())` for counts/times, `.symbolEffect` for icons
   (`.bounce` on tap, `.replace` on state change, `.pulse` for "live").
6. **Respect the user.** Every effect checks `accessibilityReduceMotion` (swap to cross-fade) and
   `accessibilityReduceTransparency`. Dynamic Type through AX5 must not break layouts.
7. **Delight is earned, not sprayed.** Big effects (particles, shaders) are reserved for real accomplishments —
   finishing a day, a consistent week, a goal. Max one "wow" moment per flow.

## Signature moments (to build)

| Where | Moment | Tech |
|---|---|---|
| Today | Cards collapse/expand with the header sliding into the nav bar | `scrollTransition`, `onScrollGeometryChange`, matched geometry |
| Today → item | Tap a card, it *becomes* the detail screen and swipes back home | `.navigationTransition(.zoom(sourceID:in:))` + `matchedTransitionSource` |
| Now / Next / Later | Drag an item between sections; others make room, drop settles with a spring + haptic | `reorderable(collectionID:)` / `reorderContainer(for:itemID:in:)` |
| Completing an item | Check fills with a draw-on stroke, row compresses, count ticks down, `.success` haptic | `symbolEffect(.drawOn)`, `numericText`, `sensoryFeedback` |
| Finishing the day | Subtle confetti/sparkle burst + ripple from the last check | Vortex particles or a Metal `layerEffect` ripple |
| Floating add button | Glass button morphs into a quick-add bar, then into a sheet | `GlassEffectContainer` + `glassEffectID` morphing |
| Mode switches | Toolbar glass pills merge/split as options appear | `glassEffectUnion`, `glassEffectID` |
| Lists of records | Rows fade/scale/blur at the scroll edges | `scrollTransition { content, phase in … }`, `visualEffect` |
| Empty states | Gently animated SF Symbol + one-line copy, never a stock illustration | `symbolEffect(.breathe)`, `PhaseAnimator` |
| Headers/hero | Slow, living background for the day header (time-of-day tint) | `MeshGradient` animated with `TimelineView` |
| Live Activity / widget | Timers that tick, progress that animates between timeline entries | ActivityKit, WidgetKit `contentTransition`, `invalidatableContent` |
| Siri/Shortcuts | Interactive snippets that match the app's visual language | App Intents snippets |
| On-device AI | Suggestions stream in word-by-word with a soft reveal, not a spinner | Foundation Models streaming + custom `TextRenderer` |

## Toolkit

### Native (preferred — zero dependencies)
- Transitions: `navigationTransition(.zoom)`, `.crossFade` and `AnyNavigationTransition`, custom `Transition`
  protocol, `matchedGeometryEffect`.
- Animation: `PhaseAnimator`, `KeyframeAnimator`, `withAnimation(_:completionCriteria:)`, `CustomAnimation`.
- Scroll: `scrollTransition`, `visualEffect`, `onScrollGeometryChange`, `scrollTargetBehavior(.viewAligned)`.
- Glass: `glassEffect`, `GlassEffectContainer`, `glassEffectID`, `glassEffectUnion`, `.buttonStyle(.glass)`.
- Graphics: `MeshGradient`, Metal shaders via `colorEffect` / `distortionEffect` / `layerEffect`, `TextRenderer`.
- Feel: `sensoryFeedback`, `symbolEffect`, `contentTransition(.numericText())`.

### Third-party (add only when a screen needs it)
- **Pow** (EmergeTools/Pow, MIT) — polished transitions (`.movingParts.*`) and change effects (shine, spray, jump) with
  built-in haptics.
- **Vortex** (twostraws/Vortex, MIT) — fast particle systems (confetti, sparkles, fireworks) for celebration moments.
- **Inferno** (twostraws/Inferno) — ready-made Metal shaders (ripples, dissolves, light effects) to learn from or adapt.

## Claude Code skills installed for this (project scope)
- `swiftui-pro` (Paul Hudson) — modern SwiftUI correctness, deprecated-API avoidance, accessibility.
- `swiftui-expert` (Antoine van der Lee) — SwiftUI best practices + Instruments trace analysis for hitches/hangs.
- `swift-concurrency` (Antoine van der Lee) — Swift 6 strict concurrency.
- `liquid-glass` — iOS 26/27 Liquid Glass API reference, HIG rules, and a linter for invented APIs.
- `swiftui-skills`, `ios-app-framework-skills`, `ios-data-framework-skills`, `ios-ai-ml-skills` (dpearson2699) —
  animation, navigation, gestures, WidgetKit, ActivityKit, App Intents, SwiftData/CloudKit, HealthKit,
  Foundation Models.

## Review checklist for every screen
- [ ] Does anything appear/disappear without a transition?
- [ ] Is every tap answered (visual + haptic where meaningful)?
- [ ] Is glass only on the navigation layer?
- [ ] Reduce Motion / Reduce Transparency / AX5 Dynamic Type all look intentional?
- [ ] Dark mode looks designed, not inverted?
- [ ] 120 Hz smooth — no hitches in Instruments (`swiftui-expert` trace analysis)?
- [ ] All tokens from `Theme` — no literal colors, sizes, or durations?
