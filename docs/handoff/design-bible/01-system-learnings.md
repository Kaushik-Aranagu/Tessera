# 01 The design system, and what we learned

The cross-cutting rules every Tessera screen follows, then what Kaushik liked, what he rejected, and the reasons behind his feedback. Where a sheet and this page disagree, the newest sheet wins, except for the Oct 24 hard rules (section 7), which override every sheet. Sheet numbers refer to `/mnt/project-files/tessera/design/` (the newest are mirrored in `docs/handoff/design-sheets/`).

**Stale sources. Do not build from these without checking:**
- `.claude/skills/tessera-design/SKILL.md` describes Hero 64, mono uppercase labels, dotted underlines, "no pure #000" and glass bars.
- `docs/DESIGN_MOTION.md` lists cards, a glass add button, confetti, glass pills and Tess as three paint dabs.
- `themes.md` uses Inter Tight, cobalt as Tess's color, and brush strokes.

The *principles* in those files still hold: MotionPolicy, the house spring, Reduce Motion, haptics, no decorative color. Their *visuals* are superseded.

## 1. Principles

- **UI weighs as much as the backend (50/50).** UI is where invention happens, not polish added at the end. Never ship a stock iOS screen, a card screen, or "a list of summaries". Kaushik's ideas arrive raw: polish them and push back on them. Every round should include at least one idea he has not seen before.
- **Everything is an object.** Every thing is a linkable instance of a class (ClassDef, FieldDef, ObjectRecord, ObjectLink). Any word that names a thing can open it ("word becomes the page", sheet 138 D1). Information is dense, but it is revealed progressively:
  - a landing gives a summary plus doors;
  - a page gives one thing in focus;
  - a detail page gives everything about that thing.
- **One thing at a time (ADHD-friendly).** The screen is a scarce resource (no-buttons):
  - one primary action per screen, plus at most two fast paths; everything else is one layer down;
  - nothing stays on screen unless it earns its place;
  - Home shows one thing under the mosaic (213), and swipers show one item at a time.
- **Calm, but alive.** Color arrives through motion and moments, and resting color stays quiet (no-dots). He still wants "action, drama and things happening": small living details (sheet 236 weather words, word-wall moments, the departure-board flips).
- **Tone.** Offers, never orders. No guilt, no shaming, no "streak 0". Missed days are neutral. Receipts name the thing first (section 3).
- **Privacy is part of the design.**
  - Health, body, calendar, calories, location and money never reach widgets, backups or logs. They reach Claude only while lab mode is on (his Oct 23 ruling; strict mode turns it off in one switch). Private notes and lists may go to Claude under lab mode "for now"; workouts never do; money actions are never offered.
  - Off the phone, private items read "Private workout" or "Private note", or as a count ("3 private notes", never "Private note" repeated).
  - Inside its own room, a private item shows its real name.
  - No money ever appears on Home.

## 2. Looks, color roles, Ember, contrast

### 2.1 Looks (ThemeConcept / `DesignSystem/Looks.swift`)
- A look changes only three things: the ground, the ink and the pigments. Layout, type and motion are the same in every look.
- One base runs through the whole app, workout included (themes.md, fourth addendum). Nothing pops out brighter or darker than the rest.
- The looks in code:

| Look | Kind | Ground | Field |
|---|---|---|---|
| Porcelain | light | FFFFFF | pigment bloom |
| Obsidian | dark | 000000 | emissive glow |
| Plein | light | warm paper F3EDE2 | |
| Lacquer | dark | plum-black 130A0D | slow specular band |
| Celadon | light | jade E0EAE2 | glaze |
| White (213) | light | FFFFFF | ink2 54514D, ink3 86827C |
| Black (213) | dark | 000000 | ink2 A3A09B, ink3 6E6B67 |

