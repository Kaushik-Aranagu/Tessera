# Tessera: the design, consolidated (Oct 25, 2026)

One document for any agent or person picking this up: what is decided, the rules, every room's keystone, and exactly
how the boards are rendered and checked so they can be rebuilt on another machine. The detailed sheets live in
`docs/handoff/design-sheets/` (numbers below); where this document and a sheet disagree, the later sheet wins.

Repository rule: work in a local clone only. **Never push, open PRs, or comment on GitHub.**

---

## 1. The app at a glance

Tessera is a personal iPhone app. A tessera is one tile of a mosaic; the home screen is the mosaic. It has seven rooms,
renamed on Oct 25 to a ship theme (sheet 281):

| Room (was) | Name | What it is for | Keystone (the slot) | Status |
|---|---|---|---|---|
| Home | **Bridge** | everything at a glance | the mosaic: tiles, faces, weather words (236) | approved |
| Notes + Lists | **Log** | notes, and lists as checkable notes | the word wall (246) | approved; lists folded in (280) |
| Weather | **Lookout** | what it's like out there | the skypiece: real sky, raised glass (254 v9, 255, 256) | surface approved; inside open |
| Training | **Deck** | lifting and moving | the blackboard (258) | locked; detail open |
| Kitchen | **Galley** | cooking, pantry, groceries | the pass: ticket rail (259) | decided; finishing gesture open |
| Routines | **Watch** | things you do again | the woodland (268 v4) | locked |
| Money | **Purse** | in and out, saving, investing, debt | the index system: you are the stock (277, 278 v3, 279) | locked |

There is no Lists app: a list is a note whose lines can be checked (280). Shopping is one object in two rooms: the
Galley's "To get" ticket and a list in the Log.

---

## 2. Rules that hold everywhere

**The slot.** Every room's landing has one centrepiece in a fixed slot: 354 x 182 pt at top 196 on a 402 x 874 phone,
24 pt side margins. Content pages inside it; the band never grows. A centrepiece may bleed visually to the full 402 pt
width (the woodland does) if its edges dissolve.

**The centrepiece stays through the whole room.** On level 1, level 2 and deeper pages it stays in its slot, live to
what the lower part of the screen shows (the Galley pass is the model).

**Finish and function, not realism.** A keystone earns its place by what it does (tending, consequences, reactions),
and it must look finished and smooth. Drawn is fine when polished; half-finished sketches and photo comps both failed.
Pictures for their own sake, scenes that do nothing, and literal metaphors (a beam balance, a jar) were rejected.

**Software, not illustration, where the room is about information.** Money's keystone is a live chart system, not a
picture; the word wall and the mosaic are type and pixels. Notes' coloured words-as-weights belong to the Log only.

**Effects are 3 to 5 seconds.** Every reaction finishes inside 5 s. Reduce Motion: cross-fades only.

**Colour (sheet 241).** 3 or 4 colours a page, each with a meaning; the biggest words never share one colour; every
colour 4.5:1 for small text in both looks and ΔE ≥ 10 from Ember. States: done/paid green (sage inside money), late
wine, best/new gold, planned/private slate. Kinds: Home clay 9C4B2C / E2A07F, Food (galley) ochre 93611A / C49A5E, Body
(deck) blue 0B62AE / 8FB0EE, Subscriptions teal 1E6E77 / 84C3C9, Going out slate 34506F / A7BCD6, Saving gold 7E6A1E /
D9C27A, Money sage 3F7A62 / 8DBFA7, Routines plum 8E4A78 / D59AC4, Lists olive 5E6B1F / B5BE7A. **No red or green for
amounts, ever.**

**Look.** Paper F7F5F1 and pure black 000000. Type: Figtree for words, Outfit for numbers, Newsreader italic for Tess.
No cards, pills, filled dots, bars-as-gauges, rings-as-gauges, chart furniture for decoration, fades on text, "N of M"
counters, decorative underlines. Sentence case. Hit targets 44 pt. Back edge 0 to 24 pt. Bottom-left action word.

**Edges dissolve.** Any centrepiece that is a picture dissolves into the page: never a frame (see 6.4).

**Glass.** Keystones on a photographic ground are raised by light and shadow only (254 v9): no refraction, frost,
fill or tint. The clear glass lens appears only under a finger on a horizontal swipe control (237 v3).

---

## 3. The rooms

