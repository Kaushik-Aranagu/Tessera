# 89. Builder briefs for sheets 81 to 88

One brief per adopted sheet, for Core, Builder A and Builder B. Nothing here is new design; where a sheet and this page differ, the sheet wins. Anything that touches type sizes is marked "waits for type pick": build it against the current tokens and keep every size in one token block so it can swap.

To read a sheet: `git show HEAD:docs/design/<file>` (branch claude/project-thread-b3tu3f).

## Rules every lead holds
- Receipts name the thing first, then what happened ("Rice, removed.", "Private item, on Groceries."). Digits for counts. "best", never "record". Lists name two, three, then "and N more" from four.
- No "..." anywhere. Times read "7 pm", never "at 7 pm". " · " only inside a pack size.
- UNDO is one app-wide slot: 4 s for a new add, 10 s for a change; 10 s under VoiceOver.
- Walls: a private note is only ever "Private note" (also "Private recipe", "Private item"), never its words, in any row, context line, side, Tess line, VoiceOver or Spotlight. A money or body question answers "That stays on this phone."
- Cobalt is Tess's voice only. No dots, no streaks, no red, no guilt in an empty state. Reduce Motion: 150 ms crossfade through MotionPolicy.
- Every screen declares its side swipe: left edge out, right edge in (glance, then full side), middle along a run or in; up and down only read; pull down at the top opens the area index. `.selection` once on the full side, none at the glance. Core owns SideHost.

## 81. Notes front (Builder B; Core for the counts)
**Build, in order**
1. Empty page: context "A place for loose thoughts", the writing line, "Nothing written yet." at 66% ink. Tess: `Say "note: bar felt heavy" and I'll keep it here.`
2. Private note row: reads "Private note" at 100% ink plus its time ("Tue"); no words anywhere.
3. Long list: one sheet, back word pinned, rows fade into Tess's band from 736, a long line wraps to two, never cut. Tess: "Landlord and Bench press come up most."
4. Side word BY THING at the right of the context line; wire it to SideHost.
5. Core: by-thing counts through the walls (thing names only; a Private note adds only to the private count).
**Side swipe:** BY THING (LINKS). No run, so the middle goes in too. Glance: "23" notes, "Landlord 4", "5 private", foot ALL OF THEM. Full side: MENTIONED, NOT ABOUT A THING ("Notes on their own", 9), KEPT PRIVATE ("Private note", 5, nothing tappable).
**Copy:** empty side "Nothing to group yet." (opens straight to the full side); Tess "Landlord comes up most, 4 times."; VoiceOver action "Show by thing"; "Note kept."
**Walls:** a Private note never counts under a thing; the glance "5 private" equals the side's private line.
**Waits for type pick:** Accessibility 3 sizing (Title scale, time dropping under its row).
**Acceptance:** sheet rows 1 to 7. **Open:** Face ID on a Private note (drawn as plain tap).
**Read:** `notes-81.md`, `notes-grammar.md`, `every-side.md` row 22.

## 82. Day log: empty and first day (Builder B)
**Build, in order**
1. Empty: back word, "October" title, THE DAY word, TODAY, and "Your days write themselves here." No past labels, no count, no Tess line.
2. First entry: the quiet line fades 220 ms, the entry rises 10 pt in 360 ms ("18:40 Done: call the bank"); a Tess-written entry gets her 2.8 s wash. No "first", no "Day 1". The quiet line never returns once any record exists.
3. Side THE DAY: glance, then full side grouped TRAINED, COOKED, TASKS; empty groups are absent.
4. Tess speaks on the side only, from 2 entries: "3 of 4 came after 6 pm." (proposal; Research owns the rule).
**Side swipe:** THE DAY (FACTS) by word, and by the right edge (32 pt above 736) if Product rules it. The middle never opens it. Glance: "4 things", two named ("Push Day A", "Dal tadka"), "and 2 more", foot ALL OF TODAY. One entry "1 thing". Empty "Nothing yet." only, no foot word.
**Copy:** VoiceOver "Show the day"; full side title "Thursday", context "4 things".
**Walls:** no money or weight on the side; a private note counts as "Private note".
**Waits for type pick:** AX3 title 56 and times above text, the glance's 56 big fact.
**Acceptance:** sheet rows 1 to 7; glance count equals the lines of the day in view.
**Open:** right edge as well as the word; the faint workout on the side.
**Read:** `daylog-82.md`, `day-log-v1.md`, `day-log-page.md`, `empty-states.md`.

