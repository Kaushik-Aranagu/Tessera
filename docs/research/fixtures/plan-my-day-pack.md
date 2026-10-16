# Plan my day: the context pack, fixture for Builder B's wiring

For: Builder B (wiring `ClaudePlanWording`), Core (A3, A4, CA4), QA (pack snapshot test). Owner: Research lab.
Read at origin/master `20f0a16`. "decisions.md" is `docs/product/decisions.md` (times PT, Oct 15 unless dated). Code: `TesseraCore/Sources/TesseraTess/PlanWording.swift` (PW), `Tasks/DayPlan.swift` (DP),
`Tasks/DayPlan+Store.swift` (DPS). No app code calls `ClaudePlanWording` or `PlanPack` yet (audit-master-oct16.md:18).
Scene: Mon Oct 19 to Mon Oct 26, America/Los_Angeles (PDT all days), PPL plan at 5 a week, key stored, "Tess asks Claude" on,
calendar connected unless a row says not, event titles off (CA4). Pack is the one-line sorted-keys JSON in the user turn.

## Rules

| Rule | One line | Source |
|---|---|---|
| A3 | `ClaudePlanWording.allowed` is a required init argument; Builder B passes `{ model.asksClaude }`; off sends nothing | qa/audit-master-oct16.md:42; board/core.md:14; board/ios-b.md:31 |
| A4 | A block whose title trips `SecretWords.mentions` or the money or body screen goes as "task" (task, timed task) or "busy" (event), times kept, with a pack snapshot test | audit:48; core.md:14, :63; fixtures/money-body-wall.md W7, MB24 to MB27 |
| CA4 | `PlanPack.init` defaults `includesEventTitles` to false; titles go only when the caller passes true (his Oct 22 call) | research/claude-requests-audit.md:64; core.md:20 |
| R4 | Nothing with a secret word leaves the phone; a secret-word task with no value stays a task and packs as "task" | research/secret-words-check.md:38 (Research 139) |
| R4 (order) | Handles follow the rules order: carry-overs, then due today, then Later; blocks in time order | plan-my-day-scenarios.md:19 |
| Light | Only `light: true` or `false` and `cap` 2 or 3 go; C1 to C3 `lightReason` never | light-day.md:35; DP:43 |
| Never | No Health values, sleep line, notes, set history, `rolls`, `rolledFrom`, UUIDs, Groceries count, recipe link, cook timers, place or zone, money amounts, body facts, day-mark kind, memory lines | plan-my-day-prompt.md:54; decisions.md 7:55 PM PT Oct 15; day-marks.md DM13 |
| Memory | None on master. Later only screened noticed training-time lines (`TessMemoryScreen`), never private ones | ai/architecture.md:65, :156 |
| No call | Switch off, no key, cap reached, window closed, no ghost lines (PW:41), or a workout running | PW:433, :447; decisions.md 8:50 PM PT Oct 15 |
| Budget | Pack at most 400 tokens; call about 1,000 in, 1,160 max; fixed part about 870 (instructions 2,306 bytes, schema 1,129) | calendar-pack.md:11; ai/spend-projection.md:16 |

Tokens: pack bytes / 4, rounded; "in" adds the fixed 870. Master's estimate is bytes / 4 + 10 (ClaudeKey.swift:143).

## Days

