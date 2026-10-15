---
name: tessera-design
description: Tessera's house design rules — the anti-generic checklist for every screen, component, animation and piece of copy. Read this before writing, changing or reviewing any UI in Tessera (SwiftUI views, DesignSystem, widgets, Live Activities, empty/error states, onboarding, copy).
---

# Tessera design rules

Tessera is a personal app meant to be used every day. It should feel crafted, calm and specific, not like a generic
AI-generated app. Read `docs/DESIGN_MOTION.md` for the signature moments; this file has the hard rules.

## Never
- **Inter or Roboto as a display face.** Use SF Pro (system) with deliberate weights/widths, SF Pro Rounded or a
  chosen display face once the visual direction is picked. Never ship a default-looking type ramp.
- **Purple/blue "AI" gradients**, glowing blobs, sparkle icons as decoration.
- **Pure `#000000` / `#FFFFFF`** for backgrounds or text. Use tuned near-black/near-white tokens from `Theme.Colors`.
- **Card soup**: stacks of identical rounded rectangles. Vary hierarchy: some content is a list, some is a hero,
  some is inline text. No two adjacent sections should share an identical card style.
- **Emoji as icons.** Use SF Symbols (with `symbolEffect`) or custom drawn glyphs.
- **Glass on content.** Liquid Glass is only for chrome: tab bar, toolbars, floating controls, sheets.
- **Decorative color.** Color carries meaning (state, category, time, urgency). If a color means nothing, remove it.
- **Literals in views.** Colors, fonts, spacing, radii and durations come from `Theme`.

## Motion
- **House spring:** `Theme.Motion.house` = `Spring(duration: 0.42, bounce: 0.12)`. Use it for ~90% of motion
  (appear/disappear, layout changes, navigation-adjacent movement).
- **Direct manipulation** (drag, swipe, scrub, toggles under the finger): `Theme.Motion.snappy`.
- **Celebration only** (finishing something meaningful, rare): `Theme.Motion.celebrate` (`.bouncy`).
- **Every animation goes through `MotionPolicy`** (`DesignSystem/MotionPolicy.swift`): use
  `.tesseraAnimation(_:value:)` or `withTesseraAnimation(_:reduceMotion:_:)`. With Reduce Motion on, movement becomes
  a short opacity cross-fade; nothing slides, scales, bounces or spins.
- No linear or ease-in-out curves for UI movement. No animation longer than ~0.5 s except celebrations.
- Haptics via `.sensoryFeedback` for meaningful state changes only; never on scroll.

## States
- Design **empty, loading and error** states for every screen before calling it done.
  - Empty: one specific line of human copy + one clear action. No stock illustrations.
  - Loading: skeletons/redacted placeholders that match the final layout; no bare spinners for > 300 ms.
  - Error: say what happened and what to do, in plain words. Keep the user's input.

## Copy & tone
- Specific, human, short. "3 things left today", not "You have 3 pending items".
- **Count consistency, not streaks.** Show "Done 5 of the last 7 days", never "Streak: 0 🔥".
- **Never shame.** No guilt, no red badges for missed days, no "You broke your streak". Missed days are neutral.
- No exclamation marks unless something genuinely good happened.

## Accessibility (non-negotiable)
- Dynamic Type through AX5 with layouts that reflow, not truncate.
- VoiceOver labels/hints/grouping on every custom control.
- Contrast ≥ 4.5:1 for text (verify with the `accessibility-sufficient-contrast-specialist` skill).
- Reduce Motion and Reduce Transparency produce an intentional design, not a broken one.

## Visual direction
TODO — to be filled in once Kaushik picks one of the three visual directions being mocked up (palette, type
pairing, surface treatment, iconography, signature texture). Until then, use the placeholder `Theme` tokens and
keep components easy to restyle.
