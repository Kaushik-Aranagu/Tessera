# QA review: #558 motion idea 2 "she wakes with him" + gather queue (Builder A)

Head reviewed: 02c59a0 (cut from #403's merged head; merge-tree on current master clean). Static review. **PASS**

- Wake: the first foreground of his 4 am day wakes her once (SoulRouter.swift:221-241). "woke on" goes in
  UserDefaults, so a relaunch the same day doesn't repeat it. A live workout, Speak or a waiting ask skips the wake,
  but the day still counts. `-freshDay` is read only through LaunchFlags. The timing is pure (SoulWake.swift): shut
  1 s, open over 400 ms, stretch at 1.5 s, one blink at 3.4 s, all over by 4 s. Under Reduce Motion or Low Power
  there is no stretch and the lids crossfade over 200 ms (TessSoul.swift:159, :172).
- Scene phase: `.foregrounded(underLive:)` on active and `.backgrounded` on background (TesseraApp.swift:85-89). This
  closes the settle half of R7 on #403: `.backgrounded` → `settle(rest)` (SoulRouter.swift:196-198) now runs.
- Gather queue: an ask during the gather queues (SoulRouter.swift:165) and starts when the lights land
  (SoulRouter.swift:257-264), after Done or in place of rest. That matches the lab note on #453.
- Tests use their own UserDefaults suites (SoulWakeTests.swift:22-24). No TesseraCore, Catalog or migration change.
  The ScaleTests budget miss is the known flake on Core's board and isn't touched here.

Lows
- **R1** AppModel's init sends `.foregrounded(underLive: false)` (AppModel.swift:134) before the scene phase can say
  a live workout is on top. If he relaunches mid-workout, the day's wake is spent on the hidden Home soul. It's
  harmless (he never sees it), but tomorrow's first open is then the only one that wakes her. Passing
  `isWorkoutPresented` there, or letting the scene phase alone send it, would keep it.
- **R2** `.backgrounded` settles to rest even while she works on a Claude ask. On return the answer's Done may still
  play. Builder A should check it in the motion clip. Not blocking.
