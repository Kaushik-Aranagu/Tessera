# Landing contract (Oct 25, 2026, v2: updated for Kaushik's final design set, TESS.md and tess.tar.gz, 2:13 PM PDT)

> **v2 overrides, newest wins.** Where this file and the list below disagree, the list is right.
> 1. **Slot:** the keystone is 354 x 182 pt at top 196 on 402 x 874, 24 pt side margins, the Home mosaic's slot, on every landing (not 354 x 220 at 180). More content pages inside it (the Galley tickets flip); the band never grows. A picture keystone may bleed to the full 402 pt width if its edges dissolve into the page (the Watch woodland does).
> 2. **The centrepiece stays through the whole room:** on level 1, 2 and deeper pages it stays in the same slot, live to what the lower part shows (the Galley pass is the model).
> 3. **Landing stack (hub 282):** title 40 pt room color; the sentence at top 106 (26 pt light, key phrases bold in role colors; the Log keeps its 16 pt ink2 line from 246); keystone at 196-378; caption line at 390; two update rows at 424 (tap opens, swipe right Done, swipe left Not now, Undo 10 s); doors at 540 (the Log's dial stays at 432); action word bottom-left; Tess bottom-right.
> 4. **Ship names (sheet 281, his verdict):** Home = Bridge, Notes and Lists = Log, Weather = Lookout, Training = Deck, Kitchen = Galley, Routines = Watch, Money = Purse. Tessera stays the app name. Titles, doors that name rooms, Tess's lines and Home tiles take the new names.
> 5. **Lists is not an app (sheet 280).** A list is a note whose lines can be checked; list titles and open items appear on the Log word wall (a due item in wine, a checked item struck). No Lists landing. Shopping is one object in two rooms (the Galley's "To get" ticket and a list in the Log).
> 6. **Keystones are locked per room** (section 2 table): Bridge mosaic, Log word wall, Lookout skypiece, Deck blackboard, Galley pass rail, Watch woodland (268 v4), Purse index system (277, 278 v3, 279). The shared word wall is no longer the interim keystone for Training, Kitchen, Money or Settings.
> 7. **Finish and function, not realism.** Keystones are real material (photo plates plus a live layer) or deliberately graphic (pixels, type, chalk, hairlines). Illustrated scenes of objects that aim at realism are rejected. The Watch woodland is flat illustration, polished, and is the one approved drawn scene.
> 8. **Glass:** the Lookout glass is raised by light and shadow only (no refraction, frost, fill or tint). A clear glass lens appears only under a finger on a horizontal swipe control (237 v3); there is no lens or glass on ordinary swipes.
> 9. **Colors:** no red or green for money amounts, ever; done and paid inside the Purse is sage. Kind colors: Home clay 9C4B2C / E2A07F, food (Galley) ochre 93611A / C49A5E, body (Deck) blue 0B62AE / 8FB0EE, subscriptions teal 1E6E77 / 84C3C9, going out slate 34506F / A7BCD6, saving gold 7E6A1E / D9C27A, Purse sage 3F7A62 / 8DBFA7, Watch plum 8E4A78 / D59AC4, lists olive 5E6B1F / B5BE7A (the list kind inside the Log).
> 10. **Do not push** is the design agent's repository rule in his TESS.md; builders here push only to their own branches, as before.


The shared rules every room landing follows: Home, Training, Kitchen, Notes, Lists, Routines, Money, Weather and the Settings landing. Builders build to this file. It does not redraw anything; it locks what the approved sheets already say and settles their conflicts (section 10).

Sources, newest approved wins: 246 Notes landing (approved Oct 24, 1:54 AM), 236 Home (v2.2 approved), 241 color roles, 228/227/226 (approved Oct 23, layout bands), 248 Routines woodland (awaiting his verdict, used for Routines only), design bible 01 (rules) and 06 (open questions). Kaushik's words in `docs/handoff/codex-chat-oct24.md` outrank all of them.

A landing is a summary plus a keystone plus doors. Never the full list.

## 1. Frame and the four bands

Frame 402 x 874 pt (iPhone 17), 24 pt gutters. Other sizes scale the gaps, never the slot sizes. No ScrollView on a landing.

| Band | y (pt) | What it holds | Fixed? |
|---|---|---|---|
| Header | 54 - 170 | Room title (Figtree 700 40 pt, room accent, top at 54). One state line under it (Figtree 16, ink2, one line, never wraps). | yes |
| Keystone | 196 - 378 | The room's one expressive element, x 24 - 378 (354 x 182). See section 2 and the v2 note. | yes |
| Doors | 432 - 576 | The 3-place dial (section 4). | yes |
| Brief | 612 - 740 | One line at 612 (Figtree 15, ink2, one ink 600 name). Routines may use two update rows in 64 pt slots (17 pt light, name 600). Nothing else. | slot yes, content per room |
| Foot | 768 - 840 | Action word bottom-left, Tess bottom-right. | yes |

- Landings use no section labels, cards, pills, bars, rings, tab bars, door rows at the foot, filter rows or counters ("N of M").
- Home is the one exception to the band table: it keeps its own slots (236 v2.2: board 84-180, mosaic 248 x 160 at 210-370, one thing 400-612, apps 640-760, foot 768-840). The mosaic is Home's keystone and keeps its own size. Every other rule below still applies to Home.

## 2. Keystone slot (one container, every landing)

- Position and size: x 24 - 378, y 196 - 378, 354 x 182 pt, on every landing. The container is one shared view (`LandingKeystone`) that owns the frame, the hit region, arrival, Reduce Motion and the caption line. Rooms supply only the content.
- The slot background is the page color. No border, fill, card or shadow. Content blends into the page at the edge.
- A smaller scene (Routines woodland 354 x 160) is centered vertically in the slot; the caption line sits at y 390 (Figtree 15, ink2, one line).
- The element is built from the room's own data, reacts to what Kaushik does (add, complete, open), and moves by itself in small ways. Scenes scale with the amount of data; no per-item drawings.
- Behavior is the same everywhere:
  - Tap an element inside it: opens that thing (one tap). In Routines a first tap names a tree in the caption, a second opens it.
  - A drag that starts in the slot belongs to the slot until lift. The page, the dial and the edge zones never take it.
  - Ambient motion: a single-word or single-part moment every 5 s, a re-pack or swap every 40 s, a whole-slot moment every 2 min. Every effect lasts 5 s or less.
  - Arrival: pieces glide into place 22 ms apart on the house spring, finished in about 0.6 s. VoiceOver gets the final state at once.
  - Reduce Motion, Reduce Transparency, Low Power: one calm still frame, no moments, no blur, swaps cross-fade (150 ms). Everything stays tappable.
  - Private items never appear in the slot (word wall) or show as "Private ..." / a count; the app switcher snapshot masks private content.
- Keystone content per room (locked by Kaushik, Oct 25; the slot and behavior are shared, the content is per room):

| Room (was) | Keystone | Status |
|---|---|---|
| Bridge (Home) | the mosaic: tiles, faces, weather words (236) | built |
| Log (Notes and Lists) | word wall of note and list titles (246) | built, approved |
| Lookout (Weather) | the skypiece: the page is a real sky (photo plates by condition and hour), the glass raised by light and shadow (254 v9, 255, 256) | surface approved, inside open |
| Deck (Training) | the blackboard: slate band with a chalk-dust feather edge, chalk drawn in two passes, ghosts of wiped chalk, drag writes, fast swipe left is the towel, tap a number opens the lift (258) | locked, detail open |
| Galley (Kitchen) | the pass: a ticket rail of paper tickets, permanent on every Galley page, tickets flip up for more, big ticket takes 2.4 shares, cook mode turns the rail into the recipe and timer tickets (259) | decided, finishing gesture open |
| Watch (Routines) | the woodland, 268 v4: flat-illustration trees lit by the real hour, hold a tree 1.5 s to water it, buds are steps, missed days wilt softly (no counter, no red), rake leaves, plant on open ground, planned rest hangs a lamp | locked |
| Purse (Money) | the index system: category dial across the top, an index scroller at the right, one "you are the stock" chart between; swipe sideways for category, up and down for index (277, 278 v3, 279) | locked |
| Settings | no approved keystone: the word wall of setting areas stays as the interim | interim |

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
| Keystone | 24-378 x 196-378 | taps on its parts; any drag that starts there |
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

## 12. Per-room table (ship names)

| Room | Accent | Keystone | Doors | Action word | Empty state |
|---|---|---|---|---|---|
| Bridge | none | mosaic | the apps list | none (Undo line) | per 236 |
| Log | notes plum 8A4570 / E3A3CB | word wall | All notes, Lists, Ideas, From Tess, Voice memos, Pinned, Mentions, Private, Archive | New note | "Write the first thing down." |
| Lookout | sky amber C9772E / E8A06A | skypiece | Hours, Week, Air | Rain alert | per 243 |
| Deck | 0B62AE / 8FB0EE | blackboard | This week, Library | Start Push A (Log a walk on a rest day) | "Rest today. Next is Saturday." |
| Galley | 93611A / C49A5E | pass rail | Tonight, Pantry, Recipes, Groceries, Leftovers | Cook (Dishes as a foot word) | "Tonight?" with "nothing planned yet" |
| Watch | 8E4A78 / D59AC4 | woodland | Today, Body, Mind, Home, Across the lake | Plant | "Quiet day" |
| Purse | 3F7A62 / 8DBFA7 | index system | This month, Kinds, Saving, Investing, Debts, Mine | Log (adds a spend) | "Nothing yet" |
| Settings | ink | word wall (interim) | Tess, Privacy, Units, Claude, Backups, About | none | n/a |

## 13. Shared components to reuse

`LandingPage` (frame and bands), `LandingKeystone` (new, section 2), `DoorsDial` (section 4, from the Notes dial), `LandingZones` and `GestureKit` (section 5-6), `MotionPolicy`, `TessFont`, `WordFit` (fixed slots), `AppAccents` and `Theme` tokens. No landing may define its own slot geometry, dial, swipe thresholds or animation curves.

## 14. Test and evidence per landing

- UI tests: tap keystone part, tap and drag dial, swipe row right and left (Done, Not now, Undo within 10 s), action word tap and drag options, back edge, right margin.
- Fit tests at default size, AX3, AX5; Reduce Motion on.
- Simulator recording (raw clips stay gitignored, trimmed clip kept) and Reduce Motion and AX5 stills.
- `scripts/test.sh` ends "All green" on the exact head; Release build; install on sample data.
