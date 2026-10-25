# Landing contract (Oct 25, 2026)

The shared rules every room landing follows: Home, Training, Kitchen, Notes, Lists, Routines, Money, Weather and the Settings landing. Builders build to this file. It does not redraw anything; it locks what the approved sheets already say and settles their conflicts (section 10).

Sources, newest approved wins: 246 Notes landing (approved Oct 24, 1:54 AM), 236 Home (v2.2 approved), 241 color roles, 228/227/226 (approved Oct 23, layout bands), 248 Routines woodland (awaiting his verdict, used for Routines only), design bible 01 (rules) and 06 (open questions). Kaushik's words in `docs/handoff/codex-chat-oct24.md` outrank all of them.

A landing is a summary plus a keystone plus doors. Never the full list.

## 1. Frame and the four bands

Frame 402 x 874 pt (iPhone 17), 24 pt gutters. Other sizes scale the gaps, never the slot sizes. No ScrollView on a landing.

| Band | y (pt) | What it holds | Fixed? |
|---|---|---|---|
| Header | 54 - 170 | Room title (Figtree 700 40 pt, room accent, top at 54). One state line under it (Figtree 16, ink2, one line, never wraps). | yes |
| Keystone | 180 - 400 | The room's one expressive element, x 24 - 378 (354 x 220). See section 2. | yes |
| Doors | 432 - 576 | The 3-place dial (section 4). | yes |
| Brief | 612 - 740 | One line at 612 (Figtree 15, ink2, one ink 600 name). Routines may use two update rows in 64 pt slots (17 pt light, name 600). Nothing else. | slot yes, content per room |
| Foot | 768 - 840 | Action word bottom-left, Tess bottom-right. | yes |

- Landings use no section labels, cards, pills, bars, rings, tab bars, door rows at the foot, filter rows or counters ("N of M").
- Home is the one exception to the band table: it keeps its own slots (236 v2.2: board 84-180, mosaic 248 x 160 at 210-370, one thing 400-612, apps 640-760, foot 768-840). The mosaic is Home's keystone and keeps its own size. Every other rule below still applies to Home.

## 2. Keystone slot (one container, every landing)

- Position and size: x 24 - 378, y 180 - 400, 354 x 220 pt, on every landing. The container is one shared view (`LandingKeystone`) that owns the frame, the hit region, arrival, Reduce Motion and the caption line. Rooms supply only the content.
- The slot background is the page color. No border, fill, card or shadow. Content blends into the page at the edge.
- A smaller scene (Routines woodland 354 x 160) is centered vertically in the slot; the leftover 60 pt holds its caption line (Figtree 15, ink2, one line).
- The element is built from the room's own data, reacts to what Kaushik does (add, complete, open), and moves by itself in small ways. Scenes scale with the amount of data; no per-item drawings.
- Behavior is the same everywhere:
  - Tap an element inside it: opens that thing (one tap). In Routines a first tap names a tree in the caption, a second opens it.
  - A drag that starts in the slot belongs to the slot until lift. The page, the dial and the edge zones never take it.
  - Ambient motion: a single-word or single-part moment every 5 s, a re-pack or swap every 40 s, a whole-slot moment every 2 min. Every effect lasts 5 s or less.
  - Arrival: pieces glide into place 22 ms apart on the house spring, finished in about 0.6 s. VoiceOver gets the final state at once.
  - Reduce Motion, Reduce Transparency, Low Power: one calm still frame, no moments, no blur, swaps cross-fade (150 ms). Everything stays tappable.
  - Private items never appear in the slot (word wall) or show as "Private ..." / a count; the app switcher snapshot masks private content.
- Keystone content per room (the slot and behavior are locked; content can be replaced without touching the container):

| Room | Keystone | Status |
|---|---|---|
| Home | the mosaic | built |
| Notes | word wall of note titles (246) | built, approved |
| Routines | habit woodland (248) | specified, unreviewed |
| Training, Kitchen, Lists, Money, Settings | word wall, same engine as Notes, fed by the room's own words (lifts and routines by recency and personal best; pantry, recipes and shopping by what is low or cookable; lists by what is due; bills and categories with no amounts; setting areas by what changed) | interim choice, section 10 |
| Weather | the condition word with its weather effect (236 v2.4-2.8, 243), cloud and fog behavior as specified | specified |

## 3. Type tokens

| Use | Token |
|---|---|
| Room title | Figtree 700, 40 pt (door page title 34) |
| State line, brief | Figtree 400, 16 pt / 15 pt, ink2 |
| Dial focus | Figtree 700, 21 pt x 1.32 (about 28 pt), meaning color |
| Dial neighbors | Figtree 21 pt scaled smaller, ink2 |
| Numbers | Outfit, tabular: 300 below 28 pt, 200 from 28 pt up |
| Units | Figtree 400, ink2, half the numeral, minimum 10 pt, joined by a no-break space |
| Action word | Figtree 600, 20 pt |
| Small labels | 13 pt, 600, tracked 0.06 em |
| Tess's own words | Newsreader italic only |
| Word wall | Figtree 900 capitals, same-color outline 3.5% of size, mitred, tracking -0.01 em, nothing under 13 pt |

