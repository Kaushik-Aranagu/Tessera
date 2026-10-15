# Product decisions log

*Small calls made by Product so that fixtures and builds stay consistent. Newest first. Kaushik's own decisions are in `morning-questions.md`.*

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
