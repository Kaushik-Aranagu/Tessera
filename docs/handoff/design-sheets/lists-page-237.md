# 237 Lists inner page (board https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik)

Builds on 226 (landing) and 217 (Lists room). Owner: Builder B (Lists).

## Palette (3 colors + ink)
- Olive accent 5E6B1F / B5BE7A (5.4:1 on paper, 10.6:1 on black): the dial focus, the focused list, the list title, actions, the check strike.
- Slate labels 34506F / A7BCD6 (7.6:1 / 10.8:1): small-caps "Your lists", "List" / "Private", "Done".
- Wine 9A2541 / EE8E9C (7.1:1 / 9.0:1): due only: "Fri" beside a thing, "due Friday", the count of a list due soon.
- Ink and ink2 for everything else. No underlines.

## Landing
- Dial (232 spec), lenses Going / Due soon (due by Saturday) / Done (every thing checked) / All, looping.
- Brief from templates: "19 things left across 7 lists. Before the trip is due Friday."
- Depth wheel (254 pt band):
  - A header row rides above the first list: small caps "Your lists" in slate, then "7 lists, due first" at 13 pt.
  - Focus: the name in olive Semibold, 26 pt fitted down to 21 pt, then whole words.
  - Detail line 1, 13 pt: "5 of 9 left, due Friday" (the due part in wine Medium) plus ", private".
  - Detail line 2, 15 pt ink2: the next open things, whole items only, e.g. "Passports, Both chargers, The blue jacket".
  - Other rows: 17 pt stepping to 15 pt ink2 with the count left (wine when due soon). Depth blur 0.65 / 1.0 pt, never on the focus, behind "Depth on wheels".
  - Order: due soon first, then most recently touched.
- Foot "New list": tap to start a new list with the add line open. Drag right for "Private list".

## A list (slides from the right; back by the left edge)
- Header: the lens on the left, "5 of 9 left" or "All done" on the right.
- Title in olive, fitted 28 pt down to 21 pt. Meta: small caps "List" or "Private", then "9 things, due Friday".
- Rows are 40 pt, at 19 pt. Open things come first, in their order. Then a "Done" small-caps label, then the checked things in ink2, struck by a 1 pt olive line. Each due thing shows its day at 13 pt in wine.
- Tap a thing, or swipe it right past 70 pt, to check it. The line draws left to right over 260 ms with a .medium impact. After 520 ms the thing drops to Done: "Passports, done. Undo". The last thing reads "Before the trip, all done. Undo".
- Swipe left for Not now: it moves to the end of the open things, "Cash for tolls, not now. Undo".
- Tap a done thing to bring it back: "Passports, back on the list. Undo".
- More than 400 pt of rows pages vertically ("1 of 2"). Swipe or scroll turns the page with the spring.
- Adding:
  - Tap "Add" and a new line opens at the top with the caret in olive. The word becomes "Done".
  - Return adds the line ("Travel pillow, added. Undo") and opens the next one.
  - Esc, tapping away, or "Done" ends adding. Text that was typed is kept.
- Gestures on the action word (230 rule):
  - "Add" dragged left: "Clear done" (removes the checked things: "4 done, cleared. Undo"). If there are none: "Nothing done to clear."
  - "Add" dragged right: "Uncheck all" (to use a list again, e.g. packing): "Before the trip, all unchecked. Undo".
  - No gestures while adding.
  - Each option is also an accessibilityAction.

## Privacy
- A private list shows its real name and things inside the Lists room only. Everywhere else (the landing headline, Home lines, notices, widgets, Live Activity, Siri, Tess and Claude lines, backups) it reads "Private list" (shownLabel).
- Private list things never go to Claude. Ordinary lists go only with asksClaude on, each with a sent-log row.
- Groceries are not a list. They stay as Pantry To get (the earlier ruling). The Home Shopping face (236) reads To get.

## v2, Oct 23 10:20-10:25 PM (his asks + the coordinator's rulings on the review)
Board v2: https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik

**Kinds row (his 10:20 / 10:23 PM; a shared pattern for every room).**
- At top 46, 30 pt tall, the phrase "Lists / 8 lists" is replaced by a horizontal row of kinds, each with a count: All lists 8, Shopping 2, Trips 1, Home 2, People 1, Watch and read 2.
- The current kind sits first at x 0: 17 pt Semibold ink, with its count at 15 pt in the accent. The others follow at 20 pt gaps, 15 pt Regular ink3, with 13 pt counts. The row is clipped at the right edge, with no "...".
- To change kinds: drag the row (it snaps on a spring to the nearest kind, or moves one kind past 30 pt), tap a kind, swipe across the dial horizontally (past 50 pt, as long as the swipe is more horizontal than vertical), use a trackpad horizontal swipe, or press the left and right arrows. Each change gives a tick.
- Changing the kind changes:
  - the dial's lenses, which slide 28 pt in the direction of travel and spring back;
  - the lists in the wheel, with the same clip-in;
  - the brief;
  - the action word.
