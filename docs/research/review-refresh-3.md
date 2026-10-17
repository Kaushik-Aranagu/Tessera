# Review refresh 3: the Catalog v9 pin, 10 minutes on the phone

*Research lab, Oct 16, 2026 (Pacific). For Product to fold into `product/review-session.md` as the "Next build"
section once the pin SHA is named. Covers what the v9 pin carries beyond the installed 7b321d2. Read at origin/master
da49fc4. Nothing was run on a phone; every line is read from master's code, QA's reviews or the v9 script
(`next-build-script-v9.md`). Every value is made up.*

**Tags.** [merged #N] is on master now. [blocker, open #N] holds the pin, so it will be in. [rider, if in] is in only
if it merges before the last blocker; Product drops the item if `git merge-base --is-ancestor` says no.

**Before he starts.** Install-day Step 0 (Review > Backups, SAVE A COPY) is done before the install, not here. Ask two
yes/no questions only: is a Claude key on the phone, and is "Tess asks Claude" on? If both are yes, note the receipts
count in Settings > Claude. Never ask him to type, show or paste the key.

## The items, in the order a normal day meets them

| # | Try | Expect | He answers | Depends on |
|---|---|---|---|---|
| 1 | Open the app for the first time on the new build. | One line by the soul: "Sunday, rest day." with UNDO. Leave it. | yes / no | rider, if in (Core's rest-day reader, no PR yet) |
| 2 | Morning, on a training day, before starting: look at Home. | The hero names the routine ("Push A") with **today** above it. No line ends in "…" and no " · ". | yes / no | blocker, open #366 (AI-1 Home lines) |
| 3 | Tap Tess, Write: `pay rent fri` | A task "Pay rent" on Friday, with UNDO. Not "Didn't catch that." Tap UNDO. | yes / no | rider, if in (money-verb fix, no PR yet; on master today this is still a miss) |
| 4 | Write: `wifi password is tacocat`, then `what's my wifi password?` | "Private note, kept." with UNDO, then "It's in your private notes." | yes / no | merged #422 |
| 5 | Write: `$212.37 at Costco`, then `slept 5 hours` | Neither line mentions Claude. The money one is "Didn't catch that." on this pin (the LOG / NOT NOW ask comes later). If the receipts count was noted, it hasn't moved. | yes / no | merged #451 (MU2) |
| 6 | Airplane Mode on. Write: `$38.20 trader joe's`, then `door code 4417`. Airplane Mode off, reopen the app. | Never "No connection. Saved it for Claude." The code one is "Private note, kept." Receipts count unchanged after reopening. | yes / no | merged #451 (A2, CA7) |
| 7 | Settings > Claude, the month line. | "This month $… of $50." (the amount opens the receipts). Without a key, tell us what shows instead. | yes / no | merged #422 ($50 cap) |
| 8 | Settings, the Rest day row. | "Rest day: Sunday." | yes / no | rider, if in (rest-day reader plus Builder B's row) |
| 9 | Kitchen > Recipes, paste a recipe whose last line is `wifi: TacoNet / tacocat24`, and save. | The wifi line draws dimmed as an ignored line, and the saved recipe holds no tacocat. No "I left out 1 line" line yet. | yes / no | rider, if in (#454, QA PASS, open) |
| 10 | "Hey Siri, add a task in Tessera", then say `door code 4417`. | Siri says "Private note, kept." and no task appears. | yes / no | merged #457 |
| 11 | iPhone Settings > Tessera > Microphone off. Hold Tess's soul. Then hold the tab row. | "Mic is off for Tessera." beside the soul, then Tess at rest. The glass pill rises on the tab row. Mic back on after. | yes / no | merged #446 (stuck listening) |
| 12 | Evening: start the workout, log 2 sets, tap PAUSE. | Home reads "Push A, paused at bench" with **paused just now** above. | yes / no | blocker, open #366 |
| 13 | Finish it. | "Push A done" with **done at** the time above, for example "done at 7 pm". One tap down: "*n* exercises, *n* sets." | yes / no | blocker, open #366 |
| 14 | One pick: Home's lines overall. | Plain line per thing reads right / too terse / too wordy. | pick | blocker, open #366 |

About 10 minutes: items 1 to 11 take a minute or less each, 12 and 13 ride a workout he does anyway.

## On the trip, not in the 10 minutes

| # | Try | Expect | He answers | Depends on |
|---|---|---|---|---|
| T1 | In New York (Oct 27 or 28), after a workout, look at Home that evening. | "Pull A done" for that day; no second session offered. | yes / no | merged #377 (0bff60b) |
| T2 | Back home, open that exercise's history. | The New York set reads by its own day ("Yesterday" the next day). | yes / no | merged #391 (70112f9) |

Known gap, not a fail: the Review page in New York can count a task done late Monday on Tuesday (R12, `trip-check.md`).

## Drop or change in the current guide

- The 7b321d2 section's step 2 ("type your key yourself in Add a Claude key"): change to the yes/no question above.
- "Not yet in this build: one plain line per thing on Home": moves into items 2, 12 to 14 once #366 is in the pin.
- Item 4 of the 7b321d2 section ("Rest day tomorrow comes in the next build"): keep only if the rest-day rider is in.
- Question 7 for the huddle (misses to Claude): the walls now answer most of it; keep only "is the switch still yes?"

## Unsure

- Item 5: QA's #451 review says a walled phrase that nothing on the phone catches gets "Didn't catch that.", but the
  on-device model still reads it, so `slept 5 hours` may land as something else. The check is that no line mentions
  Claude and the receipts count holds.
- Item 7: whether the month line shows with no key on the phone. The "of $50" text is ClaudeSection.swift:191 and :460.
- Item 3: decisions 12:02 to 12:05 PM PT ("pay rent fri" is a task again) are in open docs PR #460, not on master yet,
  and no Core code PR exists; the receipt wording is a guess from "Coffee, today 7 pm."
- Item 1: the reader writes Sunday only on first launch of a build that has it, so it can't be retried.
