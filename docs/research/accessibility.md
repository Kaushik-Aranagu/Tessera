# Accessibility audit: VoiceOver, Dynamic Type, Reduce Motion

Board item 27. Traced by hand on `origin/master` at `11f4648` (no simulator or Accessibility Inspector here).
Scope: `App/`, `DesignSystem/`, `Features/*`, `Widgets/`. Three checks:

- **VO**: VoiceOver on ink actions and stroke words. Tappables with no label, trait or action; gestures with no
  accessibility action; images that should be hidden; spoken text that only appears for a few seconds.
- **DT**: Dynamic Type at the largest accessibility size (AX5). Fixed fonts, `lineLimit(1)` on content, fixed frames
  that clip.
- **RM**: Reduce Motion through `MotionPolicy`. Raw `.animation(`, `withAnimation(`, springs and transitions that
  bypass the policy or ignore `accessibilityReduceMotion`.

Severity: **High** means a VoiceOver user cannot do the thing, or AX5 text is cut off on a main screen.
**Med** means it works but is wrong or degraded. **Low** means house-rule drift (bypasses `MotionPolicy` but already
checks Reduce Motion) or a corner case.

Owners: **A** = Builder A (Workout, Exercise, Plans, Routine, Widgets, DesignSystem). **B** = Builder B (Home, Command,
RootView, BottomChrome). **Core** = Notes, Review, Groceries, Recipes, Backup. `Features/Objects` and `Features/Tess`
are not in the owner list; they are given to B here because Tess's soul and the object handles live in B's chrome
(see open questions).

## What is already good

Worth keeping as the pattern for the fixes below:

- The instruments have real VoiceOver paths. `WeightDial`, `RepsDrum`, `RPEStops`, `PortionDrum` and `StepLine` use
  `accessibilityAdjustableAction`, and the dial adds "Type value", "Add 15 seconds" and "Skip rest".
- `PaintKey` (the stroke word) is one combined element with `.isButton` and a default `accessibilityAction`, so a hold
  key can be fired with a double-tap.
- `ExerciseStrip` gives reorder as "Move up" and "Move down" actions plus `.escape`. `HomeQueue` gives the swipes as
  "Done" and "Not now".
- `MarginSection` and `HomeSpatialView.fitted` reflow at accessibility sizes. Every `TextRole` font uses
  `Font.custom(_:size:relativeTo:)`, so almost no text is a fixed size.
- Most motion already goes through `.tesseraAnimation` and `withTesseraAnimation`, and most `TimelineView`s pause
  on Reduce Motion.

## A systemic gap first

`MotionPolicy.resolve` (DesignSystem/MotionPolicy.swift:8) only swaps the **timing curve** for a 0.15 s ease-out.
It cannot change **what** moves. A `.move(edge:)`, `.offset`, `.push` or `scaleEffect` animated through
`withTesseraAnimation` still slides or scales under Reduce Motion, just faster. So every travel transition has to
check `reduceMotion` itself, and a dozen don't (rows marked RM below). Row A5 proposes a policy helper so this stops
being per call site.

---

