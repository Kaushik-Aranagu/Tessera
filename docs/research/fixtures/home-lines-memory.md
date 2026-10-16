# Home lines with memory (board item 124, AI-10)

For: Core (AI-10, the `homeLines` pack), the AI thread (AI-3 checks, AI-5 eval), Design (41, 49), Builder B (AI-4 swap-in). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Traced by hand, not run (no Swift toolchain here). Read against:
- `docs/ai/ship-list.md` AI-10: "`homeLines` pack adds the last 7 recent lines and up to 10 noticed training lines; fixtures H5 and H2 pass";
- `docs/ai/architecture.md` section 4 (memory) and section 6 (Home lines read "recent, noticed");
- `docs/ai/home-lines.md` (context 6 words, 32 characters, no stop; detail 14 words, 80 characters, one stop; Claude rewrites only context and detail; over cap is rejected, never cut; digits survive, D2 aside);
- `HomeLines.swift` on master f2f10f9, and `TessMemory.swift` plus `TessMemory+Turnover.swift` on `origin/core/tess-memory` (e098e7e, not on master);
- earlier traces: `home-lines-day.md` (G1-G12), `tess-memory.md`, `tess-knows-trace.md`, `ai5-home-lines-eval.md` with E1-E20.

**What the code does today.** `HomeLines` takes no memory at all, so the rules lines below are the same with or without memory. Memory only reaches Home through Claude's context and detail, once AI-4 and AI-10 land. On the branch, `pack(Reads)` already drops private lines and takes told, then up to 10 noticed (one area), then 7 recent. The branch writes noticed lines in the third person ("Usually trains 6 pm to 8 pm.", "Cooks most on Sundays."); the rows use the second person that architecture section 4 asks for.

## 1. Memory used in the rows

| Id | Kind, group | Text (second person) | Private | In the Home pack under AI-10 |
|---|---|---|---|---|
| N1 | noticed, Training, rule `training.window` | You usually train 6 pm to 8 pm. | no | yes |
| N2 | noticed, Training | You train about 5 days a week. | no | yes |
| N3 | noticed, Kitchen, rule `kitchen.day` | You cook most on Sundays. | no | **no** as written ("training lines"); see H-M2 |
| T1 | told, Training | You rest on Sundays. | no | **no** (Home reads recent and noticed); see H-M1 |
| T2 | told, About you | You work 9 to 5. | no | no |
| T3 | told, Training (body fact) | Your left shoulder gets sore on overhead pressing. | **yes** | never |
| T4 | told, About you (health) | Your energy is low in the mornings. | **yes** | never |
| R1-R7 | recent, last 7 days | "Mon: Pull A done, 2 tasks, cooked chili." and so on | no | yes, the last 7 |

## 2. Rows

Rules = what `HomeLines` draws (hero / context / detail). Claude = what Claude may put in the context or detail, and what must fail. "Uses" = the memory line the words lean on. "Sent" = whether that line may be in the pack.

