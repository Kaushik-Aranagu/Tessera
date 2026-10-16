# What Tess knows, traced (board item 117)

For: Core (AI-7, AI-8, the forget helper), Builder B (AI-9), AI architecture, Design (49). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Read against these sources:
- Design 49 `docs/design/tess-knows.md` (512ec3e, branch claude/project-thread-b3tu3f);
- architecture section 4 and ship-list AI-7 to AI-9 on master 13a8819;
- the AI thread's #350 (open, head ab8d9df), which adds `group`, `source`, `derivedFrom`, `lastUsedAt` and `private`, the hold for forget everything, and the 40-cap line.

Nothing is built yet, so this is a read of three documents against each other.

**Where they agree:**
- the two doors;
- the count line;
- groups and sources;
- private lines saying "stays on this phone";
- swipe to FORGET with a 10 s UNDO and redaction;
- forget everything as a hold with UNDO;
- the 40-cap line once, with no UNDO;
- nothing on the page is ever sent.

**Below:** 16 gaps, the four that would lose or leak his data first.

## 1. Data that would come back or leak

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| F1 | **A forgotten noticed line comes back on Sunday.** Noticed lines are recomputed at Sunday 04:00 from the ledger, so FORGET on "You train after work on weekdays." lasts until the next recompute, and forget everything refills the page within a week. | arch 4 "Recomputed weekly; replaced"; Design "take any of it away with one gesture" | FORGET on a noticed line writes a suppression for that pattern (its rule id, no text), and the recompute skips it until he says "remember that…" on the same thing. Forget everything suppresses every rule until he unsuppresses from the empty page | Core, AI |
| F2 | **Backups and the op log outside the redaction.** Redaction covers earlier ops, but two places still hold the text: `.tessera` backups written before the forget, and the capture text of the "remember that …" op. A restore of an older backup brings the line back. | arch 4; resign-day.md (backups ride with the data) | The forget helper also redacts the capture op and the ghost-row op. Restoring a backup re-applies the forget log (ids and rule ids, no text) after restore, so forgotten lines stay forgotten | Core |
| F3 | **Private body facts vs the screen.** Arch keeps a told body fact ("my left shoulder gets sore on overhead pressing") as `private`. But "a screen runs on every line before it is written" with the plan validator's health words, so the line Design draws as an example would be refused. | arch 4 "What memory never holds" and "Body facts" | The health and money word screen runs only on lines that can be packed. A told line that trips it is kept, marked `private`, and Tess says "Kept, on this phone only." Measured values (digits next to a health word) are still refused | Core, AI |
| F4 | **Claude's `remember` on a miss auto-keeps.** Design lands it like his own ("Kept…", source "from what you said on Oct 16"). Arch says a ghost row "he keeps or drops". A guess about what he meant shouldn't become memory without his yes. | arch 5 "remember tool writes … a pending ghost row"; AI-8; Design "A new fact arriving" | His own "remember that …" keeps after the 2 s dry, as drawn. Claude's `remember` stays a ghost row until he keeps it (KEEP / NOT NOW, one-ask grammar). It never dries in on its own | Core, Design copy |

## 2. Gaps in what he sees

