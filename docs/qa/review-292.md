# QA review 292: ink line sheen and bead fix (#292)

PR head a8030d9 on base 7001578: Paint.swift (+58/-28) plus the recording `docs/recordings/29-ink-line-sheen-bead.mp4`. Static review plus a frame-by-frame read of the recording; no toolchain or simulator here. Base check: Paint.swift hasn't changed on master since 7001578, and a trial merge with master is clean. No deletions.

**Verdict: PASS on the code. The crash check still needs one run on the simulator, which I can't do from here (H1).**

## What it closes
- **review-278 I1:** the sheen and the bead now play. The old code set start and end values in one transaction, so SwiftUI coalesced them and nothing showed. Both now run through `keyframeAnimator`, keyed to a counter: `releases` for the sheen (Paint.swift:332-345) and `completions` for the bead (:349-363). A new trigger value restarts the run from its first keyframe, so rapid taps restart the sheen instead of stacking. At rest, both `Sheen()` and `Bead()` start at alpha 0 (:493-502), so nothing shows before the first trigger.
- **The crash fix:**
  - The bead's size is `max(value.radius, 0) * 2` (:351). Every keyframe is a `LinearKeyframe` with easeOut or easeInOut, and neither curve overshoots, so the radius stays within 0-7 and the frame can't go negative or NaN. That was the `CALayer setBounds` exception.
  - The sheen moves only by `offset` and `opacity`, never its frame.
- **Design M1:** a hold's bead and medium haptic land on completion, and its action fires 200 ms later (:425-435). Taps and Reduce Motion fire at once. In the recording the bead shows at the tip of "Log set" for about 2 frames at 8 fps before the page moves on (about 22.5 s in), so the page no longer swallows it.
- **L1/L2:**
  - The no-op `.opacity(holding ? 1 : 1)` is gone.
  - The doc comment at :228-232 now describes the ink line and bead.
  - The `onWorkoutGround` comment matches one base across the app.
- **Bead on taps:** a tap also bumps `completions`, but the bead's opacity is `isTap ? 0 : alpha` (:352), so taps never show one.

## Recording
- 590×1282 at 60 fps (2690 frames, 44.8 s). Porcelain only.
- It shows Now → workout, the hold on Log set, rest, Skip rest, and the next set.
- The hold refill and the bead are visible. I couldn't see the sheen on a tap in the frames. Skip rest swaps the page on release, so its sheen runs on a key that is cross-fading out (see L2).

## H1 (needs a Mac run, not a code change): the crash paths and Obsidian
The coordinator asked for hold-then-tap, Skip rest and rapid taps on the workout keys, in both looks. The recording has no Obsidian pass and no rapid taps. From the code, I see no path to a negative or NaN frame, but the earlier crash was only seen at runtime.
- **Ask:** the iOS build or Builder A thread runs these on the simulator against a8030d9:
  - Hold Log set, then within 200 ms tap Skip rest or +15.
  - Tap Skip rest 5 times fast.
  - Tap Log set, and the tap words, 10 times fast.
  - Do all of it in Porcelain and in Obsidian (`-theme obsidian`).
- **Pass:** no crash, and the bead and sheen are visible on the dark ground.

## Lows
- **L1:** the 200 ms delay runs in an unstructured `Task` (:432-435). If the key leaves the screen in that window, the action still fires. That's intended (the hold completed), but a second hold on another key in the window could make two actions arrive out of order. That's unlikely, because a hold takes `duration`. No change needed; worth noting if a hold ever ends a workout.
- **L2:** the sheen is only seen on taps that leave the key on screen. On a tap that swaps the page, like Skip rest, it plays on a key that is cross-fading out. For Design to decide whether that's fine.
- **L3:** the keyframe runs are guarded by `!reduceMotion` but don't go through `MotionPolicy` (CLAUDE.md: "Animate only through MotionPolicy"). The behaviour is right (no motion with Reduce Motion on). A one-line note at :326 saying the guard is the policy would keep the rule readable.