| # | Moment (Pacific) | Facts | Memory present | Rules: hero / ctx / detail | Claude may say | Uses | Sent |
|---|---|---|---|---|---|---|---|
| M-H1 | Tue Oct 20, 5:10 pm | Push A planned | N1, N2, R1-R7 | Push A / this evening / (none) | "this evening, your usual slot" (5 words, 29 chars) | N1; marks it used today | yes |
| M-H2 | Tue 7:30 am | Push A planned | N1 | Push A / today / (none) | "today" only. **Fail:** "today, at 6 pm as usual" (6 is in N1, not in the item's `numbers`, C6) | none | N1 yes, but its digits license nothing |
| M-H3 | Tue 7:40 am | Push A done at 7:35 am, 18 sets, no best | N1 | Push A done / done at 7:35 am / 6 exercises, 18 sets. | "done at 7:35 am". **False, passes checks:** "done at 7:35, your usual slot" (he trained in the morning; N1 says evenings). Also no "early today", it reads as a judgment against N1 | none | yes, but needs the fit flag (H-M3) |
| M-H4 | Tue 8:06 pm | Push A done 8:05 pm, records [Bench] | N1 | Push A done / done at 8:05 pm / 6 exercises, 18 sets, 1 new best. | "done at 8:05, a bench best" or "a bench best" (D2). **Fail:** "done at 8:05, a bench record" (word is "best", H-M8) | none needed | yes |
| M-H5 | Sun Oct 25, 10:15 am | rest day, tacos planned tonight | N3, T1 | Rest day / Sunday / (none) | "Sunday, a cook day" (E7 shape). Not "Sunday, as you said": T1 is not in the Home pack | N3 | only if H-M2 lands |
| M-H6 | Wed 10:15 am | rest day, no cook planned | N3 | Rest day / Wednesday / (none) | "Wednesday". **False, passes checks:** "Wednesday, a cook day" (N3 is about Sundays) | none | N3 yes (if H-M2), must not apply |
| M-H7 | Thu 5:30 pm | Push A planned (overhead press in it) | T3 (private), N1 | Push A / this evening / (none) | "this evening, your usual slot". **Never:** "this evening, easy on the shoulder" or any word from T3. T3 is not in the pack; "shoulder" passes C12 today (H-M7) | N1 | T3 **never**; N1 yes |
| M-H8 | Thu 7:30 am | Pull A planned | T4 (private), T2, N1, N2 | Pull A / today / (none) | "today". **Fail:** "today, low energy morning" (C12 energy). Pack snapshot holds N1, N2, R1-R7 and no T2, T3, T4 | none | T4 never, T2 no |
| M-H9 | Tue 5:10 pm, then FORGET N1 at 5:30 pm | Push A planned | N1 until 5:30 pm | Push A / this evening / (none) | 5:10 pm "this evening, your usual slot"; **after the forget, the same minute:** "this evening" (rules). Cached Claude line and its JSON entry dropped, no call needed (H-M4) | N1, then none | N1 gone from the next pack |
| M-H10 | FORGET N1 Sat; Sunday 04:00 recompute; Mon 5:10 pm | Pull A planned | N2 (N1 suppressed) | Pull A / this evening / (none) | "this evening". "your usual slot" must not come back. **Branch today:** no rule id or suppression, so Sunday rewrites N1 and the line returns (H-M5) | none | N1 never again until he says "remember that" |
| M-H11 | Tue 4:30 pm | Push A planned | T2 | Push A / today / (none) | "today". **Fail:** "today, after 5" (5 is his word in T2, not a fact, C6). T2 is About you and not in the Home pack anyway | none | no |
| M-H12 | Mon 5:10 pm, no workout since Wed | Pull A planned (`sinceLastDays` nil on planned facts) | R1-R7, N2 | Pull A / this evening / (none) | "this evening" or "this evening, your usual slot" (if N1). **Fail:** "this evening, back at it again" (C10 again); "this evening, first in 5 days" (5 is counted from recent lines, not licensed, C6) | N1 if present | R lines yes; counts from them license nothing |
| M-H13 | Sun 4:10 pm | tacos planned, toBuy 2 | N3 | Tacos today / 2 to buy / (none) | "tonight, 2 to buy". **Fails C9 today:** "your Sunday cook, 2 to buy" (Sunday is not the first word and not in `names`, H-M9) | N3 | if H-M2 |
| M-H14 | Tue 5:10 pm | Push A planned | N1 | Push A / this evening / (none) | **Fail:** "this evening, as usual…" (C5), "You usually train 6 pm to 8 pm" (7 words, digits not licensed). Memory text is never echoed whole | none | N1 yes |
| M-H15 | Tue 8:06 pm | Push A done 8:05 pm, records [Bench] | N1 | as M-H4 | Detail stays counts: "6 exercises, 18 sets and 1 new bench best." **Passes checks today, should fail:** "6 exercises, 18 sets, 1 new best, in your usual slot." (H-M10) | none in detail | yes |
| M-H16 | Tue 6:30 pm | Push A running, bench set 3 (`fixed`) | N1 | Push A, bench set 3 / now / 1 exercise, 2 sets. | nothing: fixed items are never sent, so no memory is read and N1 is not marked used by Home | none | item not sent |

**Holds in every row:** the hero never changes; the rules line shows first and stays when the switch is off, offline, capped or a check fails; no "!", "…", " · " or emoji; no grading words (missed, behind, late, again, only, still, streak, should, finally); "best", never "record", in Claude's words; no digit that is not in the item's `numbers`; no private line in any pack; no body or health word on Home.

## 3. Gaps

| # | Where they disagree or are silent | Rows | Proposed default | Owner |
|---|---|---|---|---|
| H-M1 | **Told lines on Home.** AI-10 and arch section 6 say Home reads recent and noticed only. `home-lines.md` says "memory lines" in general, and eval E15 and E17 put told lines in the Home memory. "You rest on Sundays." is the most useful Home line he can give her | M-H5 | Home also reads non-private told lines in Training and Kitchen (not People, not About you), after noticed in the trim order | AI thread |
| H-M2 | **Kitchen noticed lines.** AI-10 says "noticed training lines"; `home-lines.md` table ("Sunday, a cook day"), E7 and E18 need Kitchen. `Reads.area` on the branch takes one area | M-H5, M-H6, M-H13 | Home reads noticed Training and Kitchen; `Reads` takes a set of areas; still 10 lines at most | AI thread, Core |
| H-M3 | **Today contradicts a noticed line.** No check can tell that 7:35 am is outside "6 pm to 8 pm" or that Wednesday is not Sunday. E17 already shows the trap for a told line | M-H3, M-H6 | The phone adds per item `fits: [ruleId]` (start or plan time inside the window, today is the noticed day). "usual", "as always", "a cook day" are allowed only when the item lists a fit; else the check fails | Core, AI thread |
| H-M4 | **Forget, same day.** Claude lines are cached by pack hash (in memory and a JSON file) and calls are debounced 10 min, 40 a day. Nothing ties a cached line to the memory it used, so a forgotten line can stay on Home until the next call, or all day offline | M-H9 | FORGET drops every cached line whose pack held that memory id; Home shows the rules line at once; the JSON file is rewritten. Store memory ids with each cache entry | Core |
| H-M5 | **Suppression is not on the branch.** No rule ids; recompute on any day when noticed lines are empty; a second Sunday turnover makes new ids (`tess-memory.md` M3, T6, T9) | M-H10 | As `tess-memory.md`: rule id per pattern, suppression list, recompute only Sunday and only once | Core |
| H-M6 | **Person.** The branch stores "Usually trains 6 pm to 8 pm." and "Cooks most on Sundays."; E5, E7, E9, E15, E17, E18 use third-person memory; arch says second person, one text | all | Store second person ("You usually train 6 pm to 8 pm."); rewrite the eval's memory strings when AI-10 lands | Core, Research |
| H-M7 | **Body parts slip past C12.** C12 bans sore, pain, body, energy; not shoulder, knee, back, elbow. A guessed body line passes | M-H7 | Add a whole-word body-part list to C12 (Core's `bodyWords`, matched as words, so "back" in "back at it" needs its own call: ban "back" only next to a body noun, or not at all) | AI thread (AI-3) |
| H-M8 | **"record" vs "best".** `HomeLines` row text says "Bench record." / "2 records."; SO FAR and `home-lines.md` say "best"; no check bans "record" in Claude lines | M-H4 | New check C15: "record" and "records" fail in a Claude line; row text moves to "best" (item 116 G3) | Core, Design copy |
| H-M9 | **Weekday names.** C9 lets a capitalized word through only as the first word or from `names`. "your Sunday cook" fails; "Sunday, a cook day" passes | M-H13 | Today's weekday (his 4 AM day) joins the item's `names`; other weekdays still fail | AI thread, Core |
| H-M10 | **Memory in the detail slot.** `home-lines.md` section 2 only covers the context line; the detail checks pass "…, in your usual slot." | M-H15 | Detail stays counts only. Memory words ("usual", "as you said", "your") fail in detail | AI thread, Design |
| H-M11 | **A rules "usual slot" line.** Arch section 4 names "Home's usual-slot line" as an on-phone reader of memory; `home-lines.md` puts "your usual slot" only in Claude's column; `HomeLines` reads no memory | M-H1 | AI-10 keeps rules lines memory-free. A rules usual-slot line is a later Design call; if built, it uses the same `fits` flag | Design, Core |
| H-M12 | **What "used today" means for Home.** Every Home call packs up to 17 lines, so all would read "used today" on the page every day | M-H1, M-H16 | Mark a line used only when it is packed for an item it fits (H-M3) or when a shown line leans on it; recent lines are never marked | AI thread, Design 49 |
| H-M13 | **Gaps counted from recent lines.** Planned workout facts have no `sinceLastDays` (only `fact(done:)` sets it), so "first in 5 days" on a planned item is unlicensed, and recent lines tempt Claude to count | M-H12 | Keep: counts come from facts only. Add `sinceLastDays` to planned workout facts later if Design wants "first in 5 days" before he trains | Core |
| H-M14 | **Memory digits never licensed.** N1's 6 and 8 and T2's 9 and 5 reach the pack but not `numbers`. Not written down anywhere | M-H2, M-H11 | Say it in `home-lines.md` section 2: digits in memory lines license nothing on Home | AI thread |
| H-M15 | **Reverting after a forget.** Design's ruling covers a Claude line arriving (wet `tess`, dries over 2 s). A line falling back to rules is not drawn | M-H9 | Plain crossfade back to the rules line, no `tess` colour, no haptic; Reduce Motion is the same crossfade | Design, Builder B |

## 4. Eval rows for `home-lines-eval.json` (proposed, not added)

E21 is already proposed by item 116 for the done cook, so these start at E22. Memory strings are second person (H-M6). "Proposed check" rows fail only once that gap's default lands.

| Id | Maps | Now | Memory | Item (hero / rules ctx) | Slot | Probe | Expect | Why or human note |
|---|---|---|---|---|---|---|---|---|
| E22 | M-H1 | Tue 5:10 pm | N1 | Push A / this evening | context | this evening, your usual slot | pass | |
| E23 | M-H2 | Tue 7:30 am | N1 | Push A / today | context | today, at 6 pm as usual | fail | C6: 6 not licensed |
| E24 | M-H3 | Tue 7:40 am | N1 | Push A done / done at 7:35 am | context | done at 7:35, your usual slot | pass (fail with H-M3) | human: false, he trained in the morning |
| E25 | M-H5 | Sun 10:15 am | N3 | Rest day / Sunday | context | Sunday, a cook day | pass | |
| E26 | M-H6 | Wed 10:15 am | N3 | Rest day / Wednesday | context | Wednesday, a cook day | pass (fail with H-M3) | human: false, N3 is Sundays |
| E27 | M-H7 | Thu 5:30 pm | (none: T3 private, not packed) | Push A / this evening | context | this evening, easy on the shoulder | pass (fail with H-M7) | human: false, and a body line on Home |
| E28 | M-H4 | Tue 8:06 pm | N1 | Push A done / done at 8:05 pm | context | done at 8:05, a bench record | pass (fail with H-M8) | "best", never "record" |
| E29 | M-H12 | Mon 5:10 pm | R1-R7 | Pull A / this evening | context | this evening, back at it again | fail | C10 again |
| E30 | M-H12 | Mon 5:10 pm | R1-R7 | Pull A / this evening | context | this evening, first in 5 days | fail | C6: 5 counted from recent lines |
| E31 | M-H13 | Sun 4:10 pm | N3 | Tacos today / 2 to buy | context | your Sunday cook, 2 to buy | fail (pass with H-M9) | C9 Sunday |
| E32 | M-H14 | Tue 5:10 pm | N1 | Push A / this evening | context | this evening, as usual… | fail | C5 "…" |
| E33 | M-H15 | Tue 8:06 pm | N1 | Push A done / done at 8:05 pm | detail | 6 exercises, 18 sets, 1 new best, in your usual slot. | pass (fail with H-M10) | memory in detail |
| E34 | M-H9 | Tue 5:31 pm | (none: N1 forgotten) | Push A / this evening | context | this evening, your usual slot | pass | human: false, nothing in the pack says usual |

Two checks belong in the AI-4 pack snapshot test, not in probes: no private line (T3, T4) and no About you or People told line is ever in the Home pack (M-H7, M-H8); after a forget, the pack and the cache file hold no trace of the line (M-H9).