| # | Day, opened | Inputs | Stays on the phone | Pack | Tokens pack / in |
|---|---|---|---|---|---|
| P01 | Mon 19, 7:30 am | Push A (date-only); Renew car registration (due 5 pm), Pay electricity bill, Call Priya 12:30 pm; Later Fix bike light; Standup, Design review | Event titles (CA4), the Health sleep line | P01 | 204 / 1,074 |
| P02 | Tue 20, 8:05 am | Rest day; Email landlord re lease (rolled), "Reset my PIN", Review lease renewal (Later), Haircut noon; calendar "Not now"; 9 open groceries | "Reset my PIN" goes as "task" (R4); `rolls`, old 7 pm time, groceries | P02 (`cal:false`, `rest:true`) | 132 / 1,002 |
| P03 | Wed 21, 7:45 am | Pull A; Order contact lenses, "Pay Sam back $40", Cook dal tadka (recipe, 4 to buy), Pick up parcel 4 pm; all-day "Ana's birthday", "Office closed" | "$40" task as "task" (A4); birthday (DP:211); all-day titles (CA4); recipe link, groceries | P03 | 150 / 1,020 |
| P04 | Thu 22, 7:20 am | Legs A; "Refill lexapro 10mg", Submit timesheet, Call insurer; Physio 1 pm; 4 meetings; Health granted, slept 5h40 | Meds title as "task" (A4 body; a medicine with a dose is a health fact, Product 12:06 PM PT); C3 reason; sleep value; Call insurer (cap 2, not placed) | P04 (`light:true`, `cap:2`) | 216 / 1,086 |
| P05 | Thu 22, as P04, titles on | Caller passes `includesEventTitles: true` after his Oct 22 yes; "Vendor call https://zoom.us/j/123", "IT: reset VPN password", all-day "Hackathon week" | URL cut (calendar-pack.md:53); password event as "busy" (A4) | P05 | 223 / 1,093 |
| P06 | Fri 23, 7:10 am | Push B; Fill in visa form (rolled), Book flights (due 4 pm), Sign NDA, Update CV, dry cleaning 12:15 pm, Call mom 7:30 pm; memory told line "gate code 4417" (private); note "tacocat" | Update CV (cap); the told line and note; history | P06 (as dryrun Fri) | 180 / 1,050 |
| P07 | Fri 23, 12:10 pm | Morning tasks done; he says "sick today" | The word "sick" and the mark's kind; Push B drops; only `rest:true` | P07 | 106 / 976 |
| P08 | Fri 23, 5:20 pm | Push B running since 5:05 pm | Everything: no call during a workout | **nothing** | 0 |
| P09 | Sat 24, 9:20 am | Pull B finished 9:15 am; Return library book (rolled), Car wash, Cook carbonara; timer "rice 12" running; 11 groceries | Finished workout (no block); timer, groceries, best sets | P09 | 99 / 969 |
| P10 | Sat 24, 1 pm | Month ledger at $49.99 | Everything; line "Claude paused until Nov 1. Here's your usual plan." (PW:450) | **nothing** | 0 |
| P11 | Sun 25, 8:30 am | Rest day; Water plants, Sort the garage, Recover files from old laptop | Nothing more: "Recover" is his title, allowed | P11 (`rest:true`) | 106 / 976 |
| P12 | Sun 25, 3 pm | Every task done, nothing in Later | Everything: no ghost lines, `PlanPack` is nil (PW:41) | **nothing** | 0 |
| P13 | Sun 25, 8:30 am, switch off | As P11 with "Tess asks Claude" off | Everything; rules plan, no line | **nothing** | 0 |
| P14 | Mon 26, 7:30 am, trip day | Push A; Expense report (due 5 pm), "Text sitter the door code", Water the plants, Leave for SFO 8 pm; all-day "NYC trip"; Flight SFO-JFK 10:30 pm | Door-code task as "task" (R4); all-day title; flight (after the 9 pm window); no zone, date or place | P14 | 152 / 1,022 |
| P15 | Mon 26, 9:45 pm, at the gate | Window closed at 9 pm (DP:217) | Everything | **nothing** | 0 |

Largest pack 223 tokens (P05), largest call about 1,093 in: under 400 and under 1,160.

## Expected packs

