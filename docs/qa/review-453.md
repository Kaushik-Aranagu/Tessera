# QA review: #453 Tess working, tess-motion.md §5 (Builder A)

Head checked: `0d5cd07` (1 commit, branched from bb7f082). `git merge-tree` against master 20f0a16 is clean. Builder A reports `scripts/test.sh` all green (443 engine, 144 app). Static review, plus a contact sheet of docs/recordings/49-tess-working-obsidian.mp4 (10.3 s, 1206×2622, 60 fps).

**Verdict: PASS.**

## The four checks
- **`-soulScript work|workFail` is simulator only.** `SoulRouter.runScript` (SoulRouter.swift:237-248) reads `LaunchFlags.value(after: "-soulScript")`. That returns nil off the simulator, so the replay can never run on his phone. It drives the router with `.askClaude` and then `.claudeDone` or `.claudeFailed`, the same events the app sends. The script is called once, from `AppModel.init` (AppModel.swift:126).
- **No raw launch-argument reads.** The only `ProcessInfo` use is `isLowPowerModeEnabled` (TessSoul.swift, `onChange(of: mode)`), which reads a device state, not a launch argument. That is what §13 asks for.
- **The merge is clean.** It merges into current master 20f0a16. I couldn't fetch 7334c8b7 by that name; please re-check if master moves before the merge.
- **No view sets a mode.**
  - `.working` and `.gathering` are set only inside `SoulRouter.handle`: `.askClaude` leads to `settle(.working)`, and `.claudeDone` or `.claudeFailed` leads to `gather(thenDone:)`.
  - The 820 ms gather is the router's own `timer`.
  - `TessSoul` keeps only a view-local overlay clock (`work`: split and gather times), derived from `mode` in `onChange`. Its one sleep drops the overlay a second after the gather and moves to 30 fps after 20 s. Neither touches the router.
  - The live corner never works: `page != .home` gives `.thinking`, and `theLiveCornerNeverWorks` covers it.

## The router rules
- Work runs on under `.closed`, `.heardNothing`, `.appeared`, `.foregrounded`, `.returnLine`, `.committed` (which brightens only), the line's 4 s and local thoughts (`.sent`, `.heard`, `.liveAsk`).
- His touch (`.speak`, `.tessOpened`) cuts it.
- A second ask joins the running one.
- An ask during a Done queues `.working` behind it.
- A failure gathers with no Done.
- A Done begins only when the lights land (`doneBeginsOnlyWhenTheLightsLand`).
- The only emitter in the app is the key check (ClaudeSection.swift:332), which always ends in `.claudeDone` or `.claudeFailed`, so nothing leaves her working.

## Clip
Twelve frames at 1.5 fps show the rest, then the split, the constellation beside her (no straight slides), the gather, and the Done bloom at the end. The Home page under her doesn't change. Design passes the motion.

## Lows (non-blocking)
- L1, latent: `.backgrounded` cancels `timer` (SoulRouter.swift:162-163). If it lands during the 820 ms gather, she is stuck in `.gathering`. While stuck:
  - `isWorking` stays true, so `.foregrounded`, `.appeared` and the line timer never settle her.
  - `.claudeDone` returns early (`guard mode != .gathering`).
  - Local thoughts never show thinking.
  - Only his touch or a `playDone` event frees her.

  Nothing emits `.backgrounded` on master yet. Whoever wires it (with #402 L6) should make `.backgrounded` finish or settle a gather, not just cancel it.
- L2: under Reduce Motion the `TimelineView` stays unpaused for the whole work (`paused: reduceMotion && work == nil`), though the frame is still after its 200 ms crossfade. It ticks at 60 fps for nothing. Pausing it once `sinceSplit > 0.2` and before the gather would save the frames.
- L3 (pre-existing, not this PR): in the clip, the Next row "Read · Designing Data-Inten…" truncates with "…". This is the #366 L4 family; Builder B owns it.