- Settings > Look is one sentence: "**Porcelain** by day, **Obsidian** by night". Tap a name to cycle it; hold to pin. `-theme <name>` pins a look on the simulator.
- He wants absolute black (#000) for dark. Every board gets a quick theme flip between pure black, white and warm paper (little-details-rule). Boards draw light on paper F7F5F1.
- **Soft dark** (his pick 10:15 PM Oct 23, sheet 230 v2), on 000000:

| Role | Hex |
|---|---|
| accent (Training) | 8FB0EE |
| go | 8FC9A0 |
| ink | E8E3DA |
| ink2 | A49E96 |
| ink3 | 78736D |
| edge | 2A2A2E |

  His second choice was Moonlight: B0C1E6, A8CDB4, DCD7CE, 9C968E. He said Soft is "fine for now", so a better set may still come.
- Ink tiers: ink is for text, ink2 for secondary text, ink3 for rest and disabled. Nothing on Home uses ink3 text (236).

### 2.2 Color roles, app-wide (sheet 241, his 11:53 PM "not monotonic")
- **3-4 colors per page, each with a meaning.** Never 1, never 5 or more. Color goes on type and fine lines only, never on fills.
- **Room accent:** the room title, the bottom-left action word, and the focused item when it has no kind.
- **Kind colors:** each kind wears its own color on its name, count, focused items, page title and action word. A kind that belongs to another room wears that room's accent. The other kinds take a color from the shared set: teal, clay, gold, slate.
- **State colors (the same everywhere):**

| State | Color |
|---|---|
| done, logged, paid, in stock, a gain | go green 25803D / 8FC9A0 |
| late, due, expiring, warning | wine 9A2541 / EE8E9C |
| best, new, starred | gold 7E6A1E / D9C27A |
| planned, private, later, small-caps labels | slate 34506F / A7BCD6 |

- **Shared kind colors:**

| Kind color | Light | Dark |
|---|---|---|
| teal | 1E6E77 | 84C3C9 |
| clay | 9C4B2C | E2A07F |
| plum | 8A4570 | D69CC0 |
| steel | 2F6A8F | 8DBAD6 |
| lavender | 6A5E8C | B4A9D6 |

- **BIG TYPE rule (his 12:07 AM Oct 24):**
  - The 2-4 biggest type elements on a page never share a color. Each takes the color of its meaning.
  - Vary their weight and size too, for example a 600 title, a 200 light stat number and a 600 hero at another size.
  - The action word may share the title's accent, because they sit at opposite ends of the page.
- **Money exception:** in Money, paid uses the room's sage, not go green. No amount is ever colored as good or bad.

### 2.3 Room accents (light / dark)

| Room | Accent | Notes |
|---|---|---|
| Training | blue 0B62AE / 8FB0EE (Soft) | Splits: Push clay, Pull teal, Legs plum, streak gold. Library: Routines green, Exercises gold, Programs slate, Goals blue. The old 3B8CF2 dark and the crimson are retired. |
| Kitchen | ochre A8701F (name and big numbers) / C49A5E | Small text in light uses 93611A (A8701F is only 3.9:1). Pantry teal, Recipes clay, Shopping ochre. |
| Money | sage 3F7A62 / 8DBFA7 | Bills clay, Subscriptions teal, Savings gold, Late wine. **Unconfirmed:** README says Money moved to sea teal 2A7878 / 7BC0C4 (223); 241 and the code use sage. |
| Lists | olive 5E6B1F / B5BE7A | v9 kinds: Shopping ochre, Trips steel, Home teal, People plum, Watch and read lavender. Small-caps labels in ink2. Slate only on "Private". |
| Notes | violet 5B3FB8 / B9A9E0 **must change** | It is only ΔE00 6.1 from Ember. Plum 8A4570 / E3A3CB is proposed (246) and needs confirming in the Notes round. Kinds: Ideas gold, Journal clay, Reading teal, Work slate. |
| Routines | plum 8E4A78 / D59AC4 | Code still has D79AA6. Kinds: Mornings gold, Evenings slate, Body training blue, Home clay, Mind teal, Borrowed wears the source room's accent. |
| Home | no room accent | See below. |
| Weather | sky amber C9772E / E8A06A | Condition colors below. |
| Tasks | ink | |

- **Home colors:**
  - The date wears the sky of the hour as a left-to-right gradient (216). Evening, for example, is BF6A22 → A33C62 light and E8A06A → F286A6 dark.
  - Rain or snow eases the second stop 30% toward slate.
  - Each highlighted door word is Figtree 700 in its room's accent.
- **Weather condition colors (light / dark):**

| Condition | Light | Dark |
|---|---|---|
| rain | 557A93 | 9DBACE |
| snow | 6E8296 | C9D6E2 |
| wind | 5E6E7E | B4C2CC |
| cloud | 6B7480 | B9C0C8 |
| white-cloud days | 8A7552 | DCCDAA |
| moon | 4A5788 | B3BDE8 |
| fog | 727880 | A7ACB2 |
| ice | 2F7299 | 9FD0EE |
| storm | 53507A | ABA8DC |
| warn | A23B27 | F08F72 |
| bolt | 5B4FD0 | FFF1A8 |

  Highlights take their meaning's color: rain wears rain slate, never a sunset wash.
- **Code is behind.** `AppAccents.swift` still has Training C4472A / EE6A4C and Kitchen dark D49A52. The sheets win.

### 2.4 The Ember rule and contrast
- **Ember is Tess's color** (215 final):
  - light: FF5A26 (middle), E5341C, FFA90F;
  - dark: FF6B3D, FF4A33, FFC23D.
- Nothing else on screen may sit within ΔE00 10 of Ember. The only exception is the accent of the room currently cueing her (she takes that accent at L 0.64 light / 0.74 dark).
- Cobalt is no longer reserved for Tess.
- **Contrast:** every text color reaches 4.5:1 on F7F5F1 and on 000000. A color under that bar is for large text or strokes only (go 2FA24D was 3.0, so it moved to 25803D).
- **Spacing between colors:** every role color sits ΔE ≥ 10 from Ember and from its own room's accent.
- Check new colors with a script (the c241 check.py approach), using ΔE2000, not CIE76.

## 3. Type
- **Figtree** for words. **Outfit** for numbers, with tabular figures (`tnum`) and fractions as digits with `frac`. **Newsreader** only for Tess's own words (New York in the app). Licences: SIL OFL, credited on About.
- Sentence case everywhere. US words. Never name a city.
- **Number weight:** Outfit 300 below 28 pt and 200 from 28 pt up. An estimate is one step lighter than an exact value and always reads "about".
- **Units:** the unit sits at about half the numeral's size, minimum 10 pt, Figtree 400, ink2, 2 pt after the number, joined by a no-break space. Every weight shows lb or kg.
- **Copy:**
  - Digits for counts.
  - "6 pm", never "at 6 pm".
  - Dates as "Oct 12".
  - "best", never "record".
  - Receipts read "Thing, what happened." ("Tacos, 2 added.").
  - Money undo reads "Reversed".
- **Sizes in use:**

| Element | Type |
|---|---|
| Room title | Figtree 700, 40 pt |
| Door page title | 34 pt |
| Home date | Figtree 600, 23 pt |
| Home rows | 500, with 700 highlights |
| One thing, big tier | Figtree 700 38 pt, or Outfit 400 56 pt |
| One thing, mid tier | 500, 20 pt |
| One thing, small tier | 500, 15 pt, ink2 |
| Action word | 600, 20 pt |
| Small caps labels | 13 pt, 600, tracked 0.06 em |
| Smallest text | 13 pt (word wall and labels); units 10 pt |

- **Title fit (his 9:11 PM):** big fixed titles shrink 1 pt at a time to a floor of about 0.75x, then cut at whole words or use Tess's short form. Examples:

| Title | Range |
|---|---|
| exercise name | 34 → 26 |
| Kitchen reel | 46 → 34 |
| dial focus | 44 → 32 |
| wheel focus | 28 → 21 |
| note title | 28 → 21 |

  Home's sentence lines keep a fixed size. Never use "...".
- **Fixed text slots (224):** every shown piece of text has a fixed width and line count.
  - The phone measures each written form, full to short, and shows the longest form that fits.
  - If none fits, the on-device model (never Claude) writes a shorter one. Names, digits and days survive.
  - VoiceOver reads the full text.
  - Input fields are exempt.
  - The QA fit test runs at default size, AX3 and AX5.
- **Section labels:** small caps, 600, tracked, in the section color (slate, or ink2 in Lists). Items stay sentence case in ink. **Unconfirmed:** the page-palette rule puts a hairline under the label, but 230 and 246 draw none.
- **Word wall type (246):** Figtree 900 capitals, "sharpened" with a same-color outline at 3.5% of size and mitred joins, tracking −0.01 em. Letters are never spaced unevenly, there are no gaps, and stretch is at most 8%.

## 4. Layout grammar
- **Frame:** 402 × 874 pt (iPhone 17), 24 pt gutters. Hit targets are at least 44 pt.
  - The back edge zone is 0-24 pt and nothing else takes it.
  - The action word starts 28 pt or more from the left edge.
  - Tess's corner is bottom right.
- **Home slots (236 v2.2, approved):**

| Slot | y (pt) |
|---|---|
| board, three 30 pt rows | 84-180 |
| mosaic, 248 × 160, right | 210-370 |
| one thing | 400-612 (hard clip 92 pt from the right, where the sign sits) |
| apps list, 3 × 40 | 640-760 |
| foot: Undo line left, Tess right | 768-840 |

  Home has no ScrollView. The gaps scale on other sizes.
- **Landings** are a summary plus doors into sub-areas, never a full list (his 11:27 PM). The approved pattern is Notes (246):
  - title at 54;
  - one ink2 line;
  - an expressive element on the mosaic slot (word wall, x 24-378, y 180-400);
  - doors on a 3-place dial at 432-576;
  - one line at 612;
  - the action word at the bottom left.
- **Deeper pages (247):**
  - Dials are for landings only.
  - Each depth level has one fixed block, identical on every sibling page (Notes door wall 354 × 132 at y 140, list from y 300).
  - Font sizes vary per page to fill the block exactly.
  - No gaps, and no row of all-equal sizes.
- **226 four bands** (approved 5:40 PM Oct 23): headline 170, brief 50 (two lines, right-aligned), body 262 (1-3 columns on a 24 pt line grid, six lines then pages), foot 36. The *layout* stands, but 240, 242 and 246 superseded the *landing content*.
- **Foot (224):** one action word at the bottom left in the room accent, Tess at the bottom right. No menus, no door rows, no tab bars. The title tap opens the room's index. A pull from the right margin opens the side (76). The left edge goes back.
- **Long lists:** fewer items per page and page turns, not endless scroll (his Oct 17 rejection of sheet 89). Page turn = pages of 5-6 rows. One column for long lists; a right-hand value column is allowed, and moves under the name at AX sizes.
- **Element kit (222, "all of them are really cool"):**

| Element | What it is |
|---|---|
| drum | words on a cylinder past a reading line |
| thumb arc | a quarter circle at the bottom-left corner, shown only while a value is being set |
| page turn | long lists as pages |
| fold | pinch to regroup days, weeks and months |
| word strip | a sideways run of words |
| thread | a cord pulled to advance a step |
| pressed number | numbers as instruments; changes go on Undo with "was" |

  The lens element was later rejected.
- **Wheels (230):** the shared `mkWheel` component, with 40 pt rows and the focus row at 30 pt. Rows step down with distance (20, 17, 15 pt in ink2). A header sits as row −1 in small caps. Focus snaps one row on the spring with a tick, and the wheel springs back to "now" 6 s after the last touch.
- **Dials:** 3 places only (the focus plus one above and one below), 48 pt slots, looping. The focus is 1.32x in its meaning color; neighbors are ink2. A tap on a neighbor turns to it, and a tap on the focus opens it.
- **Pixels, tiles and mosaic** belong to Home only. Inside rooms: type, hairlines (1-2 pt), negative space and columns.

## 5. Motion and charms
- **Rules:**
  - Everything animates through MotionPolicy (`.tesseraAnimation`, `withTesseraAnimation`).
  - House spring: Spring(duration 0.42, bounce 0.12). Firm: 0.35 / 0. Snappy: 0.25, for direct manipulation. Celebrate: bouncy 0.5, rare.
  - Ink dry: 1.1 s after a 0.4 s hold.
  - No linear curves. No fades on text: reveals are clips or rises.
- **Reduce Motion:** a 150 ms crossfade or a plain appear, and effects go off.
- **Low Power** turns off depth blur and auto-turns. Reduce Transparency turns off blur.
- **Haptics (175):** one per moment. Tick for picking and scrubbing, soft for landing or marking (Undo too), rigid for finishing. Never on scroll, never a warning buzz.
- **Depth blur on every wheel:** 0.65 pt one row out and 1.0 pt two or more rows out (230); the Notes dial goes up to 1.8 pt (246). Never on the focus. None under Reduce Motion, Reduce Transparency or Low Power. This is the only blur allowed.
- **Numbers (138, 230):**
  - Numbers never step with − / +. They scroll: drag 16 pt per value, with a tick, while ghost values show at 0.42x in ink3.
  - A tap opens a full depth-wheel dial.
  - After a hand change, "was 185" shows for 2 s under the new value, never on money.
  - Digits roll.
  - Unit turn: tap or swipe the unit word to convert, and the digits roll.
  - Pressure: weight rises with drag speed.
- **Word effects:**
  - Weather words act out their weather (236 v2.4-2.8): one effect per WeatherCondition. Clouds appear only on mostly sunny, partly cloudy and cloudy, level with and behind the word. Sunny is shine only. Fog masks the word (he loves it). Rain and snow have no cloud. Flashes stay well under 3 per second.
  - Home board rows flip letter by letter like a departure board, every 5-10 s with jitter.
  - The word wall has single-word moments every 5 s (flip, jumble, dissolve), a swap and re-pack every 40 s, and a whole-wall moment every 2 min.
  - Tess's words reveal one word at a time (62 ms each) with a 3 pt rise. No letter flips in conversation.
- **Action word gestures (230, every room):**
  - Tap does the action. Drag left for stop or remove, right for again or redo.
  - The word leans up to 18 pt. Past 56 pt it rolls to the option's name with a selection tick.
  - Release commits with a medium impact and a "Thing, what happened. Undo" receipt.
  - Short of 56 pt it springs back with a soft tick. A side with no option moves 6 pt with a rigid tick.
  - VoiceOver gets each option as an accessibilityAction.
- **Undo** lasts 10 s everywhere. There is one app-wide Undo slot. Money reads "Reversed".
- **Transitions:**
  - A word becomes its page (matched geometry). Pages slide in from the right; the left edge goes back.
  - Receipts travel home from Tess's corner.
  - Sheets lift like paper, with no shadow or dim.
- **Little details** he loves: the Sunset word painted with the sky gradient, the Kitchen skyline, the fog. Look for one or two small, subtle touches per board. They must never be loud or heavy.

## 6. Gesture rules
- Swipe right means Done, swipe left means Not now. There is one 90 pt step, never two (207). Policy (`gesture-policy.md`):
  - A drag starts at 10 pt; the axis locks at 12 pt.
  - A row arms at 96 pt; a flick is 500 pt/s with 28 pt of travel.
  - A tap is held off for 120 ms after a wheel settles.
- A single swiped element takes both axes: left or up for next, right or down for previous. The exceptions are when the two axes mean different things, and dials, wheels and rails.
- A strip or zone owns any drag that starts on it, until lift. A parent never decides for a child's region.
- Swipers slide 1:1, with no lens or glass, no page dots, no "N of M". The first time, the next item peeks 12 pt.
- Weeks start Monday.
- Edges (76): left edge = out/back; right margin = in (glance, then full side); the middle = along a run; vertical = reading.

## 7. Banned (with the reason, so nobody re-offers it)

| Banned | Why |
|---|---|
| Cards, pills, button shapes, glass slabs (no-buttons, Oct 15) | He dislikes every rectangular, oval or pill shape, Apple's included |
| Bars, rings, gauges, chart furniture | They read as generic dashboards. The barbell is an object, not a meter |
| Middle dots, filled or colored dots, bullets (no-dots) | They distract. A " · " is allowed only in a pack size |
| Decorative underlines (8:58 PM Oct 23) | An underline is for linked words only, never a marker. Home has none |
| Fades on text, "...", "N of M" counters | Layout and text must feel solid. Cut at whole words |
| Lens or glass on swipes (10:51 PM Oct 23) | "I don't want that lens effect at all" |
| Pixels or tiles outside the Home mosaic (4:27 PM Oct 23) | Overused. Pixel lintels 210 and 217-225 are dead |
| − / + steppers | Numbers scroll |
| Bottom menus, door rows at the foot, tab bars | One action word only |
| Blur, other than wheel depth | No soft patches. Tess is never diffused |
| Two-color pages | "Too monotonic" |
| Big type sharing one color | "All of it in blue, looking the same" |
| Anything within ΔE 10 of Ember | Ember is Tess's |
| Drawn food stand-ins (pan, grocery) | They read poorly. Only his photo, or nothing. The muscle figure is approved |
| Fine-line drawings on landings (240) | "Drawings are the worst" |
| Text that wraps or moves layout | Layout jumps feel broken to him |

## 8. Learnings: what he liked, what he rejected, the patterns

**Liked:**
- the living pixel mosaic and the departure-board sentence (200);
- the mosaic lending its pixels to the one-thing sign (his own idea);
- the Sunset sky word, the Kitchen skyline, the fog word;
- the element kit (222);
- the word wall / word band (12:43 AM Oct 24, "the first landing idea he liked");
- the 3-place dial;
- Soft dark;
- the stack-and-handle set mark;
- the Tess smooth cloud (rev 9+);
- the muscle figure;
- weather word effects ("all good, very glad").

**Rejected, in time order:**

| Date and time | Rejected |
|---|---|
| Oct 15-21 | the machined look; Inter Tight; Fraunces; Cormorant and Urbanist (116: "too sharp") |
| Oct 17 | sheet 89 density |
| Oct 18 | food drawings |
| Oct 22 4:47 PM | the Tess orb/Sphere skin ("ugly") |
| Oct 23 11:16 AM | the 208 apps dial and the simplified Tess |
| Oct 23 | dabs, wet paint, sun core and turbulent texture for Tess; the lip-sync mouth; presets and underlined offers in her layer |
| Oct 23 4:27 PM | crimson for Training; pixel lintels |
| Oct 23 | captions at the mosaic edge; the square mosaic skin |
| Oct 23 9:33-10:06 PM | tally marks, "5 5 5", Pulse, Climb, Waves, Arrows, plate stack (set marks) |
| Oct 23 10:51 PM | the lens |
| Oct 23 11:39-11:52 PM | the doors list, the big reel, and the summary-plus-2-column grid ("sections and sections of lists again") |
| Oct 24 12:07 AM | all of 240 |
| Oct 24 12:27 AM | 242 round 1: strings and chimes "too bad"; swarm "too much" |
| Oct 24 | tide ("doesn't have anything"); Archivo condensed; the spine shelf (he likes columns, reuse them elsewhere); plain door rows ("too basic"); the pile (2:02 AM) |

**Patterns behind his feedback:**
1. **"Too basic"** means plain rows or stock lists. Give him an instrument (dial, wall) instead.
2. **"Too monotonic"** means too few colors, or big words that share a color. Use 3-4 role colors.
3. **"Too much"** means the effect outweighs the information it carries. Every effect must carry real state.
4. **He hates gaps, uneven spacing and uneven letter spacing.** Packed and justified is right; fillers and repeats are fine.
5. **Stacked sections read as "lists again".** Compose one page instead.
6. **Fine-line drawings and literal metaphors (strings, chimes, jars) fail.** Kinetic type works.
7. **Layout must never jump.** Use fixed slots.
8. **He likes expressive elements "at the mosaic's level"** but not the mosaic itself in rooms.
9. **When changing a piece, never drop approved pieces.** List every carried feature (Home, 1:07 PM Oct 23).
10. **Iterate one room at a time**, landing first (6:06 PM Oct 23). Explore several display options before picking.
11. **Re-asking settled questions frustrates him.** Check memory and sheets first, and give one recommendation per question.
12. **He cannot open file paths** (/mnt and local). Show every visual as a claude.ai artifact page, and the phone is where he truly reviews.

**How the design process worked:**
- **Each round** = one board artifact plus a numbered sheet (the number goes up with time), indexed in README.md. NEWER WINS.
- **Each board** has a light/black flip and live elements. It is versioned in place (same URL, v1 → v20), and a re-cut keeps the URL.
- **His verdicts** are logged by PT time ("his 9:20 PM") in the sheet and in memory. A version is "approved" only when he says so; a board is a reference and the sheet is the spec.
- **Reviewer pass** (manager-reviewer.md) before a round goes out: look, accents, motion, privacy, tone, process. Then the round goes to the builders, split by lead:
  - Builder A: Training, looks, motion, mosaic;
  - Builder B: Home, Notes, Kitchen, Lists, Routines, Money;
  - Core: data and AI.
- **Each feature** sits behind a Review switch (default Off), or is on by default when he asks.
- **Sheets reach the repo** through docs PRs (`docs/handoff/design-sheets/`), which merge always.
- **Cadence:** design never idles. One short reply per round with the board link. Real forks still go to him.

## Open questions and contradictions
1. Ember: 241's table measures against Ember "3433D6 D6266E F2B21B" (the old living-colours palette), but Tess's Ember is FF5A26 / E5341C / FFA90F (215). 241's ΔE column may be against the wrong colors. Re-measure.
2. Notes 246 and 247 put "From Tess" in "Tess blue", but Tess is Ember now. The color for Tess's words in rooms is unconfirmed.
3. Proposed Notes plum 8A4570 / E3A3CB shares its light hex with Legs and People plum (D69CC0 dark) and is close to Routines plum 8E4A78.
4. Money: sage (241, code) or sea teal 2A7878 / 7BC0C4 (README, 223)?
5. Wheel blur cap: 1 pt (230) or 1.8 pt (246 dial)?
6. Section labels: with a hairline under (page-palette-rule) or none (230, 246)?
7. Stray counters: "1 of 6" (237 kinds row) and "1 of 2 pages" (226 AX state) break the no-counter rule.
8. Weather 243 writes "4 PM"; the copy rule says "4 pm".
9. Code accents (AppAccents, Looks) lag behind 230 and 241. The SKILL.md and DESIGN_MOTION.md visuals are stale.
