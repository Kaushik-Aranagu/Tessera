# Living colours: how the rule table learns from his day

For: Core (the rule table, after WeekFacts), AI architecture (the `soulPalette` job), Design (48's guide). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Reads Design 48 (`/mnt/project-files/tessera/design/living-colours.md`), `docs/ai/architecture.md` section 9 and master 8469e3d.

**In one line:** the phone already holds every signal the picker needs; "learning" means four of Design's fixed bands bend to his own clock and habits, plus a no-repeat rule. Claude's once-a-day pick is worth most as a choice among the candidates the rules allow, made after quiet hours end and not at 04:00.

## 1. Signals the phone already has

| Signal | Where on master | Used for | Sent to Claude |
|---|---|---|---|
| Part of day, weekday, season | phone clock, `TesseraDay` (4 AM day) | Design's bands | as words ("morning", "Thu", "autumn") |
| Rest day | `RestDay.swift`, `restWeekday` setting | Orchard | yes |
| A best today | `TrainingLedger.records(for:)`, the set's "was PR when logged" flag | Ember | yes or no only |
| Workout running, paused or done | `ProcessTable` | the idle gate; "first workout finished" change | kind and state only |
| Cook running | `Cooking.swift` via `ProcessTable` | Kiln | kind only |
| Planned cook today | **not on master yet** (the planned-cook fact is part of Core's AI-1 HomeLines) | Kiln | when it exists |
| Look, light or dark | `ThemeStore` pair | pigment set | yes |
| His usual training slot | AI-7 noticed lines (Sunday 04:00) | evening band start | the noticed line |
| His first and last write of the day | op log `zone` times | morning and late-night bands | **never** (it is a sleep proxy) |
| FORGET or "keep her colours" | AI-9 page, later ask | the only feedback he gives | as "pinned" |

Never read: health, body weight, notes, money, people, places, calendar titles. Mood is not a signal, and nothing he does makes her look sad.

## 2. What "learning" means here (all on the phone, no model)

1. **Morning starts when his day does.** Design's band is 04:00 to 11:00. Use the median time of his first write over the last 14 days instead, kept between 05:00 and 10:00. If he is up at 9, the 04:00 pick holds Today and Lagoon arrives at 9 rather than in his sleep.
2. **Evening starts at his usual slot.** If the noticed lines say "usually trains 6 to 8 pm", Kiln's lean starts at 18:00. If he trains at 20:00, it starts at 20:00. If nothing is noticed yet, Design's 18:00 holds.
3. **Late night follows his last write,** the median over 14 days, kept between 22:00 and 01:00. See conflict K1.
4. **No repeat for more than three days.** Each band has two leans (morning: Lagoon or Aurora). If the same palette has shown in the same band 3 days running, take the other one. This answers architecture section 9's "predictable after a week" doubt without a model.
5. **A pin is a hard no.** A palette he FORGETs is not picked again for 30 days. "Keep her colours" pins Today until he unpins.

All five reduce to small numbers recomputed at Sunday 04:00 alongside the noticed lines. They are unit-testable from the fixtures in section 5.

## 3. What Claude's once-a-day pick adds

Honestly, little at 04:00. Nothing has happened yet, so the pack is yesterday's lines and today's plan, and the rules already read both.

Proposal: the phone computes the day's **candidate set** (one to three palettes it allows, for example `[Kiln, Lagoon]` on a cook day morning), and Claude picks one of them plus the two nudges. It runs **once, at the first idle moment after quiet hours end (07:00)**, not at 04:00.

- Claude can't paint Ember without a best or Orchard on a training day. Truth holds by construction, the same way the Home lines' numbers do.
- What it adds is the judgement the rules can't make: reading the last 7 recent lines and the week's shape ("third push day this week, a cook tonight") into a nudge, and varying the warmth so a run of similar days doesn't look the same.
- Cost stays at about $0.0002 a call and at most 31 calls a month (architecture section 9).
- `proposeSoul` gains one rule: `palette` must be in `candidates`. The phone refuses any other name.

## 4. Conflicts between Design 48 and architecture section 9 (Design and AI decide; defaults given)

- **K1, late night falls in quiet hours.** Design's guide picks Aurora from 23:00, but its own cadence forbids any change from 23:00 to 07:00 except at 04:00. As written, Aurora can never arrive. Default: the evening pick made before 23:00 carries Aurora's weight −0.1 from 22:00 when his last-write median says he is usually up past 23:00. Otherwise the palette doesn't change at night.
- **K2, a crossfade or the pooling bloom.** Section 9 says the palette crossfades over about 2.8 s. Design 48 says "Not a crossfade": each dab pools its pigment 120 ms apart and dries over 2.8 s. Default: Design's bloom, since motion is Design's. Section 9 should drop the word.
- **K3, the order when leans collide.** The guide doesn't say what wins. A rest day where he cooks? A best on a cook evening? Default order: a best (Ember) > rest day (Orchard) > cook (Kiln) > time of day. Season nudges always apply. A look change pauses everything for 2 h.
- **K4, when Claude runs.** Section 9 says 04:00. Default here: first idle after 07:00, as in section 3. The 04:00 pick stays the rules'.
- **K5, three changes a day.** With a 2 h gap, the morning, a best and the evening already make three. A day with a best before noon and a cook at 18:00 has no change left for the evening band. Default: Ember holds for the rest of the day (as the guide says), so the evening lean is skipped and no change is lost.

## 5. Day-shape fixtures for Core's unit tests

The times are his day. "Pick" lists each change with its time, in order.

| # | Day | Expected picks |
|---|---|---|
| L1 | Thu, up 7:10, Push A at 18:20, no best | 04:00 Today; 07:10 Lagoon +0.1 weight; 18:00 Kiln +0.1 warmth |
| L2 | Same, bench best at 19:05 | 04:00 Today; 07:10 Lagoon; 19:05 Ember (once idle after the workout) |
| L3 | Sunday rest day, cooks chili at 17:00 | 04:00 Orchard; 17:00 stays Orchard (rest beats cook, K3) |
| L4 | Sat, up 9:30 | 04:00 Today; 09:30 Lagoon |
| L5 | Morning lean shown Lagoon 3 days running | day 4, 07:10 Aurora +0.1 weight |
| L6 | He FORGETs Kiln on Tue | no Kiln until 30 days later; evening takes Today +0.1 warmth |
| L7 | Look change at 12:00 | 12:00 Today on the new look; 14:00 the day's pick |
| L8 | Workout live at 18:00 (the evening band) | the change waits for idle; dropped if not idle by 18:30; the next moment picks |
| L9 | Usually trains 20:00 (noticed) | evening lean at 20:00, not 18:00 |
| L10 | Up past midnight most nights (last write ~00:40) | 22:00 Kiln carries weight −0.1 (K1); no change after 23:00 |
| L11 | Switch on, Claude returns Ember on a day with no best | refused (not in the candidates), the rules' pick stays, nothing visible |
| L12 | Offline all day | rules only, same as L1; no visible failure |

## 6. Next

- Design: K1, K2, K3 and K5.
- AI architecture: K4 and the candidates rule.
- Core: builds the five learned numbers with the rule table after WeekFacts.
- Builder A: nothing new.
