# QA review: #446 a refused hold settles Tess to rest (Builder B)

Head checked: `159a629` (branch ios/refused-hold, cut from master 5af8f2c). `git merge-tree` against master 5601a24 is clean. Static review only; Builder B reports `scripts/test.sh` app tests green (140).

**Verdict: PASS.**

## What changed
- `BottomChrome.speak(hold:)`, refused-hold branch (Features/Command/BottomChrome.swift:590-593): emits `.heardNothing` before `say(...)`.
- The router's `.heardNothing` closes the surface (it was already closed for a hold) and settles to `rest`; a Done in flight still plays out (SoulRouter.swift:79-83).
- `say` then emits `.lineShown`. That timer settles nothing while she's listening (SoulRouter.swift:104-105), which was the bug: a refused hold left her listening behind the line. She is now at rest when the line shows, and the 4 s timer is a no-op at rest.
- The tap path is unchanged: the refusal card shows on the open surface, and she stays listening with it, which is the rule for an open surface.

## Tests
- `aRefusedHoldSettlesToRest`: speak(hold) → heardNothing → lineShown leaves `.idle` with the surface closed. The router is pinned at 12:00 (router(hour:), SoulRouterTests.swift:9-14), so the night `.resting` can't flip it.
- `theLineAloneNeverSettlesAListen`: documents the old bug at the router level (listening survives a line's 4 s).

## Lows (non-blocking)
- L1: the tests drive router events by hand. Nothing checks that BottomChrome itself emits `.heardNothing` on a refusal; a UI test with a denied mic can't run on the simulator anyway. It's a one-line call, so a read is enough.
- L2: `aRefusedTapKeepsTheSurfaceOpen` never sends a refusal, so it is true by construction (it only checks speak(hold: false) after tessOpened).
- L3: `theLineAloneNeverSettlesAListen` waits 4.3 s of real time, which adds to #402 L4 (router tests on real time, about 12 s → 16 s). An injected sleeper would fix both together.