## DesignSystem (Builder A)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| A1 | VO | DesignSystem/Paint.swift:293-294 | Every hold `PaintKey` gets the hint "Touch and hold", but VoiceOver's double-tap fires `accessibilityAction { complete() }`. The hint sends VO users to the wrong gesture. The meta text ("Hold · 82.5 × 5") is merged into the label, so VO also reads "Hold". | Drop the gesture from the hint: `.accessibilityHint(isTap ? "" : "Confirms on double-tap")`. Hide the meta from the combined element (`meta().accessibilityHidden(true)`) and let callers fold any value into their own `accessibilityLabel`, as WorkoutModeView already does. | Med |
| A2 | DT | DesignSystem/Paint.swift:264 | The stroke word label is `.fixedSize()`, so it can never wrap. At AX5 the 34 pt word (title style) roughly doubles. "Clear the basket", "Back to today" and "Next exercise" run off the right edge. | `.fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)` with `@Environment(\.dynamicTypeSize) var typeSize`. The stroke is a background, so it follows the wrapped width. | High |
| A3 | DT | DesignSystem/Theme.swift:383-384 | The fallback path for a missing family scales once with `UIFontMetrics.scaledValue` and returns `Font.system(size:)`. That font does not follow a Dynamic Type change while the app runs. It only matters when a concept's font is not bundled (Workshop, Machined). | Return `Font.system(style, design:)` with a `.weight`, or bundle the face. Plein (Inter Tight) is not affected. | Low |
| A4 | DT | DesignSystem/Editorial.swift:33 | `.tracking(spec.tracking * spec.size)` uses the unscaled size. At AX5 the uppercase labels (+8%) get proportionally tight tracking. | Scale the tracking: `@ScaledMetric(relativeTo: .callout) var labelTracking = 16 * 0.08`, or read `UIFontMetrics(forTextStyle: spec.textStyle.uiKit).scaledValue(for:)` in the modifier. | Low |
| A5 | RM | DesignSystem/MotionPolicy.swift:8-10 | Systemic. `resolve` swaps the curve but leaves travel and scale (see above). There is also no sanctioned way to run a **progress** fill (hold fill, drying line, capture stroke) that must keep its real duration under Reduce Motion, so those call sites use raw `withAnimation`. | Add two helpers and use them in rows A24, A26, A31, B7, B8, B21, C9, C14 and C17 (snippet 1). | High |
| A6 | RM | DesignSystem/Paint.swift:120, 279, 286, 352-354 | Raw `withAnimation`. Lines 120, 279 and 352 already check Reduce Motion; line 286 (drain back) does not, but it only changes a fill. | 286: `withTesseraAnimation(.easeIn(duration: 0.22), reduceMotion: reduceMotion) { fill = 1 }`. 279: `MotionPolicy.progress(duration)` from A5. 120 and 352: wrap in `withTesseraAnimation`. | Low |
| A7 | RM | DesignSystem/Editorial.swift:74; DesignSystem/TextEffects.swift:88, 113 | Raw `withAnimation` for the entrance and the glyph reveal. They already check Reduce Motion, but they bypass the policy. | `withTesseraAnimation(.smooth(duration: 0.28).delay(Double(order) * Theme.Motion.stagger), reduceMotion: reduceMotion) { shown = true }` | Low |
| A8 | RM | DesignSystem/ThinkingIndicator.swift:20 | `TimelineView(.animation(..., paused: false))`. Under Reduce Motion the glyph is drawn still but redrawn 60 times a second. | `paused: reduceMotion` | Low |

**Snippet 1 (A5):**

```swift
extension MotionPolicy {
    /// Travel becomes a cross-fade under Reduce Motion.
    static func transition(_ travel: AnyTransition, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : travel
    }
    /// A fill that shows elapsed time keeps its real duration; it never travels, so it is exempt.
    static func progress(_ duration: Double) -> Animation { .linear(duration: duration) }
}
```

