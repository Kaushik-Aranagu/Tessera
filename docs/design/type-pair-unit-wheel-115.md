# Item 115: the type pair and the unit wheel (Design, Oct 20 PM PT)

Status: Kaushik chose pair 4 (Oct 20, 4:5x PM) and asked for the unit wheel (his 5:10 PM). Page with the drawings:
https://claude.ai/artifact/GVeZJ5v4bZbF3yHyReNZMs ; image mockups/fonts-final-115.png.
Ships behind a Settings > Review row "Font" (key review.font, default On for the pair, Off = Inter Tight). The unit
wheel is not behind a switch (it only adds a gesture and changes display).

## 1. Fonts (both SIL OFL 1.1, free to bundle; credit on About)
- Words: Cormorant Garamond (variable, weights 300-700). Use LINING numerals always (font-variant lining-nums /
  .monospacedDigit not needed; set `lnum`), never oldstyle: oldstyle makes a "1" read as a capital I.
- Numbers and small caps labels: Urbanist (variable, 100-900).
- Bundle both in the app target AND the widget extension; register in Info.plist (UIAppFonts) per target.
- Credit on About: "Cormorant Garamond (c) The Cormorant Project Authors. Urbanist (c) The Urbanist Project Authors.
  SIL Open Font License 1.1."

## 2. Scale (1.5x steps), points
14 label / 21 body / 32 key and row name step / 48 numerals in lists / 72 page title / 108 hero numeral (live set reps).
The live weight is 162 (1.5 x 108) only on the live set. Never between steps.

## 3. Roles
- Page title: Cormorant Garamond 500, 72 (60 on the live set), -0.02 em, stage colour. Wraps to two lines when long
  (AI day names); never cut, never "...".
- Works line, row names, start key: Cormorant Garamond 500 / 600, 23 and 32 (32 is the key word).
- Kicker row (the old violet line): Urbanist 600, 14, +0.12 em, UPPERCASE, ink 50%. Left "Training", right
  "5 exercises, 55 min". It replaces the violet context line.
- Numerals: Urbanist ExtraLight 200, -0.03 em, tabular. 48 in rows; 108 and 162 on the live set.
- Units: Urbanist 600, 10, +0.14 em, UPPERCASE, ink 50%, 4 pt after the number, sitting on its baseline.
- Detail under a row ("4 x 5-8"): Urbanist 600, 11, +0.12 em, UPPERCASE, ink 50%.
- Removed: the blue "ready for 82.5" Tess line at rest (Tess speaks only when she has something to say), the violet
  context line, lines between rows, the per-row figure.

## 4. The unit wheel (one component: NumberWithUnit)
- Everywhere a number carries a unit, the unit is a small word that can be swiped. Swipe up or down on the unit (or on
  the number plus unit): the units that fit step in a short wheel, one visible at a time, a light tick haptic per
  step; the number converts as the unit changes (82.5 KG -> 181.9 LB); it settles on release.
- Display only. Stored values never change (kg stays kg, ml stays ml). The choice is remembered per KIND of unit
  (weight, length, volume, temperature, time), so changing one kg to lb changes every weight in the app, and a
  small "reset" is Settings > Looks and day > Units.
