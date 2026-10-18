# Handoff block for a fresh thread (Ops, Oct 17)

Kaushik's ask (Oct 17, 12:18 PM PT, timeline message cmsg_01VTPva3JGXrfvetgUvAWE7MEAkdcHifViwJXzLz4XeVnh): when a lead moves to a new thread, the new thread must know it continues another chat and have breadcrumbs back to the old conversation and the rules he wants kept, to look up when it needs them.

Every handoff brief carries the block below, filled in. The coordinator pastes it when starting the fresh thread; the outgoing lead fills the blanks it knows (its own handoff note). Nothing here is a secret: no key, no key prefix, no key length. Breadcrumbs are pointers, not copies, so the brief stays short.

## The block (copy, fill the angle-bracket parts)

```
HANDOFF: you are the fresh <TEAM> lead. You continue an earlier chat; you are not starting from zero.

1. Old thread: <link text and thread id cmsg_...>, old session <cse_... or session_...>.
   Read it when you need history, a promise, or the exact words of a decision:
   cloud thread -> fetch_thread (thread id, oldest_first) or list_events (old session id, ask for the last few hundred events);
   Mac session -> you cannot read it; ask the coordinator to relay the passage, or read your handoff note and board.
2. Your handoff note: <where>: ops/rotation-handoffs.md in the project files (section "<TEAM>"),
   mirrored to docs/ops/handoff-block.md in the repo for Mac sessions (git show origin/master:docs/ops/handoff-block.md).
   It lists open PRs, open verdicts, cards waiting on Kaushik and what to do next.
3. Where the standing rules live (look here before asking Kaushik again):
   - project memory (the index you were given; cloud threads): /tmp/claude/memory/team/silo/MEMORY.md and the team files it names;
   - your board: ops/board/<team>.md (repo: docs/ops/board/<team>.md);
   - decisions: product/decisions.md (repo: docs/product/decisions.md), newest first;
   - the project instructions block and CLAUDE.md in the repo;
   - the rule list below.
4. Rules of Kaushik's that apply to your team. Each has the message it came from;
   read the message with fetch_messages (cloud) or ask the coordinator to quote it (Mac):
   - <rule in his words or close to them> (<message id>, <time PT>)
5. How to refresh: if a rule, a promise or an earlier decision is unclear, look it up (steps 1 to 4) before asking him; ask him only when the lookup does not answer.
   If you find a rule missing here, tell the coordinator so the block is fixed for the next handoff.
```

## How to hand off (the outgoing lead and the coordinator)

1. The outgoing lead writes its handoff note (open PRs and heads, verdicts waiting, cards waiting on Kaushik, next work, habits that paid off) into its section of rotation-handoffs.md, and sends the coordinator the text.
2. The coordinator starts the fresh thread, putting the block above (filled in) at the top of the brief, ahead of the task text, and attaches nothing else except what the lead named.
3. The fresh lead's first action is to read the block's items 2 and 3 and confirm in one line to the coordinator that it did. Only then is the old thread retired (never mid-PR, never with a question to Kaushik open).
4. Breadcrumb rule for rules: when Kaushik states a new standing rule, the lead who hears it adds one line to item 4 of its team's block with the message id, so the next handoff inherits it.
5. The Ops mirror chore copies this file to docs/ops/ after each change (Mac sessions cannot read the project files).

## Secret rule (applies to every breadcrumb)

No key, no key prefix, no key length, no screenshot of one, ever. Never cite or quote the Key check threads ("Memory experiment, key check", "Claude key check and memory run"); if a rule came from there, cite the decision in decisions.md instead.

## Breadcrumb notes for the leads that moved on Oct 17

Each note is the filled block for that lead's fresh thread. Message ids were read back from the timeline on Oct 17 (all are Kaushik's own messages). Session ids: send_message wants the `session_` form (swap `cse_` for `session_`). Each lead also gets the general rules (G) first.

