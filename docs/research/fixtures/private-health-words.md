# Body words sweep (board item AO)

For: Core (PrivateFacts), QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

HW19 in [`habits-weight-week.md`](habits-weight-week.md) found that `feeling sick, no gym` still reaches Claude after
#451 and #471. Product decided "sick", "unwell" and "feeling sick" join PrivateFacts on the next build
(`docs/product/decisions.md`, Sick days). This sweep looks wider: everyday health and body phrasing Kaushik types or
says, what `PrivateFacts.isBodyShaped` does with each on master today, and the smallest word and rule changes that wall
the leaks without walling his gym slang, his kitchen or his work idioms.

Builds on [`money-body-wall.md`](money-body-wall.md) (W2 to W4, MB15 to MB40). Every phrase below is made up. The board
line for AO names `fixtures/private-health-words.md` with 60 or more phrases for Core 0ac; this file is that sweep,
under the name the coordinator asked for.

## 1. How this was traced

- Master is `origin/master` at 017a94e (PrivateFacts is unchanged since #451 and #471). The code is
  `TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift` (`symptoms` :55-58, `vitals` :49-50, `medicines` :51-54,
  `isBodyShaped` :64-89).
- "Master today" is the result of a small Python port of `words`, `isTraining` and `isBodyShaped`, kept outside the
  repo. The port also runs the existing wall rows: every row in `PrivacyFollowupTests` and `MoneyWallTests` comes out
  as the Swift tests expect. The trace column names the set that fired, or why nothing did.
- None of the 126 phrases is money-shaped (no currency sign, no money word with a number, no two-decimal amount), so
  `isWalled` equals `isBodyShaped` for every row.
- "With §4" is the same port with the words and rules of sections 4 and 5 added. It walls every "yes" row and none of
  the "no" rows, and every existing wall and pass test row still holds.

What a wall does on master, so the cost of a wrong answer is clear:

- **Leak** (should be walled, isn't): when the grammar misses, the router lets Claude run if "Tess asks Claude" is on
  (`TessModel.swift:77-79`), the inbox may keep it offline (`TessInbox.swift:30`), and a task title with the word rides
  in Plan packs (`PlanWording.swift:38`).
- **Over-wall** (walled but shouldn't be): the grammar still runs first, so a task or grocery it reads is unharmed. A
  grammar miss becomes a private note instead of going to the model chain (`TessGrammar.swift:141`, `parseBodyFact`
  :153-157), and a task title goes into Plan packs as "task". Safe, but "oven temp 425" turns into a private note.

## 2. Counts

| Verdict | Rows | Where |
|---|---|---|
| ok | 47 | 12 walled correctly today, 35 traps and plain rows that stay plain today |
| leak | 69 | Every illness word but sore, fever and aches, all mental health, physio, injuries named without a hurt or sore word, period, tiredness, diet, the no-number weight questions |
| over-wall | 10 | BW113 to BW115 (fever and headache idioms), BW117 to BW123 (`resting`, `hr`, `pulse`, `temp`, `tablet` with any number) |

The 10 over-walls are new findings: they come from words already on master, not from HW19. The worst for daily use
are BW117 (`resting 90 sec between sets`, a rest timer phrase) and BW123 (`charge the tablet 2pm`, where the clock
time counts as a number because `isBodyShaped` never strips times).

## 3. Rows

"Wall?" is the proposed answer. Decisions taken here are marked in "Why" and listed again in §6.

### Illness

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW1 | `feeling sick, no gym` | yes | HW19. A sick day is a health fact (decisions, Oct 16) | false: no word in any set | **leak** | walled |
| BW2 | `sick today` | yes | Health state | false: no word in any set | **leak** | walled |
| BW3 | `i'm sick, skip push` | yes | Health state | false: no word in any set | **leak** | walled |
| BW4 | `sick day tomorrow` | yes | Health state, planned | false: no word in any set | **leak** | walled |
| BW5 | `feeling unwell` | yes | Named by Product with "sick" | false: no word in any set | **leak** | walled |
| BW6 | `feel ill, going home early` | yes | Health state | false: no word in any set | **leak** | walled |
| BW7 | `think i have the flu` | yes | Illness | false: no word in any set | **leak** | walled |
| BW8 | `got a cold` | yes | Illness | false: no word in any set | **leak** | walled |
| BW9 | `caught a cold, skipping legs` | yes | Illness | false: no word in any set | **leak** | walled |
| BW10 | `head cold all week` | yes | Illness | false: no word in any set | **leak** | walled |
| BW11 | `tested positive for covid` | yes | Illness, a test result | false: no word in any set | **leak** | walled |
| BW12 | `covid test came back positive` | yes | Illness, a test result | false: no word in any set | **leak** | walled |
| BW13 | `sore throat` | yes | Symptom | true: `sore` in `symptoms` | ok | walled |
| BW14 | `bad cough since monday` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW15 | `coughing all night` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW16 | `allergies are brutal today` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW17 | `congested, no cardio` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW18 | `sinus infection` | yes | Illness | false: no word in any set | **leak** | walled |
| BW19 | `running a fever` | yes | Symptom | true: `fever` in `symptoms` | ok | walled |
| BW20 | `fever 101.3` | yes | Vital with a value | true: `fever` in `symptoms` | ok | walled |
| BW21 | `chills and body aches` | yes | Symptom | true: `aches` in `symptoms` | ok | walled |
| BW22 | `stomach bug` | yes | Illness | false: no word in any set | **leak** | walled |
| BW23 | `food poisoning from the tacos` | yes | Illness | false: no word in any set | **leak** | walled |
| BW24 | `threw up last night` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW25 | `under the weather` | yes | Health state, idiom for ill | false: no word in any set | **leak** | walled |
| BW26 | `feel awful today` | yes | Health state | false: no word in any set | **leak** | walled |
| BW27 | `buy advil and tissues` | yes | A drug name says he is treating something | false: `advil` is in `medicines`, which needs a number | **leak** | walled |
| BW28 | `need to pick up my prescription` | yes | Medication | false: no word in any set | **leak** | walled |
| BW29 | `took nyquil` | yes | Medication | false: no word in any set | **leak** | walled |

### Mental health

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW30 | `anxious about the review` | yes | Mental health state | false: no word in any set | **leak** | walled |
| BW31 | `had a panic attack` | yes | Mental health event | false: no word in any set | **leak** | walled |
| BW32 | `feeling depressed` | yes | Mental health state | false: no word in any set | **leak** | walled |
| BW33 | `depression is bad this week` | yes | Mental health state | false: no word in any set | **leak** | walled |
| BW34 | `therapy at 4` | yes | Mental health care. The grammar still makes the task on the phone | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW35 | `call my therapist tomorrow` | yes | Mental health care | false: no word in any set | **leak** | walled |
| BW36 | `psychiatrist appt thursday 10am` | yes | Mental health care | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW37 | `burnt out this week` | yes | On the memory screen's health list (burnout) | false: no word in any set | **leak** | walled |
| BW38 | `refill lexapro` | yes | Medication, no number | false: `lexapro` is in `medicines`, which needs a number | **leak** | walled |
| BW39 | `took a xanax` | yes | Medication, no number | false: `xanax` is in `medicines`, which needs a number | **leak** | walled |
| BW40 | `stressed about the launch` | no | Everyday mood, not a health fact (hard case H8) | false: no word in any set | ok | plain |

### Doctor and appointments

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW41 | `doctor appt friday 10am` | no | Logistics, names no condition | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW42 | `dentist at 3 pm` | no | Trap: routine visit | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW43 | `annual physical monday` | no | Routine checkup, names no condition | false: no word in any set | ok | plain |
| BW44 | `physio tuesday 5pm` | yes | Physical therapy implies an injury under care | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW45 | `physical therapy at 4` | yes | Same as physio | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW46 | `PT appointment thursday` | no | Trap: bare PT can't say trainer or therapy, so it stays plain | false: no word in any set | ok | plain |
| BW47 | `PT at 6 with Marco` | no | Trap: personal trainer | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW48 | `see doctor about the rash` | yes | Symptom named | true: `rash` in `symptoms` | ok | walled |
| BW49 | `doctor said rest the shoulder 2 weeks` | yes | Medical advice about his body | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW50 | `blood work monday 8am` | yes | Lab test | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW51 | `flu shot appointment sat` | no | Decided: a routine shot names no illness, like the dentist | false: no word in any set | ok | plain |
| BW52 | `covid booster at cvs saturday` | no | Routine shot, as above | false: no word in any set | ok | plain |
| BW53 | `buy covid tests` | no | A shopping item, no result | false: no word in any set | ok | plain |
| BW54 | `bp has been high lately` | yes | Vital state, no number (decisions: body questions stay on the phone) | false: `bp` is in `vitals`, which needs a number | **leak** | walled |

### Injuries in training

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW55 | `tweaked my back on deadlifts` | yes | Injury | false: no word in any set | **leak** | walled |
| BW56 | `pulled a hamstring` | yes | Injury | false: no word in any set | **leak** | walled |
| BW57 | `shoulder pain on bench` | yes | Pain | false: no word in any set | **leak** | walled |
| BW58 | `knee hurts on squats` | yes | Pain (L1) | true: `hurts` in `symptoms` | ok | walled |
| BW59 | `lower back is tight` | yes | Body state | false: no word in any set | **leak** | walled |
| BW60 | `rolled my ankle on the run` | yes | Injury | false: no word in any set | **leak** | walled |
| BW61 | `sore from legs` | yes | Soreness (L1 "sore shoulder") | true: `sore` in `symptoms` | ok | walled |
| BW62 | `skip legs, knee is swollen` | yes | Injury | false: no word in any set | **leak** | walled |
| BW63 | `strained my wrist` | yes | Injury | false: no word in any set | **leak** | walled |
| BW64 | `tendonitis flaring up` | yes | Condition | false: no word in any set | **leak** | walled |
| BW65 | `ice the knee after the run` | yes | Injury care | false: no word in any set | **leak** | walled |
| BW66 | `knee day at the gym` | no | Trap: existing near-miss row | false: no word in any set | ok | plain |
| BW67 | `shoulder day` | no | Trap: a routine name | false: no word in any set | ok | plain |
| BW68 | `foam roll calves` | no | Training, no injury | false: no word in any set | ok | plain |
| BW69 | `pulled the plan back a day` | no | Trap: "pulled" and "back" not adjacent | false: no word in any set | ok | plain |

### Period and cycle

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW70 | `period started today` | yes | Cycle | false: no word in any set | **leak** | walled |
| BW71 | `on my period, light session` | yes | Cycle | false: no word in any set | **leak** | walled |
| BW72 | `period cramps` | yes | Cycle, symptom | true: `cramps` in `symptoms` | ok | walled |
| BW73 | `cycle day 3` | yes | Cycle | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW74 | `pms, skipping cardio` | yes | Cycle | false: no word in any set | **leak** | walled |
| BW75 | `spin cycle class at 7` | no | Trap: cardio class | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW76 | `trial period ends friday` | no | Trap: billing | false: no word in any set | ok | plain |

### Sleep and energy

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW77 | `so tired today` | yes | Energy state (memory health word) | false: no word in any set | **leak** | walled |
| BW78 | `exhausted after work` | yes | Energy state | false: no word in any set | **leak** | walled |
| BW79 | `tired of this bug` | no | Trap: "tired of" | false: no word in any set | ok | plain |
| BW80 | `couldn't sleep` | yes | Sleep fact (QA L1) | false: no word in any set | **leak** | walled |
| BW81 | `slept badly` | yes | Sleep fact (L1) | true: `slept` in `symptoms` | ok | walled |
| BW82 | `slept 5 hours` | yes | Sleep fact (MB20) | true: `slept` in `symptoms` | ok | walled |
| BW83 | `took a 2 hour nap` | yes | Sleep fact with a value | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW84 | `napped after lunch` | yes | Sleep fact | false: no word in any set | **leak** | walled |
| BW85 | `nap at 2` | no | A plan with a time, like "sleep by 11" | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW86 | `sleep by 11` | no | MB39 pass row | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW87 | `up all night with a headache` | yes | Symptom | true: `headache` in `symptoms` | ok | walled |

### Diet and body

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW88 | `1800 calories today` | yes | Intake (memory health value word) | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW89 | `cutting, 2000 cal a day` | yes | Intake | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW90 | `macros 180 protein 250 carbs` | yes | Intake | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW91 | `burned 600 cal on the bike` | no | Workout output, like a distance | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW92 | `fasting till noon` | yes | Diet practice | false: no word in any set | **leak** | walled |
| BW93 | `bloated after dinner` | yes | Symptom | false: no word in any set | **leak** | walled |
| BW94 | `hungover, no gym` | yes | Body state | false: no word in any set | **leak** | walled |
| BW95 | `bad hangover` | yes | Body state | false: no word in any set | **leak** | walled |
| BW96 | `bmi 24` | yes | Body measure (QA L1) | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW97 | `waist 34 in` | yes | Body measure | false: no word in any set (number, but no vital, medicine or weigh word) | **leak** | walled |
| BW98 | `body fat 18%` | yes | Body measure (L1) | true: the body fat pattern | ok | walled |
| BW99 | `what did i weigh monday` | yes | Decisions Oct 16: body questions with no number stay on the phone | false: weigh word with no number | **leak** | walled |
| BW100 | `bw trend` | yes | Same decision | false: weigh word with no number | **leak** | walled |
| BW101 | `buy protein powder` | no | Groceries | false: no word in any set | ok | plain |

### Traps that stay plain

| # | Phrase | Wall? | Why | `isBodyShaped` on master today | Verdict | With §4 |
|---|---|---|---|---|---|---|
| BW102 | `that set was sick` | no | Slang for great | false: no word in any set | ok | plain |
| BW103 | `sick set on bench` | no | Slang | false: no word in any set | ok | plain |
| BW104 | `that workout was sick` | no | Slang | false: no word in any set | ok | plain |
| BW105 | `sick of rice, buy pasta` | no | Fed up, groceries | false: no word in any set | ok | plain |
| BW106 | `sick of this` | no | Fed up | false: no word in any set | ok | plain |
| BW107 | `sick beat` | no | Slang | false: no word in any set | ok | plain |
| BW108 | `cold brew 2` | no | Groceries | false: no word in any set (number, but no vital, medicine or weigh word) | ok | plain |
| BW109 | `cold weather run tomorrow` | no | Weather | false: no word in any set | ok | plain |
| BW110 | `cold plunge after lift` | no | Training recovery | false: no word in any set | ok | plain |
| BW111 | `pain au chocolat for breakfast` | no | Food | false: no word in any set | ok | plain |
| BW112 | `this deploy is a pain` | no | Idiom | false: no word in any set | ok | plain |
| BW113 | `run a fever check on the server` | no | Idiom | true: `fever` in `symptoms` | **over-wall** | plain |
| BW114 | `cabin fever, going for a walk` | no | Idiom | true: `fever` in `symptoms` | **over-wall** | plain |
| BW115 | `this migration is a headache` | no | Idiom | true: `headache` in `symptoms` | **over-wall** | plain |
| BW116 | `ping the server health check` | no | Ops | false: no word in any set | ok | plain |
| BW117 | `resting 90 sec between sets` | no | Rest timer, not resting heart rate | true: `resting` in `vitals` with a number | **over-wall** | plain |
| BW118 | `walk the dog for 1 hr` | no | Duration | true: `hr` in `vitals` with a number | **over-wall** | plain |
| BW119 | `pulse 30 sec in the blender` | no | Kitchen | true: `pulse` in `vitals` with a number | **over-wall** | plain |
| BW120 | `oven temp 425` | no | Kitchen | true: `temp` in `vitals` with a number | **over-wall** | plain |
| BW121 | `chicken internal temp 165` | no | Kitchen | true: `temp` in `vitals` with a number | **over-wall** | plain |
| BW122 | `dishwasher tablets 2 boxes` | no | Groceries | true: `tablets` in `medicines` with a number | **over-wall** | plain |
| BW123 | `charge the tablet 2pm` | no | Device | true: `tablet` in `medicines` with a number | **over-wall** | plain |
| BW124 | `cold butter for the dough` | no | Kitchen | false: no word in any set | ok | plain |
| BW125 | `weigh the flour 500 g` | no | MB34 pass row | false: weigh word with no number | ok | plain |
| BW126 | `bench 80 x 8` | no | MB31 pass row | false: set notation (`isTraining`) | ok | plain |

**Bare medicine names (decisions 2:40 pm, Core 0ac slice 2).** A medicine name alone, or with only a buy or list verb, is walled. Today `medicines` needs a number beside the word, so every row below leaks.

| ID | Phrase | Wall? | Why | Master today | Result | Proposed |
|---|---|---|---|---|---|---|
| BW127 | `advil` | yes | Bare medicine name (the AU and AX finding) | false: `advil` needs a number | **leak** | walled |
| BW128 | `tylenol` | yes | Bare medicine name | false: no number | **leak** | walled |
| BW129 | `ibuprofen` | yes | Bare generic name | false: no number | **leak** | walled |
| BW130 | `lexapro` | yes | Bare name, mental health medication | false: no number | **leak** | walled |
| BW131 | `zyrtec` | yes | Bare name, allergy medication | false: no number | **leak** | walled |
| BW132 | `add advil to the list` | yes | List verb plus medicine name | false: no number | **leak** | walled |
| BW133 | `groceries: milk, advil, eggs` | yes | One medicine item walls that item, not the whole list (the AX groceries path) | false: no number | **leak** | walled item; milk and eggs plain |
| BW134 | `Advil` | yes | Case: capitalized brand | false: no number | **leak** | walled |
| BW135 | `vitamin d` | no | Trap: supplement, not a condition | false: no word in any set | ok | plain |
| BW136 | `cough drops` | no | Trap: shop item (decided plain with flu shot and bare "PT" at 1:36 pm) | false: no word in any set | ok | plain |

## 4. Word additions, set by set

All words are lowercase whole words as `words(_:)` splits them. "No number" means the word walls by itself (the
`symptoms` tier, `isBodyShaped` :70); "number" means it walls only when the phrase also holds a number (:76-80).

**Slice 1, decided by Product (HW19, next build):** `symptoms` += `sick`, `unwell`. "feeling sick" then walls through
`sick`. This slice must ship with the `sick` mask in CR1 (§5), or BW102 to BW104, BW106 and BW107 become new
over-walls ("that set was sick" turns into a private note).

**Slice 2, Research default, for Product to confirm:**

| Set | Change | Rows it closes |
|---|---|---|
| `symptoms` (no number) | += `flu`, `covid`, `cough`, `coughing`, `congested`, `congestion`, `allergies`, `sinus`, `strep`, `chills`, `feverish`, `sneezing`, `nauseated`, `puked`, `bloated`, `hungover`, `hangover`, `swollen`, `tendonitis`, `concussion`, `pain`, `tired`, `exhausted`, `fatigue`, `fatigued`, `sleepless`, `napped`, `fasting`. `flu`, `covid`, `pain` and `tired` need their masks (CR2 to CR5). `fever` and `headache` stay but get masks (CR6, CR7) | BW7, BW11, BW14 to BW18, BW57, BW62, BW64, BW77, BW78, BW84, BW92 to BW95 |
| new `mindWords` (no number) | `anxious`, `anxiety`, `depressed`, `depression`, `burnout` | BW30, BW32, BW33 |
| new `careWords` (no number) | `therapy`, `therapist`, `psychiatrist`, `counselor`, `counseling`, `physio`, `physiotherapy`, `chiropractor`. Not `doctor`, `dentist`, `physical` or `pt` | BW34 to BW36, BW44, BW45 |
| new `cycleWords` (no number) | `pms`, `ovulation`, `ovulating`, `luteal`, `menstrual` | BW74 |
| new `drugNames` (no number), split out of `medicines` | Moves `advil`, `tylenol`, `ibuprofen`, `acetaminophen`, `aspirin`, `aleve`, `lexapro`, `zoloft`, `sertraline`, `prozac`, `adderall`, `xanax`, `melatonin`, `benadryl`, `claritin`, `zyrtec`, `meds`, `medication` here, and adds `nyquil`, `dayquil`, `sudafed`, `mucinex`, `antibiotics`, `prescription`, `inhaler`. A drug name says what he is treating, with or without a number | BW27 to BW29, BW38, BW39 |
| `medicines` (number) | Keeps `pill`, `pills`, `dose`, `capsule`, `capsules`, `tablet`, `tablets`. `tablet(s)` and `capsule(s)` count only with a take verb (`take`, `took`, `taking`, `pop`, `popped`) or `mg` in the phrase | BW122, BW123 |
| `vitals` (number) | Remove `resting` (it never walls alone: "resting hr 58" walls on `hr`, "resting heart rate 58" on "heart rate"). Add `bmi`, `waist`, `calories`, `kcal`, `cal`, `cals`, `macros`. Guards in CR14 for `hr`, `temp`, `temperature`, `pulse` and the calorie words | BW88 to BW90, BW96, BW97, BW117 to BW121 |

Optional, one line: compute `hasNumber` in `isBodyShaped` from `withoutTimes(lower)`, as `isMoneyShaped` already does
(:32). A clock time is never a body value, and it fixes BW123 on its own. Every existing wall row still holds with it.

## 5. Context rules (phrases, not single words)

Each rule is a Swift `Regex` on `lower`. A **wall** rule returns true before the word checks. A **mask** removes the
matched text before the word checks, so its word can't fire there. Both run after `isTraining`, as today.

| # | Kind | Rule | Walls | Stays plain |
|---|---|---|---|---|
| CR1 | mask | `/\bsick\s+of\b/`, `/\b(?:set\|lift\|pr\|workout\|session\|pump\|song\|view\|beat\|car\|shot\|play\|trick)\s+(?:was\|is\|looks\|looked)?\s*sick\b/`, `/\bsick\s+(?:set\|lift\|pr\|workout\|session\|pump\|song\|view\|beat\|car\|shot\|play\|trick)\b/` | BW1 to BW4 still wall (`gym`, `push` and `day` are not in the slang list) | BW102 to BW107 |
| CR2 | mask | `/\bflu\s+(?:shot\|vaccine\|jab\|clinic)\b/` | BW7 | BW51 |
| CR3 | mask, then wall | Mask `/\bcovid(?:-19)?\s+(?:shot\|booster\|vaccine\|jab\|tests?)\b/`; wall `/\bcovid\b.*\bpositive\b\|\bpositive\b.*\bcovid\b/` | BW11, BW12 | BW52, BW53 |
| CR4 | mask | `/\bpain\s+(?:au\|aux\|de)\b/`, `/\b(?:is\|was\|what)\s+a\s+(?:pain\|headache)\b/`, `/\bpain\s+in\s+the\s+(?:ass\|butt)\b/` | BW57 | BW111, BW112, BW115 |
| CR5 | mask | `/\btired\s+of\b/` | BW77 | BW79 |
| CR6 | mask | `/\b(?:cabin\|spring)\s+fever\b/`, `/\bfever\s+(?:check\|dream\|pitch)\b/` | BW19, BW20 | BW113, BW114 |
| CR7 | wall | Cold is never a single word: `/\b(?:a\|head\|chest)\s+cold\b(?!\s+(?:brew\|plunge\|shower\|front\|weather\|snap\|one\|beer\|water\|butter\|case\|call\|start\|open))/` | BW8 to BW10 | BW108 to BW110, BW124 |
| CR8 | wall | `ill` is never a single word (typed "ill" is often "I'll"): `/\b(?:feel\|feeling\|felt\|am\|im\|been\|got)\s+ill\b/` and "i'm ill" | BW6 | "ill call mom at 5" |
| CR9 | wall | `/\bunder\s+the\s+weather\b/`, `/\bthrew\s+up\b\|\bthrowing\s+up\b/`, `/\bstomach\s+bug\b\|\bfood\s+poisoning\b/`, `/\b(?:feel\|feeling\|felt)\s+(?:awful\|terrible\|rough\|lousy\|crappy\|run\s+down\|like\s+crap\|like\s+death)\b/` | BW22 to BW26 | "feeling great, extra set" |
| CR10 | wall | `/\bpanic\s+attack/`, `/\b(?:burnt\|burned)\s+out\b/` | BW31, BW37 | "don't panic, deploy at 5" |
| CR11 | wall | Care and tests: `/\b(?:doctor\|doc\|dr\|dentist)\s+(?:said\|says\|thinks\|wants)\b/`, `/\bblood\s+(?:work\|test\|tests\|draw\|panel)\b/`, `/\b(?:bp\|blood\s+pressure\|heart\s+rate\|sugar\|glucose)\s+(?:is\|was\|has\s+been\|been)?\s*(?:high\|low\|up\|spiking)\b/` | BW49, BW50, BW54 | BW41 to BW43, "blood orange" |
| CR12 | wall | Injury: an injury verb next to a body part, either order. Verbs: `tweaked`, `pulled`, `strained`, `tore`, `torn`, `rolled`, `twisted`, `jammed`, `pinched`, `tight`, `stiff`, `locked up`, `ice`, `iced`, `icing`. Parts: `back`, `lower back`, `upper back`, `knee(s)`, `shoulder(s)`, `ankle(s)`, `wrist(s)`, `hip(s)`, `neck`, `elbow(s)`, `hamstring(s)`, `calf`, `calves`, `groin`, `quad(s)`, `glute(s)`, `achilles`, `rotator cuff`, `pec(s)`, `bicep(s)`, `tricep(s)`, `foot`, `feet`, `shin(s)`, `it band`. Shape: `verb (my\|a\|the)? (left\|right)? part` or `part (is\|feels\|was\|got\|are)? (verb\|swollen\|killing me)` | BW55, BW56, BW59, BW60, BW63, BW65 | BW66 to BW69, "tight deadline", "pulled pork" |
| CR13 | wall | Cycle: `/\b(?:my\|on\s+my)\s+period\b\|\bperiod\s+(?:started\|came\|cramps\|pain\|day\|late\|is\s+late)\b/`, `/\bcycle\s+day\s*\d\|\bmy\s+cycle\b/` | BW70, BW71, BW73 | BW75, BW76, "period 3 class" |
| CR14 | guard | Number-tier guards. `hr`: counts only when no number sits right before it (`\d+\s*hrs?` is a duration). `temp`/`temperature`: counts only for a number from 35 to 42.5 or 95 to 106 (a body temperature in C or F). `pulse`: not with `sec`, `secs`, `seconds`, `times`, `blender`, `until`. `calories`/`kcal`/`cal`/`cals`: not with `burn`, `burned`, `burnt` | BW88, BW89 ("2000 cal") | BW91, BW118 to BW121 |
| CR15 | wall | Sleep: `/\b(?:couldn't\|couldnt\|can't\|cant\|didn't\|didnt\|barely\|no\|bad\|poor\|terrible\|little)\s+(?:sleep\|slept)\b/`, and a nap with a length `/\b\d+(?:\.\d+)?\s*(?:h\|hr\|hrs\|hour\|hours\|min\|mins\|minutes)\s+nap\b/` | BW80, BW83 | BW85, BW86, "sleep in saturday" |
| CR16 | wall | Weight questions with no number (decisions 1:23 PM PT Oct 16): `/\bwhat\s+did\s+i\s+weigh\b\|\bhow\s+much\s+do\s+i\s+weigh\b\|\bbw\s+trend\b\|\bbody\s+weight\b/` | BW99, BW100 | BW125 ("weigh the flour 500 g") |

## 6. Hard cases and the calls taken here

| # | Case | Call | Why |
|---|---|---|---|
| H1 | "sick" as slang (BW102 to BW107) | Plain, through CR1 | Product's slice adds `sick` alone. Without the mask, his gym talk becomes private notes. A slang list is short and closed; a miss in the list only over-walls, it never leaks |
| H2 | "cold" (BW8 to BW10 vs BW108 to BW110, BW124) | Rule only (CR7), never a word | Cold drinks, weather, plunges and butter are daily; an illness needs "a", "head" or "chest" in front |
| H3 | "flu shot appointment sat" (BW51), "covid booster" (BW52), "buy covid tests" (BW53) | Plain | A routine shot names no illness, same as BW42 "dentist at 3 pm". "positive" overrides (BW12). Product may prefer to wall every vaccine; that only needs CR2 and CR3's masks dropped |
| H4 | PT (BW46, BW47) vs physio (BW44, BW45) vs doctor (BW41) vs therapist (BW35) | Bare `pt` plain; `physio`, `physical therapy`, `therapy`, `therapist` walled; `doctor`, `dentist`, `physical` plain | "PT at 6" is most often his trainer. Physio and therapy say what he is being treated for; a doctor or dentist visit doesn't. A walled task is still made by the grammar; only its title rides as "task" in Plan packs (`PlanWording.swift:38`) |
| H5 | "pain" (BW57 vs BW111, BW112) | Word plus CR4 mask | "pain in the neck" stays an idiom even when he means his neck: a known miss, small next to walling every "this is a pain" |
| H6 | "ill" | Rule only (CR8) | A typed "ill" is usually "I'll" with the apostrophe dropped |
| H7 | Existing over-walls on master (BW113 to BW115, BW117 to BW123) | Fix with CR4, CR6, CR14, the `resting` removal and the tablet take-verb guard | `resting 90 sec between sets` and `walk the dog for 1 hr` are training and life phrases he types often. Today a grammar miss on them becomes a private note |
| H8 | "stressed" (BW40), "anxious" | `stressed` plain; `anxious` walled | Stress is everyday mood. "anxious to ship" (eager) over-walls; accepted, since the cost is only a private note |
| H9 | Calories eaten vs burned (BW88 vs BW91) | Eaten walled; burned plain | Burned calories are a workout output, like distance (MB40). `protein` stays plain: "buy protein powder" (BW101) and "protein 2 lb" are groceries; "macros" with a number carries the intake rows |
| H10 | "period", "cycle" (BW70 to BW76) | Rules only (CR13) | "trial period", "spin cycle", "cycle 20 min" are common; the possessive or "started" carries the meaning |
| H11 | Injury words (BW55 to BW69) | Rule only (CR12), except `swollen` and `tendonitis` | "pulled", "tight", "back", "rolled" all have daily meanings; adjacency to a body part is the signal. "pulled the plan back a day" (BW69) stays plain because the words are not next to each other |
| H12 | `fever`, `headache` idioms (BW113 to BW115) | Keep the words, add masks (CR4, CR6) | Real fevers and headaches are frequent; idioms are a short list |
| H13 | "tired" (BW77, BW79) | Word plus "tired of" mask | Energy state is on the memory screen's health list (`TessMemory.swift:98`) |
| H14 | What a walled miss turns into | Unchanged | "feeling sick, no gym" becomes a private note "Feeling sick, no gym" until the day mark rule (DG2) reads it as a sick mark. Safe: nothing leaves the phone |

## 7. Swift Testing lines for Core

In the style of `PrivacyFollowupTests` (`TesseraCore/Tests/TesseraCoreTests/PrivacyFollowupTests.swift`). The first
test is slice 1 (decided). The second is slice 2 (§4 and §5, pending Product). The third holds every "no" row and must
pass before and after both slices.

```swift
    /// Research AO (docs/research/fixtures/private-health-words.md) BW1 to BW5, HW19: Product's sick words.
    @Test(arguments: [
        "feeling sick, no gym", "sick today", "i'm sick, skip push", "sick day tomorrow", "feeling unwell",
    ])
    func sickWordsAreWalled(_ phrase: String) {
        #expect(PrivateFacts.isWalled(phrase), "\(phrase)")
    }

    /// Research AO, the other leak rows: everyday health with no number, or with a number no set reads.
    @Test(arguments: [
        "feel ill, going home early", "think i have the flu", "got a cold", "caught a cold, skipping legs",
        "head cold all week", "tested positive for covid", "covid test came back positive", "bad cough since monday",
        "coughing all night", "allergies are brutal today", "congested, no cardio", "sinus infection", "stomach bug",
        "food poisoning from the tacos", "threw up last night", "under the weather", "feel awful today",
        "buy advil and tissues", "need to pick up my prescription", "took nyquil", "anxious about the review",
        "had a panic attack", "feeling depressed", "depression is bad this week", "therapy at 4",
        "call my therapist tomorrow", "psychiatrist appt thursday 10am", "burnt out this week", "refill lexapro",
        "took a xanax", "physio tuesday 5pm", "physical therapy at 4", "doctor said rest the shoulder 2 weeks",
        "blood work monday 8am", "bp has been high lately", "tweaked my back on deadlifts", "pulled a hamstring",
        "shoulder pain on bench", "lower back is tight", "rolled my ankle on the run", "skip legs, knee is swollen",
        "strained my wrist", "tendonitis flaring up", "ice the knee after the run", "period started today",
        "on my period, light session", "cycle day 3", "pms, skipping cardio", "so tired today",
        "exhausted after work", "couldn't sleep", "took a 2 hour nap", "napped after lunch", "1800 calories today",
        "cutting, 2000 cal a day", "macros 180 protein 250 carbs", "fasting till noon", "bloated after dinner",
        "hungover, no gym", "bad hangover", "bmi 24", "waist 34 in", "what did i weigh monday", "bw trend",
    ])
    func everydayHealthPhrasesAreWalled(_ phrase: String) {
        #expect(PrivateFacts.isWalled(phrase), "\(phrase)")
    }

    /// Research AO, the "no" rows: gym slang, kitchen, idioms, routine visits and durations stay unwalled.
    @Test(arguments: [
        "stressed about the launch", "doctor appt friday 10am", "dentist at 3 pm", "annual physical monday",
        "PT appointment thursday", "PT at 6 with Marco", "flu shot appointment sat", "covid booster at cvs saturday",
        "buy covid tests", "knee day at the gym", "shoulder day", "foam roll calves", "pulled the plan back a day",
        "spin cycle class at 7", "trial period ends friday", "tired of this bug", "nap at 2", "sleep by 11",
        "burned 600 cal on the bike", "buy protein powder", "that set was sick", "sick set on bench",
        "that workout was sick", "sick of rice, buy pasta", "sick of this", "sick beat", "cold brew 2",
        "cold weather run tomorrow", "cold plunge after lift", "pain au chocolat for breakfast",
        "this deploy is a pain", "run a fever check on the server", "cabin fever, going for a walk",
        "this migration is a headache", "ping the server health check", "resting 90 sec between sets",
        "walk the dog for 1 hr", "pulse 30 sec in the blender", "oven temp 425", "chicken internal temp 165",
        "dishwasher tablets 2 boxes", "charge the tablet 2pm", "cold butter for the dough", "weigh the flour 500 g",
        "bench 80 x 8",
    ])
    func everydayLookAlikesStayUnwalled(_ phrase: String) {
        #expect(!PrivateFacts.isWalled(phrase), "\(phrase)")
    }
```

Today the second test fails on all 64 rows, and the third fails on the 10 over-wall rows (BW113 to BW115, BW117 to
BW123).