```text
P01 {"allDay":[],"blocks":[{"due":"17:00","end":"08:00","id":"t1","kind":"task","min":30,"run":1,"start":"07:30","title":"Renew car registration"},{"end":"08:10","id":"t2","kind":"task","min":10,"run":1,"start":"08:00","title":"Pay electricity bill"},{"end":"08:30","id":"t3","kind":"task","min":20,"run":1,"start":"08:10","title":"Fix bike light"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"busy"},{"end":"12:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"11:00","title":"busy"},{"end":"12:50","fixed":true,"id":"k1","kind":"timedTask","min":20,"start":"12:30","title":"Call Priya"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Push A"}],"cap":3,"light":false,"now":"07:30","weekday":"Mon","window":["07:30","21:00"]}
P02 {"allDay":[],"blocks":[{"end":"08:20","id":"t1","kind":"task","min":15,"run":1,"start":"08:05","title":"Email landlord re lease"},{"end":"08:30","id":"t2","kind":"task","min":10,"run":1,"start":"08:20","title":"task"},{"end":"09:00","id":"t3","kind":"task","min":30,"run":1,"start":"08:30","title":"Review lease renewal"},{"end":"12:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"12:00","title":"Haircut"}],"cal":false,"cap":3,"light":false,"now":"08:05","rest":true,"weekday":"Tue","window":["08:05","21:00"]}
P03 {"allDay":[],"blocks":[{"end":"07:55","id":"t1","kind":"task","min":10,"run":1,"start":"07:45","title":"Order contact lenses"},{"end":"08:05","id":"t2","kind":"task","min":10,"run":1,"start":"07:55","title":"task"},{"end":"16:15","fixed":true,"id":"k1","kind":"timedTask","min":15,"start":"16:00","title":"Pick up parcel"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Pull A"},{"end":"18:45","id":"t3","kind":"task","min":45,"run":2,"start":"18:00","title":"Cook dal tadka"}],"cap":3,"light":false,"now":"07:45","weekday":"Wed","window":["07:45","21:00"]}
P04 {"allDay":[],"blocks":[{"end":"07:30","id":"t1","kind":"task","min":10,"run":1,"start":"07:20","title":"task"},{"end":"07:40","id":"t2","kind":"task","min":10,"run":1,"start":"07:30","title":"Submit timesheet"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"busy"},{"end":"10:45","fixed":true,"id":"e2","kind":"event","min":45,"start":"10:00","title":"busy"},{"end":"13:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"13:00","title":"Physio"},{"end":"15:00","fixed":true,"id":"e3","kind":"event","min":60,"start":"14:00","title":"busy"},{"end":"16:00","fixed":true,"id":"e4","kind":"event","min":30,"start":"15:30","title":"busy"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Legs A"}],"cap":2,"light":true,"now":"07:20","weekday":"Thu","window":["07:20","21:00"]}
P05 {"allDay":["Hackathon week"],"blocks":[{"end":"07:30","id":"t1","kind":"task","min":10,"run":1,"start":"07:20","title":"task"},{"end":"07:40","id":"t2","kind":"task","min":10,"run":1,"start":"07:30","title":"Submit timesheet"},{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"10:45","fixed":true,"id":"e2","kind":"event","min":45,"start":"10:00","title":"Vendor call"},{"end":"13:45","fixed":true,"id":"k1","kind":"timedTask","min":45,"start":"13:00","title":"Physio"},{"end":"15:00","fixed":true,"id":"e3","kind":"event","min":60,"start":"14:00","title":"Roadmap"},{"end":"16:00","fixed":true,"id":"e4","kind":"event","min":30,"start":"15:30","title":"busy"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Legs A"}],"cap":2,"light":true,"now":"07:20","weekday":"Thu","window":["07:20","21:00"]}
P06 {"allDay":[],"blocks":[{"end":"07:50","id":"t1","kind":"task","min":40,"run":1,"start":"07:10","title":"Fill in visa form"},{"due":"16:00","end":"08:20","id":"t2","kind":"task","min":30,"run":1,"start":"07:50","title":"Book flights"},{"end":"08:25","id":"t3","kind":"task","min":5,"run":1,"start":"08:20","title":"Sign NDA"},{"end":"12:30","fixed":true,"id":"k1","kind":"timedTask","min":15,"start":"12:15","title":"Pick up dry cleaning"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Push B"},{"end":"20:00","fixed":true,"id":"k2","kind":"timedTask","min":30,"start":"19:30","title":"Call mom"}],"cap":3,"light":false,"now":"07:10","weekday":"Fri","window":["07:10","21:00"]}
P07 {"allDay":[],"blocks":[{"end":"12:30","fixed":true,"id":"k1","kind":"timedTask","min":15,"start":"12:15","title":"Pick up dry cleaning"},{"end":"13:00","id":"t1","kind":"task","min":30,"run":1,"start":"12:30","title":"Update CV"},{"end":"20:00","fixed":true,"id":"k2","kind":"timedTask","min":30,"start":"19:30","title":"Call mom"}],"cap":3,"light":false,"now":"12:10","rest":true,"weekday":"Fri","window":["12:10","21:00"]}
P09 {"allDay":[],"blocks":[{"end":"09:35","id":"t1","kind":"task","min":15,"run":1,"start":"09:20","title":"Return library book"},{"end":"10:05","id":"t2","kind":"task","min":30,"run":1,"start":"09:35","title":"Car wash"},{"end":"18:45","id":"t3","kind":"task","min":45,"run":2,"start":"18:00","title":"Cook carbonara"}],"cap":3,"light":false,"now":"09:20","weekday":"Sat","window":["09:20","21:00"]}
P11 {"allDay":[],"blocks":[{"end":"09:00","id":"t1","kind":"task","min":30,"run":1,"start":"08:30","title":"Water plants"},{"end":"11:00","id":"t2","kind":"task","min":120,"run":1,"start":"09:00","title":"Sort the garage"},{"end":"11:30","id":"t3","kind":"task","min":30,"run":1,"start":"11:00","title":"Recover files from old laptop"}],"cap":3,"light":false,"now":"08:30","rest":true,"weekday":"Sun","window":["08:30","21:00"]}
P14 {"allDay":[],"blocks":[{"due":"17:00","end":"08:15","id":"t1","kind":"task","min":45,"run":1,"start":"07:30","title":"Expense report"},{"end":"08:25","id":"t2","kind":"task","min":10,"run":1,"start":"08:15","title":"task"},{"end":"08:35","id":"t3","kind":"task","min":10,"run":1,"start":"08:25","title":"Water the plants"},{"end":"18:00","fixed":true,"id":"w1","kind":"workout","min":60,"start":"17:00","title":"Push A"},{"end":"20:30","fixed":true,"id":"k1","kind":"timedTask","min":30,"start":"20:00","title":"Leave for SFO"}],"cap":3,"light":false,"now":"07:30","weekday":"Mon","window":["07:30","21:00"]}
```

