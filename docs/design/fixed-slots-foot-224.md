# Item 224: Text that fits its place, and one action word at the foot (Oct 23, 4:15 PM PT)

Kaushik, 4:09 PM. Every element gets its own layout. Shown text must never take more room than its place or jump to the next line, so the layout doesn't move when things change. Input is exempt. Tess shortens anything that doesn't fit. He also doesn't like bottom menus: the foot gets a single word on the left that starts something (a capture or an action mode), and Tess is on the right.

## 1. Fixed slots (every display surface; supersedes "lines wrap" in 205 and 211 for display text)
- Every piece of shown text sits in a slot with a fixed width and a fixed line count, declared in the layout. Examples:
  - Home top rows: 1 line each (216).
  - The one thing's big tier: 2 lines.
  - A room's sentence: 2 lines.
  - A fact line: 1 line.
  - A row name: 1 line.
- The font never shrinks to fit, and nothing is ever cut with "...".
- Each templated text has an ordered set of forms, from full to short, at least two (as in 216's notices). The phone measures each form with the real font at the current Dynamic Type size, and shows the longest form that fits the slot.
- When no form fits, Tess writes a shorter one on the device, within the slot's character budget. It is checked by measuring again. Facts survive: names, digits and days are never dropped or changed. If it still doesn't fit, the shortest form is used. Builders test with the longest names in the sample data.
- A user-written title (a note, a list item, an exercise) gets a one-line short label made once by Tess on the device, kept beside the real title, and used only where a slot is too narrow. Private things use shownLabel, which is already short.
- Text changing in place never changes the slot's size: departure flips, entrances and summaries all happen inside it.
- At accessibility sizes each slot's line count may grow by one, set once for the size, never by the content. If a layout still can't hold it, the value moves under its name (131 §2c).
- Input fields and the note writer are exempt: they grow as he types.
- QA: a fit test renders every slot with the longest sample text at default size and AX3, and fails on any wrap past the slot, any "...", or any frame that changes height when the content changes.

## 2. The foot: one action word, bottom left (supersedes the door rows at the foot in 131 v2, 218, 219 and 223)
- No menus or rows of door words at the foot of any room.
- Bottom left: one action word in the room's accent, weight 600, 20 pt, which starts something:
  - Training: "Start Push A" (live workout mode).
  - Kitchen: "Cook" when a dinner is planned (cook mode), otherwise "Plan tonight".
  - Notes: "Write".
  - Lists: "Pack" (the lead list's run mode).
  - Routines: "Start" plus the next routine's name, for example "Start night" (run mode), or "Pick up" while one is running.
  - Money: "Add a spend" (sheet 172's sentence capture).
- Bottom right is Tess's corner, untouched.
- The doors move up:
  - Title tap opens the room's index (all its places).
  - The right edge opens the glance and then the side (76).
  - Doors that matter today become linked words in the sentence, for example "Rent is due Friday" opens Due.
- Each room's own body (sheets 218 to 223) keeps everything else.

## Reviewer fixes (coordinator relay, Oct 23)
1. While the thumb arc shows, the bottom-left action word steps aside with a plain swap (no fade). It swaps back when the arc leaves.
2. The edge door is a short pull from the right margin only, never from a row, so it can't clash with row swipes or Home's pages. The left edge is the way back (no back word, 4:16 PM ruling).
3. Short forms come only from the on-device model, never Claude. Private and walled items use shownLabel and never get a generated label. Generated labels stay out of backups, widgets and the Lock Screen. Short lines keep the no-amount and digits rules.
4. Each form is computed once and cached; layout never waits on it. Until it's ready, the shortest written form shows.
5. VoiceOver always reads the full text.
6. Each room's title-tap index lists every door it has, Money's six included. Action words: Pantry "Add a thing", Recipes "Cook", Habits "Check in", Tasks "Add a task", Review "Start review". Tess gives a one-time hint for the title tap and the edge.
7. The fit test runs at default, AX3 and AX5. Action-word colours stay ΔE 10 or more from Ember.