- Fit rules: weight kg/lb; body weight kg/lb/st; length cm/in; distance km/mi; volume ml/fl oz/cup (recipes);
  mass g/oz (recipes, groceries); temperature C/F; time min/hr (display only, a timer's run is unchanged); temperature C/F.
- Money: see section 7 (decided: swipes, estimate with the rate date).
- Rounding: converted values round to the plate or step that fits (lb to 0.5, kg to 0.25), the original is one tap
  away: a tap on the unit shows "82.5 kg" for a second in ink 50% as a receipt (info only).
- Privacy: a private workout's numbers use the same wheel but nothing about them leaves the phone; body values
  convert on the phone only and never reach Claude, Sent rows, backups, logs or widgets.
- Reduce Motion: the wheel becomes a tap that cycles the units with a 150 ms crossfade. VoiceOver: the unit is an
  adjustable element ("kilograms, adjustable, swipe up or down to change"); the spoken value follows ("181.9 pounds").
- Dynamic Type: the unit scales with the number; at AX sizes it moves under the number on its own line.

## 5. Where it appears, by owner
- Builder A: Training page rows and Start key, live set (weight, reps, rest), the set marks tooltip, exercise sheet
  best and history, the cook clock (min/hr), timers sheet, Day log lines, widgets and Live Activity (display units
  only, no wheel on widgets: they show the chosen unit).
- Builder B: Groceries (amounts, g/oz), Recipes (ingredients, servings scale, ml/cup, temperature), Reading (pages
  stay pages, no wheel), Notes/Habits counts (no unit, no wheel), You page body values (kg/lb, cm/in), Money screens
  (wheel, estimate shown as "about", section 7), Settings > Looks and day > Units.
- Core: the converter (one pure UnitConverter with rounding rules), the per-kind unit choice store, formatting in
  receipts and DayStory ("Bench press, 181.9 lb" when lb is chosen), tests that stored values never change; the rates cache (fetch rates only, never amounts, never via Claude).

## 6. Open (Design to settle with the first build)
- Whether the wheel needs a visible hint the first time (one quiet "swipe the unit" line, once, in Tess blue).
- The order of the wheel (kg then lb, last used first).

## 7. Data plane and control plane (Kaushik, Oct 20 5:14 PM): the model behind the component
Every measurement the app shows or takes (a weight, a quantity, a temperature, a duration, a distance, an amount) is
ONE object, a Measure, made of two parts that are drawn and controlled separately.

DATA PLANE (what it is, how it is drawn)
- value: a number stored in the base unit of its kind (kg, g, ml, C, s, m); never changed by display.
- unit: one of the units of its kind. kind: weight, mass, volume, length, distance, temperature, time, count, money.
- Each part is its own styled piece: the number (Urbanist ExtraLight, scale step) and the unit (Urbanist 600, 10 px
  caps, ink 50%). A screen may show the number alone, the unit alone, or both; each carries its own role and its own
  accessibility element.

CONTROL PLANE (what can change, and how)
- Number control: the number alone is changeable where the screen allows (the dial or drum for sets and amounts,
  the keyboard for a typed amount); editing it changes the stored value in the shown unit and converts back to base.
- Unit control: the unit alone is swipeable when its kind has more than one option (up/down wheel, tick haptic);
  a kind with one unit (reps, pages, steps, count) shows a plain word with no gesture and no affordance.
- The relation (the point): changing the unit re-expresses the SAME stored value in the new unit, so the number on
  screen changes by itself (82.5 KG -> 181.9 LB; 180 C -> 356 F; 250 ML -> 1.06 CUP). Editing the number never
  changes the unit. One shared converter does both, so no screen does its own sums.
- Scope: the unit choice is per kind and app-wide (set once, true everywhere that kind appears); a screen may pin a
  kind locally (a recipe card in cups) only if its own switch says so.
- A screen declares what it exposes: `.measure(value, kind, controls: [.number, .unit])`, `.unit` only (a read-only
  figure whose unit still swipes), or `.number` only (a fixed-unit figure). Widgets and Live Activities draw
  both parts in the chosen unit with no controls.

WHERE EACH KIND LIVES (so every place is covered)
- Kitchen: ingredient mass/volume (g, oz, ml, cup, tbsp), oven and probe temperature (C, F), cook times (min, hr).
- Workouts: load (kg, lb), distance (km, mi), time, body length and weight on the You page (cm, in, kg, lb, st).
- Climate: temperature (C, F), wind (km/h, mph), rain (mm, in), once Weather arrives.
- Health and body: weight, height, energy (kcal, kJ); phone-only, never to Claude.
- Finances: an amount is a Measure of kind money with the currency as its unit. DECIDED by Kaushik Oct 20 5:15 PM
  (card, "Swipe, about"): (A) the unit swipes like every other kind and the number converts, using
  exchange rates the phone fetches now and then (only the rates are fetched, never his amounts) and caches; a converted
  amount is an estimate as of the last fetch and reads "about 24.80 EUR" with "rates of Oct 20" one tap away; the
  amount stays STORED in the currency he typed; nothing about his spending goes to Claude, Sent rows, logs or widgets;
  no rates yet or offline = the unit does not swipe and shows only the typed currency. (B, not chosen) no swipe. Sign stays against the number as #1165 draws it in both.
- Temperature is a kind: C and F (also K only if asked); stored in C.

RATES (Kaushik 5:15 PM: "take some cached values whenever we can take it live"): use the live rate whenever the phone
can fetch one (on open and at most once an hour while the page is up); otherwise the last cached rate, shown with its
date ("about 24.80 EUR, rates of Oct 20"). Only when there is no cached rate at all does the unit stop swiping.

CONTRACT FOR THE BUILD
- Core owns Measure, MeasureKind, UnitConverter (pure, tested: round-trips are exact within a tolerance, stored
  value unchanged, money converts to nothing) and the per-kind choice store.
- The UI piece (Builder A builds it once, B reuses it): `MeasureView(measure, controls:)` draws the two parts and
  handles the swipe; callers never format a number or a unit by hand.
