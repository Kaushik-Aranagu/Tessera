# Home, first review: one line per thing, and the glass tabs (Design items 41 and 42)

**Kaushik's principle, in one line:** Home should say one plain line per thing and never cut text, the day bar should earn its space or go, and the tabs should feel like glass he can hold and slide through, with the pages moving under his finger.

This sheet answers his first review of the build (16 Oct, 11:58 PM PT): the "Thursday night" bar takes space with no meaning; the workout detail ("1 exercise, 2 sets, 1 record") is too much and ends in three dots; the Start underline should change state; the top tabs are basic and need a glass feel and hold-and-swipe. The AI architecture thread is writing the Tess line grammar for Home in parallel; the hero and context lines here are placeholders in that grammar's shape (a thing, a state, a time), and the words follow its sheet.
- Board: `mockups/home-first-review.png` (source `studies/home-first-review.html`), Obsidian with one Porcelain phone. Before (the build), after paused, after done, one tap down, the tabs held, and a fresh day.
- Recording: `recordings/tab-lens.mp4` (11s). A plain swipe with the ink line stretching, then hold the tabs: the lens forms, the pages shrink and the neighbours show live; slide through REVIEW and KITCHEN with a tick per word; let go on TRAINING and the lens melts into the ink line.

## 41. One line per thing

### The rules
1. **A thing gets one line.** The hero is the thing and its state ("Push A, paused at bench", "Push A done", "Push A"). The context line above it is the time ("paused 21 min ago", "this evening", "today"). Nothing else about the thing sits on Home. The counts (exercises, sets, bests) live one tap down.
2. **Never cut text.** No line on Home ends in "…". Each line has up to three forms, and the first that fits its width is drawn:
   - The hero: Hero 56 on one line; else Title 44 on one line; else Title 44 on two lines (50pt leading, so a two-line hero is 100pt tall and everything below it moves down 50).
   - A row title: Body 21 on one line; else Body 21 wrapped to two lines (the row grows from 46 to 74). The time stays on the first line.
   - A context line: Body 21; if it doesn't fit, the words shorten ("paused 21 min ago" → "paused 21 min"), never the type.
   - Nothing on Home truncates, ever. If a title can't fit two lines of Body 21 at 346pt, it's the title that's wrong, and Tess's capture already keeps titles short.
3. **No dots, no separators.** A row is the title and its time, nothing between them. "Read · Designing Data-Intensive Applications" becomes "Read Designing Data-Intensive Applications" on two lines.
4. **The day bar goes.** "Thursday night" stays as the day label (Body 21 at 138), because it's one plain line that says where he is in the day. The painted stroke under it goes from Home: it has no value on it that a line doesn't say better. Everything below moves up 60pt: context at 186, hero at 220, the Start key at 296, Next at 388, rows at 440 + 46k (a wrapped row adds 28).
   - **The done fleck** (`task-reward.md`, done beat 0) now arcs to the **day label** and blooms there (the same 30pt wash, 900ms), since there's no stroke tip to land on. Everything else in that sheet stands. The day stroke itself lives on in the Day log and the day strip sheets, one tap down.
   - "Thursday night" is the only day word on Home. No date, no weather, no step count.
5. **The Start key's ink line is the workout's progress.** The key is a label word (`START PUSH A`, `RESUME PUSH A`) with the ink-line lens under it, as every ink action. The lens changes state:
   - Before the workout: full ink.
   - Paused: a 22% ink track the full width, filled to the share of sets done (2 of 9 sets = 22%). It's the one place on Home that says how far along he is, without a number.
   - Done: the key goes, and the hero says "Push A done".
   - Running (he's in the workout and comes back to Home): the fill is live, in `liveInk`, drying to ink when he pauses.
6. **One tap down is the detail.** Tapping the hero opens the workout's page: ‹ TODAY at 58, Title 44, the context line, then SO FAR ("1 exercise, 2 sets, 1 new best." as one sentence), the exercise with its sets, STILL TO GO, and the same Start key. The counts that were on Home are here, as one line of prose, not a ledger.
7. **Next is titles and times only.** No "Push Day A · Bench Press, set 2" second line, no "Resume" word at the right. The running or paused thing is the hero; it doesn't repeat in Next.

### What changes in the build
- Home: drop the painted stroke and its dashed guide; drop the ledger row under the hero and its detail line; move the frame up 60pt. The hero is `Theme` hero 56 with the step-down forms. Row titles wrap.
- The Start key: `startKey` with a `progress` (0 to 1, nil for full) and a `wet` flag for running.
- The workout page gains SO FAR and STILL TO GO as in the board (it already has the sets).
- `task-reward.md`: the fleck's target is the day label.

## 42. The glass tabs

### The rules
1. **A tap works as today.** Tap a word and the page swaps on the house curve (380ms); the ink line slides to the new word.
2. **A swipe on the page moves the pages 1:1.** As the page moves, the ink line stretches from the current word toward the next and snaps there on the settle spring when he lets go (420ms). The words don't move.
3. **Hold the tab row (260ms) and the glass lens forms.** A Liquid Glass pill (40pt tall, the word plus 10pt each side, radius 22) rises out of the row under his finger over 320ms on the settle spring, with `.selection`. The ink line fades while the lens is up. The word under the lens scales to 1.12. This is the one place on the page that uses Liquid Glass: the navigation layer.
4. **The pages shrink to 78%** (360ms, house curve) and sit side by side with 14pt between them, on a near-black ground (`#0A0A0C` in Obsidian, the look's ground darkened 4% in the others). The neighbours are live, at 55%: the real pages, with their own content. He sees Review's week and Kitchen's list without leaving Today.
5. **Slide along the row and the lens follows the finger.** The pages slide with it, 1:1 in tab units. When the lens crosses a word, that word swells to 1.12 and the one it left settles back (200ms), the lens re-sizes to the new word, the page under it brightens to 100%, and `.selection` ticks once. One tick per word, never per pixel.
6. **Let go and the page under the lens opens.** The pages grow back to full (480ms, house curve), the lens melts down into the ink line under the word (280ms), and the word settles to 1. A hold with no slide is a cancel: the same return, no page change, no haptic.
7. **Reduce Motion:** the pages crossfade instead of sliding and shrinking; the lens still forms and the ticks still play.

### What changes in the build
- The tab row gains a long-press gesture that drives a `TabLens` state: `held`, `position` (a Double in tab units), `lensWidth`.
- The page host renders the four pages in a horizontal strip, scaled by `held ? 0.78 : 1`, offset by `position`.
- The lens is a `.glassEffect` capsule on the navigation layer only, never on the pages.

## Owners
- **Builder B:** Home's lines and frame, the Start key's progress, Next rows (41).
- **Builder A:** the tab lens (42), since the looks and the tab strip are his.
- **AI architecture thread:** the words in the hero and context lines.
