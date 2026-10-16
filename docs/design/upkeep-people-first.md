# Upkeep and People: the first screens, with real copy (board item 7)

This sheet deepens `upkeep.md` and `people.md` for Builder B. Where they differ, this sheet wins.
- Drawn to `no-buttons.md`, `themes.md` and `no-dots.md`.
- The data is the shared eval store: Thu 15 Oct 2026, 18:00.
- The copy is from Research's `fixtures/upkeep.md`, `fixtures/upkeep-starters.md` and `fixtures/people.md`.
- Still: `mockups/upkeep-people-first.png` (source `studies/upkeep-people-first.html`), showing Upkeep's first run, the Upkeep page in Porcelain and in Obsidian, and the People page.

## The HomeLink words (the doors)
- **Upkeep and People are words on Review's link line,** which becomes: **The week · Notes · Upkeep · People**. That's `HomeLinkLine`, Body 21/600 ink, where a tap zooms in.
  - If the line passes 346pt, it wraps to a second line. Reading and Money (item 8) join the same line.
  - Kitchen keeps its own page, because it has three doors and a running process.
- **Add the cases** `.upkeep` and `.people` to `HomeLink`.
  - The back word on both pages is **‹ REVIEW**.
  - The zoom comes from the word, and on the tap the zoom floods in at 12% of the class pigment (`no-dots.md`): `neutral` for Upkeep and `context` for People.

## Upkeep

### First run: the pick (Research's starters, open question 6 answered)
- **This shows the first time the Upkeep page opens**, and never at launch.
- **Tess's line** in cobalt, Body 21: "What do you keep up with? Pick any."
- **Ten starters show at first, in five groups.** Each group has a label word in `inkSecondary`:
  - KITCHEN: Clean the kitchen 7, Take out the bins 4, Descale the kettle 30.
  - FLOORS AND BATHROOM: Hoover the flat 7, Clean the bathroom 7.
  - LAUNDRY: Laundry 7, Change the bed sheets 14.
  - PLANTS: Water the plants 7.
  - BILLS: Pay rent 30, Pay council tax 30.
- **15 MORE** is a label word. A tap unfolds the other fifteen into their groups, in the same column, and the page scrolls.
- **A starter line:** Body 21 in a 36pt row, with the interval in the right column as a label ("7 DAYS").
  - **Unpicked:** 400 weight, `inkSecondary`.
  - **Picked:** 600 weight, `ink`.
  - **The moment of picking:** the ink sweeps in from the left (240ms). A faint `neutral` wash blooms behind the words and dries (`no-dots.md`).
  - A second tap fades the line back. There's no tick, box or dot.
- **Keep N** is a stroke word at the bottom right, in the `now` stroke. It appears with the first pick, and N counts live on the settle spring.
  - It writes one `AddChore` per pick in one undoable batch.
  - Tess says "Keeping 5. Tell me when you do one." with UNDO.
- **SKIP** is a label word at the bottom left. It writes nothing, and the list never shows again.
- **Picked chores read "never logged"** and don't drift to Now until the first log (Research's default for question 2).

### The Upkeep page (screen 6)
These changes are made to `upkeep.md`, so that it meets the type tiers and the contrast rules:
- **Names are Title 34/500,** not 28 (28 isn't a tier).
  - Ink runs from `inkTertiary` at the foot to `ink` at the NOW hairline. That's allowed because the names are 34pt.
  - There's no hex grey. Read the tiers from the look.
- **The age moves under the name,** as a label line in `inkSecondary`:
  - "21 DAYS · USUALLY 14"
  - "6 DAYS · USUALLY 7"
  - "TODAY"
  - For a chore with no interval: "NEVER LOGGED" or "7 DAYS".
  - This frees the right edge, so long names like "Change the water filter" never collide.
- **Spacing:** a name and its age take 72pt. Two chores with close staleness never overlap; the later one pushes down by 72. Past staleness 1, chores stack under the hairline, stalest first.
- **NO RHYTHM YET** sits on a hairline at y 716, with the names in one Body line at `inkSecondary`: "Laundry · Take out the bins". The middle dot here is text, not a marker.
- **Logging a chore done by holding it (0.6s):**
  - The name fills from left to right in `health` (sage). That's the moment.
  - It sinks to the foot on the settle spring, and the sage dries to the foot's `inkTertiary` over `Theme.Motion.dry`.
  - Tess says "Cleaned bathroom. Was 21 days, usually 14."
- **Empty, after SKIP:** Tess says "Tell me what you just did. Try: watered plants."

**The fixture page, top to bottom:**
- Clean the bathroom (21 of 14, under the hairline).
- Water the plants (6 of 7).
- Pay rent (15 of 30).
- Top up the oil (9 of 30).
- Clean the kitchen (TODAY, at the foot).
- Footnote: Laundry · Take out the bins.

### A chore on Now (screen 7)
`upkeep.md` §7 stands, with one change:
- "Grey #8E8798" becomes `inkTertiary` for the name at Hero 56, with the age line in `inkSecondary`.
- Fixture: "Clean the bathroom" with "21 days, usually 14".

## People (screen 7, the People page)
`people.md` §7 stands, with these values:
- **Names at Title 34/500,** 48pt lines with a 16pt gap, most recently talked first.
  - Fixture order: Sam, Mum, Ben, Will, Rose, Mark, Bill.
  - Never mentioned: **Rosemary** and **Ravi**, at 400 weight in `inkTertiary` (allowed at 34pt).
- **The margin birthday** is Body 21 in `inkSecondary`, on the line that holds the name: "Mum, Sun".
- **Arrival:** the names set in one by one as `people.md` says. There are no coloured marks. The **one moment** comes when a name moves to the front after "met Sam": it lifts out, travels to the start of the paragraph (settle spring, 520ms) with a faint `context` wash that dries, and the paragraph reflows behind it.
- **Rosemary, person and herb:** the page shows only the person. A long press on the name shows "PERSON · ALSO A HERB IN RECIPES" as a label line in `inkSecondary`.
- **Empty:** Tess says "Tell me who you talked to. Try: met Sam."

## Accessibility and Reduce Motion
As in `upkeep.md` and `people.md`, plus:
- **A starter** reads "Water the plants, every 7 days, picked" (or "not picked").
- **Keep 5** reads "Keep 5 chores".
- **Reduce Motion:** the pick is a 200ms crossfade from `inkSecondary` to `ink`, with no wash.