### 3.1 Bridge (Home), 236: approved
Fixed slots, the mosaic blend, faces and "one thing". Weather words with per-condition effects (fog masks the word,
clouds only on cloudy kinds, sunny is shine only). Light-mode tiles 3.6 pt, saturation x1.55, brightness x1.08 (to
confirm). The Lists face merges into the Log's.

### 3.2 Log (Notes + Lists), 246 + 237 + 280
The word wall: a quarter-screen band packed edge to edge with sharpened Figtree capitals in many colours, justified
rows that solve their own height, live moments every 5 s; doors on the three-place dial with the focused door's
newest notes beside it. Lists are a kind of note: check (tap or swipe right past 70 pt; strike draws over 260 ms; drops
to Done after 1.5 s), not now (swipe left), add, clear done (drag the action word left), uncheck all (drag right),
private lists (real names only inside the room), due days in wine. List titles and open items appear on the wall.

### 3.3 Lookout (Weather), 254 v9 + 255 + 256
The whole page is a real sky (photographic plates, CC0 from Poly Haven plus generated gap-fillers, chosen by condition
and hour). The keystone is the skypiece: the screen's glass softly raised in the slot. Approved surface: light off the
top-left (soft white, blur 14, offset -4), shadow bottom-right (blur 20, 8 down, 24% / 36% on dark skies) plus a wider
fainter one (blur 34, 14 down, 9% / 16%), 1 pt hairline of the same light and shade, edges melting into the ground.
Open: what lives inside the glass (rain collecting, snow drifts, lightning scorch, wind shaking the numbers), the rest
of the page, overcast-night and storm plates.

### 3.4 Deck (Training), 258
A slate band under the page type with a noise-feathered dust edge (44 pt), chalk drawn in two passes with jitter and
grain knocked out, ghosts of wiped chalk. Drag writes; a fast swipe left is the towel; tap a number opens the lift.
Haptics written in 258. Open: the chalk hand (Reenie Beanie recommended, Caveat fallback), colours by split.

### 3.5 Galley (Kitchen), 259
The pass: a ticket rail permanent on every Galley page, live to the page below; paper tickets on clips with torn
edges, hand lettering, title in the thing's colour; swipe up flips a ticket to its next page (rotateX, 0.65 s); a big
ticket takes 2.4 shares of the rail; cook mode turns the rail into the recipe ticket and a timer ticket, steps struck
as you go. Open: the finishing gesture (hold-and-tear recommended).

### 3.6 Watch (Routines), 268 v4: locked
A smooth flat-illustration woodland lit by the real hour, in which each routine is a tree you tend.
- **Scene:** sky keyframed by hour; sun and moon on arcs; drifting soft clouds; three hazed hill layers with far tree
  silhouettes; meadow with grass and wildflowers; a lake that holds the sky; a caretaker on a bench (lantern at night);
  Weather's rain and snow arrive here; fireflies at night.
- **Trees:** eleven kinds, one per routine, neighbours never sharing a colour: lemon (Water), lavender shrub (Stretch),
  maple orange (Lunch), white birch (Tidy), green poplar (Walk), willow (Journal), dark pine (Swim, weekly), pink
  blossom (Read), shrub (Backup, automated), umbrella pine (Badminton, weekly), purple jacaranda (Call family, weekly).
  Three rows (back x0.5, mid x0.72, front x1.0); the lake keeps the middle clear. Two-tone crowns with a crisp
  terminator toward the sun and a few lit leaf dabs; shadows swing with the sun.
- **Growth:** sprout < 3 days, small plant 3 to 7, young tree 7 to 28, tree 28+, fruit 35+ (broadleaf only).
- **Doing a routine:** hold a tree 1.5 s; a cloud gathers and rains on it; on release it springs (damped bounce), glows,
  34 petals scatter, sparks rise, a ring spreads on the grass, two birds fly in. Steps are buds: tap to open each.
- **Missing days:** a dry tree yellows, shrinks, sags and drops leaves; swipe along the grass to rake them. No counter,
  no red. Planned rest hangs a lamp in the tree. Plant: tap open ground; the caretaker walks out and sets a seed.
- **Ambient:** thirsty trees drop a leaf now and then; butterflies around tended trees; a fish ripples the lake.
- **Edges:** see 6.4. The canvas spans the full 402 pt, scene centred.

