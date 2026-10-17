# Kitchen cook mode: accessibility acceptance (K84)

*Kitchen lead, 2026-10-17. Docs only. Rows K84.1 to K84.30. This file adds the accessibility pass for cook mode and does not restate existing rows. Rows it leans on keep their ids: `cook-mode-acceptance.md` (the cut, the UI bar, the recipe-clock rulings 1 to 5, O1 to O4), `meal-plan-groceries-acceptance.md` (MP-F1 to MP-F7), `kitchen-refill6-lane2-acceptance.md` (K40.4, K40.5, K40.11, K41.12), `kitchen-refill5-acceptance.md` (K29.12), `kitchen-widget-wash-acceptance.md` (KW-W15, KW-W17), `kitchen-first-use-empty-states.md` section 6, `parallel-steps-acceptance.md` (PS14).*

## Rules these rows hold to

- **House copy.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a clock time. Clocks are lowercase ("8:30 pm", "12 pm"). Counts are digits. US English. A private cook reads "Private recipe" on every surface, spoken or drawn.
- **Cobalt is Tess's voice only.** No focus ring, button or timer takes cobalt. Vermilion is for "running" only.
- **Never sums.** Nutrition is never added up. No row in this file speaks or draws a meal total, a day total or a "calories left" figure. A step or a recipe may read its own per-serving figure only.
- **UNDO.** 4 s for a new capture, 10 s for a change or a remove, and a flat 10 s under VoiceOver (`decisions.md` 1:48 PM Oct 16, C3).
- **Setup for all rows.** Weeknight dal (6 steps, step 2 timed "8 minutes") on iPhone 17, Porcelain, unless a row says otherwise. Existing UI bar still holds: every target at least 64 pt, no text under 16 pt, no cards, pills or modals, screen stays awake.

## A. Dynamic Type (up to the largest accessibility sizes)

| # | Given / When / Then |
|---|---|
| K84.1 | **Given** cook mode open on step 1 at the default size. **When** the text size is set to each of XS, L (default), XXXL, AX1, AX3 and AX5 (no relaunch). **Then** the step words scale with the setting and wrap in full at every size; nothing is cut with an ellipsis; no word is truncated mid-line. At AX5 the step view scrolls inside its own area, and the bottom key stays on screen (K84.9). |
| K84.2 | **Given** AX5. **When** step 2 is shown with its scaled amounts under the title. **Then** the amounts go to one column, one amount per line ("1 cup red lentils", "2 cups water"); nothing overlaps the title; the 16 pt floor holds (nothing drawn smaller than the scaled body). |
| K84.3 | **Given** AX5 and a running timer on step 2. **When** the horizon line, the timer label and the key row are on screen together. **Then** the key row reads "8 MIN LEFT" (digits), wraps to a second line before it clips, and is never replaced by an icon. The horizon line stays a drawn line at its set height (points, not scaled), like the wash in KW-W15; only its label scales. |
| K84.4 | **Given** AX5 and two timers running ("Simmer" and "Bread · 8 MIN"). **When** the stack draws. **Then** each timer keeps its own labelled line, soonest first; lines stack one per row and none is dropped; the "+1" of the Live Activity is not needed on screen because both lines show. |
| K84.5 | **Given** AX3 and the Weeknight dal long step ("Add the lentils, stir, and simmer 20-25 min until soft"). **When** the step is read. **Then** the minutes show as "20 MIN" (the lower bound, per the cook-mode defaults) beside the step, wrapping under the words rather than pushing them off screen. |
| K84.6 | **Given** AX5 and the last step. **When** the Done key draws. **Then** it reads "DONE" in full, at least 64 pt tall, full width, and wraps its hint "Hold to finish" under it rather than shrinking the word. |
| K84.7 | **Given** AX5 and Tess's line after a stop: "Simmer stopped." with UNDO. **When** the slot opens. **Then** the line wraps to as many lines as it needs and UNDO keeps a 64 pt target in the same slot; the slot never covers the Next key (it rises above it). |
| K84.8 | **Given** AX5 on the private cook of a recipe. **When** the page opens. **Then** the title reads "Private recipe", wrapped if needed, and no scaled layout path shows the name. |

## B. One-handed use (thumb reach)