## Gaps on master

| # | Where | Master does | Expected | Fix | Owner |
|---|---|---|---|---|---|
| G1 | PW:39 | `includesEventTitles: Bool = true`; P01 sends "Standup", "Design review", P03 sends "Office closed" | "busy", `allDay` [] (CA4) | Default false; Builder B passes it explicitly | Core |
| G2 | PW:412 | `allowed = { true }`; P13 sends if the caller forgets | No call (A3) | Required init argument, as `ClaudeRecipeReader` | Core; Builder B passes `{ model.asksClaude }` |
| G3 | PW:77 | Copies every title; P02 "Reset my PIN", P03 "$40", P04 "lexapro 10mg", P05 "VPN password", P14 "door code" go out. No money or body screen exists yet (MU2 in flight) | "task" or "busy" (A4, R4, W7) | Screen in `PlanPack.init` with `SecretWords.mentions` and MU2's screen; build `titleWords` (PW:160) from sent titles; snapshot test of P01 to P14 | Core |
| G4 | PW:433, :93 | No running check; P08 sends `"running":true` | Nothing during a workout | `word` returns `.rules(line: nil)` when a block is running; Builder B shows no offer | Core, Builder B |
| G5 | DPS:60; TessGrammar.swift:141 | "sick today" makes task "Sick" at 1 pm (day-marks.md D4); Push B stays; no `rest` | P07: no "Sick" block, `rest:true`, no w1 | Day marks (147, DG2, DG3) feed `restDay` | Core |
| G6 | DP:211; PW:105 | With titles on: no URL cleaning, no 40-character cap, no limit of 3 all-day titles, no over-400 merge | P05 as above (calendar-pack.md:46-74) | Clean in the EventKit reader before `PlanInput.Event`; merge rule in `PlanPack` | Builder B (reader), Core (merge) |
| G7 | PW:444 | Estimate counts `"\(dict)"`, not `pack.json` | Bytes of the wire pack | Estimate on `pack.json` | Core |

**Ruled (Product, decisions.md 12:06 PM PT):** a screened task goes as "task" and a screened event as "busy" (core.md aligns). Money words with no amount go as typed, as the 12:04 "pay" ruling; a medicine with a dose ("Refill lexapro 10mg", P04) is a health fact and is screened. G1-G7 are one Core PR with A3, A4 and CA4 before Builder B wires it. The 1,270 vs 1,160 token gap is with AI architecture.