### 3.7 Purse (Money), 277 + 278 v3 + 279: locked
**Indices.** Money is a set of indices. An index is a named rule over the ledger (kind, tag, counterparty, account,
currency, direction, size, recurring/one-off/unplanned, text, time; and/or/not) with its own clock, series class,
transform, baseline and liveness, optional children and alerts. Built-ins are rules with defaults (MONTH, SPEND, each
kind, FIXED, SURPRISES, SAVE, PORTFOLIO, NET); the user's (DEBTS with CAR/HOME/EDUCATION/PERSONAL; INDIA with family,
investments, the loan) sit beside them as equals; sets may nest or overlap. Make one by saying it to Tess or by the
sentence with blanks: *Track [money out] to [Mum, Zerodha, HDFC] in [INR] as [a monthly flow], called INDIA.* Every
index gives a chart, headline, summary, record, forecast, alerts, budget line and a door.

**The slot (354 x 182).** Across the top, a three-place dial of categories (This month · Kinds · Saving · Investing ·
Debts · Mine), focused one large in the index colour. Down the right, a scroller of the category's indices (name,
number, sparkline against its baseline; one lit, neighbours faded, arrows when more). One chart between, with its
clock, headline number, reading and Tess's line. Swipe sideways = category; up and down = index; taps do the same.
Doors under the slot = the categories. Tap the slot = the full chart, same layout, larger.

**The chart, "you are the stock" (MONTH).** Ticker YOU · OCT; open = payday balance; solid sage line = still yours by
day; ▲/▼ vs last month at today; dashed forecast at your everyday pace with known bills placed as drops on their dates;
a fan between your calmest and heaviest pace; the close on the 31st; a dotted clay floor "promised to bills" (above it
is spendable); last month faint behind; volume bars by day stacked in kind colours; ▲ at the 31st for payday. Scrub
any day (past shows receipts, future shows bills, "hold to defer"); hold a future drop to defer the bill; a what-if
handle draws a slate ghost forecast for a purchase today; drag under the chart to sum a range by kind; pinch out to the
year (every month a line, the closes as dots). Pace counts everyday spending only (fixed = home, subscriptions,
saving, gym). The line draws itself on open; the today dot breathes; a payment flashes a ring.

**Series classes and transforms (279).**
| Class | Example | Clock | Transform | Baseline |
|---|---|---|---|---|
| Balance | MONTH | month by day | cumulative in minus out | 0 |
| Flow | FOOD, INDIA | 12 months | per-period total; this period projected (hollow) | your average or budget |
| Pace | SPEND | month by day | cumulative ÷ same day last period × 100 | 100 |
| Monotonic up | SAVE, NET | 24 months / 5 years | ÷ plan × 100, contributions as bars; level is the headline | 100 |
| Monotonic down | DEBTS | years | schedule ÷ balance × 100, payments as bars; payoff date in the reading | 100 |
| Ratio | SURPRISES, FIXED | 12 months | ÷ income of the period | the usual share |
| Live | PORTFOLIO | 30 days, ticks | ÷ cost basis × 100 | 100 |
| Composite | INDIA | 12 months | stacked by child + share-of-income line | your average |

**Renderer rules.** (1) Baseline first, then axis; indexed series symmetric about the baseline. (2) Monotonic series
never chart the level. (3) Each class has its natural window; pinch moves within it without changing the transform.
(4) Outliers kept with a mark; axis from the 5th to 95th percentile, padded. (5) The unfinished period is hollow.
(6) Units honest: never convert currency silently; percent and index never on one axis. (7) Two series share a
baseline, not an axis. (8) Colour is never a judgement. (9) Reduce Motion: cross-fades.

---

## 4. Tess
Tess's lines are Newsreader italic, one sentence, written from the room's state ("The basil's been dry since Monday",
"Food is running 37% over last month", "On this pace you close the month with 179"). In Purse, Tess's sentences are
written from indices. Room names in her mouth use the ship names ("Lookout says rain by four", "Watch: walk at six",
"Purse closes the month at 179").

---

## 5. What was tried and set aside (do not re-propose)
- Routines: woodland v1 drawn (248), worn paths / sampler / beads (260), the cat (261), orrery and music box (262), plain
  ideas (263: record player, day map, polyrhythm, sundial, voice), day-map makeovers (264, 265), photo windowsill and
  photo woodland (266, 267). Verdict: finish and function; the woodland, polished, won.