## Workout, live mode (Builder A)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| A9 | VO | Features/Workout/WorkoutModeView.swift:533, 570 | The log key's label is "Hold to log set 3, ...". That puts a gesture into the label, and VoiceOver's double-tap logs the set anyway. | `"Log set \(n), \(weight) kilograms for \(reps) reps"` | Med |
| A10 | VO | Features/Workout/WorkoutModeView.swift:131 (root of the full-screen cover) | There is no `.escape` action, so the two-finger scrub can't minimise the workout. Only the chevron button works. | `.accessibilityAction(.escape) { model.isWorkoutPresented = false }` | Med |
| A11 | VO | Features/Workout/LiveTessCorner.swift:28, 51-57 | Tess's line and the Undo word hide after 4 s and are never announced. A VO user misses "Logged.", record lines and the only Undo. | Snippet 2. | High |
| A12 | VO | Features/Workout/ExerciseStrip.swift:185-186 | "Move up" is offered on the first row and "Move down" on the last. | Snippet 3. | Low |
| A13 | VO | Features/Workout/WorkoutParts.swift:59-60 | "Swap within the movement" is on every lane name, but it acts on the current exercise. Names that are not current get an empty hint, yet they open the exercise page. | Show the action only `if isCurrent` (use `.accessibilityActions { }`). Use the hint "Opens the exercise page" for all names. | Low |
| A14 | VO | Features/Workout/LiveSetStrokes.swift:48 | "Edit." is part of the label. | Label `"Set \(n), \(kg) kilograms by \(reps)"` plus `.accessibilityHint("Edits this set")`. | Low |
| A15 | DT | Features/Workout/WorkoutModeView.swift:346 | The minimise chevron uses `.font(.system(size: 16, weight: .semibold))`, a fixed size. | `.font(.body.weight(.semibold))`. The 44 pt frame stays the hit area. | Low |
| A16 | DT | Features/Workout/WorkoutModeView.swift:460 | `numberRow` is `.frame(height: 196)`. It holds `Theme.numeral(72)` (largeTitle scaling), the voice "rest" line, the plate line and the reps drum. At AX sizes it spills over the set area below. | `.frame(minHeight: 196, alignment: .top)`, or `@ScaledMetric(relativeTo: .largeTitle) var numberRowHeight: CGFloat = 196`. | Med |
| A17 | DT | Features/Workout/WorkoutModeView.swift:613 | `keyRow` is `.frame(height: 62)` but `PaintKey` asks for `minHeight: 64`. The label overflows it at any size above Large. | `.frame(minHeight: 64)` | Med |
| A18 | DT | Features/Workout/WorkoutModeView.swift:391-392 | The subline (what to do now) is `lineLimit(1)` with `minimumScaleFactor(0.8)`, so it truncates at AX sizes. | `.lineLimit(typeSize.isAccessibilitySize ? 3 : 1)` | Med |
| A19 | DT | Features/Workout/WorkoutModeView.swift:126 | The ask sheet is `.presentationDetents([.height(84)])`, so the text field clips at AX sizes. | `@ScaledMetric var askHeight: CGFloat = 84`, then `.presentationDetents([.height(askHeight)])` | Med |
| A20 | DT | Features/Workout/ExerciseStrip.swift:82, 152-168 | The running-order rows have a fixed pitch of 64. The name is `lineLimit(1)` at min scale 0.6 and "Set 2 of 4" grows beside it, so at AX5 names are squeezed and cut. | `@ScaledMetric(relativeTo: .title) var pitch: CGFloat = 64` (the reorder maths at :101 and in `reorder` must use the instance value). At AX sizes put the set label under the name. | Med |
| A21 | DT | Features/Workout/WorkoutParts.swift:35-36, 71 | The exercise lane is a fixed 64 pt band, with the name at `lineLimit(1)` and min scale **0.45**. At AX5 a long name shrinks back to about its original size, which cancels Dynamic Type. | `@ScaledMetric(relativeTo: .title) var laneHeight: CGFloat = 64`, and `lineLimit(typeSize.isAccessibilitySize ? 2 : 1)` | Med |
| A22 | DT | Features/Workout/SwapPanel.swift:78 | The option name is `lineLimit(1)` with min scale 0.7, beside the load text. | At AX sizes stack the name over the load: `ViewThatFits(in: .horizontal) { HStack {...}; VStack(alignment: .leading) {...} }` | Low |
| A23 | RM | Features/Workout/LiveTessCorner.swift:68, 93-96 | The soul's tap swell (scale 1.35) runs under Reduce Motion. The policy only shortens it. | `guard !reduceMotion else { action?(); return }` before the swell, as BottomChrome.swift:170 does. | Low |
| A24 | RM | Features/Workout/WorkoutModeView.swift:426 | The rest block uses `.transition(.opacity.combined(with: .blurReplace))` with no Reduce Motion swap. The design doc says Reduce Motion means no blur. | `.transition(reduceMotion ? .opacity : .opacity.combined(with: .blurReplace))` | Low |

**Snippet 2 (A11):**

```swift
@Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
// ...
.task(id: "\(line)|\(holdsLine)") {
    shownLine = line
    if let line, !line.isEmpty { AccessibilityNotification.Announcement(line).post() }
    guard !holdsLine, !voiceOver else { return }   // keep the line and Undo while VO is on
    try? await Task.sleep(for: .seconds(4))
    if !Task.isCancelled { shownLine = nil }
}
```

**Snippet 3 (A12):**

```swift
.accessibilityActions {
    if index > 0 { Button("Move up") { session.move(entryID: entry.id, to: index - 1) } }
    if index < count - 1 { Button("Move down") { session.move(entryID: entry.id, to: index + 1) } }
}
```

