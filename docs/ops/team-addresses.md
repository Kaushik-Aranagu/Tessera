# Team addresses and the one-page check (Ops, Oct 17)

One table of where each lead is now. Product keeps it current when a lead moves (Product is told first), then runs the check below. Mac leads (Core, Builder A, Builder B) are Remote Control sessions: they take relays from the coordinator, not direct sends. Sessions: send_message wants the `session_` form (swap `cse_` for `session_`). Threads are `cmsg_` ids.

| Team | Thread | Session |
|---|---|---|
| Coordinator | (project chat) | session_017NnYJ1KC3sgjujSxa7psmU |
| Product (rotated about 4:30 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7M4PS458UQbE4cTCBrUUs8ZG | session_01RBgnhXvCZZhM8wDwJqs5Rx |
| Kitchen | cmsg_01VTPva3JGXrfvetgUvAWE7M89s9yq77kzrHiVK6fDMbrZ | session_01WXUguo5FzJwPMPZohELbQR |
| QA (rotated 8:56 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7M4ssnyX2AFNBvTnuUMj5Y1K | session_016tTiZavEry3vudhWSeD15v |
| Design | cmsg_01VTPva3JGXrfvetgUvAWE7MPgmjA8hTn97dR7fqUQnzdE | session_015X5sbwjvU5TcEzjZg4LaQr |
| Research | cmsg_01VTPva3JGXrfvetgUvAWE7MPtwgew3oJ7cvhswUWWXx7k | session_017t1kiDAoSpJVo4NVP2BpZU |
| AI architecture | cmsg_01VTPva3JGXrfvetgUvAWE7MFkXAPBQ4sJbazgjECDVsu7 | session_011uM8VcURgDjjMD2eApQiCb |
| Tess motion lab (moved 2:15 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7MFM6C5LmJuscgTzpa8hF8Tv | session_01HhkZiRUzaM6tsigSeaJYcY |
| Core (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MHSnAXPPHMDNfPXTyZd75VX | session_01G3n7sadfakzAogtiqM742p |
| Builder A (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MUBkL1XKPxcemXhXnudvRpC | session_018k2u1aFREN7kbum42Nnf8Q |
| Builder B (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MVrjJCAw7HRqQ33DygSn2Qc | session_01MP1MQQduHXSJ11GiBAgEB4 |
| Ops (rotated 8:56 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7M6dJfVeBsPFV1RHWEuVJhxU | session_018JM7uZ2p9n5pHhe2U4JvC8 |

Retired (a message to these gets `session_inactive`): Ops thread cmsg_01VTPva3JGXrfvetgUvAWE7M4sZwbno9N8W6eaaMTwMASs, session_01RWgiTA9S2ayUkTS9R4LtQ2 (8:56 PM Oct 17); QA thread cmsg_01VTPva3JGXrfvetgUvAWE7MCy1jQu1AAK4DaoaMNk6LTX, session_01LivGht4DsiiWp8zDyRGFtz (8:56 PM Oct 17); Kitchen session_01TRh7xwt9UhB98fN8BteVgs (thread cmsg_01VTPva3JGXrfvetgUvAWE7MJ6x15H146i8Ubn1hrFjuEJ, rotated 6:45 PM Oct 17); QA session_011G5V3Hxc6iNaYxFTxRs5Eg (thread cmsg_01VTPva3JGXrfvetgUvAWE7MCGo649SeUBPdKzkV1rnwTw); Product cse_01STY2yX8fnVksnqnnPkcBQG (thread cmsg_01VTPva3JGXrfvetgUvAWE7MRLK2oiTKs6EG9Uu5qfT6M1); QA cse_01SPUv55gtzktZjCda2KjMoW, cse_01M6UTgTZa2bJBa8bLiyL3rv, cse_016hxroCB7KSo9FQG2RL5PdR; motion lab cse_01DRmRTCUkFkcxiqBGpsU9Jw; old coordinator session_016gJ8tAQxkZ4HmhA3ukc6ok.

## The check (about two minutes, after any move)
1. For each retired id above, run `grep -rl "<id>" /mnt/project-files/tessera /tmp/claude/memory/team/silo --include=*.md`.
2. Every hit must be a line that says "retired" or "old" (handoff-block.md and rotation-handoffs.md do). Any other hit is a stale address: fix that line to the table's current id.
3. For each new id in the table, grep it the same way and confirm the team's board header, its handoff section and the memory thread-ids file name it.
4. Add the move to the table and the retired list in the same edit, and send Ops the new ids so the repo mirror of handoff-block.md follows.

Last run (Oct 17, 9:25 PM PT, Ops): after the 8:56 PM rotations the retired-id grep found stale non-retired lines in memory design-thread-ids.md line 13 (QA id; Product told) and rotation-handoffs.md line 122 (fixed). memory team-addresses-pointer.md fixed (Ops, QA, Kitchen). Earlier run (2:30 PM): stale lines in design-thread-ids.md, tess-motion-lab.md and ai-arch-routing.md (old motion lab and coordinator ids) were reported to their owners; not re-checked.
