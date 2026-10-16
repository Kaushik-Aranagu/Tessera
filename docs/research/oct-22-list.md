# Thursday 22 Oct: re-sign day, and Kaushik's one morning message (board items 91, 92 and 121)

*Research, refreshed Oct 16 about 12:20 PM PT at `origin/master` 234080a. Times Pacific. Sources: `pin-checklist.md`,
`next-build-script-v9.md`, `review-refresh-3.md`, `resign-day.md`, `install-day-script.md`, `review-session.md`,
`decisions.md`, `ops/board/*.md`, `trip-checklist.md`, master's log since 9:57 AM PT Oct 16.*

## Where things stand
- **On his phone:** 7b321d2, installed Fri Oct 16 9:57 AM PT over the app, data untouched. It carries #320, #330,
  #334, #337 and #343 only. Store at Catalog v5. Free Personal Team signing lapses about **Fri Oct 23, 9:57 AM PT**,
  so Thursday is re-sign day. Reminder: **Thu Oct 22, 10 AM PT**.
- **The next pin is Catalog v9, not named yet.** At 234080a the blockers #422, #446 and MU2 with A2 (#451) are
  merged; **#366 (Home lines) is still open** (Design clip pass, then QA confirm). Riders merged: #454 (paste/link
  wall), #457 (Siri task wall). Not merged: the mark-private pass, P1/T1, P2, the rest-day reader.
- **Rules that hold either way:** never delete Tessera; bundle `com.kaushikaranagu.tessera`, team `WMP2WF3P54`,
  App Group `group.com.kaushikaranagu.tessera`, none of them renamed. Step 0 is always SAVE A COPY. Rollback build is
  444e72b (v5). An older build on a newer store is shown safe through v7 (V4 checks 7b321d2 on the v9 store). A
  newer backup restored onto an older build is forbidden until tested.