### G: rules for every team
- Merge PRs yourselves; never ask him to merge (Oct 15, 2:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M6DCbfNCPD4kLaSA9gjbK29)
- If blocked on him, put it on hold and do other work; ask only if truly necessary (Oct 15, 2:54 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M38KyUWoXmuM1kGBJSEim5S)
- Personal app, always changing: high velocity, many features fast, imperfect is fine (Oct 15, 8:55 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MWThFue7kHFvDgyBqFn4Ppj)
- Threads must not sit idle; leads plan independent tasks; local plus central governance (Oct 15, 11:04 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MQPRGjx5HdaJaD9HybCNKy3)
- Chief of staff has the broad view and trusts team leads with the deep view; random periodic checks only (Oct 16, 11:26 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M8afBAc5E2F37v9buPMUfXX)
- Manage usage by switching model and effort, never stopping work; 90% project, 10% his; mind the weekly limit (Oct 16, 5:06 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M3e1FLSEXPDvRCHFmBTXUFM)
- Keep work running even on cheaper models and CPU work; big model and high effort only when it counts (Oct 16, 5:40 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MKsHbg1eZMcNBM2tGBfjbBv)
- There is always work; put in enough resources to find it and saturate (Oct 16, 5:42 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M3wPJPcq3jxnNVw6y6g6ZGD)
- Brief update in your thread every 2 to 3 hours that ends with what you need from him; a daily presentation of today, next and the week (Oct 16, 8:20 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MQvAYv1ZP13asD93vc8YGGY)
- A fresh thread must know it continues another chat and have breadcrumbs to old conversations and rules (Oct 17, 12:18 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MEAkdcHifViwJXzLz4XeVnh)
- Coordinator's how-we-work rule, 9:30 PM PT Oct 17 (not Kaushik's words): authors send PRs to QA and do not copy the coordinator; QA sends the coordinator verdicts, batched when several land close together; leads message the coordinator only for Mac relays, blockers, rotations and rulings, plus the 3-hourly updates in their own threads; no "ready to merge" note once QA has sent the verdict.
- Coordinator's merge rule, 10 PM PT Oct 17 (not Kaushik's words): leads never merge. Only the coordinator's merge workers merge, using the merge recipe and a pinned head, after QA's verdict. (Kaushik's rule above means he never has to merge; the workers do it.) Tonight a lead squash-merged #953 with no head pin and no premerge check; the audit was clean but skipped the recipe.

### Product
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7M9buvsufEBhXZqJtov6ZY72; old session cse_013bC75Wtuv4sc7B2EmqcXVZ.
- Current thread (rotated 7:20 AM PT Oct 18, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7MWi2dCL7tNxRpj8bBAegpPg; session session_01TtjFYrCSBXmZzXXajVQvgq.
- Retired (Product, 7:20 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7M4PS458UQbE4cTCBrUUs8ZG; session session_01RBgnhXvCZZhM8wDwJqs5Rx. Earlier line: Fresh thread (rotated about 4:30 PM PT Oct 17, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7M4PS458UQbE4cTCBrUUs8ZG; session session_01RBgnhXvCZZhM8wDwJqs5Rx. Retired: thread cmsg_01VTPva3JGXrfvetgUvAWE7MRLK2oiTKs6EG9Uu5qfT6M1, session cse_01STY2yX8fnVksnqnnPkcBQG.
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "Product" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for Product (plus G):
   - Next domain: recipes, groceries, lists built on notes and lists; offer options, no clutter (Oct 15, 10:08 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MHov6f1LgB5VxUochonHG95)
   - Long term, Tess is the manager agent and his first contact; keep that in the architecture docs (Oct 16, 11:27 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXBTCyKqWtY6o5AB68nf99K)
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)
   - UI carries 50% of the weight of the backend; be as creative and innovative in UI (Oct 15, 12:47 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MDdEf7HFeA7JuuPy9ZKPyLt)
   - No cards; elegant, smooth transitions and text effects; the app must make him want to use it (Oct 15, 12:45 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MFAjBiVQe19swLsWzT6BSt9)

### Kitchen
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7MJ6x15H146i8Ubn1hrFjuEJ (Kitchen lead, rotated 6:45 PM Oct 17, session_01TRh7xwt9UhB98fN8BteVgs stood down), before it cmsg_01VTPva3JGXrfvetgUvAWE7MBXXiW98VQjyxykT4o3aJzs and cmsg_01VTPva3JGXrfvetgUvAWE7MHov6f1LgB5VxUochonHG95; older sessions cse_01WEnBRbu1uKt5FybKX4ffbe, cse_01Fe7U23BpiBM3LSkVTTfatZ.
- Fresh thread (rotated 9:15 AM PT Oct 18): cmsg_01VTPva3JGXrfvetgUvAWE7M4Apt8RTcQ1bkk4838dHvZT; session session_01FYpVsczTwVXiUhydnzexBt.
- Retired (Kitchen, 9:15 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7M89s9yq77kzrHiVK6fDMbrZ; session session_01WXUguo5FzJwPMPZohELbQR.
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "Kitchen" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for Kitchen (plus G):
   - Next domain: recipes, groceries, lists built on notes and lists; offer options, no clutter (Oct 15, 10:08 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MHov6f1LgB5VxUochonHG95)
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)
   - AI cap starts at $50 a month (Oct 16, 9:27 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MWjyW2G8YtFpqHaF9gKnDcD)
   - No cards; elegant, smooth transitions and text effects; the app must make him want to use it (Oct 15, 12:45 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MFAjBiVQe19swLsWzT6BSt9)

### QA
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7M3cdnVjUDBstQ8XtwdEoetT (Repo maintainer, resolved Oct 17 7:21 AM PT); old session cse_016hxroCB7KSo9FQG2RL5PdR.
- Current thread (rotated 11:28 AM PT Oct 18, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7M8HsLv7SwF7ADQiw2UCohCr; session session_01LbGAxUTg7rWH8bWgK5EBJA.
- Retired (QA, 11:28 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7MGdnjMQ1bVU1jh77iNkirwA; session session_0159fgVMPVtfHwTED546XWC8.
- Retired (QA, 7:20 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7M4ssnyX2AFNBvTnuUMj5Y1K; session session_016tTiZavEry3vudhWSeD15v. Earlier line: Fresh thread (rotated again about 8:56 PM PT Oct 17, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7M4ssnyX2AFNBvTnuUMj5Y1K (QA); session session_016tTiZavEry3vudhWSeD15v. Retired: thread cmsg_01VTPva3JGXrfvetgUvAWE7MCy1jQu1AAK4DaoaMNk6LTX, session session_01LivGht4DsiiWp8zDyRGFtz (the 4:30 PM generation); thread cmsg_01VTPva3JGXrfvetgUvAWE7MCGo649SeUBPdKzkV1rnwTw, session session_011G5V3Hxc6iNaYxFTxRs5Eg; and thread cmsg_01VTPva3JGXrfvetgUvAWE7MGRpS7oj5KfU9dSEo1Piu6j, session cse_01SPUv55gtzktZjCda2KjMoW (and the earlier cmsg_01VTPva3JGXrfvetgUvAWE7M5h3w4owqhDYuba8C5nBymK, cse_01M6UTgTZa2bJBa8bLiyL3rv).
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "QA" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for QA (plus G):
   - Release to his phone aggressively: daily and with each new feature (Oct 16, 3:02 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MBLpTsJ6CxszumZC5nRYaTs)
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)

### Design
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7M9qhtQTdNEMQe3jgZZMuJ5g; old session cse_01SL6miEcidPoK87LdeaQGbH.
- Current thread (rotated 7:20 AM PT Oct 18, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7M3F8b4jtX4yY2bBm8U8ew71; session session_018qJ8EcmJouiyUeGQbQfgEX.
- Retired (Design, 7:20 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7MPgmjA8hTn97dR7fqUQnzdE; session session_015X5sbwjvU5TcEzjZg4LaQr. Earlier line: Fresh thread: cmsg_01VTPva3JGXrfvetgUvAWE7MPgmjA8hTn97dR7fqUQnzdE; session cse_015X5sbwjvU5TcEzjZg4LaQr.
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "Design" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for Design (plus G):
   - UI carries 50% of the weight of the backend; be as creative and innovative in UI (Oct 15, 12:47 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MDdEf7HFeA7JuuPy9ZKPyLt)
   - No cards; elegant, smooth transitions and text effects; the app must make him want to use it (Oct 15, 12:45 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MFAjBiVQe19swLsWzT6BSt9)
   - No default rounded rectangle or pill buttons and cards; more elegant, subtle controls (Oct 15, 12:00 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M8AkTjBBbEgur6vod4tmgHM)
   - No colored bullet dots; subtler accents or another indicator, or remove it (Oct 15, 8:07 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MHEpw7LgdCjfhjJv3XZx7Xn)
   - Color subtle, not high contrast, but still drama and life (Oct 15, 8:08 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MQHKFMuRDPnR3tcpka9jnTn)
   - Pure black is the shared base for now; the layers above can change; per-app themes come later (Oct 15, 8:25 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MQdKHstZUDWn8b559fvzjkJ)
   - The thick underlines are too heavy; refine or replace (Oct 15, 8:26 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MVARW7f9SCbpdckG5sQ1gQP)
   - Bigger titles can take a subtle colour or accent shift; no brush underlines (Oct 16, 1:32 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXPAT6b2UtkhrJP1bYG9PGZ)
   - Capture and text sheets: neat, calm, peaceful, smaller fonts; the rep scale must not eat space; numbers edit in place (Oct 15, 6:45 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MAgzuDSbVSYL8eGvDWAtYkV)
   - Light themes with pure whites and rich minimal palettes, plus pure black ones; skip full-suite testing at that point (Oct 15, 6:40 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MVKU1mupG37dFrCHfM1bAbm)
   - Round dial and great haptics; creating and finishing a task must feel good and rewarding (Oct 15, 11:19 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M2yYjh5bH5tgUeUjekxLF4D)

### Research
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7MCHUVZQTvpxVy5UZmhdenMF; old session cse_01WMUdQQHF9pRNj9dwSJFGef.
- Previous fresh thread (retired 9:40 PM PT Oct 17): cmsg_01VTPva3JGXrfvetgUvAWE7MPtwgew3oJ7cvhswUWWXx7k; session cse_017t1kiDAoSpJVo4NVP2BpZU.
- Current thread (rotated 7:20 AM PT Oct 18, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7MWr4kZQo1z1nwP1aRpCcNCw; session session_01LdX7E6RE6FmHbEE6K5Hth9.
- Retired (Research, 7:20 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7MVwggk1QksBUnspxQ8a39Qi; session session_016prm61LgTia7soLeQ5zxP8. Earlier line: Current thread (rotated 9:40 PM PT Oct 17): cmsg_01VTPva3JGXrfvetgUvAWE7MVwggk1QksBUnspxQ8a39Qi; session cse_016prm61LgTia7soLeQ5zxP8 (send_message form: session_016prm61LgTia7soLeQ5zxP8).
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "Research" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for Research (plus G):
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)

### AI architecture
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7MNFdmU6fKkCLKUHUNnUMoWs; old session cse_01DjmvkyvRv3FrANnLQQx6U6.
- Fresh thread: cmsg_01VTPva3JGXrfvetgUvAWE7MFkXAPBQ4sJbazgjECDVsu7; session cse_011uM8VcURgDjjMD2eApQiCb.
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "AI architecture" if present; if not, ask the coordinator for the note the outgoing lead sent.
- Rules for AI architecture (plus G):
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)
   - Long term, Tess is the manager agent and his first contact; keep that in the architecture docs (Oct 16, 11:27 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXBTCyKqWtY6o5AB68nf99K)
   - AI cap starts at $50 a month (Oct 16, 9:27 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MWjyW2G8YtFpqHaF9gKnDcD)

### Core (Mac)
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7MAYovNFqJsR8HEKWCUp3Bx9; old session cse_01BQyrZn9PGsr94CrCvmUb8b.
- Fresh thread: cmsg_01VTPva3JGXrfvetgUvAWE7MHSnAXPPHMDNfPXTyZd75VX; session cse_01G3n7sadfakzAogtiqM742p.
- This is a Mac session: it cannot call fetch_thread or read these files from the project folder. Read the repo copies with git show origin/master:docs/ops/handoff-block.md, docs/ops/board/<team>.md and docs/product/decisions.md, and ask the coordinator to quote a message when you need his exact words.
- Handoff note: section "Core" in docs/ops/handoff-notes.md (repo; the Mac lead writes it there) and ops/rotation-handoffs.md. Until the outgoing lead has written it, ask the coordinator to paste the note the outgoing lead sent (the Mac cannot fetch it).
- Rules for Core (plus G):
   - Integrate Claude early (yes) (Oct 15, 11:41 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXfAj9rS5WnrrZNzcFQbtHD)
   - Long term, Tess is the manager agent and his first contact; keep that in the architecture docs (Oct 16, 11:27 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MXBTCyKqWtY6o5AB68nf99K)

### Builder A (Mac)
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7MTz37meJ7v1kwQtEuNVtmfY; old session: the thread titled "iOS build" in list_thread_sessions (Mac session; the coordinator can read it).
- Fresh thread: cmsg_01VTPva3JGXrfvetgUvAWE7MUBkL1XKPxcemXhXnudvRpC; session cse_018k2u1aFREN7kbum42Nnf8Q.
- This is a Mac session: it cannot call fetch_thread or read these files from the project folder. Read the repo copies with git show origin/master:docs/ops/handoff-block.md, docs/ops/board/<team>.md and docs/product/decisions.md, and ask the coordinator to quote a message when you need his exact words.
- Handoff note: section "Builder A" in docs/ops/handoff-notes.md (repo; the Mac lead writes it there) and ops/rotation-handoffs.md. Until the outgoing lead has written it, ask the coordinator to paste the note the outgoing lead sent (the Mac cannot fetch it).
- Rules for Builder A (plus G):
   - Release to his phone aggressively: daily and with each new feature (Oct 16, 3:02 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MBLpTsJ6CxszumZC5nRYaTs)
   - Round dial and great haptics; creating and finishing a task must feel good and rewarding (Oct 15, 11:19 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M2yYjh5bH5tgUeUjekxLF4D)
   - No cards; elegant, smooth transitions and text effects; the app must make him want to use it (Oct 15, 12:45 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MFAjBiVQe19swLsWzT6BSt9)
   - No default rounded rectangle or pill buttons and cards; more elegant, subtle controls (Oct 15, 12:00 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7M8AkTjBBbEgur6vod4tmgHM)
   - UI carries 50% of the weight of the backend; be as creative and innovative in UI (Oct 15, 12:47 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MDdEf7HFeA7JuuPy9ZKPyLt)

### Mac rules (Core, Builder A, Builder B)
- You take relays from the coordinator, not direct sends from other teams. Use the one shared simulator through the lane lock (`scripts/ops/lane_lock.sh run <lane> "<purpose>" -- <cmd>`, docs/ops/lane-lock.md). Push WIP to your branch before any long gate. Stop only your own processes, by PID. Check the screen is unlocked and the simulator destination before trusting an app test. After a frozen-PR number is sent, no pushes until it lands, except a requested fix, which is re-pinned. If your RC session parks or drops, the coordinator restarts it (a relay to your thread, or `start_rc_session`); you never start another session yourself.

### Builder B (Mac)
- Old thread: none recorded. Current thread: cmsg_01VTPva3JGXrfvetgUvAWE7MVrjJCAw7HRqQ33DygSn2Qc; session cse_01MP1MQQduHXSJ11GiBAgEB4 (send_message form: session_01MP1MQQduHXSJ11GiBAgEB4).
- This is a Mac session: it cannot call fetch_thread or read the project folder. Read the repo copies with git show origin/master:docs/ops/handoff-block.md, docs/ops/board/ios-b.md and docs/product/decisions.md, and ask the coordinator to quote a message when you need his exact words.
- Handoff note: section "Builder B" in docs/ops/handoff-notes.md (repo; the Mac lead writes it there) and ops/rotation-handoffs.md. Until the outgoing lead has written it (open PRs with heads, frozen PRs, worktree, test.sh habits), ask the coordinator to paste it.
- Scope: Home, ask slot, BottomChrome, Settings, Review, Notes, Habits, Groceries, Recipes, Plan my day, Speak, Day log, Shutdown, link fetch, AI-1/AI-9, Kitchen week, Lists. The pin and install gates are Builder A's, not yours.
- Rules: G plus the Mac rules section above.

### Ops
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7M4sZwbno9N8W6eaaMTwMASs (Ops lead, rotated 8:56 PM Oct 17); old session cse_01RWgiTA9S2ayUkTS9R4LtQ2 (stood down).
- Fresh thread (rotated 9:15 AM PT Oct 18): cmsg_01VTPva3JGXrfvetgUvAWE7M1vz7FSmbHaEGzZghmdPzNf; session session_015Nf4mTXVRg1fwrCCGNxDtR.
- Retired (Ops, 9:15 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7M6dJfVeBsPFV1RHWEuVJhxU; session session_018JM7uZ2p9n5pHhe2U4JvC8.
- Handoff note: ops/rotation-handoffs.md, section "Ops team, 9:15 AM PT Oct 18" (the earlier "Ops lead, 8:56 PM PT Oct 17" section sits before it). Board: ops/board/ops.md.
- Rules for Ops (plus G): team update every 2 to 3 hours in the Ops thread, 3 to 4 plain lines (hold after 11 PM PT until 7:48 AM); never touch keys, never change permissions; anything that changes another team's workflow goes to the coordinator as a proposal first; docs PRs keep PIN and approval-gate lines byte-identical; delegate broad scans to read-only Sonnet subagents.

### Tess motion lab
- Old thread: cmsg_01VTPva3JGXrfvetgUvAWE7M6sP74VaZtcGZHEKYPWaqrp; old session cse_01DRmRTCUkFkcxiqBGpsU9Jw.
- Current thread (rotated 7:20 AM PT Oct 18, per the coordinator): cmsg_01VTPva3JGXrfvetgUvAWE7MNzW3MppYqcHMkU2ktrp7Dc; session session_01MBzPkXUpFe8fVpCvExsZUQ.
- Retired (Tess motion lab, 7:20 AM Oct 18; a message returns session_inactive): thread cmsg_01VTPva3JGXrfvetgUvAWE7MFM6C5LmJuscgTzpa8hF8Tv; session session_01HhkZiRUzaM6tsigSeaJYcY. Earlier line: Fresh thread (moved Oct 17, 2:15 PM PT, per Product): cmsg_01VTPva3JGXrfvetgUvAWE7MFM6C5LmJuscgTzpa8hF8Tv; session session_01HhkZiRUzaM6tsigSeaJYcY.
- Read the old chat with fetch_thread (oldest_first) or list_events on the old session; read a rule's exact words with fetch_messages on its id.
- Handoff note: ops/rotation-handoffs.md, section "Tess motion lab"; board ops/board/motion.md.
- Rules for Motion lab (plus G):
   - Motion: all 11 ideas plus the mouth, the same in every area; picks in docs/design/motion/tess-picks.md (Oct 16, 9:55 AM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MJPLyya4ray7YyPPbJKfYjr)
   - Never a diffused or faded Tess as imagery; he likes Tess as she is (Oct 17, 12:46 PM PT) (cmsg_01VTPva3JGXrfvetgUvAWE7MNEpdWKZTk52xHoonWPt9wC)

## Recent product rulings (pointers only; the words live in decisions.md, newest first)
Product's rulings are not copied into this file. Look these up by stamp in product/decisions.md (repo: docs/product/decisions.md) before asking:
- titleWords trim (private title list): 4:22 PM PT Oct 17 (Core #890), later trims 4:35 and 4:50 PM.
- G102 (private grocery row reads "Private item", one tap checks it): 5:40 PM Oct 17 (#883).
- #902 tie rule (equal timestamps: surer pantry state wins) and the Pantry backfill key pantryBackfilled: 4:32 PM Oct 17.
- Area hairline is decoration, no contrast bar (labels, key words and numbers keep 4.5:1): 5:58 PM Oct 17.
- Size words (small, medium, large, extra-large, whole, half) count like unit words in the first-line title rule: 6:00 PM Oct 17.
- G139 sticky Pantry mask (a cooked private recipe's ingredient reads "Private item" everywhere in Pantry): 6:10 PM Oct 17.
- G175 (no ochre in Pantry; state word is plain ink, areaLean only on caps labels and the index line): 6:39 and 6:43 PM Oct 17.
- Weight units are not money words ("2 pounds ground beef" never masks; no two-decimal price rule when a unit follows): 6:44 PM Oct 17.
- lastUsedAt accessor named by Core, staples and optional lines get it too; Research test count 116: 6:45 PM Oct 17.
Stamps from 1:41 PM onward are mapped to real PT by the CLOCK CORRECTION line in decisions.md.

## Not included on purpose

- Rules with a secret or from the key-check threads (see the Secret rule above); the memory file's Key and privacy section is the pointer.
- Product's rulings (day boundary, quiet hours, UNDO slot and so on): they live in decisions.md, newest first, so the block points there instead of copying them.