- Sentence case everywhere, US words, digits for counts, "6 pm" (not "at 6 pm"), dates as "Oct 12", never a city name, "best" never "record".
- The 2-4 biggest type elements on a page never share a color (241).

## 4. Doors dial (one component)

- 3 places only: focus plus one above, one below. 48 pt slots (his 2:06 AM). Loops.
- Focus is 1.32x, bold, in its meaning color, with its count in Outfit 400 at about half size, ink2. Neighbors are smaller, ink2, depth blur up to 1.8 pt (none under Reduce Motion, Reduce Transparency, Low Power).
- Drag vertically to turn (a tick per door, spring settle). Tap the focus to open the door. Tap a neighbor to turn to it. A tap is held off 120 ms after the dial settles.
- Right of the focus: the room's one fact for that door (13 pt ink2 label, then up to three 16 pt lines, first 700), rising 6 pt into place when the focus changes.
- 3 to 8 doors per room. Dials appear on landings only. Deeper pages use focus wheels, page turns or the Folio.
- The dial owns vertical drags in x 24 - 378, y 432 - 576.

## 5. Touch zones (same on every landing)

| Zone | Rect | Owns |
|---|---|---|
| Back edge | x 0 - 24, full height | back or out; nothing else takes it (a landing's back goes home) |
| Right margin | x 378 - 402 | pull in for the side (glance, then full side) |
| Title | title text | tap opens the room's index |
| Keystone | 24-378 x 180-400 | taps on its parts; any drag that starts there |
| Dial | 24-378 x 432-576 | vertical turn, tap focus or neighbor |
| Brief | line at 612, or the update rows | rows: tap opens, swipe right Done, swipe left Not now |
| Action word | starts at x 28, 44 pt target, y 768-840 | tap does it; drag left or right for options |
| Tess | bottom right, own size | tap opens her; never moves or diffuses |

- Every target is at least 44 pt. Zones never overlap; a parent never decides for a child's region.

## 6. Gesture map

- Swipe right = Done. Swipe left = Not now. One 90 pt step, never two. Undo is 10 s, one app-wide slot; Money reads "Reversed".
- A single swiped element takes both axes (left or up = next, right or down = previous) unless the two axes mean different things. Dials, wheels and rails turn on their own axis.
- Action word: tap does the action. Drag left for stop or remove, right for again or redo. The word leans up to 18 pt; past 56 pt it rolls to the option name with a selection tick; release commits with a medium impact and a receipt ("Thing, what happened." plus Undo). Short of 56 pt it springs back with a soft tick. A side with no option moves 6 pt with a rigid tick. VoiceOver gets each option as an accessibilityAction.
- Thresholds (`gesture-policy.md`, `GestureKit`): drag begins at 10 pt, axis locks at 12 pt, a row arms at 96 pt, a flick is 500 pt/s over 28 pt.
- Long bodies page vertically: swipe up for next page, down for previous, past 40 pt. Pages of 5-6 rows. Horizontal swipes stay with the rows.
- Numbers never step with - / +. They scroll (16 pt per value) and a tap opens a wheel.
- Haptics: one per moment. Tick for picking and scrubbing, soft for landing or marking, rigid for finishing. Never on scroll, never a warning buzz.
- Everything animates through `MotionPolicy` (`.tesseraAnimation`, `withTesseraAnimation`). House spring 0.42 s / bounce 0.12, firm 0.35 / 0, snappy 0.25. No linear curves. No fades on text: reveals are clips or rises. Page slides in from the right, sheets lift like paper.

## 7. Text wrap and overflow

- Every shown piece of text has a fixed slot: fixed width, fixed line count. Text never wraps into a new line and never moves the layout.
- The phone measures each written form (full to short) and shows the longest that fits. If none fits, the on-device model (never Claude) writes a shorter one; names, digits and days survive.
- No smaller font to fit (except big titles that step down 1 pt at a time to about 0.75x, then cut at whole words). No ellipsis, no fade, no "...". Cut on a whole word and drop trailing punctuation and small words.
- VoiceOver reads the full text. Input fields are exempt.
- The fit test runs at default size, AX3 and AX5.

## 8. Dynamic Type, Reduce Motion, accessibility

- Text scales with Dynamic Type through AX5 on every landing; no landing clips a word.
- At AX3 and above: the header state line and the brief collapse to one line using the short form; the dial keeps 3 places (slots grow to fit); the keystone slot keeps its size and its parts stay tappable, so extra words are reached through the dial; the action word scales and Tess keeps her size.
- Reduce Motion: no moments, no blur, no drift, no walking caretaker, no petals; cross-fades 150 ms; the keystone shows one still frame.
- Every control has a VoiceOver label in plain words; every gesture has an accessibilityAction.

## 9. Color roles (241)

- 3 to 4 colors per page, chosen by meaning, never decoration. Color goes on type and 1-2 pt lines only.
- Room accent: title and action word. Kind color: that kind's name, count, focus. State colors are fixed: done green (25803D / 8FC9A0, Money uses sage), late or needs care wine (9A2541 / EE8E9C), best or new gold (7E6A1E / D9C27A), planned or private slate (34506F / A7BCD6).
- Room accents (light / dark): training 0B62AE / 8FB0EE, kitchen 93611A / C49A5E, lists 5E6B1F / B5BE7A, routines 8E4A78 / D59AC4, notes plum 8A4570 / E3A3CB, money sage 3F7A62 / 8DBFA7, weather sky amber C9772E / E8A06A. Settings uses ink (no accent) plus the kind colors.
- Nothing within the Ember distance of Tess's Ember (FF5A26 light / FF6B3D dark), except the room currently cueing her.
- The word wall may use many colors; every other element of the page still holds 3-4.

## 10. Banned on landings

Cards, pills, buttons shapes, bars, rings, gauges, middle dots, filled dots, decorative underlines, lens or glass on swipes, fades on text, "...", "N of M" counters, foot menus, door rows, tab bars, filter rows, pixels or tiles outside the Home mosaic, drawn food stand-ins, fine-line drawings as the keystone, any blur other than dial depth blur, two-color pages, text that wraps or moves layout.

## 11. Conflicts settled (open questions 06, newest approved sheet wins)

1. Keystone slot size: 246 (354 x 220 at y 180-400) beats 248's 402 x 182. The woodland scene is 354 x 160, centered in the slot.
2. Dial slot height: 48 pt (246 approved) over 64 pt (248, 238).
3. Dial on landings only; Pantry/Recipes deeper pages must move to wheels or page turns later (not a landing task).
4. Training, Kitchen, Lists, Money, Settings have no approved keystone. Interim: the shared word wall (246 engine). Money wall shows no amounts and Money stays off Home.
5. Money "About $40 a day left this month" is dropped (133 says no "left to spend"). Brief reads the due line only.
6. Ember: use FF5A26 / FF6B3D (215 final). 241's old values are ignored; its ΔE column is rechecked in QA review.
7. Notes color: plum 8A4570 / E3A3CB per 246.
8. Routines off the phone: private routines only show as "Private routine", all others by name; inside the room names read normally.
9. Swipe left = Not now overrides older left-swipe Remove or Delete; those move to an action-word drag option or an editor.
10. Counters: data values like "6 of 14" are not allowed on landings. Use "6 left" or the word form.
11. Section labels: none on landings (246). Hairline-under-label is not used.
12. Time format: "4 pm" lowercase, per the copy rule.
13. Wheel blur cap: dial 1.8 pt on landings, wheels 0.65 / 1.0 pt elsewhere, never on the focus.
14. Home foot: Undo line bottom-left, no action word (236 v2). Other landings: action word bottom-left.
15. Routines groves: Body, Mind, Home, plus Borrowed (recommended); Mornings and Evenings are filters inside Today. Withering follows 248's thresholds with soft words and no red banner.

## 12. Per-room table

| Room | Accent | Keystone | Doors (dial) | Action word | Empty state |
|---|---|---|---|---|---|
| Home | none | mosaic | n/a (apps list) | none (Undo line) | per 236 |
| Training | 0B62AE | word wall of lifts | This week, Routines, Exercises, Programs, Goals | Start Push A (Log a walk on rest day) | "Rest today. Next is Saturday." |
| Kitchen | 93611A | word wall of pantry and recipes | Pantry, Recipes, Shopping, Leftovers, Meal plan | Cook (Plan tonight when empty) | "Tonight?" with "nothing planned yet" |
| Notes | 8A4570 | word wall of titles | All notes, Ideas, From Tess, Voice memos, Pinned, Mentions, Private, Archive | New note | "Write the first thing down." |
| Lists | 5E6B1F | word wall of due lists | All, Shopping, Trips, Home, People, Watch and read | New list | "Nothing due this week." |
| Routines | 8E4A78 | woodland | Today, Body, Mind, Home, Fruit, Across the lake | Plant | "Quiet day" |
| Money | 3F7A62 | word wall of bills and categories, no amounts | Bills, Subscriptions, Income, Savings | Add a spend | "Nothing yet" |
| Weather | C9772E | condition word with effect | Hours, Week, Air | Rain alert | per 243 |
| Settings | ink | word wall of setting areas | Tess, Privacy, Units, Claude, Backups, About | none | n/a |

## 13. Shared components to reuse

`LandingPage` (frame and bands), `LandingKeystone` (new, section 2), `DoorsDial` (section 4, from the Notes dial), `LandingZones` and `GestureKit` (section 5-6), `MotionPolicy`, `TessFont`, `WordFit` (fixed slots), `AppAccents` and `Theme` tokens. No landing may define its own slot geometry, dial, swipe thresholds or animation curves.

## 14. Test and evidence per landing

- UI tests: tap keystone part, tap and drag dial, swipe row right and left (Done, Not now, Undo within 10 s), action word tap and drag options, back edge, right margin.
- Fit tests at default size, AX3, AX5; Reduce Motion on.
- Simulator recording (raw clips stay gitignored, trimmed clip kept) and Reduce Motion and AX5 stills.
- `scripts/test.sh` ends "All green" on the exact head; Release build; install on sample data.