## Plans and Routine (Builder A)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| A25 | DT | Features/Plans/WeekPage.swift:97-101 | Seven day captions sit in one row, each `lineLimit(1)` with min scale 0.75. At AX sizes the routine names shrink and then truncate. | At AX sizes switch the week to a vertical list (`PlansView` already reads `typeSize` at :85). Each cell already has a spoken label. | Med |
| A26 | RM | Features/Plans/RoutineEditor.swift:72, 265 | `.transition(.opacity.combined(with: .offset(y: 12)))` and `offset(y: -6)` are used with no Reduce Motion swap. | `.transition(MotionPolicy.transition(.opacity.combined(with: .offset(y: 12)), reduceMotion: reduceMotion))` | Low |
| A27 | DT | Features/Plans/WeekPage.swift:26-27 | The title "Sets per muscle" is `lineLimit(1)` with min scale 0.7, so it truncates at AX5. | `.lineLimit(typeSize.isAccessibilitySize ? 2 : 1)` | Low |
| A28 | DT | Features/Plans/MonthPage.swift:122-123 | Day numerals scale (callout) inside 7-column cells sized from the width. Two-digit days overflow at AX5. | Cap them with `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` and add `.accessibilityShowsLargeContentViewer()`. The cell is already spoken. | Low |

## Exercise (Builder A)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| A29 | DT | Features/Exercise/ExerciseViews.swift:133 | The history date is `.frame(width: 92)`, so "Last Tuesday" clips at AX sizes. | `@ScaledMetric(relativeTo: .subheadline) var dateWidth: CGFloat = 92`, or put the date above the strokes at AX sizes. | Low |

## Widgets, rest Live Activity (Builder A)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| A30 | VO | Widgets/RestLiveActivity.swift:297-310 | "+15" is read "plus fifteen". Both right-hand keys say "Skip", whether they skip rest or skip the set. The disabled "+15" text (25% opacity) is still read. | `.accessibilityLabel("Add 15 seconds")`; `"Skip rest"` and `"Skip set"`; `.accessibilityHidden(true)` on the disabled text. | Med |
| A31 | RM | Widgets/RestLiveActivity.swift:221 | "Go" arrives with `.push(from: .bottom)` and Reduce Motion is not checked. | Read `@Environment(\.accessibilityReduceMotion)` in `Countdown` and use `.opacity` when it is on. | Low |
| A32 | DT | Widgets/RestLiveActivity.swift:49-51 | `Font.custom(_, fixedSize:)` is used throughout, so Lock Screen text ignores Dynamic Type. This is likely deliberate (the 160 pt height cap). | Decide: either keep it (documented) or use `relativeTo:` with `.dynamicTypeSize(...DynamicTypeSize.xxLarge)`. See the open questions. | Low |

---

## Command and BottomChrome (Builder B)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| B1 | VO | Features/Command/BottomChrome.swift:48-60 | Tess closes only by tapping the veil (which is `accessibilityHidden`) or by swiping the wash down. A VoiceOver user has no way to close her. | On the expanded layer: `.accessibilityAction(.escape) { close() }` | High |
| B2 | VO | Features/Command/BottomChrome.swift:301, 382-393 | Return starts a drying line that commits in 2 s (0.6 s with Reduce Motion). The only way to cancel is a tap on the line, which has no VO action. A VO user can't stop a wrong command. | Snippet 4. | High |
| B3 | VO | Features/Command/BottomChrome.swift:120-136, 440-447 | Tess's reply line and Undo vanish after 4 s and are never announced. | Post `AccessibilityNotification.Announcement(text)` where the reply is set, and skip the 4 s clear while `accessibilityVoiceOverEnabled` is on (same pattern as snippet 2). | High |
| B4 | DT | Features/Command/BottomChrome.swift:492-499 | `ModeRow` is `.frame(height: rowHeight /* 70 */).clipped()` around a 34 pt title-style word, so Speak, Write and Show are cut at AX sizes. The dab-rise maths also uses `rowHeight`. | `@ScaledMetric(relativeTo: .title) var rowHeight: CGFloat = 70`, passed into `ModeRow` and the `rise` calculation. | Med |
| B5 | DT | Features/Command/BottomChrome.swift:126, 130 | The reply is `.frame(maxWidth: 270)` with `lineLimit(2)`, so it truncates at AX sizes. | `.frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 270)` and `.lineLimit(typeSize.isAccessibilitySize ? nil : 2)` | Med |
| B6 | DT | Features/Command/BottomChrome.swift:317-318 | The two suggestion words share one line at `lineLimit(1)`, min scale 0.8. | `ViewThatFits(in: .horizontal) { HStack {...}; VStack(alignment: .leading) {...} }` | Low |
| B7 | RM | Features/Command/BottomChrome.swift:54-55 | The capture wash rises and falls with `.offset(y: 60)` and `.offset(y: 40)`; Reduce Motion is not checked. | `.transition(MotionPolicy.transition(.asymmetric(...), reduceMotion: reduceMotion))` | Med |
| B8 | RM | Features/Command/BottomChrome.swift:140 | The reply slides in with `.offset(x: 12)`; Reduce Motion is not checked. | Same as B7. | Low |
| B9 | RM | Features/Command/BottomChrome.swift:171, 176, 365-366, 388, 522 | Raw `withAnimation`. Most check Reduce Motion; 176 does not, but it only settles a swell. | Use `withTesseraAnimation(..., reduceMotion: reduceMotion)`. Line 388 (the drying line) should use `MotionPolicy.progress(2)`. | Low |