| # | Gap | Default proposed | Owner |
|---|---|---|---|
| S1 | **Week lines have no place on the page.** Arch folds recent lines into a week line kept 8 weeks, but the page shows only "The last 14 days", so up to 8 lines he can't see or forget exist | A group "Earlier weeks" under The last 14 days, same 16 pt rows ("Week of Oct 5  6 of 6 workouts, cooked twice."), forgettable the same way. Or keep no week lines (AI's call) | AI, Design |
| S2 | **Week one shows "Nothing yet." while day lines exist.** Recent lines aren't counted, and noticed lines first appear on Sunday. On his first days the count is 0, the empty page has no groups, and The last 14 days is hidden although it holds lines | The empty state applies only when all three kinds are empty. With only day lines: "Nothing kept yet." at 196, then The last 14 days | Design, Builder B |
| S3 | **No group for a fact outside Training, Kitchen and People.** "remember that I work 9 to 5", "I'm on the US Pacific coast" | A last group "About you" for told lines with no area. Places stay refused by the screen, so the coast line is refused with "I don't keep places." | AI (`group`), Design |
| S4 | **Second person on the page, third in the store.** Arch stores "Trains after work on weekdays."; Design shows "You train **after work** on weekdays." Nothing says who converts | Store the line in second person and write packs as "lines addressed to him". There is one text and no conversion | AI, Core |
| S5 | **Value words need a field.** Design bolds his own words ("after work") and makes them editable. The store has only `text` | `valueRanges` on told lines, set from his capture's own words at write time | Core |
| S6 | **An edit can trip the screen.** Editing a value word to something with a health or money word has no drawn outcome | Same as F3: the edit is kept as `private`, and Tess says "Kept, on this phone only." For money and places: the old words stay, and Tess says "I don't keep sums of money." | Design copy, Core |
| S7 | **The 41st line when all 40 were used in 90 days.** Nothing is old enough to drop | Not kept. Tess: "I keep 40 things. Forget one and say it again." | Design copy, Core |
| S8 | **Her answer at zero.** "what do you know" with nothing kept isn't drawn | "Nothing yet. Say "remember that…" and I'll keep it." with no WHAT I KNOW word | Design copy |
| S9 | **Siri and Shortcuts.** AI-8 says they never write memory, but nothing says what Siri answers when asked to remember | "Say that in Tessera and I'll keep it." | Core, Design copy |
| S10 | **What "used today" means.** `lastUsedAt` is set when a line goes into a pack. Noticed lines are also read by on-phone rules (living colours, Home's usual-slot line), and private lines are never packed | "used" means any read by a job or rule, on the phone or in a pack, so private lines can say "used today" too | AI |
| S11 | **Group word for recents.** Design labels the group "The last 14 days". #350 lists it as a `group` value, but recent lines are a kind, not an area | Keep it a kind and let the page add the label. Nothing in the store | AI |
| S12 | **Count line wording with private lines.** "4 you told me, 8 I noticed" doesn't say which stay on the phone | Leave it. The per-line source already says so, and a third clause crowds the line | (none, noted) |

## 3. Checked and fine

- Both doors and their back words: ‹ SETTINGS and ‹ TODAY (back-word.md).
- Counts exclude day lines in both Settings and the page.
- UNDO lines name the thing, then what happened ("Left shoulder, forgotten.", "Everything forgotten, 12 things."), per the undo rule.
- One haptic at the swipe threshold (task-reward.md). Reduce Motion paths exist. VoiceOver never needs the hold.
- The page sends nothing.
- Forgetting a day line never touches the day log.
- `derivedFrom` covers lines built on lines, such as week lines from day lines (#350).

## 4. Test rows for Core and Builder B

| # | Do | Expect |
|---|---|---|
| M1 | "remember that I rest on Sundays" | "Kept. You rest on Sundays." with UNDO. Training group, source "you said so just now". Count +1 |
| M2 | FORGET that line, wait 10 s | gone. Capture op text redacted (F2). Count −1 |
| M3 | FORGET "You train after work on weekdays." (noticed), then run Sunday 04:00 | stays gone (F1) |
| M4 | "remember my left shoulder gets sore on overhead pressing" | kept, private, "stays on this phone", Tess "Kept, on this phone only." (F3). Absent from every pack snapshot |
| M5 | "remember I spent $40 at Trader Joe's" | refused: "I don't keep sums of money." Nothing written |
| M6 | Claude's `remember` on a miss | ghost row with KEEP / NOT NOW. Nothing written until KEEP (F4) |
| M7 | Forget everything, UNDO within 10 s | all lines back, in order |
| M8 | Forget everything, wait, restore yesterday's backup | forgotten lines stay forgotten (F2) |
| M9 | Day 2 after install: 1 day line, nothing else | "Nothing kept yet." and The last 14 days with 1 line (S2) |
| M10 | 41st told line, all 40 used recently | not kept, "I keep 40 things. Forget one and say it again." (S7) |
| M11 | Siri: "remember that I like tacos" | "Say that in Tessera and I'll keep it." Nothing written (S9) |
| M12 | "what do you know" at zero | "Nothing yet. Say "remember that…" and I'll keep it." (S8) |
