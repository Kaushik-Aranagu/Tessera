# Team addresses and the one-page check (Ops, Oct 17)

One table of where each lead is now. Product keeps it current when a lead moves (Product is told first), then runs the check below. Mac leads (Core, Builder A, Builder B) are Remote Control sessions: they take relays from the coordinator, not direct sends. Sessions: send_message wants the `session_` form (swap `cse_` for `session_`). Threads are `cmsg_` ids.

| Team | Thread | Session |
|---|---|---|
| Coordinator | (project chat) | session_017NnYJ1KC3sgjujSxa7psmU |
| Product (rotated about 4:30 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7M4PS458UQbE4cTCBrUUs8ZG | session_01RBgnhXvCZZhM8wDwJqs5Rx |
| Kitchen | cmsg_01VTPva3JGXrfvetgUvAWE7MJ6x15H146i8Ubn1hrFjuEJ | session_01TRh7xwt9UhB98fN8BteVgs |
| QA (rotated about 4:30 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7MCy1jQu1AAK4DaoaMNk6LTX | session_01LivGht4DsiiWp8zDyRGFtz |
| Design | cmsg_01VTPva3JGXrfvetgUvAWE7MPgmjA8hTn97dR7fqUQnzdE | session_015X5sbwjvU5TcEzjZg4LaQr |
| Research | cmsg_01VTPva3JGXrfvetgUvAWE7MPtwgew3oJ7cvhswUWWXx7k | session_017t1kiDAoSpJVo4NVP2BpZU |
| AI architecture | cmsg_01VTPva3JGXrfvetgUvAWE7MFkXAPBQ4sJbazgjECDVsu7 | session_011uM8VcURgDjjMD2eApQiCb |
| Tess motion lab (moved 2:15 PM Oct 17) | cmsg_01VTPva3JGXrfvetgUvAWE7MFM6C5LmJuscgTzpa8hF8Tv | session_01HhkZiRUzaM6tsigSeaJYcY |
| Core (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MHSnAXPPHMDNfPXTyZd75VX | session_01G3n7sadfakzAogtiqM742p |
| Builder A (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MUBkL1XKPxcemXhXnudvRpC | session_018k2u1aFREN7kbum42Nnf8Q |
| Builder B (Mac) | cmsg_01VTPva3JGXrfvetgUvAWE7MVrjJCAw7HRqQ33DygSn2Qc | session_01MP1MQQduHXSJ11GiBAgEB4 |
| Ops | cmsg_01VTPva3JGXrfvetgUvAWE7MDeYL2K6E16xSrmKNzZoVJF | session_01RWgiTA9S2ayUkTS9R4LtQ2 |

Retired (a message to these gets `session_inactive`): QA session_011G5V3Hxc6iNaYxFTxRs5Eg (thread cmsg_01VTPva3JGXrfvetgUvAWE7MCGo649SeUBPdKzkV1rnwTw); Product cse_01STY2yX8fnVksnqnnPkcBQG (thread cmsg_01VTPva3JGXrfvetgUvAWE7MRLK2oiTKs6EG9Uu5qfT6M1); QA cse_01SPUv55gtzktZjCda2KjMoW, cse_01M6UTgTZa2bJBa8bLiyL3rv, cse_016hxroCB7KSo9FQG2RL5PdR; motion lab cse_01DRmRTCUkFkcxiqBGpsU9Jw; old coordinator session_016gJ8tAQxkZ4HmhA3ukc6ok.

## The check (about two minutes, after any move)
1. For each retired id above, run `grep -rl "<id>" /mnt/project-files/tessera /tmp/claude/memory/team/silo --include=*.md`.
2. Every hit must be a line that says "retired" or "old" (handoff-block.md and rotation-handoffs.md do). Any other hit is a stale address: fix that line to the table's current id.
3. For each new id in the table, grep it the same way and confirm the team's board header, its handoff section and the memory thread-ids file name it.
4. Add the move to the table and the retired list in the same edit, and send Ops the new ids so the repo mirror of handoff-block.md follows.

Last run (Oct 17, 2:30 PM PT): ops/board/motion.md already marks the old lab retired (fine). Stale: memory design-thread-ids.md (old motion lab session), memory tess-motion-lab.md (old session and thread ids), memory ai-arch-routing.md (old coordinator session). Owners: Product (design-thread-ids), Motion lab, coordinator.