Reach zone: the bottom 60% of the screen is the thumb zone for a right or left hand holding the phone at its base. The top corners are out of reach and are never the only way to do anything.

| # | Given / When / Then |
|---|---|
| K84.9 | **Given** any step, any text size. **When** the screen is measured. **Then** the Next target is a full-width bar anchored to the bottom safe area, at least 64 pt tall (88 pt from AX1 up), labelled "NEXT" and with the hint "Next step". One tap moves one step. It is reachable with one thumb from either hand with no reach to the top half. |
| K84.10 | **Given** a step with a timer key row. **When** the controls are laid out. **Then** the hold-to-start timer key sits above the Next bar and inside the bottom 60%; no timer start, stop, extend or Next control lives only in a top corner. |
| K84.11 | **Given** cook mode is open. **When** every control is listed. **Then** each has a thumb-zone path: Next (bottom bar), timer keys (above it), stop a timer (drag its line left, or the Stop action in K84.20), Done (the bottom bar on the last step). The close of the cover is also reachable by dragging the cover down from anywhere on the step view, not only from a top-corner control. |
| K84.12 | **Given** the cover's top-left or top-right corner. **When** a control is drawn there (for example the back word). **Then** it is an extra and never the only exit; remove it in a test build and every action in K84.11 still works. |
| K84.13 | **Given** the swipe-up gesture in the cook-mode acceptance script step 2. **When** the same phone is used one-handed. **Then** Next does the same job as swiping up: step 2 arrives and step 1 stays as a dim line above it. Swiping up stays; the bottom bar is the large target alongside it, not a replacement. The two never both fire from one touch (one touch, one step). |
| K84.14 | **Given** the last step. **When** the bottom bar is held. **Then** the bar's label changes from "NEXT" to "DONE" with no layout shift (same height, same place), the hold fills left to right, and release before it completes does nothing. A single tap on DONE gives a short haptic and the hint "Hold to finish", and never finishes by accident. There is no confirm and no note field. |
| K84.15 | **Given** a running timer's line near the top of the screen. **When** it is stopped one-handed. **Then** a drag left anywhere on its line stops it (the line is at least 64 pt tall); the receipt "Simmer stopped." with UNDO appears in the bottom Tess band, in thumb reach. |
| K84.16 | **Given** a left-handed or right-handed grip. **When** the Next bar is touched at its left end and at its right end. **Then** both advance one step; the bar has no dead zone and no side-weighted label. |

## C. Reduce Motion

| # | Given / When / Then |
|---|---|
| K84.17 | **Given** Reduce Motion on. **When** a step advances (Next, swipe up, or "next" by voice). **Then** the slide is a 150 ms crossfade in place; the dim line above still shows; the order of steps is unchanged. |
| K84.18 | **Given** Reduce Motion on and a timer ends. **When** the flare would play. **Then** the line turns cadmium and the step returns as a 150 ms fade, with the haptic still given; no pulse, no loop. The flare stays until the timer is stopped (cook-mode default 8). |
| K84.19 | **Given** Reduce Motion on. **When** the cover opens and closes, a horizon line burns down, and Finish completes. **Then** the cover fades (no rise), the horizon line steps down once a minute instead of burning continuously, and Finish fades the cover out; Tess's line appears with a 150 ms fade ("Weeknight dal, first time."). Color and wording are the same as with motion. |

## D. VoiceOver (labels, order, UNDO, receipts)