- Lenses per kind (same filters underneath):
  - All: Going / Due soon / Done / All
  - Shopping: To get / Due soon / Got it all / All
  - Trips: To pack / Due soon / Packed / All
  - Home: Going / Due soon / Fixed / All
  - People: To call / Due soon / Called / All
  - Watch and read: Up next / Halfway (started but not finished) / Finished / All
- Lists carry a kind. A new list takes the current kind, and All leaves it unfiled.
- Accessibility: a tablist, each kind a tab with its count in the label.
- Any room with more than one way to sort things uses the same row above its dial, for example Notes (All, Work, Home, Ideas), Kitchen (Pantry, Recipes, To get) and Money (by pool). Builder B owns the shared component; it goes in the element kit.

**Tighter dial (his 10:20 PM).**
- Rows go from 64 to 46 pt. The focus is 40 pt, with neighbors at 22 pt.
- The dial is 140 pt tall (top 84). The brief moves to 236.
- The wheel moves to 294 and is 310 pt tall, so it gains about one and a half lists.
- Dial neighbors take the depth blur too (wheel rule).

**Action word, renamed (his 10:20 PM: a cooler name than "New list").** It now names the kind:
- All: "Start fresh"
- Shopping: "Start a run"
- Trips: "Pack a bag"
- Home: "Start a project"
- People: "Start a call list"
- Watch and read: "Save a pick"

Drag right still makes a "Private list".

**237 review rulings.**
1. Title shrink stays.
2. Wine: he's fine with pink and wine used sparingly (10:25 PM). Keep EE8E9C in dark and 9A2541 in light, for due only.
3. A checked thing stays struck in place for 1.5 s. Each new check restarts the wait, so a run of taps drops to Done together. Tapping a struck thing before it drops takes it back, with a tick. Undo returns the things to their old places. Reduce Motion waits 0.6 s. Leaving the list drops the pending things at once.
4. "Clear done" reads "Cleared 5 done. Undo". Cleared things stay recoverable through the op log for 7 days. Keep the 28 pt inset.
5. Blur stays on every depth wheel, behind the switch.
6. Autosave while adding: tapping away or Esc keeps the last thing typed.

**Privacy (his 10:25 PM).** SUPERSEDES line 43: under lab mode, private list things MAY go to Claude, each with a sent-log row, and asksClaude still gates it. shownLabel still holds off the phone. Private things stay out of notices, widgets and backups as before.

## v3, Oct 23 10:33 PM (his asks): one kind at a time under a glass lens; a deeper dial
Board v3: https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik
- **Dial depth.** Neighbors drop to 16 pt (0.4x of the 40 pt focus; it was 22) and take the wheel blur, so they read as far behind. Rows stay 46 pt apart.
- **Kinds row = one kind at a time** (top 42, 38 pt). It shows only the current kind with its count (17 pt Semibold ink, count 15 pt accent), plus "1 of 6" (13 pt Outfit ink3) at the right, which hides during a drag.
  - Each kind is a full-width page. The row follows the finger 1:1 with a 0.3x rubber band at the ends. On release it commits past 22% of the width or on a flick of 0.5 pt/ms or more, otherwise it springs back.
  - Every change gives a selection tick.
- **Glass lens (SAVED PATTERN for every horizontal swipe in the app, his 10:33 PM).**
  - On touch-down, a clear Liquid Glass lens rises around the item: a capsule 36 pt tall, sized to the item plus 28 pt. It springs from 0.86 x 0.8 to 1.
  - It has no frost. Through it the content shows slightly saturated (1.7x) and brighter. It has a bright top rim, a soft lower rim and a faint shadow. In SwiftUI this is `.glassEffect(.clear.interactive())` in a capsule.
  - The text under it swells up to 1.07x as it passes the lens's middle.
  - While dragging, the lens holds the current item. Past 20% of the way it glides (0.16 s) to the incoming item and resizes to fit it.
  - On release it eases back over 0.4 s and is gone.
  - Reduce Transparency: a 1 pt ink3 rim only. Reduce Motion: no swell, and the lens appears in place.
  - This is the one exception to "Liquid Glass on the navigation layer only". It applies only while a finger is on a horizontal swipe control.
  - Use it on the kinds rows in every room, the one-thing pager on Home, the mosaic face swipe, and Training's unit swipe.

## v5 lens (his 10:46 PM, Oct 23)
- Not a pill. The lens is a still, soft-cornered slab at the right of the row: 34 pt tall, corner radius 9, a 0.5 pt hairline in ink at 16%, a faint brightness lift (1.05) and 3% ink wash. No top highlight, no saturation, no refraction.
- The text never travels outside the lens. While a finger is on the row, the row closes down to the lens like an iris (clip to the lens shape) and is seen only through it. On release it opens back to the full row.
- While the lens is up, kinds pass at lens spacing (the wider word plus 44 pt), 1:1 with the finger, so the next word enters as the last one leaves. The lens is never empty. Its width eases between the two words.
- Up/down swipes roll the next word through the same lens.
- Reduce Transparency: hairline only. Reduce Motion: the iris and swell are skipped; the word swaps in place.
- Phone: a ZStack with the item text clipped by the same RoundedRectangle(cornerRadius: 9, style: .continuous) mask the lens draws; clip inset animates with the touch state.
