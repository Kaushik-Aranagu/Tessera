# Product decisions log

*Small calls made by Product so that fixtures and builds stay consistent. Newest first. Kaushik's own decisions are in `morning-questions.md`.*

## 2026-10-15 18:41 (Kaushik)

- **Home rail:** add KITCHEN as a fourth word, next to Review, Today and Training. Yes.
- **Claude for Plan my day:** yes. M4 slice 6b is unparked.
- **Claude as a foundation:** Claude is part of the base, built in as early as possible, not bolted on later. A "Tess model layer" foundation slice goes early in the queue after tonight's release.
- **Fetching a recipe page from a pasted link:** approved. It goes into kitchen v2, which still waits for a week of use.
- **Apple Watch:** yes. Sleep stages and resting HR are in (M4 slice 2), and the "In bed" fallback stays for nights without the Watch.
- **First phone build:** cut at 19:45 UTC, reviewed with `review-session.md`, then a huddle to make the plan concrete.

## 2026-10-15 18:40 (from Research #78)

**Plan my day (M4 slice 6)**
- The plan window ends at 21:00, when Shutdown takes over. DayLoad counts free time until 23:00.
- Ghost lines in the plan are tasks only. Events and the workout appear in the header line, not as lines.
- On a full day, tasks that would otherwise be offered for Later are left out.
- Priority is ignored, because `Task` has no priority field.

**Health and Calendar (M4 slices 1 and 2)**
- Without an Apple Watch, sleep shows time in bed ("In bed 7h45").
- Resting HR older than 36 hours is hidden.
- If calendar access is denied, Tessera says so plainly in one line with a link to Settings, never as an error.

**Questions and saved queries (M3 slices 4 and 7)**
- Adopt the minimal query AST proposed in `../research/questions-eval.md`.
- Movement pattern is a field filter, not a class lookup.
- List items get a date field (already part of Lists slice 2).

**M5 Reading**
- Approved as `ship-list-m5-reading.md`, with all of its defaults. A book never takes Now from a workout. Books appear in the evening slot from 19:00. The queue is a book state. Books are never put away. Setting a book aside can be undone. Reading is its own small app, and works offline first.

## Earlier

- **Body weight:** the trend line is the headline.
- **Lists:** "reusable", never "template"; the M3 List shape creates a List; Copy sits next to Reset; a skip is not a pick; a preview appears before saving a paste.
- **Tess:** grammar first, then the on-device model; cloud models need Kaushik's OK.
- **Cook mode:** Core builds it, and Builder A reviews the shared instruments.
- **Tess model layer reconciled with Research (18:50):** Research's T1 to T7, S1 and S2 are the build plan. The cap is $10 a month, hard stop, with no daily cap (replaces $5 and $0.50). Streaming is allowed. The beta Swift package is the planned transport, but Core confirms it in T1. Three Claude questions go to the huddle with defaults.
- **"call mum thu" said on a Thursday means today** (18:58), as people talk. The code changes in Core's grammar collision item.
- **Grammar collision fix goes right after model layer T1/T2, ahead of Groceries polish** (18:58), since Kaushik types into Tess from tomorrow.
- **Cook mode gets its own idle rule** (18:58): never suspended while a timer runs or within 45 minutes of the last step. Paste parser gaps get a paste-hardening slice with `packSize` and `section` fields.
- **No rounded-rectangle, oval or pill buttons anywhere, Apple defaults included** (Kaushik, 19:00). Design writes the replacement language and audit (`docs/design/no-buttons.md`). One sweep after the install: Builder A first puts the shared style in DesignSystem, then Builder A, Builder B and Core each sweep their own screens.
- **M5 Money ship list approved** (19:07) from Research's draft with all seven defaults: no home currency, bare amounts only with two decimals or a currency mark, "total?" asked once after a shop, category is one word, ordinal in feedback, its own small app, bank data parked. It lives at `ship-list-m5-money.md` and comes after Reading.
- **Recipe link fetch uses an honest Tessera user agent** (19:07), not a Safari-like one. When a site blocks it, Tess says so and offers "paste the text". This keeps kitchen-v2's no-spoofing line. Without a Share Extension on free signing, the entry point is an App Intent plus a Shortcut. Recipe needs a `sourceURL` field, and CreateRecipe needs a URL input, both in kitchen v2 L1.
- **Apple Watch: no Watch app yet** (19:11). Read sleep, resting HR, HRV and workout HR from Health. Now: W1 (HR on the summary) and W2 (the rest Live Activity on the Smart Stack). Later: W3 (recovery line with M4 slice 2) and W4 (de-duplicate Watch workouts).
- **M5 Home upkeep ship list approved** (19:11) with all seven defaults (`ship-list-m5-upkeep.md`). It comes after Money and needs M3 slice 2.