| # | Given / When / Then |
|---|---|
| K84.20 | **Given** VoiceOver on, step 2 of 6 with a running timer. **When** swiping right through the screen from the top. **Then** the reading order is exactly: (1) "Weeknight dal, cooking" (heading), (2) "Step 2 of 6", (3) the step's words, (4) the scaled amounts, one stop per amount line, (5) the timer, "Simmer, 8 minutes left." (durations in words, as in K41.12), (6) Tess's line if one is showing, (7) "Next", button, hint "Next step". Nothing decorative is a stop (horizon lines, the dim line above, the wash). Custom actions on the timer: "Stop" (hint "Ends this timer"). |
| K84.21 | **Given** VoiceOver on. **When** focus rests on the Next key and the user double-taps. **Then** the step advances, focus lands on the new step's "Step 3 of 6" stop, and "Step 3 of 6" is announced once. Focus never lands on the dim line above. |
| K84.22 | **Given** VoiceOver on, a timer reaches zero while focus is elsewhere. **When** the flare plays. **Then** one announcement, high priority, focus does not move: "Simmer is done." The line reads "Simmer, done. Stop." with the Stop action. No second announcement repeats it. The notification banner is replaced by the flare while cook mode is open (cook-mode default 3). |
| K84.23 | **Given** VoiceOver on, a running timer. **When** the swipe-left stop is not possible. **Then** the timer's Stop custom action does the same job, and the receipt "Simmer stopped." is announced once, high priority, focus does not move. The UNDO is held 10 s (not 4 s), its label is "Undo", role button, hint "Puts Simmer back". UNDO is the last stop before Tess's line, as in K40.4. |
| K84.24 | **Given** the UNDO of K84.23 is showing under VoiceOver. **When** the user moves focus away and back, or waits 8 s and then double-taps Undo. **Then** after 8 s the slot is still there; the double-tap brings the timer back with its real time left, and Tess says "Simmer, back." After 10 s with no action the slot closes silently, with no announcement of the closing. |
| K84.25 | **Given** VoiceOver on and a step with an ingredient peek key. **When** the key is focused. **Then** it reads "Add 7 to Groceries", button, using the same dry-run count as the visible key (cook-mode rulings, item 2). At 0 the key is not in the tree. Activating it announces "Chicken, 7 added." once, high priority (the short name, thing first), UNDO held 10 s under VoiceOver, focus to Tess's line. For a private recipe it announces "Private recipe, 7 added." (K29.12 pattern: never the name, never a price). |
| K84.26 | **Given** VoiceOver on, the last step. **When** the bottom bar is focused. **Then** it reads "Done", button, hint "Hold to finish"; a double-tap-and-hold finishes. VoiceOver's own double-tap alone does not finish and says "Hold to finish" (the same safeguard as K84.14). A named action "Finish" is offered on the bar so a user who cannot hold can complete it. |
| K84.27 | **Given** VoiceOver on, Done completes on Weeknight dal. **When** the cover closes. **Then** the receipt is read thing-first: "Weeknight dal, cooked." once, high priority, then the log line if the user moves to it ("9:05 am, Cooked weeknight dal, 45 min" per O1 to O3). UNDO held 10 s with hint "Reopens the cook on its last step". For a private recipe it reads "Private recipe, cooked." |
| K84.28 | **Given** VoiceOver on and a cook started from a plan task (MP-F1). **When** Done completes. **Then** one announcement, not two: "Tacos, done." (the MP-F1 receipt); the plan task's closing is silent. UNDO inside the 10 s window restores both the cook and the plan task (MP-F2), and the announcement is "Tacos, taken back." For a private recipe: "Private recipe, done." (MP-F6). |
| K84.29 | **Given** VoiceOver on, with a Reduce Motion and a Dynamic Type AX5 setting also on. **When** the screen is read end to end. **Then** the reading order is the same as K84.20 at every size; no stop is dropped when the text wraps; the Next bar stays the last stop before nothing else follows. (Same rule as K40.15.) |
| K84.30 | **Given** VoiceOver on the Lock Screen with a cook running (the Live Activity) and a private cook. **When** swiping through. **Then** it reads "Private recipe. Simmer, 8 minutes left." and the Stop button reads "Stop", hint "Ends the cook" (K41.12). Spoken clocks follow house copy: "Dinner, 8:30 pm." (no preposition before the clock). |

## Notes for the build

1. **Two defaults overlap here and need a ruling.** The cook-mode cut says "Swiping is the only way to change step" (default 4) while the first-use sheet (section 6) says the one action is the "Next" key and the voice command "next". K84.9 and K84.13 hold both: the bottom bar and swipe up. Product can overrule; if the bar is dropped, K84.9, K84.11, K84.13, K84.16, K84.21 and K84.29 change (VoiceOver would need "Next" as a custom action on the step instead).
2. **Target height.** The first-use sheet says the key is at least 44 pt; the cook-mode UI bar says at least 64 pt. These rows use 64 pt (88 pt from AX1), the stricter bar.
3. **Not repeated.** The 10 s UNDO window itself, the receipt grammar and the nutrition rule are unchanged; the never-sums rule is why no row speaks a total.
