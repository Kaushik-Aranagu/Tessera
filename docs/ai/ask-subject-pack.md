# `AskSubjectPack`: ask about this (spec for Core)

*AI architecture, Oct 17, 2026. Job 2 of `side-jobs.md`. Research's walls and packs are `docs/research/fixtures/ask-about-this-walls.md` (AW1 to AW20). New code is marked "new".*

## 1. What it does

Opening the ask slot on a side makes this thing the subject. `AskSubjectPack.build(subject:question:settings:)` (new) returns one of three results: a pack for the phone's own answer, a pack for Claude as well, or a refusal line with no payload.

## 2. The opt-in

- **Default: nothing from a side goes to Claude.** The phone answers every ask about a subject from its own store (Product 2:52 pm).
- **A class opts in** with a setting per class, off until he turns it on. Only the two public-name classes can opt in: Ingredient and Exercise. The setting sits under "Tess asks Claude" and does nothing while that switch is off.
- **Habits, Settings, money and body sides never opt in.** The setting does not exist for them.

## 3. The Claude payload

`{"subject": {"handle": "s1", "class": "exercise", "name": "Bench press"}, "fields": {...}, "question": "..."}`

- The real id never leaves the phone. The handle maps back on the phone.
- `name` is sent only for Ingredient and Exercise, after the walls pass on it. Every other class sends the class word in lower case.
- `fields` are only those the walls table marks "Claude yes" (public facts: the muscles, the table's per-100 g values). No notes, history, amounts, weights, places, people or health.
- The question is the typed text, unchanged.

## 4. Order of checks (first match wins)

1. Key shape in the question: refuse with the key line, no event.
2. A secret word in the question: "It's in your private notes."
3. Money or a body fact in the question: "That stays on this phone."
4. The switch off, the class not opted in, a demo launch or no key: the phone's own answer only, no Claude event.
5. At the monthly cap: the phone's answer, "Claude paused until Nov 1."
6. Otherwise: pack for Claude.

His intake ("is this enough protein for me") answers with one ingredient's table value on the phone and never goes to Claude (Product 2:36 pm).

## 5. Job settings and worst-case cost

- **Job:** `TessJob.askSubject` (new), Sonnet 5.5, effort low, `maxTokens` 300, timeout 8 s, no retries, `toolChoice` auto, no write tools. The answer is words only, wet then dry in Tess's band, under the line caps.
- **Body cap:** 1,200 bytes. The worst-case input is `1,200 / 4 + 10 + 500` (tool overhead) = 810 tokens.
- **Worst case per ask (Sonnet 5.5):** 810 x 2,000 + 300 x 10,000 n$ = 4,620,000 n$ = **$0.0046**.
- **Per day:** 20 asks a day, counted in the ledger (job "askSubject"), is $0.092 worst case. At the 21st the phone answers alone. This stays well inside the $50 month: 30 days of the worst case is $2.77.
- **Step-aside:** none. Questions keep running at 80% ($40) up to the $50 cap (Product's 8:16 ruling); only Home lines, the week story and living colour step aside.

## 6. Tests Core writes

1. All 20 AW packs through the packer alone (no call): the hard-fail strings (a private field, a note's words, money, a body fact, a secret or anything key-shaped) appear in neither payload.
2. A class that is not opted in, or the switch off, builds no Claude payload.
3. `name` is present for Ingredient and Exercise and absent for Recipe, Muscle, Equipment and every other class.
4. The 21st ask in a day makes no request and no ledger row.
5. A refused ask makes no Claude event (Product 12:12 pm).
6. The body never passes 1,200 bytes for any AW pack.