**Snippet 4 (B2):**

```swift
@Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
// on the TextField
.accessibilityAction(named: "Cancel") { cancelDrying() }   // only while ghost != nil
// in dry(): with VoiceOver on, give time to undo, or commit straight away and rely on Undo
try? await Task.sleep(for: .seconds(voiceOver ? 6 : (reduceMotion ? 0.6 : 2)))
```

## Home: Now, queue, day strip, Training, pager (Builder B)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| B10 | VO | Features/Home/HomeQueue.swift:242-266 | The row opens with `onTapGesture` but has no `.isButton`. "Done" and "Not now" are offered on workout rows, where they do nothing. | Snippet 5. | Med |
| B11 | VO | Features/Home/HomeQueue.swift:29-38 | `TessVoice.say` shows a note with UNDO for 4 s and never announces it. Groceries mirrors this note through `TessNoteLine`, so one fix covers both. | In `say`: `AccessibilityNotification.Announcement(text).post()`, and `try? await Task.sleep(for: .seconds(UIAccessibility.isVoiceOverRunning ? 12 : 4))`. | High |
| B12 | VO | Features/Home/NowPage.swift:94 | `.accessibilityHint("Touch and hold")` on Finish. VO's double-tap finishes it. | Remove it once A1 lands, or use "Marks it done". | Med |
| B13 | VO | Features/Home/NowPage.swift:285, 299-302 | The ghost capture is kept by a tap but has no `.isButton`. | `.accessibilityAddTraits(.isButton)` (the hint and the "Drop it" action are already there). | Low |
| B14 | VO | Features/Home/HomeSpatialView.swift:116-127 | Full-screen covers (Notes, Review, Groceries, Recipes) close only with the "Close" word or a swipe. There is no `.escape`. | On `link.destination`: `.accessibilityAction(.escape) { presented = nil }` | Med |
| B15 | DT | Features/Home/HomeQueue.swift:77-80, 108, 116, 122, 135, 163-164 | The queue is built from fixed points: `rowHeight` 48, `headingHeight` 40 with `.clipped()`, and a `windowHeight` 156 window. At AX sizes the 21 pt titles and the 34 pt "Later" heading are cut. This is the first screen of the app. | Snippet 6. | High |
| B16 | DT | Features/Home/HomeQueue.swift:309 | The queue title is `lineLimit(1)`. | `.lineLimit(typeSize.isAccessibilitySize ? 3 : 1)` (needs B15) | Med |
| B17 | DT | Features/Home/DayStrip.swift:93 | The pager is `.frame(height: 96)` around a 21 pt voice line plus a 30 pt stroke. At AX sizes the phrase overlaps the hero below. | `@ScaledMetric(relativeTo: .body) var stripHeight: CGFloat = 96` | Med |
| B18 | DT | Features/Home/TrainingPage.swift:77, 176, 239 | `EntryRow` is `.frame(height: 50)` (three places). | `.frame(minHeight: 50)` | Med |
| B19 | DT | Features/Home/NowPage.swift:265, 458 | The ghost capture title and the ledger step line are `lineLimit(1)`. | `.lineLimit(typeSize.isAccessibilitySize ? 3 : 1)` | Low |
| B20 | DT | Features/Home/HomeSpatialView.swift:296-299 | Four uppercase page words share the width, so they break mid-word at AX sizes. | Cap them with `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` and add `.accessibilityShowsLargeContentViewer()`. Tab words are where Apple uses the Large Content Viewer. | Low |
| B21 | RM | Features/Home/NowPage.swift:41 | The ledger row enters with `.offset(y: 10)`; Reduce Motion is not checked. | `MotionPolicy.transition(.offset(y: 10).combined(with: .opacity), reduceMotion: reduceMotion)` | Low |
| B22 | RM | Features/Home/NowPage.swift:297 | The capture commit stroke uses raw `withAnimation(.linear(duration: AppModel.captureDryTime))`. It is a visual timer, so it should keep its duration, but through the policy. | `withAnimation(MotionPolicy.progress(AppModel.captureDryTime)) { stroke = 1 }` (A5) | Low |
| B23 | RM | Features/Home/HomeSpatialView.swift:127 | `.navigationTransition(.zoom(...))` goes around `ArrivalTransition`, which cross-fades under Reduce Motion. | `.modifier(ArrivalTransition(id: link, arrival: .zoom, namespace: linkZoom))` | Low |

