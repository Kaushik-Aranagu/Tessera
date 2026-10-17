# QA review: #467 a waiting ask goes when the chrome leaves (Builder A, QA #402 L5)

Head checked: `ca22759` (1 commit, from master). `git merge-tree` against master 7e8a203 is clean. Static review only; Builder A reports 443 engine and 137 app tests green.

**Verdict: PASS.**

- **The fix.** `.onDisappear(perform: askLeft)` (BottomChrome.swift:112). `askLeft` (:535-542) clears `setAsk` and `liftAsk` and emits `.askAnswered` when one was open. The router then clears `isAskWaiting` (SoulRouter.swift:141-142), so `refusesLens` no longer sticks. The event is sent directly, because the `onChange` at :103 won't run once the view is gone. That matches §14's `askLeft`. Nothing happens when no ask is open.
- **When it fires.** BottomChrome is mounted once, in RootView.swift:37, over the NavigationStack. Pushing pages doesn't remove it. It leaves only when the root is covered or torn down; in practice that's the live workout's full-screen cover (UIKit removes the presenting view, so SwiftUI calls `onDisappear`).

**What he sees (Design):** one small change. A set-count or dated-lift ask showing beside the soul on Home ("2 × 10: 2 sets, or 2 kg?") now goes when he opens the live workout. Before, it could still be there when he came back. That follows the house rule that an ask can't wait off screen. There are no new lines.

## Lows (non-blocking)
- L1 (pre-existing, now more visible): the capture engine keeps its `pendingAsk` and `pendingDatedLift` (TessCaptureEngine.swift:34-45, 65-68). The chrome drops the ask, but the next phrase is still checked against it. So "kg", "sets" or "log", said after he left, can answer an ask he no longer sees and log a set or a dated lift. The fix is a `dropAsks()` on `TessCaptureEngine`, called from `askLeft`. Owners: Core for the API, Builder A to call it. This is in the same family as #438 I5 and the Tess review's T2.
