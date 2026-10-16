# QA review: #469 Plan my day guards (Core, QA audit A3, A4, A6)

Head checked: `c137908` (1 commit). `git merge-tree` against master is clean. Static review only; Core reports 452 package and 149 app tests green.

**Verdict: PASS.**

- **A3.** `ClaudePlanWording.allowed` has no default now, and `init` takes `allowed:` (PlanWording.swift:427-445). A caller that forgets the switch won't compile, so it can't send a plan.
- **A4.** `PlanPack.packTitle` (:41-46) applies `isPrivate` = `SecretWords.mentions` or `PrivateFacts.isWalled`. A private task goes as "task". An event goes as "busy" when it's private or when event titles are off.
  - The same screen filters all-day items (:118) and `otherNames` (:164).
  - `titleWords` is built from the packed titles and drops "task" and "busy" (:174-177). So the V11 and V12 checks never license a number or a health word that came only from a private title.
  - Claude can't echo "2100" from "pay rent 2100", and it never sees the title.
- **A6.** `reserve` refuses `estimateNano <= 0` (ClaudeKey.swift:132-133). A model with no price row can't call. Every current caller's estimate is above 0: the key check's 1-token fallback is about 1,600 n$.

## Lows (non-blocking)
- L1 (Design, once Builder B wires Plan my day): Claude's ghost line for a private block is still shown as that block's line (`applying`, :379-393). It may read "Start with the task." beside his real title "Reset bank PIN". It's safe, just odd wording. Options: show the rules line for private blocks, or let Design rule on it.
- L2: the unpriced-model refusal surfaces as the cap line ("Claude paused until Nov 1."), which isn't what happened. A dev-only failure, so a log line is enough.
- L3: CA4 is still open. `PlanPack.init` defaults `includesEventTitles: true` (:52) while his Oct 22 call is pending. Builder B must pass it explicitly, or Core flips the default.
