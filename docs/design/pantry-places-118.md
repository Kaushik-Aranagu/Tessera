# Item 118: Pantry built on places (Kaushik picked layout C, Oct 22)

Stills: mockups/pantry-places-118.png. Replaces the separate Pantry and Groceries pages with one page, "Pantry". The old
Groceries page becomes the first place, "To get". Faces and sizes follow item 116. No cards, no pills, no lines between
rows.

## 1. The page
- Back word "< Kitchen" (the app's back word) top left, Close top right, the title "Pantry" on the 22 pt gutter (72 or 48 by the item 116 rule),
  one subtitle line in the context colour ("9 in the fridge, eggs running low").
- Two halves under the title: a narrow left column of PLACES (about 112 pt wide) and the open place's contents filling
  the right. Nothing is boxed. The open place is full ink, the others ink 50%, To get is in the stage colour while it has
  items. Each place word is followed by its count in small Outfit 300.
- Places, in order: To get, Fridge, Freezer, Shelf, Counter, and "+ Add a place" (label role) for any other (Cupboard,
  Spice rack, Garage). Places are objects like everything else; a place can be renamed, re-ordered by a long press, and
  removed (its items move to To get).
- Opening a place: tap its word (or swipe sideways on the right half; a swipe moves to the next place). One haptic, the
  right half crossfades (Reduce Motion: no slide).

## 2. A place's contents
- Sections are small words above the rows (label role, ink 50%), not boxes: Fridge = Door, Shelves, Drawer; Freezer =
  Drawers, Ice; Shelf and Counter have none (they list directly). Sections can be edited by the same long press.
- Each row: the name left, the amount right (Outfit 300, unit wheel for kitchen units, item 115 and 116). "low" in the
  stage colour next to an amount that is under its usual level. "use today" or "use soon" in the stage colour for an
  item near its date (only when a date is known; never guessed).
- Row tap opens the item sheet (3). Row swipe right: used up (it goes to To get with its amount). Row swipe left: remove.

## 3. To get
- Same shape, grouped by shop section (Fresh, Dairy, Dry, then whatever the aisle re-order already uses).
- Swipe right on a row when bought: it moves into its place (the item remembers its place; a new item asks once). Swipe
  left takes it off the list. One haptic, a short glide of the row into the left column word it goes to (Reduce Motion:
  crossfade).
- The subtitle reads "7 to get"; the weekly word from item 114 stays where it is today.

## 4. The item sheet
- A bottom sheet with the item name (32), the amount in Outfit 200 at 48 with its small unit (unit wheel), a "low" note
  when it applies, a "Put it in" row of place words (the current one in full ink), and two words at the foot: "Add to
  get" and "Used up". No buttons with fills.
- Money is not shown here. Nothing from this page goes to Claude except what the existing grocery grammar already
  sends; place and amount values are never added to a Claude payload.

## 5. Owners and order
Builder B owns the page and its screens; Core owns places and sections as classes (additive migration, no new
catalog key beyond a class for Place and a place link on pantry items). One PR for the page with To get as the first
place; the item sheet and the swipes in a second. Stills for each place at default size and AX5 before PASS.

## 6. The places drum (Kaushik, Oct 22: "a nice UI element with nice effects when dragging through sections")
Clip: clips/pantry-place-drum-118.mp4 (source drum.html in the studio). The left column is a vertical drum, not a list of
buttons:
- Drag up or down anywhere on the left column. A continuous value p (which place is under the focus) follows the finger.
  The place near p grows (scale 1.18 at the focus, 0.74 far away, smoothstep), its neighbours shrink and sit at lower ink
  (ink 100% at focus, about 34% far away). No blur on the words. To get keeps the stage colour until it is the focus.
- The right half follows the same p: the contents of each place slide by 46 pt per place of distance and fade out by half
  a place away (opacity = 1 - 2.1 x distance, so two places never overlap as text), so the old content leaves as the new
  arrives. The subtitle line under the title rolls to the focus place's count ("14 on the shelf") with numericText.
- One selection haptic each time the focus passes a place. On release it snaps to the nearest place with one spring (a
  flick carries across several places by its velocity); no overshoot past the ends beyond a small rubber band.
- A tap on a place word jumps to it with the same spring. VoiceOver: the column is an adjustable element ("Pantry places,
  Fridge, 9 items"), increment and decrement move one place.
- Reduce Motion and Low Power: no scale, no slide; the focus changes with a 150 ms crossfade and the tick stays.
- Everything goes through MotionPolicy; no new animation values outside it.

## 7. Dial, not drum (Kaushik, Oct 22: the list must not travel up and down)
Replaces the moving column in section 6. Clip: clips/pantry-place-dial-120.mp4.
- The column never moves. Fixed slots at 58 pt: the focus slot with two slots above and
  two below. The four places (Fridge, Freezer, Shelf, Counter) turn through the slots as a
  loop: past Counter comes Fridge again. A place leaving the far slots fades out and
  returns from the other end, so no jump is seen.
- Slots bow a little (left edge +8 x d squared pt) so it reads as a dial; the 22 pt gutter
  holds at the focus.
- Focus = size 1.32, neighbours 0.70, ink 100% to 30%. No blur.
- To get is not in the loop. It is pinned above the dial, 24 pt, in the hot colour with its
  count, always visible. When it is the open place it grows to 1.5 and the dial dims to
  small. Tap it, or flick down past the first slot, to open it; tap or drag the dial to leave.
- The right half does not move up or down: the open place cross-fades (old out first, then
  new in) with a 14 pt sideways slip.
- Haptic, Reduce Motion, VoiceOver and MotionPolicy rules as section 6.