- **Trip:** leaves Mon Oct 26 (New York), lands at LAX Wed Oct 28, 9:20 PM PT. The trip fixes (#377, #391) are only
  in the pin, which must be on his phone by Sun Oct 25 to help.

## 9:30 AM PT: which branch (coordinator, 2 minutes)
Branch 1 only if **all** hold: Product logged "Pin named" with the SHA in `decisions.md`; Builder A's v9 gate passed
on that SHA (V1 to V6: 366 v5 rows byte-identical, timed v5 restore at or under 3.23 s, 7b321d2 opens the v9 store);
QA read the gate run; Design passed the 66 walk; and he says "install it". Anything missing: Branch 2.

## Step 0, both branches (on the phone, before anything on the Mac)
1. Not mid-workout. Finish or skip starting one until after.
2. Review > Backups, tap **SAVE A COPY**. Today's copy shows on the page. Nothing else is asked about his backup.
3. Two yes/no questions only: is a Claude key on the phone? Is "Tess asks Claude" on? If both yes, note the receipts
   count in Settings > Claude. Never ask him to type, show or paste the key.

## Branch 1: the v9 pin is named and passed its gate
1. Step 0 above. This copy is v5, made on 7b321d2, so it stays restorable on 7b321d2 and 444e72b.
2. Mac (repo `~/pilot`): `git fetch origin`, then `git worktree add ~/pilot-pin <pin SHA>` and `cd ~/pilot-pin`.
   Confirm `git merge-base --is-ancestor 7b321d2 HEAD` succeeds and Catalog is v9 with nothing at v10.
3. `xcodegen generate`, open `Tessera.xcodeproj`, scheme Tessera, his iPhone. Leave the Signing tab alone. Scheme
   Run arguments empty. Cmd-R. It installs over 7b321d2; the first launch moves his store from v5 to v9. Any
   signing or install error: Branch 2 step 4 (stop, never delete).
4. The checks right after (below), then the review items: `review-refresh-3.md` items 1 to 14, about 10 minutes
   (items 12 and 13 ride his evening workout). Trip rows T1 and T2 happen in New York.
5. If anything looks wrong: stop, don't log, don't delete. Roll back by installing 7b321d2 over the top (the rollback
   after the pin, decisions 12:16 PM PT; V4 shows it opens the v9 store); never restore a backup made on the pin onto it.
6. Product logs the install line in `decisions.md` and `board.md`. Signing then lapses 7 days after this install.

## Branch 2: the pin isn't ready, re-sign 7b321d2 as is
Same commit, same store (v5), no migration, no data change. Only the signing clock restarts.
1. Step 0 above.
2. Mac: `cd ~/pilot && git fetch origin`, then `git worktree add ~/pilot-7b321d2 7b321d2` and
   `cd ~/pilot-7b321d2`. `git rev-parse --short HEAD` must print `7b321d2`. Never build master here.
3. `xcodegen generate`, open `Tessera.xcodeproj`, scheme Tessera, his iPhone (unlocked, same Wi-Fi, trusted).
   Signing tab as is: team `WMP2WF3P54`, Automatic, bundle id unchanged. Scheme Run arguments empty. Cmd-R.
4. **Any signing or install error: stop. Never delete the app.** "Untrusted developer": Settings > General > VPN &
   Device Management, trust. Not paired: pair again. App Group refused: remove the group lines from both entitlements
   files for this install only, never rename it (the look may reset; data doesn't). Anything else: send the error
   text to the coordinator before touching the phone.
5. Let the app open by itself from Xcode, then the checks right after (below).
6. Privacy until the pin is on his phone (decisions 10:18 AM PT Oct 16): "Tess asks Claude" stays no, or he types
   no passwords, codes or money to Tess. 7b321d2 has none of the walls.
7. Next lapse: about Thu Oct 29 at the re-sign time. A pin installed Oct 23 to 25 on his word restarts the clock
   and brings the trip fixes; without it a hotel workout may show a day early (display only).

## Checks right after (both branches, one line each)
1. Opens to Now, with no Tess note about a fresh start or moving the store aside.
2. Review shows this week as before: same workouts and set counts as this morning.
3. One exercise page: history and best still go back before today.
4. Review > Backups: today's copy is there, "the last one today", at most 7 kept.
5. Settings > Claude: a key is there, yes or no, same as Step 0. Don't paste it again.
6. The look sentence reads the same looks as before.

If 1 to 3 show an empty app: stop, log nothing, never delete. The data is still in the container or the copies.

## The morning message, 9:50 AM PT (refreshed; now 10 questions)

Kitchen lead fills the brackets by 9 AM PT. Drop any question he answers first (grep `decisions.md` for "Kaushik"
after Oct 16), renumber and fix the count. Changes are listed under "Stale".
```
Morning! 10 quick ones, one word each. Reply "defaults" to take every ★. Nothing changes until you answer.
Kitchen week one: you saved [n] recipes ([p] pasted, [l] from links, [g] typed), cooked [c] times ([t] timers, [e] stopped early), and shopped [s] times with [i] items ([r] from recipes, [y] typed).
1. Did you ever want to know whether you already had something at home? Yes / ★No
2. Did you fix a recipe after saving it, or want to? ★Yes / No
3. Was there a kitchen moment you reached for something else instead of Tessera? Name it, or ★No
Money, before it's built:
4. A shop name on a spend ("38.20 at Trader Joe's")? Its own field / ★Keep it in the text
5. Currencies: just €, £, $ and ₹? ★Yes / Add one (say which)
6. After a shop, Tess asks "Groceries total?" Can you answer with just "38"? ★Yes / No
7. Does "paid 650 rent" work like "spent"? ★Yes / No
8. "Split 60 with Sam": log your half or the full 60? ★Half / Full
Claude and recipes:
9. Plan my day sends Claude your task and calendar titles (never notes, places or health). OK? ★Yes / Leave calendar out
10. Recipe page: the clock (steps by the minute), prose, or two columns? ★Clock / Prose / Columns
```

Drop 10 if Design hasn't shown him A, B and C yet (decisions 9:27 AM PT: C stays the default until he picks). The
answer-to-owner table for these questions is unchanged; see this file at 98a4407. Monday's leftovers still go at
6 PM PT with Monday's wording, rest-day question excluded.

## Stale in the old list
- **Q10, the $50 cap:** answered. His "start with 50" (9:27 AM PT Oct 16); #422 carries it. Removed.
- **Q12, rest day Sunday:** taken from his Oct 15 "Sun rest" (decisions 11:52 AM PT); the reader writes Sunday with
  UNDO on its first launch. Removed; it is review item 1 once the reader is in a pin.
- The cap "waiting on his yes" and the "12 quick ones" count (now 10).
- `resign-day.md` step 3 ("pull master" and Run): wrong for Thursday. Build the exact commit (7b321d2 or the pin).
- `review-session.md`'s 7b321d2 section: step 2 ("type your key yourself") becomes the yes/no question; "the build
  after, before Oct 22" no longer holds (the pin is not named and may land after Oct 22).

## What he says yes or no to on Thursday
1. Branch 1 only: "install it" for the named pin. Yes / not today (then Branch 2).
2. Branch 2: re-sign the same build now, phone plugged in? Yes / later today (before Fri 9:57 AM PT).
3. Step 0: today's copy saved? Yes / No (no install until yes).
4. Is a Claude key on the phone? Yes / No. Is "Tess asks Claude" on? Yes / No.
5. Checks 1 to 6 after the install look right? Yes / No (any no: stop, don't delete).
6. The morning message: one word each, or "defaults".

**Ruled (Product, decisions.md 12:16 PM PT, pin-checklist §7):** after the pin, the rollback build is 7b321d2; before the pin it is 444e72b. MU2 and A2 are ticked; #366 is the only pin blocker left.