**Snippet 5 (B10):**

```swift
.accessibilityAddTraits(.isButton)
.accessibilityActions {
    if !entry.isWorkout {
        Button("Done") { finish() }
        Button("Not now") { move() }
    }
}
```

**Snippet 6 (B15):**

```swift
@ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 48
@ScaledMetric(relativeTo: .title) private var headingHeight: CGFloat = 40
private var windowHeight: CGFloat { rowHeight * 3 + 12 }
// or, at AX sizes, drop the scrolling window and lay the rows out in a plain VStack
```

## Objects and Tess (given to Builder B, see open questions)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| B24 | VO | Features/Objects/ObjectPage.swift:431 | The `arrow.right` symbol inside each action word is read as "right arrow". | `.accessibilityHidden(true)` on the `Image` | Low |
| B25 | DT | Features/Objects/ObjectPage.swift:431 | The same arrow is `.font(.system(size: 17, weight: .semibold))`, a fixed size. | Delete the `.font`; it inherits `.textRole(.bodyStrong)` from line 433. | Low |
| B26 | RM | Features/Objects/ObjectHandle.swift:105, 113 | `HandleButtonStyle` and `PressScaleStyle` use raw `.animation(Theme.Motion.snappy, ...)`. `PressScaleStyle` scales under Reduce Motion. These styles are used on most rows in the app. | Wrap the body in a small `View` that reads the environment (as `LabelActionStyle` does) and use `.tesseraAnimation(Theme.Motion.snappy, value: configuration.isPressed)`. Scale only `if !reduceMotion`. | Med |
| B27 | RM | Features/Tess/TessMotifs.swift:84 | `Tick` uses `.animation(Theme.Motion.snappy, value:)` with a numeric roll and does not check Reduce Motion. | `.tesseraAnimation(Theme.Motion.snappy, value: Int(seconds))` | Low |
| B28 | RM | Features/Tess/TessSoul.swift:245-251 | `SoulTravel` uses raw `.animation`. It checks Reduce Motion, but the soul still travels its 0.76 s arc at a 0.2 s ease. | `.tesseraAnimation(.timingCurve(0.55, 0, 0.15, 1, duration: 0.76), value: position.x)` (and the same for y) | Low |
| B29 | RM | Features/Tess/PaintFlood.swift:26-27 | Two raw `.animation` calls on the same value; the second adds nothing. The opacity flood is not routed through the policy. | One `.tesseraAnimation(.timingCurve(0.6, 0, 0.3, 1, duration: 0.52), value: isOn)` | Low |

---

