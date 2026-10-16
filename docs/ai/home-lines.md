# Home lines: the line sheet

For: Design (aligns with `docs/design/home-first-review.md`, item 41), Builder B, Core. Owner: AI architecture team.
Date: Oct 16, 2026 (Pacific). Replaces the row-line grammar in `first-features.md` section 1 where they differ.

Design 41 fixed the frame: a thing gets one hero line (the thing and its state), one context line above it (the time), and Next rows are titles and times only. This sheet says what words go in those slots, who writes them, and what Tess may and may not say.

## 1. The slots

| Slot | Form | Who writes it | Budget |
|---|---|---|---|
| **Hero** | the thing and its state: "Push A, paused at bench", "Push A done", "Push A", "Chili, step 3", "Rest day" | **Rules only, always.** It names the object and must be exact | Hero 56 on one line, else Title 44, else Title 44 on two lines (Design 41 rule 2) |
| **Context line** (above the hero) | the time, in words: "paused 21 min ago", "this evening", "today", "done at 7:40 pm" | Rules write it; **Claude may reword it** when the switch is on | Body 21, one line, 6 words, 32 characters; if the rules line doesn't fit, its words shorten ("paused 21 min") |
| **SO FAR** (one tap down, the thing's page) | one sentence of prose: "1 exercise, 2 sets, 1 new best." | Rules write it; **Claude may reword it** | one sentence, 14 words, 80 characters; wraps, never cuts |
| **Next rows** | title as he wrote it, time on the right | Rules only; titles are his words and wrap to two lines | Design 41 rule 2 |
| **Day label** | "Thursday night" | Rules only | fixed |

So Claude touches two slots on Home: the context line and the SO FAR sentence. Everything that names a thing or carries a count is the phone's.

## 2. What the context line may say

The context line is the time, with room for one aware touch when it earns its place. Claude may:

- keep the time and add what the facts or memory say: "paused 21 min ago", "this evening, your usual slot", "done at 7:40, a bench best", "first push day in 9 days", "tonight, a cook day";
- drop the time only when the state makes it plain ("Rest day" needs no time; a done workout may say "a bench best" alone if "done" is in the hero). **Digit rule (AI-5 C-checks):** the clock time may drop on a done item; every other digit in the rules context survives, and no digit appears that isn't in the item's `numbers`.

It may not:

- name a weight, a rep, a set count or any number not in the item's `numbers`;
- say anything the pack doesn't hold (no "after a long week" unless the facts say it);
- grade him or the day: never missed, behind, late, again, only, still, streak, should, finally;
- mention sleep, energy, health, body, money, people or places;
- use "!" or emoji, greet, praise or apologise;
- exceed 6 words or 32 characters; at Dynamic Type sizes the slot wraps, never cuts.

The hero's form sets the pattern the context line answers:

| State | Hero (rules) | Context line, rules | Context line, Claude may say |
|---|---|---|---|
| planned, morning | Push A | today | today, after work / today, your usual slot |
| planned, evening | Push A | this evening | this evening, your usual slot |
| running | Push A, bench set 3 | now | now / set 3 is up |
| paused | Push A, paused at bench | paused 21 min ago | paused 21 min ago |
| done | Push A done | done at 7:40 pm | a bench best / done at 7:40 pm / first in 9 days |
| done, no sets | Push A, no sets | this afternoon | this afternoon (rules only; Claude never comments on an empty workout) |
| rest day | Rest day | Sunday | Sunday / Sunday, a cook day |
| cooking | Chili, step 3 | paused 8 min ago | paused 8 min ago |
| shopping | Groceries, 4 left | at the store | 4 left / at the store |
| planned cook | Tacos tonight | 2 to buy | 2 to buy (count from the phone; see Kitchen's note in `first-features.md` section 3) |

## 3. When the rules line shows

Always first. The rules line draws at once on every launch and every change. Claude's words replace it only when all hold: the switch is on, online, under the cap and below its 80% line, not in a live workout, the pack hash is new (else the cached words show), and the line passes every check in section 2 on the phone. Offline, capped, switched off, in demo, or on any failed check: the rules line stays, and nothing visible happens.

## 4. How a Claude line arrives (for Design)

Proposal, Design's call: the rules line is already on screen; when Claude's words differ, the line redraws as wet cobalt and dries to ink over about 700 ms through `MotionPolicy`, the same drying every Tess word already uses; identical words never redraw. No mark at rest. Reduce Motion: a crossfade.

## 5. Fixtures

The twelve rows in `first-features.md` section 1b stand, re-slotted: the "good Claude line" column is now the context line, with the hero fixed by rules. Example: H1 hero "Push A done", context "a bench best"; H5 hero "Legs A", context "this evening, your usual slot"; H6 ✗ "still on for today" is caught by the banned list.

## 6. Owners

- **Core:** `HomeLines` lens (hero, rules context, SO FAR, licensed numbers per item), the `homeLines` job and checks (AI-1, AI-4).
- **Builder B:** the slots and step-down forms (Design 41), the swap-in and drying (AI-4).
- **Design:** confirm section 4, and the exact wording of the rules lines in the table above.
