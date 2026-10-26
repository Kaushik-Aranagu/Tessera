# Item 138: Numbers and transitions, build sheet (Oct 22)

Builds sheet 136 C and D. Kaushik, Oct 22 4:38 PM PDT: "go ahead and queue them up".
Review switches (default Off): numberRules (C), roomMotion (D). Builder A owns both (motion,
type); Builder B adopts them on his pages after A's shared views land. MotionPolicy only;
Reduce Motion = 150 ms crossfade or plain appear; one haptic per moment.

## C. Numbers (one shared view: HouseNumber in DesignSystem)
HouseNumber(value, unit, kind: .exact | .estimate, role) draws every number through
Outfit. The rules below live in it, so apps get them by switching to it.
1. Hung fraction: the part after the decimal point one role smaller, ink 2, baseline
   aligned to the whole ("82" + ".5"). Money's cents already do this; Money moves onto
   HouseNumber unchanged. Integers draw no fraction slot, except Money's empty cents slot
   for "about" totals (133).
2. Old value: when a value changes by his hand (drag, type, unit turn excluded) or a new
   best lands, the old value slides down 0.6 em under the new one at ink 3, prefixed "was"
   ("was 80"), holds 2 s, then dries away (Theme.Motion.dry). Only one old value at a
   time; a second change replaces it. Never on Money balances (no "was" on money).
3. Estimate weight: .estimate = Outfit 200 at every size, .exact = Outfit 300 (below 28
   pt) / 200 (28 pt up, sheet 131) and one step heavier than an estimate at the same size:
   so at 28 pt and up, exact = 300, estimate = 200. "about" always comes with .estimate.
4. Unit turn: tapping the unit word cycles Measure's units for that quantity (kg / lb,
   cups / grams, mi / km); digits roll (existing rolling-digit tick) to the converted value,
   the unit word crossfades 200 ms. Money is not a unit turn (it converts with "about").
5. Pressure: while a number instrument is dragged, weight goes from its rest weight up to
   +200 with drag speed (clamped at 500), eased back on the settle spring when the finger
   stops. Selection tick per step as today. Reduce Motion: no weight change.
- Spacing: number and unit joined by a no-break space everywhere (fixes "kg." orphan).
- AX sizes: hung fraction comes up to full size (as Money at AX5); old value sits on its
  own line under.

## D. Transitions
1. Word becomes the page: shared modifier .opens(id) on any word that opens a page; the
   word's frame matches the target's title (matched geometry), house spring; back
   reverses into the same word. Used by 135 part 1, Home v2, landing doors, link words.
2. Things travel home: a receipt or written line moves from the Tess corner toward its
   destination (the app's edge on Home v2; the page's foot elsewhere) over 420 ms, house
   spring, and dries. Reduce Motion: appears in place.
3. Sheets lift like paper: every sheet (sides, detail sheets, Change the plan) rises from
   the bottom with its top edge leading, no shadow, no blur, no dim beyond ink 3 on the
   page under; settles on the house spring with 0.12 bounce; drag down returns it.
4. Rooms shift: moving between apps animates the ground tint (each app's ground, 127 B
   <= 3%) and the accent token over 300 ms; nothing else moves for the room change.

## QA
Switches Off = today. On: every Outfit number in the six landings and their first pages
goes through HouseNumber; "was" never on money; no-break spaces; Reduce Motion; AX5.