## Recipes (Core)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| C1 | VO | Features/Recipes/RecipePage.swift:75, 160-180, 264 | Send to Groceries is a left swipe only. The hint tells VO users to "Swipe left", which in VoiceOver moves focus back. There is no action, so a VO user cannot send a recipe to the list. | Move the `onEnded` body into `send(recipe:serves:)`, then on the column use `.accessibilityAction(named: "Add to groceries") { send(recipe: recipe.id, serves: size) }` and the hint "Actions add them to groceries". | High |
| C2 | VO | Features/Recipes/RecipePage.swift:243 | Tapping the amount flips cups to grams. It is a bare `onTapGesture` with no trait, hint or action, so VO can't find it. | `.accessibilityAddTraits(line.line.metricText != nil ? .isButton : [])` and `.accessibilityHint(line.line.metricText != nil ? "Shows it in grams" : "")` | Med |
| C3 | DT | Features/Recipes/RecipePage.swift:242 | The amount column is `.frame(width: 92)`, so "1 ½ cups" clips or wraps badly at AX sizes. | `@ScaledMetric(relativeTo: .body) var amountWidth: CGFloat = 92`, or put the amount above the name at AX sizes. | Med |
| C4 | DT | Features/Recipes/PasteRecipe.swift:266 | The step-number margin is `.frame(width: 22)`, so "10" clips at AX sizes. | `@ScaledMetric(relativeTo: .body) var marginWidth: CGFloat = 22` | Low |
| C5 | VO | Features/Recipes/PasteRecipe.swift:288 | The hint "Tap to read it as something else" names a gesture. | `.accessibilityHint("Reads it as something else")` | Low |
| C6 | RM | Features/Recipes/RecipePage.swift:74 | Under Reduce Motion the ingredient column still slides 1.4 widths off screen when sent. | Under Reduce Motion fade instead: `.offset(x: reduceMotion ? 0 : ...)` and `.opacity(away && reduceMotion ? 0 : 1)` | Low |
| C7 | RM | Features/Recipes/RecipePage.swift:129 | `.navigationTransition(.zoom(...))` goes around `ArrivalTransition`. | `.modifier(ArrivalTransition(id: routeID(route), arrival: .zoom, namespace: zoom))` | Low |
| C8 | RM | Features/Recipes/RecipePage.swift:175, 240 | Raw `withAnimation` and `.animation(reduceMotion ? nil : ...)`. They check Reduce Motion but bypass the policy. | `withTesseraAnimation(.smooth(duration: 0.36), reduceMotion: reduceMotion)` and `.tesseraAnimation(.smooth(duration: 0.22).delay(...), value: line.line.amount)` | Low |
| C9 | RM | Features/Recipes/PasteRecipe.swift:110 | The save bar enters with `.move(edge: .bottom)`; Reduce Motion is not checked. | `MotionPolicy.transition(.move(edge: .bottom).combined(with: .opacity), reduceMotion: reduceMotion)` | Low |
| C10 | RM | Features/Recipes/PasteRecipe.swift:159, 164 | Raw `withAnimation` for the brush pass. Reduce Motion returns early at :153, so this is drift only. | `withTesseraAnimation(.smooth(duration: 0.28), reduceMotion: reduceMotion) { revealed = index }` | Low |
| C11 | RM | Features/Recipes/PortionDrum.swift:68 | Raw `.animation(.easeOut(duration: 0.16), value: isCurrent)`. | `.tesseraAnimation(.easeOut(duration: 0.16), value: isCurrent)` | Low |

## Groceries (Core)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| C12 | DT | Features/Groceries/GroceriesView.swift:431 | The item line is `lineLimit(1)`, so long names truncate at AX sizes. The comment says the name truncates, never the amount, which is right for default sizes only. | `.lineLimit(typeSize.isAccessibilitySize ? 3 : 1)` (read `dynamicTypeSize` in `GroceryRow`) | Med |
| C13 | DT | Features/Groceries/GroceriesView.swift:634, 638 | Tess's note line is `.frame(maxWidth: 270)` with `lineLimit(2)`. | Same as B5. | Low |
| C14 | RM | Features/Groceries/GroceriesView.swift:147, 402, 444, 614 | `.move(edge: .bottom)`, `.push(from: .top)` and `.move(edge: .top)` transitions with no Reduce Motion swap. Line 402 runs for every item added. | `MotionPolicy.transition(..., reduceMotion: reduceMotion)` at each site | Med |
| C15 | RM | Features/Groceries/GroceriesView.swift:508-510, 516, 530-532 | Raw `.animation` inside the aisle and peek transitions. They check Reduce Motion, so this is drift. | Keep the shapes; build the animation from `MotionPolicy.resolve(.smooth(duration: 0.34).delay(0.16), reduceMotion:)`. | Low |

## Notes (Core)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| C16 | DT | Features/Notes/NotesView.swift:173, 179, 187 | The note title and its second line are `lineLimit(1)`, and the `.fixedSize()` time on the right takes width from them. At AX5 a title is a few letters. | At AX sizes use `lineLimit(3)` and move the time under the text (`VStack` when `typeSize.isAccessibilitySize`). | Med |
| C17 | RM | Features/Notes/NotesView.swift:18, 88 | The zoom goes around `ArrivalTransition`, and new notes enter with `.push(from: .top)` with no Reduce Motion swap. | Use `ArrivalTransition` and `MotionPolicy.transition(...)`. | Low |

