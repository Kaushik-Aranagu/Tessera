# Plan my day: blind read, Haiku against Sonnet

For: Kaushik (the read), Core (the fill-in), Product (the gate). Research lab, board item 79, 2026-10-16.
Inputs: `fixtures/plan-my-day-claude.md` (the 23 packs, section 5's human read and Haiku bar), `plan-my-day-prompt.md` (reply schema), `tess-voice.md`, `product/decisions.md` 7:44 PM PT (use 2 gate with 23 packs).
State: no model has been called and no key is in. Every `{{dNN.A}}` and `{{dNN.B}}` below is an empty slot until the eval runs.

## 1. How to read it (a few minutes)

- Each row is one morning. Read the one-line day, then plan A and plan B. One is Haiku, one is Sonnet; the letters are shuffled, and the key is folded shut at the very end. Don't open it until every row is ticked.
- **Sounds like Tess:** tick A, B, both or neither. Yes means you would be happy to see it on Now as is: short, plain, offers instead of telling, no guilt, no counts, nothing she couldn't know (`tess-voice.md`).
- **Better:** tick one of A, B or same. "Same" means you'd take either one; use it freely, don't hunt for a winner.
- **Take back:** if any single line is one you would take back, strike it through (`~~like this~~`). The gate needs 0 of those on Sonnet's side.
- Each slot reads as: start line, then each task with its time, then the gym line if any, then the note. Every time on the sheet is Pacific wall-clock (2 to 24 Nov 2026, all PST).
- The "Watch for" hints name the slip each day tempts. They describe the day, not either plan.
- About 15 seconds a row, 22 rows: five to six minutes.

## 2. The 23 mornings

**d01** Mon 2 Nov, 8 am. Landlord reply, expense report (due 5 pm), physio; Standup, Design review, 1:1 Priya; Push A 6 pm.
- A: {{d01.A}}
- B: {{d01.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d02** Tue 3 Nov, 8 am. No calendar access; bank call, bike light, 2 hours on the garage; Pull A 6 pm. Watch for "clear" or "free".
- A: {{d02.A}}
- B: {{d02.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d03** Wed 4 Nov, 8 am. Lease email, PR 412 (due noon), timesheet; Standup, Sprint planning; Legs A 6 pm. Short night, never sent.
- A: {{d03.A}}
- B: {{d03.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d04** Thu 5 Nov, 8 am. Light day: Q4 goals (due 5 pm), council tax; Standup, Client call, Team lunch; Push B 6 pm, no gym line.
- A: {{d04.A}}
- B: {{d04.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d05** Fri 6 Nov, 8 am. Visa form, invoice, fridge; Standup, All-hands, Vendor call; Pull B moved to 6:30 pm. Watch for "pushed back".
- A: {{d05.A}}
- B: {{d05.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d06** Sat 7 Nov, 8 am. Call mum, Parkrun 9 am, Legs B 11 am, lunch with Nikhil, garage after, carbonara 6 pm. Nothing to reorder.
- A: {{d06.A}}
- B: {{d06.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d07** Sun 8 Nov, 8 am. Meal prep list, bike light, photo backup before brunch at Anu's 11 am. No workout. Watch for gym or rest talk.
- A: {{d07.A}}
- B: {{d07.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d08** Mon 9 Nov, 8 am. Car insurance (due noon), contacts, Lisbon trip after Standup; Quarterly review; Push A 6 pm.
- A: {{d08.A}}
- B: {{d08.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d09** Tue 10 Nov, 8 am. Light day after a missed Push A; landlord reply, fridge; Hiring panel; Push A 6 pm. Watch for "again".
- A: {{d09.A}}
- B: {{d09.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d10** Wed 11 Nov, 8 am. Light, meetings back to back until 6 pm; expense claim, slides after Pull A. Watch for meeting counts.
- A: {{d10.A}}
- B: {{d10.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d11** Thu 12 Nov, 8 am. Flowers (due noon), photo backup; Standup; Legs A 6 pm; Call mum 7:30 pm. Mum's birthday is never sent.
- A: {{d11.A}}
- B: {{d11.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d12** Fri 13 Nov, opened 11:07 am during Design crit; landlord reply, invoice, parcel; Retro 4 pm; Push B 6 pm. Watch for "late".
- A: {{d12.A}}
- B: {{d12.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d13** Sat 14 Nov, 8 am. Plants, Amazon return, call grandma (30 min each, no lengths set); Haircut 10 am; Pull B 5 pm.
- A: {{d13.A}}
- B: {{d13.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d14** Sun 15 Nov, 8 am. Empty day. **Skipped:** no call is made, both sides show the rules card. Nothing to tick; scored in section 3.

**d15** Mon 16 Nov, 8 am. Light day, five fixed things including Dentist 3 pm; Call GP, receipts; Legs B 6 pm.
- A: {{d15.A}}
- B: {{d15.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d16** Tue 17 Nov, 8 am. Flights (due 4 pm), cancel gym trial, sign NDA; Standup, Arch review; Push A 6 pm. Declined pitch never sent.
- A: {{d16.A}}
- B: {{d16.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d17** Wed 18 Nov, 8 am. Light interview day; feedback for Ana, team lunch order between interviews; Debrief; Pull A 6 pm.
- A: {{d17.A}}
- B: {{d17.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d18** Thu 19 Nov, 8 am. Light day opening with Legs A at 8 am; insurer call, electricity bill; Ops review. Watch for training advice.
- A: {{d18.A}}
- B: {{d18.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d19** Fri 20 Nov, 8 am. Library book, Lisbon trip; Standup, Friday demo; Push B 6 pm, then cook chilli for 90 min.
- A: {{d19.A}}
- B: {{d19.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d20** Sat 21 Nov, 9 am. Legs B already done (not sent); Call mum, car wash, Kids football 10 am, garage after.
- A: {{d20.A}}
- B: {{d20.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d21** Sun 22 Nov, 8:30 am. Planned rest day; haircut booking, bathroom, Farmers market 10 am, meal plan after. Only "Rest day." allowed.
- A: {{d21.A}}
- B: {{d21.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d22** Mon 23 Nov, opened 7:40 am, Push A under way since 7:05 am; Priya reply, flights, dry cleaning. Watch for "start Push A".
- A: {{d22.A}}
- B: {{d22.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

**d23** Tue 24 Nov, 8 am. Rhea in town; Anu's gift, parking permit; Standup, Sprint review; Pull A 6 pm. Anu's birthday is never sent.
- A: {{d23.A}}
- B: {{d23.B}}
- Sounds like Tess: A [ ] B [ ]   Better: A [ ] B [ ] same [ ]

## 3. Scoring (after every row is ticked)

Open the key at the end and write which letter was Sonnet and which was Haiku on each row. Then count, against Product's gate (decisions.md 7:44 PM PT: raw 21 of 23, human read 19 of 23, Haiku wins or ties 18 of 23):

- **Sounds like Tess (Sonnet):** rows where Sonnet's letter is ticked, plus 1 for d14. Passes at **19 of 23** or more, with 0 struck lines on Sonnet's side.
- **Sounds like Tess (Haiku):** same count on Haiku's letter. Haiku only takes over plan wording if it also reaches 19 of 23 on its own.
- **Haiku wins or ties:** rows where Better is Haiku's letter or "same", plus 1 for d14. Passes at **18 of 23** or more.
- **"Same" counts as a tie:** it counts for Haiku in "wins or ties" and is never a Sonnet win. A row with no Better tick counts as a Sonnet win; better to go back and tick it.
- decisions.md lists the Haiku count with the use 2 gate; the fixture (section 5) reads it as the bar for Haiku replacing Sonnet. The count is the same either way; Product says which it gates.

**d14 and 23 against 22.** Only 22 packs are called; d14 has no reply to read. The sheet credits d14 on both counts, as the raw bar already does ("d14 passes by making no call"): the rules card is the same on both sides and says nothing Tess would take back. With that credit the bars on the 22 rows read are **18 of 22** sounds like Tess and **17 of 22** wins or ties. These are exactly the decided rules redone on 22: 80% of 22 is 17.6, rounded up 18; 75% of 22 is 16.5, rounded up 17. So 23 against 22 does not change the gate. It would change only if someone counted 19 and 18 out of the 22 read rows (86% and 82%, one row stricter each). Product to confirm the d14 credit in one line.

## 4. Fill-in recipe (for whoever runs the eval)

1. Run the eval as in `fixtures/plan-my-day-claude.md` section 7 (`-planEval`, key in the Keychain only). It writes one file, `Application Support/Tessera/evals/plan-<yyyy-MM-dd-HHmm>.json`, with a record per call: `id` (d01 to d23), `model`, `run`, codes, tokens, n$, ms and the reply JSON. Pull it with `xcrun simctl get_app_container booted com.kaushikaranagu.tessera data`.
2. For each pack, take **run 1** of `claude-haiku-5-5` and run 1 of `claude-sonnet-5-5`. If a run 1 has no decodable reply (code V1), use run 2, then run 3; if none decode, the slot is the rules plan text "Here's your usual plan.". Keep replies that broke a rule as they are: the read is of what he would see, not of what passed.
3. Open the key at the end. Where it says "A = Haiku", Haiku's reply goes in `{{dNN.A}}` and Sonnet's in `{{dNN.B}}`; "B = Haiku" swaps them.
4. Write each slot as one line from the reply only: `Start: <startWith.line>` / then per ghost line in run order `<block start as am/pm> <task title>: <line>` / then `Gym: <workout lineText>` only if not empty / then `Note: <note>` or `Note: none`. Separate parts with " / ". Times as "8 am" or "8:15 am", never 24-hour.
5. Leave out everything that could unblind the row: model ID, run number, codes, tokens, cost, latency.
6. d14 has no record and no slot. Don't touch the ticks, the summaries or the key. Save the filled copy as `plan-my-day-blind-read-filled.md` next to this one, so this blank stays reusable for a rerun.
7. Never paste the key, request headers or anything from the Keychain into any file.

<details>
<summary>Key: which plan is Haiku (open only after every row is ticked)</summary>

Rule: for pack `dNN`, take the first hex digit of the SHA-256 of the text `tessera-79-dNN` (no newline). 0 to 7 means A is Haiku; 8 to f means B is Haiku. Reproduce with `printf 'tessera-79-d01' | shasum -a 256`.

| Pack | Digit | Haiku | Pack | Digit | Haiku |
|---|---|---|---|---|---|
| d01 | a | B | d13 | 7 | A |
| d02 | f | B | d14 | 1 | (skipped) |
| d03 | c | B | d15 | 6 | A |
| d04 | 1 | A | d16 | 6 | A |
| d05 | f | B | d17 | a | B |
| d06 | d | B | d18 | 9 | B |
| d07 | 3 | A | d19 | 3 | A |
| d08 | 2 | A | d20 | 3 | A |
| d09 | 3 | A | d21 | 0 | A |
| d10 | 7 | A | d22 | 4 | A |
| d11 | 2 | A | d23 | a | B |
| d12 | d | B | | | |

Of the 22 read rows, Haiku is A on 13 and B on 9.

</details>
