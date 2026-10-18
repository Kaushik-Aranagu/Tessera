# Groceries and Lists motion under the new rulings, and a Home and Settings Low Power pass (board items 59, 60)

For: Builder A (flag, haptic origin, shared line), Builder B (Groceries, Lists, Home), Design (zoom, line spot), QA. Written Oct 17, PM (Pacific). Read from the code on master `eaa4c305` (file:line below) and from kitchen gap hunt 17 (G244 to G250). Kitchen gap hunt 18 was not on master when this was written; if it grades the same lines differently, its number wins and only that row changes. Product's rulings (decisions.md 9:17 PM Oct 17, project mirror line 1009): the Low Power zoom into a screen is a 150 ms crossfade (G247); one shared Tess line with UNDO on every full-screen layer (G250); haptic weights: check and uncheck light, Done and Clear success, Reset medium (G249).

**One flag.** `isReduced` = Reduce Motion or Low Power (D5, cached, updated on `NSProcessInfoPowerStateDidChange`); every `reduceMotion` below means it. Meaning never changes in the reduced form: same strike, same count, same words, same haptics.

## 59. Groceries and Lists

### Reduced forms (what normal does today, what replaces it)

| Moment | Normal (code) | Reduced (RM and LP) |
|---|---|---|
| Zoom from the Kitchen word into either screen | system `.zoom` (HomeSpatialView:174) | 150 ms crossfade; the word does not fly. Cover mechanism is Builder A's; the rule is "no travel, 150 ms". Same rule for the workout rise (RootView:65, which already waits 150 ms) |
| Check a grocery | ink strike 320 ms, 450 ms wait, sage dab arcs 520 ms into the basket (two curves), count rolls, basket breathes 1.04 for 200 + 200 ms (GroceriesView:259-293) | strike is a 150 ms ink fade, wait 150 ms, no dab, count crossfades 150 ms, no breath. Light tap at the end of the strike, as normal |
| Aisle handoff in the shop | outgoing folds back 260 ms, incoming rises 14 pt out of a 4 pt blur, 340 ms from 160 ms; "then Dairy" blurs 120 + 220 ms (:543-598) | one 150 ms crossfade for the hero and the peek (the 0.18 s literals at :580 and :591 become the policy's 150 ms: G246) |
| Process seam while shopping or a list runs | `TimelineView` at 60 fps for the whole trip (Machined:189; G244) | still and lit. Normal power: the timeline runs only across the 1.35 s glint, then the seam rests with no tree re-evaluation |
| Ground wash drift, hold-key sheen and bead (G248) | `repeatForever` drift 7 to 8 s; sheen and bead on release | wash paused; no sheen, no bead. The key still fills left to right and completes with the same haptic |
| Lists: pick moment | name lifts out on a spring (0.52 s, bounce 0.18, scale 0.4 in, 2 pt blur); skip eases 180 ms then waits 200 ms (ListsPick:22-35, 83) | 150 ms crossfade in, 150 ms out; the 200 ms gap before the next pick stays (a beat, not motion) |
| Lists: finished section | scales away to 0.96 with a 2 pt blur (ListsView:258-293); chevron turns | 150 ms fade, no scale, no blur; the chevron swaps with a crossfade |
| Lists: REMOVE word on the swipe | rises 6 pt as it reveals (ListsSwipe:31) | opacity only, no rise |
| Lists: page entrance | rise with hero blur, 120 ms stagger (Editorial:59-81) | 150 ms fade, no stagger |
| Receipts and the shared line | 300 ms blur-in (see below) | 150 ms fade, no rise |

Dead code to delete (G247): the `reduceMotion ? .easeInOut(0.2) : ...` ternaries inside `withTesseraAnimation` (ListsView:539, 680, 694; ListsPick:35). The policy already returns 150 ms, so the one number is 150.

### The shared Tess line with UNDO on every full-screen layer (G250)
- **One view, drawn by every full-screen layer** (the Pantry's pattern), sitting between the page's content and its keys. On Groceries it sits above the basket; the basket stays where it is (no push down while the line shows): the line owns a reserved row of one line's height, so adding a grocery with something in the basket moves nothing.
- **Arrives** with the house line motion: a 300 ms blur-in with an 8 pt rise (reduced: 150 ms fade, no rise). **Leaves** when the hold ends (4 s for a new thing, 10 s for a change with UNDO; VoiceOver 10 s) with a 240 ms fade (reduced: 150 ms). A new line replaces the old one in place with a crossfade, never stacked.
- **UNDO** is the last stop in the line, a button, in the same view, reachable by VoiceOver (G250's test: add a row with one in the basket; the line and UNDO are in the accessibility tree). Pressing it removes the line with a 150 ms fade and plays the map's `.undo` once; the thing's own reversal motion follows (a grocery returns to its aisle with the house 320 ms fade-and-rise, reduced 150 ms).
- **At accessibility sizes** (G259) the line grows to as many lines as it needs, full width minus the gutters; the reserved row grows with it over 320 ms (reduced: 150 ms crossfade, no growth animation).
- **Words and haptics** are as ruled elsewhere ("Rice, on Packing.", "Packing, done.", "Packing, reset."; thing first, private forms unchanged). The line itself never has a haptic; the haptic belongs to the action that wrote it.

### Haptic weights (G249), one per moment
| Moment | Haptic | Whose | In Low Power | In quiet hours |
|---|---|---|---|---|
| Check a grocery or a list item | light impact, at the end of the strike | his touch | yes | yes |
| Uncheck | light impact, same weight, at its landing | his touch | yes | yes |
| Done (the shop finished, a list run finished), Clear the basket | `.done` (success pattern); one per finish | his action | yes | yes |
| Reset a list | `.aisleCleared` (medium impact); one per reset | his action | yes | yes |
| Aisle cleared by his last strike in it | `.aisleCleared` (medium), keyed to his strike, not to the aisle value, so an UNDO or a row landing from Pantry or the Bar never buzzes (GroceriesView:581) | his touch | yes | yes |
| Pick lands (ListsPick) | `.pickedUp` (light 0.5) stays until Product rules 12.2's "medium" | his touch | yes | yes |
| Remove armed on the swipe | `.selection` (ListsSwipe:34) | his touch | yes | yes |
Done, Clear the basket and Reset are named-action-only for VoiceOver (G258, 9:17 PM): double tap speaks the hold hint, the named action completes, and the haptic above plays once either way; UNDO covers each for 10 s.

Rules: raw `.sensoryFeedback` on these screens (GroceriesView:209, 402, 581) goes through `tesseraFeedback`; `Haptic` gains an origin (his touch, or Tess's landing) so a landing can follow quiet hours; nothing on these two screens is a Tess landing today. Tests: `uncheckPlaysLightImpact`, `finishPlaysOneDone`, `resetPlaysMedium`, `undoDoesNotBuzzAisleCleared`, `lowPowerKeepsGroceryHaptics`.

## 60. Home and Settings Low Power pass (static read, nothing run)

Rule: in Low Power, ambient motion stops, motion that carries meaning becomes a 150 ms crossfade, ticks are system-driven or on the minute, haptics of his touches stay. Every row below keys off Reduce Motion only today.

| Where | Today | In Low Power (and RM, if it differs) |
|---|---|---|
| Now's pending-capture words and a plan row waiting to be kept: breathing words (NowPage:496, HomePlan:307) | `TimelineView` at 30 fps, paused by Reduce Motion only | paused at the breath's mean; the words and the dry-ink moment unchanged |
| Day stroke's end (DayStrip:227) | `repeatForever` blur and opacity breath, 1.8 s | still at rest values (blur 0.4, opacity 1) |
| Training lane's waiting guide (TrainingPage:622) | 20 fps breath | still at 0.9 opacity (the value Reduce Motion already uses) |
| Ground with the time-of-day sky (ThemeLayers:128), where the look has one | 15 fps drift | one frame at the hour's tint, refreshed at the next hour boundary with a 150 ms crossfade |
| Tess's thinking glyph for looks without the soul as the indicator (ThinkingIndicator:20) | `TimelineView` at 60 fps, `paused: false`, always, even in Reduce Motion | Low Power 30 fps; Reduce Motion no turning, a slow opacity pulse (0.85 to 1 over 3.2 s, as her idle). It stays alive: a still thinking mark reads as stuck |
| Queue row finish (HomeQueue:451-478) | strike 420 ms, dry, hold 900 ms, then the op lands and the queue closes up | the reduced path that exists for RM: ink strike 150 ms, no wet phase, op lands after 150 ms; the receipt, UNDO and haptic are the same |
| Queue row "becoming next" bloom (HomeQueue:431) | 500 ms wash | none |
| Zoom into the Kitchen screens and the workout rise | `.zoom` | 150 ms crossfade (G247, above) |
| Soul, page turns, sides | already ruled (D5, R3) | no change |
| Seam and clocks on Home | 30 s periodic ticks (RootView:48, NowPage:226, DayStrip:108); DrainBar 1 s | unchanged except the DrainBar and the cook figure, which follow `tess-cook-clock-lowpower-and-timer-end.md` (item 56) |
| Settings, Claude section (ClaudeSection:109, 278) | transitions `.opacity` plus a 6 pt offset, run through the policy so they last 150 ms but still move 6 pt | opacity only, no offset |
| Settings, monthly budget bar (ClaudeSection:432-438) | draws left to right over 0.5 s unless Reduce Motion | fills in place, no draw, in Low Power too |
| Settings, rest-day sentence and the stray literals (RestDaySentence; ClaudeSection:191 `0.18`) | policy-routed except the `0.18` | the literal goes through the policy's 150 ms |
| Settings, Page turn preview (tess-finish-hero-settings-paging.md item 40) | plays once per pick | the mini page crossfades 150 ms; no growing row |
| Settings, pin a look | `.pinned` haptic, paint flood from the soul 700 ms | flood is one pass and stays (tess-motion.md 13); haptic stays |

Checks: one device pass with `-lowPower` and a real toggle: Home at rest for 30 s draws nothing that moves; Training with a waiting lane shows a still guide; the Claude section opens with no 6 pt slide; `reduceMotionFlagIncludesLowPower` (one unit test on the flag, as gap hunt 16 G219 asks) covers every row at once.

## The kitchen timer end is `timeUp` (settled)
`Haptics.swift` names `.timeUp` (heavy impact 0.9) for "Rest is up, or a kitchen timer ends, with the app on screen", and the cook sheet said `.success`. Product ruled at 9:18 PM Oct 17 (decisions item 2) that the haptic map wins: the kitchen timer end is `timeUp`, and it plays in Low Power. The cook sheet in #946 carries it (fixed in eb69f1de).