## Review (Core)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| C18 | RM | Features/Review/ReviewView.swift:247 | Raw `.animation(reduceMotion ? nil : Theme.Motion.house.delay(...))`. | `.tesseraAnimation(Theme.Motion.house.delay(Double(index) * 0.05), value: shown)` | Low |

## Backup (Core)

| # | Check | File:line | What is wrong | Fix | Sev |
|---|---|---|---|---|---|
| C19 | VO | Features/Backup/BackupView.swift:113 | With the system back button hidden, the VoiceOver two-finger scrub may not pop the page (needs a device check). Only "‹ Review" is available. | `.accessibilityAction(.escape) { dismiss() }` | Med |

---

## Summary

80 rows. 9 are High.

| Owner | VO | DT | RM | Total | High |
|---|---|---|---|---|---|
| Builder A | 8 | 16 | 8 | 32 | 3 (A2, A5, A11) |
| Builder B | 9 | 10 | 10 | 29 | 5 (B1, B2, B3, B11, B15) |
| Core | 4 | 5 | 10 | 19 | 1 (C1) |
| **All** | **21** | **31** | **28** | **80** | **9** |

High rows that block a person outright (fix first):

1. **B1, B2 (Tess, BottomChrome):** a VoiceOver user can't close Tess and can't cancel a command that commits
   itself in 2 s (0.6 s with Reduce Motion). This is the worst issue in the audit: it can write wrong data with no
   way to stop it.
2. **C1 (Recipes):** sending to Groceries has no VoiceOver path, and the hint gives the wrong gesture.
3. **B3, B11, A11 (Tess's lines everywhere):** every confirmation and every Undo disappears in 4 s and is never
   announced. There are no `AccessibilityNotification` calls anywhere in the app.
4. **B15 (Home queue) and A2 (stroke word):** the two most-seen pieces of UI clip or run off screen at AX5.
5. **A5 (MotionPolicy):** the policy cannot stop travel, so about a dozen transitions still slide under Reduce
   Motion. One helper fixes the pattern.

## Open questions

1. **Ownership.** `Features/Objects` (ObjectPage, ObjectHandle) and `Features/Tess` (TessSoul, TessMotifs,
   PaintFlood) are not in the owner list. They are given to Builder B here. `HandleButtonStyle` (B26) is really
   design system and could move to A.
2. **Instrument caps.** `RepsDrum` is capped at `.large`, and `RPEStops` and the `WeightDial` labels at `.xxLarge`.
   `TextRole.hero` is capped at `.xxxLarge`. These look deliberate (the drum geometry is fixed). If they stay,
   should they get `.accessibilityShowsLargeContentViewer()` so a long-press shows the value large?
3. **Live Activity type (A32).** Keep fixed sizes on the Lock Screen, or scale with a cap?
4. **MotionPolicy API (A5).** Is a `transition(_:reduceMotion:)` plus a `progress(_:)` exemption the right shape,
   or should the policy become a `ViewModifier` that also strips `offset`/`scale`? Whatever is picked should go
   into `docs/DESIGN_MOTION.md` and the tessera-design skill checklist.
5. **Zoom and Reduce Motion.** If iOS 27's `.zoom` navigation transition already cross-fades under Reduce Motion,
   B23, C7 and half of C17 can be dropped. Check on the simulator with Reduce Motion on.
6. **Escape on custom back words (C19, B14, A10).** Check with VoiceOver on the simulator whether the scrub pops or
   dismisses when the system back button or bar is hidden. If it does, those rows drop to Low.
7. **Auto-commit timers.** The ghost capture (2 s), Tess drying (2 s) and toasts (4 s) are short for VoiceOver and
   Switch Control users. Should the app have one rule, for example "no auto-commit while VoiceOver runs"?
8. **Not covered.** Contrast was not checked (for example `inkTertiary` at 38% and the `0x6E6480` step line on
   NowPage), and neither were Reduce Transparency or Voice Control names. Next step: a MobileBuildMCP pass with AX5
   screenshots of Home, the workout, Groceries and a recipe, plus Accessibility Inspector's audit, to confirm the
   DT rows.
