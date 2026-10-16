# Next build's phone script, Catalog v9 pin

For: Builder A (Simulator, v9 gate) and QA (phone walk). Owner: Research lab. Oct 16, 2026 (Pacific), master 7334c8b.
Pin SHA not named yet: QA checks each section's item with `git merge-base --is-ancestor`; one not in is skipped, not failed.

| Section | Depends on | State at 7334c8b |
|---|---|---|
| Gate V1-V6 | #422 (5af8f2c, Catalog v9), #399, #380 | merged |
| Wall W1-W14 | MU2 (Core, pin blocker; QA #428 A1, Research MW1-MW9) | **no PR yet** |
| Inbox I1-I4 | A2 inbox-retry fix (Core, pin blocker; inside MU2 or beside it) | **no PR yet** |
| Listening L1-L3 | #446 (159a629, refused hold settles to rest) | merged |
| Home H1-H6 | #366 (Builder B, Home lines, pin blocker) | **open** |
| Trip X1-X3 | #377 (0bff60b) and #391 (70112f9) | merged |
| Rest day R1-R5 | Core's reader (Research 146, RG1-RG5) and Builder B's Settings row (RG4) | **no PR yet**; rider at most |
| Paste P1 | Paste/link SecretWords wall (Core) | rider, no PR yet |

Every value is made up. Never type, say, show or paste the Claude key; key presence is yes or no only. On the
phone, tap UNDO or NOT NOW after each row that writes.

## Step 0, on the phone, before the install (Product, ff548605)

| # | Do | Expect | Result |
|---|---|---|---|
| S0 | Review > Backups, tap **SAVE A COPY**. | Today's copy shows on the page. Nothing else is asked about his real backup. | [ ] P [ ] F |
| S1 | Ask him two yes/no questions: is a Claude key on the phone? Is "Tess asks Claude" on? | Write down yes or no for each. If both are yes, note the Claude receipts count in Settings > Claude now. | [ ] noted |

## The v9 gate (Builder A, Simulator; check it's in the pin: #422, Catalog v9, nothing at v10)

Exact archives of 444e72b (v5 demo store), 7b321d2 and the pin. Any V fail stops the install; the phone stays on 7b321d2.

| # | Do | Expect | Result |
|---|---|---|---|
| V1 | Install the pin over the seeded v5 copy (444e72b) without deleting the app. | Launches clean, no crash. Home draws. | [ ] P [ ] F |
| V2 | Compare every v5 row before and after. | All 366 v5 rows byte-identical, none missing (the accepted 8:56 AM v8 gate count). Any other count stops the gate until Builder A explains it. The v8 and v9 fields are added empty. GRDB schema unchanged. | [ ] P [ ] F |
| V3 | Restore a v5 backup file into the pin through Review > Backups. **Time it.** | Rows come back byte-identical, v8 and v9 fields empty, clean launch after. Write down the seconds. Fail above 3.23 s (the 2.23 s before restore plus 1 s; pin-checklist.md). | [ ] P [ ] F |
| V4 | Install 7b321d2 over the pin's v9 store. | Opens, runs, draws Home. Rows unchanged, extra classes ignored, no crash. | [ ] P [ ] F |
| V5 | On the pin, "wifi password is tacocat" then "what's my wifi password?". | "Private note, kept." and the Day log reads "Private note". Then "It's in your private notes." | [ ] P [ ] F |
| V6 | Confirm the rule still stands. | Restoring a newer backup onto an older build stays **forbidden**. Nobody tries it on the phone. | [ ] noted |

## Money, body and health wall (check it's in the pin: MU2)

Builder A first, on the Simulator with `-fakeClaudeKey`, the switch on, and a spy on Claude requests (QA's CA5 stub,
or the usage ledger if the stub isn't built): W1-W10 make **zero** requests, and the spy body holds none of 212.37,
2100, 3,412, 182.4, 83, 128/82, advil, lexapro. Then the phone, where the receipts count from S1 must not rise.
Tess lines are from `fixtures/money-body-wall.md` W8 (MU2's ask is decided; the body and health lines are proposed,
so take the merged PR's wording). A fail is any Claude call, or "Saved it for Claude", or "Claude didn't see that".

| # | Type in Ask Tess | Expect | Result |
|---|---|---|---|
| W1 | `$212.37 at Costco` (MB1) | "$212.37 at Costco?" with LOG / NOT NOW. Tap NOT NOW. | [ ] P [ ] F |
| W2 | `paid rent 2100` (MB3) | "Rent 2100?" with LOG / NOT NOW. Tap NOT NOW. | [ ] P [ ] F |
| W3 | `venmo sam 25 for pizza` (MB5) | A money ask on the phone, never a Claude line. NOT NOW. | [ ] P [ ] F |
| W4 | `checking is at 3,412` (MB7) | Stays on the phone (ask or private note). Receipts count unchanged. | [ ] P [ ] F |
| W5 | `182.4 lb this morning` (MB16) | The body weight ghost for 182.4 lb. UNDO. | [ ] P [ ] F |
| W6 | `weighed in at 83 kg` (MB17) | Body weight 83 kg ghost. UNDO. | [ ] P [ ] F |
| W7 | `bp 128/82` (MB18) | A private note, "Kept, on this phone only." (proposed). UNDO. | [ ] P [ ] F |
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
| R2 | Settings, the Rest day row. | "Rest day: Sunday." | [ ] P [ ] F |
| R3 | Sim: `-demoTime 10:00` on a Sunday, Mon to Sat done (S09). | "today" / "Rest day" / "Push A is a tap away." | [ ] P [ ] F |
| R4 | Sim: Thu 7 am, Mon to Wed done (S06). | Push B hero, not "Rest day". | [ ] P [ ] F |
| R5 | Type "rest day Sunday" (S17). | "Sunday, rest day." and no task. | [ ] P [ ] F |

## Rider (check it's in the pin: paste/link wall)

| # | Do | Expect | Result |
|---|---|---|---|
| P1 | Paste a recipe ending "wifi: TacoNet / tacocat24" (P1) and save. | "I left out 1 line that looked private." Original text holds no tacocat. | [ ] P [ ] F |

## Report back

- The pin SHA, and for each section: in, skipped (with the missing item), pass or fail.
- V3's restore time in seconds (fail above 3.23 s), and V2's row count if it isn't 366 (the gate stops).
- The S1 answers (yes/no only) and the receipts count before and after W1-W14 and I4.
- What each queued phrase in I2 became, and whether the retry is wired at all (I3).
- Any Tess line that differs from this script, word for word, with the row number.
