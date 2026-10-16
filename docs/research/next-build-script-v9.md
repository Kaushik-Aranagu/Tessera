# Next build's phone script, Catalog v9 pin

For: Builder A (Simulator, v9 gate) and QA (phone walk). Owner: Research lab. Oct 16, 2026 (Pacific), master 7334c8b;
refreshed 12:55 pm PT at master 01b30a2 (`pin-gate-dry-read.md` G1-G3, G6-G8, G12-G15, G20).
Pin SHA not named yet: QA checks each section's item with `git merge-base --is-ancestor`; one not in is skipped, not failed.

| Section | Depends on | State at 01b30a2 |
|---|---|---|
| Gate V0-V6 | #422 (5af8f2c, Catalog v9), #399, #380 | merged |
| Wall W1-W14 | MU2 (Core, pin blocker; QA #428 A1, Research MW1-MW9) | merged: #451, bf2a4bb, 12:03 pm PT |
| Inbox I1-I4 | A2 inbox-retry fix (Core, pin blocker) | merged inside #451, bf2a4bb |
| Listening L1-L3 | #446 (159a629, refused hold settles to rest) | merged |
| Home H1-H6 | #366 (Builder B, Home lines, pin blocker) | merged: 6047078, 12:47 pm PT, with the 4 am day label (`HomeLineHero.swift` reads the day through `TesseraDay`) |
| Trip X1-X3 | #377 (0bff60b) and #391 (70112f9) | merged |
| Rest day R1-R5 | Core's reader (Research 146, RG1-RG5) and Builder B's Rest day row (RG4) | **no PR yet**; rider at most |
| Paste P1 | #454 paste/link SecretWords wall (Core) | merged: 234080a, 12:12 pm PT |
| Notes B1 | #471 notes refuse a Claude key (Core) | merged: 68c9a19, 12:22 pm PT |
| Siri SI1-SI2 | #457 Siri Add a Task wall (Core, QA I3) | merged: cf50bb0, 12:07 pm PT |
| Newer copy B5-B6 | #475 newer-catalog store and backup refused (Core) | merged: 76be1c0, 12:36 pm PT |
| Riders M1, P14 | M1 (no backup from the in-memory fallback), P14 (Siri routes like the Ask bar) | **not on master**; skip if not in |

Every value is made up. Never type, say, show or paste the Claude key; key presence is yes or no only. On the
phone, tap UNDO or NOT NOW after each row that writes.

## Step 0, on the phone, before the install (Product, ff548605)

| # | Do | Expect | Result |
|---|---|---|---|
| S0 | Review > Backups, tap **SAVE A COPY**. | Today's copy shows on the page. Nothing else is asked about his real backup. | [ ] P [ ] F |
| S1 | Ask him two yes/no questions: is a Claude key on the phone? Is "Tess asks Claude" on? | Write down yes or no for each. If both are yes, note the Claude receipts count in Review, under Claude, now. | [ ] noted |

## The v9 gate (Builder A, Simulator; check it's in the pin: #422, Catalog v9, nothing at v10)

Exact archives of 444e72b (v5 demo store), 7b321d2 and the pin. Any V fail stops the install; the phone stays on 7b321d2.
V0 runs on the Mac before any other row and before anything touches the phone.

| # | Do | Expect | Result |
|---|---|---|---|
| V0 | Mac, before the install: `git log --oneline 7b321d2..<pin SHA>`, then read `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift` at the pin. | No merge of #403 (eyes) or #407 (tessEyes, v10) in the list. `CatalogPackage(id: "system", version: 9, ...)`; nothing at v10. Either fails: stop, no install. | [ ] P [ ] F |
| V1 | Install the pin over the seeded v5 copy (444e72b) without deleting the app. | Launches clean, no crash. Home draws. | [ ] P [ ] F |
| V2 | Compare every v5 row before and after. | All 366 v5 rows byte-identical, none missing (the accepted 8:56 AM v8 gate count). Any other count stops the gate until Builder A explains it. The v8 and v9 fields are added empty. GRDB schema unchanged. | [ ] P [ ] F |
| V3 | Restore a v5 backup file into the pin through Review > Backups. **Time it.** | Rows come back byte-identical, v8 and v9 fields empty, clean launch after. Write down the seconds. Fail above 3.23 s (the 2.23 s before restore plus 1 s; pin-checklist.md). | [ ] P [ ] F |
| V4 | Install 7b321d2 over the pin's v9 store. | Opens, runs, draws Home. Rows unchanged, extra classes ignored, no crash. | [ ] P [ ] F |
| V5 | On the pin, "wifi password is tacocat" then "what's my wifi password?". | "Private note, kept." and the Day log reads "Private note". Then "It's in your private notes." | [ ] P [ ] F |
| V6 | Confirm the rule still stands. | Restoring a newer backup onto an older build stays **forbidden** on the phone; nobody tries it there. On the Simulator, B6 below shows the pin refuses one. | [ ] noted |

## Money, body and health wall (check it's in the pin: MU2)

Builder A first, on the Simulator with `-fakeClaudeKey`, the switch on, and a spy on Claude requests (QA's CA5 stub,
or the usage ledger if the stub isn't built): W1-W10 make **zero** requests, and the spy body holds none of 212.37,
2100, 3,412, 182.4, 83, 128/82, advil, lexapro. Then the phone, where the receipts count from S1 must not rise.
Tess lines are master's (#451 and #471): money gives "Didn't catch that.", body and health facts become a private
note with "Private note, kept." (`TessGrammar.parseBodyFact`, `TessCaptureEngine.swift:300`). A fail is any Claude call, or "Saved it for Claude", or "Claude didn't see that".

| # | Type in Ask Tess | Expect | Result |
|---|---|---|---|
| W1 | `$212.37 at Costco` (MB1) | Merged #451: "Didn't catch that." and no Claude call (the "$212.37 at Costco?" LOG / NOT NOW ask comes later). | [ ] P [ ] F |
| W2 | `paid rent 2100` (MB3) | As W1 (#451). | [ ] P [ ] F |
| W3 | `venmo sam 25 for pizza` (MB5) | As W1 (#451). | [ ] P [ ] F |
| W4 | `checking is at 3,412` (MB7) | Stays on the phone (ask or private note). Receipts count unchanged. | [ ] P [ ] F |
| W5 | `182.4 lb this morning` (MB16) | The body weight ghost for 182.4 lb. UNDO. | [ ] P [ ] F |
| W6 | `weighed in at 83 kg` (MB17) | Body weight 83 kg ghost. UNDO. | [ ] P [ ] F |
| W7 | `bp 128/82` (MB18) | A private note, "Private note, kept." UNDO. | [ ] P [ ] F |
| W8 | `slept 5 hours` (MB20) | Private note, as W7. UNDO. | [ ] P [ ] F |
| W9 | `took 2 advil` (MB21) | Private note, as W7. UNDO. | [ ] P [ ] F |
| W10 | `remember my rent is 2100` (MB10) | "I don't keep sums of money." on the phone. Memory page doesn't show it. | [ ] P [ ] F |
| W11 | Near-miss: `bench 80 x 8` (MB31) | Logs the set as today. No money ask, no private note. UNDO. | [ ] P [ ] F |
| W12 | Near-miss: `weigh the flour 500 g` (MB34) | Not walled: it may reach Claude (spy count +1 on the Simulator). No body weight ghost. | [ ] P [ ] F |
| W13 | Near-miss: `Costco run saturday` (MB35) | Task "Costco run", Saturday. UNDO. | [ ] P [ ] F |
| W14 | Near-miss: `budget meeting 3pm` (MB38) | Task at 3 pm. UNDO. | [ ] P [ ] F |

## Inbox retry (check it's in the pin: A2)

| # | Do | Expect | Result |
|---|---|---|---|
| I1 | Sim: on 7b321d2 with `-fakeClaudeKey` and the switch on, take the Mac offline. Type `door code 4417` and `$38.20 trader joe's` (MB14). | 7b321d2 answers "No connection. Saved it for Claude." for each. Both wait in the inbox. | [ ] P [ ] F |
| I2 | Install the pin over it, go online, open the app twice. | The spy sees **zero** requests holding 4417 or 38.20. Write down what became of each phrase (unsent, private note, or money ask). | [ ] P [ ] F |
| I3 | Sim: if the pin wires no caller for the retry, say so. | "Not wired" passes I2 trivially; add a test-only check that `add` refuses both phrases. | [ ] noted |
| I4 | Phone: Airplane Mode on. Type `$38.20 trader joe's`, then `door code 4417`. Airplane Mode off, reopen. | The money ask, then "Private note, kept.", never "Saved it for Claude". Receipts count unchanged after reopening. | [ ] P [ ] F |

## Stuck listening (check it's in the pin: #446)

| # | Do | Expect | Result |
|---|---|---|---|
| L1 | iOS Settings > Tessera > Microphone off. Hold the soul. | "Mic is off for Tessera." beside the soul, then Tess at rest. She never stays listening. | [ ] P [ ] F |
| L2 | Right after L1, hold the tab row. | The glass pill rises: the tab lens works (a stuck listen refused it). | [ ] P [ ] F |
| L3 | Tap the soul, tap **Speak** (mic still off). Then mic back on. | The surface stays open with the refusal line until he closes it. | [ ] P [ ] F |

## Home lines (check it's in the pin: #366)

Words from `HomeLines` and `fixtures/home-lines-day.md`; times carry "pm" (decisions 11:50 AM PT).

| # | Do | Expect | Result |
|---|---|---|---|
| H1 | Training day, nothing started: Today, morning then after 5 pm. | Hero "Push A", **today** above, then **this evening**. Nothing ends in "…", no " · ". | [ ] P [ ] F |
| H2 | Start, log 2 sets, close from the workout (tap PAUSE). | "Push A, paused at bench", **paused just now** above. | [ ] P [ ] F |
| H3 | Finish it. | "Push A done", **done at** the time above, for example "done at 7 pm". One tap down: "*n* exercises, *n* sets." plus ", 1 new best." if he set one. | [ ] P [ ] F |
| H4 | After midnight, before 4 am. | Same "Push A done" and time. His day hasn't turned. | [ ] P [ ] F |
| H5 | "cook tacos tonight" with 2 grocery rows. | "Tacos today" before 5 pm, "Tacos this evening" after; **2 to buy** above. | [ ] P [ ] F |
| H6 | Largest text size, then H3. | The hero steps down to two lines; nothing is cut. | [ ] P [ ] F |

## Trip rows (check it's in the pin: 0bff60b and 70112f9 are ancestors; must be on his phone by Oct 25)

| # | Do | Expect | Result |
|---|---|---|---|
| X1 | Sim: finish a workout with `-demoTime 03:30` launched in New York time (`SIMCTL_CHILD_TZ=America/New_York`), relaunch in LA time. | Home: "Push A done" on the New York day; no second session offered (T1, R22). | [ ] P [ ] F |
| X2 | Sim: same run, open the exercise's history. | The set reads "Yesterday" by the workout's own zone (T4, R34). | [ ] P [ ] F |
| X3 | Sim: the turnover across that long day. | One "Tue:" memory line, never two (T3, R25). | [ ] P [ ] F |

Known gap, not an F: Review in New York counts an in-flight task on Tue (R12). Phone: no zone change; the trip is the test.

## Rest day (check it's in the pin: Core's reader RG1-RG5 and Builder B's row RG4; skip if not)

| # | Do | Expect | Result |
|---|---|---|---|
| R1 | First launch of the pin. | One op: "Sunday, rest day." with UNDO. Don't tap UNDO. | [ ] P [ ] F |
| R2 | Builder B's Rest day row, wherever the reader's PR puts it (master has no Settings screen; Review holds the look and Claude until one exists). | "Rest day: Sunday." | [ ] P [ ] F |
| R3 | Sim: `-demoTime 10:00` on a Sunday, Mon to Sat done (S09). | "today" / "Rest day" / "Push A is a tap away." | [ ] P [ ] F |
| R4 | Sim: Thu 7 am, Mon to Wed done (S06). | Push B hero, not "Rest day". | [ ] P [ ] F |
| R5 | Type "rest day Sunday" (S17). | "Sunday, rest day." and no task. | [ ] P [ ] F |

## Paste wall (check it's in the pin: #454, 234080a)

| # | Do | Expect | Result |
|---|---|---|---|
| P1 | Paste a recipe ending "wifi: TacoNet / tacocat24" (P1) and save. | Before saving, the wifi line shows pale, marked "ignored", like any line that isn't the recipe (`PasteRecipe.swift`, recording 50). No Tess line about it. After saving, the recipe's original text holds no tacocat. UNDO. | [ ] P [ ] F |

## Notes key refusal (check it's in the pin: #471, 68c9a19)

| # | Do | Expect | Result |
|---|---|---|---|
| B1 | Notes, the writing line: paste a key-shaped test string from the test kit; never his real key. Then open any note and paste the same string into its body. | Nothing is saved with it: the writing line clears, and the note keeps everything but the string. The line above Notes (or the note's context line) reads "That looks like a Claude key. It goes in Review, under Claude." No new note in the list. | [ ] P [ ] F |

## Siri Add a Task (check it's in the pin: #457, cf50bb0)

Shortcuts app > Tessera > **Add a Task**, or say it to Siri.

| # | Do | Expect | Result |
|---|---|---|---|
| SI1 | Task: `door code 4417`. | Siri answers "Private note, kept." No task named "door code 4417"; Notes shows it as a private note. Delete the note after. | [ ] P [ ] F |
| SI2 | Sim only: Task: the key-shaped test string from the test kit; never his real key. | "That looks like a Claude key. It goes in Review, under Claude." Nothing saved. | [ ] P [ ] F |
| P14 | Skip if P14 isn't in the pin. Task: `took advil 400mg`, then `pay rent 2100 friday`. | The first becomes a private note: "Private note, kept." and nothing more; Siri doesn't read the phrase back. The second stays a task (decisions 12:11 pm PT). Delete both after. | [ ] P [ ] F [ ] skipped |

## Newer copy refused (Builder A, Simulator; check it's in the pin: #475, 76be1c0)

A Catalog v10 store and a v10 backup copy come from a build of #407's head on a scratch Simulator. Never on the phone.

| # | Do | Expect | Result |
|---|---|---|---|
| B5 | Launch #407's head once (store goes to v10), then install the pin over it without deleting the app. | The launch note: "Your data is from a newer Tessera, so I left it untouched. Update the app to open it; nothing you do this time will be kept." The v10 store file is unchanged on disk (same checksum before and after). | [ ] P [ ] F |
| B6 | On the pin with its own v9 store, Review > Backups, pick the v10 copy. | "That copy is from a newer Tessera. Update first." Nothing restored; rows unchanged. | [ ] P [ ] F |
| M1 | Skip if M1 isn't in the pin. Right after B5 (the in-memory session), send the app to the background, reopen, background again. | No new backup copy: Documents/Backups holds the same files as before B5, none newer and none from an empty store. | [ ] P [ ] F [ ] skipped |

## Report back

- The pin SHA, and for each section: in, skipped (with the missing item), pass or fail.
- V3's restore time in seconds (fail above 3.23 s), and V2's row count if it isn't 366 (the gate stops).
- The S1 answers (yes/no only) and the receipts count before and after W1-W14 and I4.
- What each queued phrase in I2 became, and whether the retry is wired at all (I3).
- V0's result: no #403 or #407 merge in `7b321d2..<pin SHA>`, Catalog v9.
- B1, SI1, SI2, B5 and B6 pass or fail; M1 and P14 in or skipped (if M1 is skipped, #407 waits; pin-checklist §2).
- Any Tess line that differs from this script, word for word, with the row number.