## 83. Review: the first week (Builder B)
**Build, in order**
1. First week: hero "1 session in your first week"; no ring on any day; no mark before first use; bands only for what exists (TRAINING 1 SO FAR, TASKS DONE 3, THE WEEK'S LINES "Thu  Push Day A, the first time.").
2. Zero-day: hero "Your first week starts today", day letters with today in ink, "Nothing to count yet."; then "A quiet week so far".
3. The run's ends: a swipe toward the past in the earliest week, or toward the future in the current one, moves the body up to 26 pt and springs back in 380 ms. No haptic, no text, no wrap.
4. THE DAYS lists from the first-use day; "N to go" only on the current week; the denominator stays 7.
5. Tess silent on all three fronts and on the first week's side.
**Side swipe:** THE DAYS (by word or right edge); the middle runs along weeks. Glance full week "5 of 7 days", "Wednesday, 6 tasks", "2 to go", foot ALL DAYS. First week "1 day", "Thursday, 3 tasks". Zero-day "Nothing yet." only. Full week Tess: "Wednesday was the fullest day."
**Copy:** "1 day" in week one, "N of 7 days" from week two (ruled). VoiceOver "Show the days".
**Walls:** no money of his on Review's bands in a first week; no miss ring, no ghost of last week.
**Waits for type pick:** AX3 seven columns to rows (hero 56/62, text 32/38).
**Acceptance:** sheet rows 1 to 6. **Open:** the no-ring-in-week-one rule is Design's proposal.
**Read:** `review-first-83.md`, `review-week.md`, `rest-dab.md`, `depth.md`.

## 84. One error and offline sheet (Core owns the slot; A and B wire their areas)
**Build, in order**
1. Core: one notice in the UNDO slot at Tess's band, ink, Body 19, beside the soul, replacing her line for its window; a new notice replaces the old one, never a stack.
2. Core: one `.warning` per failed finger or voice action; none for kept receipts, background work or a repeat failure.
3. Core: tap the line to retry (dim to 60%, 0.5 pt ink line over 150 ms); success crossfades into the area's own receipt.
4. A and B: each failing write (finish, grocery check, set log, pantry word, routine edit, note, habit tick) shows the line with no reward animation, haptic or success line.
5. Core: store a failed widget or Live Activity write so the band can say it on next open.
**Side swipe:** none; the slot is a line, not a page. Tess's key and off lines are buttons that open CLAUDE in Settings with the origin's back word.
**Copy:** "Didn't save. Try again." (10 s); "Set 4 didn't save. Try again." (live workout only); "Private note didn't save. Try again."; "Kept it for later." (4 s, not tappable); "Recipe link, kept for later."; "Claude is busy. Kept it for later."; "Claude didn't answer in time. Kept it for later."; "Needs a connection."; cobalt Tess lines "No Claude key yet.", "Claude is off.".
**Walls:** no raw error, key, URL, model name, money or body figure, secret task title or private words on any notice. Offline is never a banner or icon.
**Waits for type pick:** Body 19 notice size and the AX3 three-line growth from 820.
**Acceptance:** sheet rows 1 to 8, including the strings test and an injected throw per area. **Open:** the two Claude lines as words for Product.
**Read:** `errors-84.md`, `list-remove.md`, `claude-settings.md`, `one-ask.md`.

## 85. Habits: the front and its side (Builder B; Builder A for the haptic pattern)
**Build, in order**
1. Empty: "No habits yet." at 66%. Tess: `Say "new habit read 5 a week" and I'll keep it.`
2. A habit line: name, count "3 of 5", seven strokes. At zero the count is "5 a week"; "0 of" never appears.
3. Check-in: swipe the line right past 140 pt, or tap a stroke. The stroke lands wet and dries in 2 s, a fleck arcs to the soul, the count rolls, one done-pattern haptic at release. Tess "Read, 3 of 5 this week." with UNDO 4 s. A repeat does nothing and Tess says "Read is already in for today."
4. Tapping a done stroke clears it (10 s UNDO). Long list: pinned back word, fade into the band, Tess "Read and Stretch are done for the week."
5. Side (below).
**Side swipe:** two pages, LATELY and HOW IT COUNTS, facet words at 196. Right edge in, middle between pages, left edge out; rows keep only the right swipe. Glance "3" habits, "Read today", "Train Tuesday", foot ALL OF IT. Empty opens straight to "Nothing to look back on yet." LATELY: "Last marked", "Last week, 4 days". HOW IT COUNTS: "5 a week, by hand", "A week runs Monday to Sunday.", "A day starts 4 am." (no "at" before a time; sheet 85 draws it with one, Design to confirm)
**Walls:** no streak, "missed", red, percentage, chart or sentence about a gap, including on the side.
**Waits for type pick:** Title 34 for the heard words and the AX3 count drop.
**Acceptance:** sheet rows 1 to 6. **Open:** none; both side questions ruled yes.
**Read:** `habits-85.md`, `habits-grammar.md`, `task-reward.md`, `no-dots.md`.

## 87. Lists and Recipes fronts (Builder B; Core for the Lists side grammar)
**Build, in order**
1. Recipes empty: context "None yet", "No recipes yet.", Tess `Paste a link or a page and I'll read it.`
2. Lists empty: context "Just Groceries", Groceries "NOTHING TO GET", "No other lists yet." Tess `Say "new list: packing" and I'll start it.`
3. One and long states: Recipes "1 recipe", row "Tacos, Tue"; 38 recipes scroll as one sheet, names over 30 characters wrap; Tess "Chili is the one you cook most."
4. Private recipe row: "Private recipe" at 100% ink plus its day; context "38 recipes, 2 private".
5. Remove an item: swipe left, REMOVE in `live` at 60 pt, commits past 96, count rolls, "Rice, removed." with 10 s UNDO; UNDO says "Rice, back on Groceries." A private item reads "Private item"; "Private item, removed.".
**Side swipe:** Recipes ITS OBJECTS (LINKS): glance "38" recipes, "Newest, Dal", "Most used, Chili", foot ALL LINKS; full side NEWEST (3 named, "and 35 more"), MOST USED, EVERY RECIPE HAS, KEPT PRIVATE ("Private recipe", 2). Lists ON THEM (PARTS, proposed): "9" lists, "Packing 9 left", foot ALL OF THEM. Empty sides: "Nothing to show yet.", "Nothing else to show yet." Rows have no swipe of their own on the shelf.
**Walls:** a private recipe or item name appears nowhere else and never reaches Claude.
**Waits for type pick:** the shelf tiers (56, 34, 21) and Title 58 at AX3; keep them in one token block.
**Acceptance:** sheet rows 1 to 5. **Open:** the Lists side kind and word are proposals.
**Read:** `lists-recipes-87.md`, `kitchen/lists-9-12.md`, `sweep-19.md`, `list-remove.md`.

## 88. Imagery (Builder B: plate; Builder A: muscle figure; Core: fields)
**Build, in order**
1. Core: `Recipe.photo` as a file on the object, `Ingredient.colour` and the colour table; Private objects skip the plate. The fetched image stays out of backups.
2. Builder B: `ObjectPlate`, 393 x 56 at the top edge, full bleed, opaque to 34 and melting by 56. The wash is there at first paint; a photo dries in over it in 380 ms.
3. Builder B: the og-image read once at Save (one GET, 2 MB cap, cropped to 786 x 112). Missing or failed is silence. Kitchen medium widget gets a 10 pt wash only.
4. Builder A: `MuscleFigure`, front and back, worked regions at 72%, half sets at 36%; a row tap takes its region wet and dries in 1.2 s with one `.selection`. The Routine title carries the mini map, dropped if the title wraps past x 280.
5. Fallback chain: first 3 ingredient lines, staples skipped, pale foods shaded 12% toward ink, ending at Kitchen green `#12936A`.
**Side swipe:** MUSCLES is a page of the exercise side (sheet 76), reached by the middle swipe or its facet word; Tess is silent there. No other side is added by this sheet.
**Copy:** "Nothing known yet." (no figure when the table has nothing); VoiceOver "Photo of Sheet-pan paprika chicken, from budgetbytes.com"; "Works chest, shoulders and triceps".
**Walls:** a Private recipe or note gets no photo and no pigment; no photo goes to Claude, a widget or a prompt; a progress photo is drawn nowhere. His own camera photo on the plate is not built in v1.
**Waits for type pick:** the MUSCLES context at 138 and AX3 row sizes.
**Acceptance:** wash at first paint, no spinner or grey box; private objects stay plain ground; the figure is one VoiceOver element.
**Open:** none. **Read:** `imagery-88.md`, `living-colours.md`, `title-accent.md`, `kitchen/link-fetch-us.md`.
