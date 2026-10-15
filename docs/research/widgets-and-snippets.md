# Widgets, controls and snippets for slice 10

For: Product lead, iOS Builder A (widgets), Design studio. 2026-10-15. Research lab.

**Bottom line.** Start with App Intent snippets. They run in the app process, so they need no App Group and no paid account, and they are the only one of the four surfaces with real layout freedom. Next, add a Control Center control to open capture. The Home Screen and Lock Screen widgets come last, because they need an App Group (likely fine on a free team, but verify) and a snapshot file.

## What each surface can do

| Surface | Interaction | Text input | Motion | Data |
|---|---|---|---|---|
| Snippet (iOS 26) | `Button(intent:)` and `Toggle(intent:)`; the snippet re-renders in place | None in the view. Ask with a `@Parameter` prompt before it opens | `.contentTransition(.numericText())` works, but only if state lives in a shared store | App process via `@Dependency` |
| Home widget | Buttons and toggles only (iOS 17+) | None | Transitions between entries; `Text(timerInterval:)` and `ProgressView(timerInterval:)` tick live; nothing else loops | App Group snapshot |
| Lock accessory | Same, on a monochrome vibrant ground | None | Timer text only | App Group snapshot; Health is unreadable while locked |
| Control (iOS 18+) | `ControlWidgetButton` or `ControlWidgetToggle`; also works on the Lock Screen buttons and the Action button | None | System-drawn | Symbol and title only |

- **Refresh.** Roughly 40 to 70 timeline reloads a day. A reload the app asks for while in the foreground, or one caused by a widget button, does not use that budget. Call `WidgetCenter.shared.reloadTimelines(ofKind:)` after each write.
- **Smart Stack.** Set `TimelineEntryRelevance(score:duration:)` on entries, for example a high score on gym days around the usual time. An iOS 26 `RelevanceConfiguration` exists for watchOS relevant widgets; **unverified** on iPhone.
- **Snippet API names** (from WWDC25 and third-party write-ups): `SnippetIntent`, `ShowsSnippetIntent`, `ShowsSnippetView`, `.result(view:)`, `.result(value:snippetIntent:)`, `AppDependencyManager`. To chain steps, return a different `SnippetIntent`. Set `isDiscoverable = false` on helper intents. Confirmation and manual reload APIs: names **unverified**. Snippets do not appear in Control Center.
- **Lock Screen auth.** Whether a widget button runs before Face ID is controlled per intent (`authenticationPolicy`, **unverified name** on iOS 26). Don't let a set be logged from a locked phone.

## Sharing data and the free team

- A widget extension is sandboxed away from the app, so it cannot open `tessera.sqlite` without an App Group container.
- **App Groups on a free Personal Team: probably yes, not confirmed.** An Apple DTS answer says each personal team registers App IDs "including those with ... App Groups and HealthKit" in its own namespace, which implies they are allowed. Apple's capability table did not render for us. Confirm with one build, not with docs.
- **Design for the extension:** don't put GRDB in it. On each write, the app writes a small `now.json` (under 4 KB) to the group container and reloads timelines. Widget button intents call into the app (a `LiveActivityIntent` runs in the app process, **verify**) or write a pending op that the app imports.
- **Without an App Group**, snippets and controls still work fully. The widget can only show static text and deep links.
- Free-team costs: profiles expire every 7 days, and the extension uses one more App ID.

## Well-made examples (from memory, not re-checked this pass)

- **Flighty:** one huge number, such as the gate countdown, with everything else small. This is the type tier we want.
- **Things:** a checkbox-only interactive list, with no other chrome.
- **(Not Boring):** textured, material grounds. This is the painterly precedent.
- **Structured:** a timeline on a single axis.
- **Hevy:** stat grids. That is the card look we avoid.

## Four recommendations

1. **Snippet: "Log a set"** (Siri, Shortcuts, Action button). Shows the current exercise and last set as two big numerals with a hairline between them, plus "Same again", "+2.5" and "+1 rep" buttons. Each tap rolls the numerals.
   *First version:* `LogSetIntent` plus one `SnippetIntent` with "Same again". Add `AddGroceryIntent` and `CaptureIntent`, each a single String parameter returning a one-line confirmation snippet.
   *Gotcha:* the snippet draws on the system platter, so the painterly ground won't show. Rely on type alone.
2. **Home Screen widget: "Now"** (medium). One line in the top type tier with a hairline seam under it, a pre-rendered painterly image as the ground, and one button ("Done" or "Same set again").
   *First version:* read-only, reading `now.json`; tap opens the app.
   *Gotcha:* iOS 26 tinted and clear modes remove the image and colors. Check `widgetRenderingMode` and fall back to type over the seam.
3. **Control: "Capture".** A `ControlWidgetButton` that opens the ghost row with the keyboard up. Also works on the Action button and Lock Screen.
   *First version:* the button only, with a custom SF Symbol.
   *Gotcha:* there is no room for design here. Spend the effort on the glyph.
4. **Lock Screen accessory: "Rest"** (rectangular). The exercise name, plus a live `Text(timerInterval:)` rest countdown during a workout. This is the one moving element.
   *First version:* inline text with the Now line.
   *Gotcha:* monochrome only, and no Health data while locked.

## Sources

- WWDC25 "Explore new advances in App Intents": https://developer.apple.com/videos/play/wwdc2025/275
- Superwall, interactive snippets: https://superwall.com/blog/app-intents-interactive-snippets-in-ios-26
- Nutrient, snippet intents: https://www.nutrient.io/blog/wwdc25-snippet-intents/
- Apple, Configuring app groups: https://developer.apple.com/documentation/xcode/configuring-app-groups
- Apple DTS on personal-team App Groups: https://developer.apple.com/forums/thread/834802
- Apple capability table (did not render): https://developer.apple.com/help/account/reference/supported-capabilities-ios
- WWDC23 "Bring widgets to life" and WWDC24 "Extend your app's controls across the system"