- Money: the jar (269), the in/out pipe flow (269 v2), the town (270), tiles (271: too close to the Bridge mosaic; kept
  as a possible inner page), the balance of words (272: too close to the Log's word wall), three ways (273), liquid
  balance (274: the literal beam threw him off), five metaphors (275: afloat, tug of war, rising water, charge, push),
  charge (276: liked; possible widget). The stock chart and indices won.
- Names: keystone-based, purpose-based, Roman rooms, Greek gods, plain house, newspaper. The ship won.

---

## 6. How the boards are rendered (replicate on any machine)

### 6.1 What a board is
A single self-contained HTML file per design round: `docs/handoff/design-sheets/<topic>-<nnn>/board.html`. No build
step. It starts with `<title>`, `<meta name="claude:viewport-fit-sides" content="cover">`, a Google Fonts link
(Figtree, Outfit, Newsreader), then `<style>`, then the markup, then one `<script>` IIFE. Colours are tokens on `:root`
with dark overrides under `@media (prefers-color-scheme: dark)` guarded by `:root:not([data-theme="light"])` and again
under `:root[data-theme="dark"]`. The page shows: a header (sheet number, title, one paragraph), the landing on two
phones (paper and black), a large sandbox of the keystone with buttons for its moves, and a "what it does" grid.

### 6.2 The phone and the slot
- `.phone` is 402 x 874 with radius 46, scaled to fit with `transform: scale(w/402)` on a `[data-fit]` wrapper whose
  height is set to `874 * s`. `.phone.black` swaps the tokens to the black look.
- The status bar, title (40 pt, room colour), the sentence at top 106 (26 pt light, key phrases bold in role colours),
  the keystone `<canvas class="key">` at left 24, top 196, 354 x 182 (or left 0, width 402 when it bleeds), a caption
  line at 390, two update rows at 424, doors at 540, the action word bottom-left, "Tess" bottom-right, the home bar.

### 6.3 Canvas drawing
- Size: `canvas.width = cssWidth * max(2, devicePixelRatio)`; draw in logical units with
  `ctx.setTransform(s,0,0,s,ox*s,0)` where `s = canvas.width / logicalWidth` (354, or 402 with `ox = 24` for a bleed).
- One `requestAnimationFrame` loop for the page: `dt = clamp((now - last)/1000, 0, 0.05)` (clamp to 0 at the bottom:
  headless browsers can hand a negative first frame), `W.t += dt`, then every canvas draws.
- State is shared; effects are per canvas. When several canvases show the same data (phones and sandbox), an action
  changes the shared state once and pushes its effect to every canvas (`all(fn)`), never from one canvas's handler
  alone.
- Displayed values ease toward real ones (`shown += (real - shown) * min(1, dt*k)`), so things move, never jump; a
  value that "arrives" (a droplet, a floor, a drop) is held back until its animation lands.
- Transitions between modes are time-based, not integrated: record `from`, `t0`, `target`, and compute
  `lerp(from, target, clamp((t - t0)/duration, 0, 1))`. (An integrated version drifted out of range in headless.)
- Every board accepts query parameters for screenshots: `?hour=`, `?weather=rain|snow`, `?demo=<state>`, `?ix=`,
  `?born=1` (skip the draw-in), `?instant=<seconds>` (move animations forward). Keep these; they are how the states
  are captured.

### 6.4 Techniques used
- **Light by hour (woodland).** Keyframes of `{h, top, hor, hill, amb, warm}`: 0 0B1526/24324A, 5.4 1A2742/4A4E68,
  6.5 8FA4C8/F2C9A6, 8.5 A9C7DD/EDE5CF, 13 9CC3DC/EAE8D6, 17 9DB9D3/F0DDBC, 18.9 6C78A6/F3AE84, 19.8 2E3A63/B07A78,
  21 101C33/2D3A56; eased between neighbours. Sun x = lerp(26, 328, f), y = 96 - sin(f·π)·78 over rise 6.3 to set 19.4.
- **Crowns.** Union of 3 to 6 lobes (ellipses) per kind; fill in the shade colour; clip to the union; draw the base
  colour as a large ellipse offset toward the sun and the lit colour smaller on top: a crisp two-tone terminator.
- **Dissolve (no frame).** In this order: (a) the upper sky thins into the page colour (linear wash, 0.92 at the top to
  0 at 96 pt); (b) lean the whole scene toward the page colour (12% on paper, 22% on black); (c) page-colour mist 56 pt
  in from each side and 48 pt up from the bottom (stops 0.85, 0.5, 0.2, 0.05, 0); (d) an alpha mask applied with
  `destination-in`: per pixel `fx(x)·fy(y)` with smootherstep `u³(u(6u-15)+10)`, sides over 11% of the width, top 12%,
  bottom 18%. The page colour is read from whatever the canvas sits on
  (`getComputedStyle(canvas.closest('.phone') || body).backgroundColor`).
- **Reactions.** Damped bounce `1 + a·sin(e·π·2.4)·exp(-e·2.1)` scaled from the tree's base; glow as radial gradients
  (`lighter` on black); particles with life, gravity and drag; rings as expanding ellipses.
- **Charts (Purse).** Pure canvas paths; baselines dashed; forecast dashed ink; fills as vertical gradients to 0; labels
  Figtree 600 at 4.4 to 5 pt in small caps, numbers Outfit; everything clamped inside the plot.
- **Metaballs (tried, 274).** Per-pixel field Σ(r²/d²)², colour weighted by contribution, alpha by a narrow threshold,
  at device resolution capped at 760 px wide. Kept here for reference.

### 6.5 Checking and screenshotting (tooling)
- **Syntax check before every publish:** `session-oct25/scripts/jscheck.sh <board.html>` runs each `<script>` block
  through SpiderMonkey (`gjs -c "new Function(src)"`) and flags unclosed tags. A bracket counter alone missed real
  errors; always use this.
- **Headless Chromium:** a standalone build from `https://cdn.playwright.dev/builds/chromium/1148/chromium-linux.zip`
  unzipped to `/tmp/claude-49350/chromium/chrome-linux/chrome` (no pip or node needed). Any recent Chrome works.
- **Screenshot:** `session-oct25/scripts/shot.sh <board.html> <out.png> [width] [height] [virtual-ms]` with
  `QS='?hour=17.6&demo=water&p=0.6'`. It wraps the board in a skeleton if needed and runs
  `chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --window-size=W,H
  --virtual-time-budget=MS --screenshot=out.png file://...?QS`.
- **Read state without pixels:** `chrome ... --virtual-time-budget=2500 --dump-dom file://...` and grep the status line;
  boards write errors into it (`say('Error: ...')`), which is how blank canvases were diagnosed.
- **Contact sheets:** Python 3 + Pillow crop the canvas region from each screenshot and paste them into a labelled grid
  (see `session-oct25/scripts/render2*.py` and the inline scripts in the session). Headless timing is coarse; use
  `?instant=` to place an animation mid-flight.
- **Plates (Lookout):** `session-oct25/scripts/crop_plates.py` crops tonemapped Poly Haven JPGs to portrait strips
  centred on the sun; prompts for generated plates are in `design-sheets/weather-plates/PROMPTS.md`.

- **The woodland and virtual time:** the Watch woodland (268 board, prototype `watch.html`) never settles under
  `--virtual-time-budget`; Chromium hangs until killed. Shoot it with `REAL=1 shot.sh ...` (real-time `--timeout`).
- **Screenshot the prototype on a settled screen:** open it with `reset(name)`, not `go()`, or the shot catches the
  slide-in. Bridge's top lines flip on a timer; re-shoot if one is mid-flip.

### 6.5a The linked prototype (how it is put together)
`design-sheets/prototype/` is the whole app on one phone: `index.html` plus `purse.html`, `watch.html` and
`weather-plates/`. Open `index.html` from disk or serve the folder (`python3 -m http.server`).
- **Locked rooms come from their boards.** Purse and Watch landings are the 278 and 268 boards themselves, loaded in an
  iframe. `session-oct25/scripts/make_embed.py <board> <out>` makes `purse.html` and `watch.html`: it pins the
  board's first phone at 0,0 at scale 1 (`?embed=1&look=paper|black`), hides the board's status bar, home bar and Tess
  word (the prototype draws its own) and applies the ship title. Edit the board, then re-run make_embed.py; never edit
  the generated files. Two things the embed must not do: hide the rest of the board with `display:none` (zero-width
  canvases hang the woodland) or set `overflow:hidden` on html/body (also hangs it).
- **Ship names are applied at render.** Screens are written with the old room names; `shipNames()` renames `.ttl`,
  `.backw` and `.kback` on render, and the v2 block renames `ROOMS` and drops Lists from the Bridge app list.
- **Class names are global.** The prototype grew in layers (v1 screens, then a v2 block), and three v2 classes reused
  v1 names: `.glass` (a v1 frosted menu with blur, padding and z-index 20) made the Lookout glass a frosted band that
  covered the readout; `.hours` moved Today's strip; `.board` collided with Bridge. They are now `.wglass`, `.whours`
  and `.tboard`. Before adding a class, grep for it.
- **Lookout text colour** is chosen from the plate's brightness under the glass. From `file://` the plate taints the
  canvas and `getImageData` throws; the prototype then judges by the hour (night or dark plate: light text).

### 6.6 Publishing and sharing
Boards are published as private claude.ai artifacts from their file path (same path = same URL on update). The person
reviews on a phone from a remote session, so send screenshots and files into the chat; links only work on his own
account. Commit locally after every round with the sheet, renders and scripts.

### 6.7 Building it in the app (pointers)
Woodland: SwiftUI `Canvas` in a `TimelineView`, fed by Routines objects (stage and health from the log), the dissolve
as a mask image. Purse: an `Index` type (rule AST, clock, class, overrides, children, pins, alerts) beside the ledger,
evaluated lazily over the object store with a cached series per clock; one chart component that implements the class
table and renderer rules; the dial and scroller as two `ScrollView`s with snapping. Lookout glass: two shadows and a
hairline over the plate, no material. Galley tickets: views with `rotation3DEffect` for the flip.

---

## 7. Where everything is
| What | Path | Board |
|---|---|---|
| This document | `docs/handoff/TESSERA-DESIGN.md` | |
| Running design record | `docs/handoff/design.md` | |
| Session handoff (decisions in order) | `docs/handoff/session-oct25/HANDOFF.md` | |
| Woodland (Watch) | `design-sheets/routines-garden-268/` + `.md` | https://claude.ai/artifact/Pi96MVUEPMS2vvChk4vrDp |
| Stock chart (Purse) | `design-sheets/money-stock-277/` + `.md` | https://claude.ai/artifact/FYcAr5BR2G5sMdajk5VUXS |
| Indices (Purse) | `design-sheets/money-indices-278/` + `.md` | https://claude.ai/artifact/MZjgtzedb9kp3ZGBvUQtcL |
| Index system spec | `design-sheets/money-index-system-279.md` | |
| Lists folded into Log | `design-sheets/lists-decision-280.md` | |
| Names | `design-sheets/names-281.md` | |
| Galley pass | `design-sheets/kitchen-rail-259/` + `.md` | https://claude.ai/artifact/T1UHN2Rtak4TmZwbsfvHep |
| Deck blackboard | `design-sheets/kitchen-training-258/` + `.md` | https://claude.ai/artifact/RTMonbdXvyVWjQWnYcYXeP |
| Lookout glass | `design-sheets/kitchen-weather-254/`, `weather-inside-255/`, `weather-plates/` | TQ2mH5kFqJqXZs7jMEoXts, XDNb4wm84nHNguDhFMqesr |
| Log word wall | `design-sheets/notes-landing-246.md` | https://claude.ai/artifact/1mSPKcxhvQB4pFU2tmQZkx |
| Bridge mosaic | `design-sheets/home-delta-236.md` | https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM |
| Linked prototype | `design-sheets/prototype/` (index.html, purse.html, watch.html, weather-plates/) | https://claude.ai/artifact/1dH25PYRWRd3TU7LAacNHc |
| Final hub board | `design-sheets/hub-282/` | https://claude.ai/artifact/2F78G1zeJzmwezUFX4w8ck |
| Tooling | `docs/handoff/session-oct25/scripts/` (jscheck.sh, shot.sh, make_embed.py, crop_plates.py, render26x.py) | |
| Rejected rounds | `design-sheets/` 260 to 276, each with its verdict | |

## 8. Open items
1. Lookout: what lives inside the glass; the rest of the page; overcast-night and storm plates.
2. Galley: the finishing gesture (hold-and-tear recommended); flip animation polish; haptics.
3. Deck: the chalk hand; colours by split; reactions.
4. Log: rename on screen; lists on the wall; door pages review.
5. Purse: which indices ship first (MONTH, SPEND, SAVE, PORTFOLIO); the "unplanned" flag; live data sources.
6. Watch: Reduce Motion path; touch targets for back-row trees on device; day-one sprout size.
7. Apply the ship names across titles, Bridge tiles, Tess's grammar and specs when each room is next built.
