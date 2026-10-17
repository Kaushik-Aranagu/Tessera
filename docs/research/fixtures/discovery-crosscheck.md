# Discovery gaps against the boards

For: Product lead, Research lab, Date: 2026-10-17

I checked all 14 gaps in discovery-gaps.md against every file in ops/board and board.md, matching the Evidence files and symbols as well as topic words. Each gap was boarded under "DISCOVERY items" at the 5:51 PM decisions, and later riders (6:00) sharpened the done-whens. A line counts as OWNED only if finishing it would make the gap's "Done when" true. Eleven gaps are OWNED and three are PARTLY owned. None is fully UNOWNED. Line numbers refer to files in ops/board (D = discovery item letter on that board).

| # | gap (5 words) | owner per gaps doc | status | board line cited | what is missing |
|---|---|---|---|---|---|
| 1 | Task finish haptic wrong, doubled | Builder B, Core, QA | OWNED | ios-b.md:163 (D1); qa.md:31 (D3); core.md:264 (D6, HapticLog) | nothing |
| 2 | Capture made, listening haptics | Builder B | OWNED | ios-b.md:164 (D2), cue-count test added at :174 (D10) | nothing |
| 3 | Raw sensoryFeedback scattered everywhere | Builder B, Builder A, QA | OWNED | ios-b.md:166 (D4); ios-a.md:109 (D1); qa.md:31 (D1) | nothing |
| 4 | No-dots rule unapplied in screens | Builder B, Builder A | PARTLY | ios-b.md:165 (D3), allowed list at :174; ios-a.md:110 (D2) | PaintDab doc-line change and the per-screen recording or UI-test rows from no-dots.md; only design.md:153 mentions the lint wording, report-only |
| 5 | Failed write still says done | Core, Builder B, Builder A, QA | OWNED | core.md:258 (D1), :265 (D7); ios-a.md:112 (D4), :114 (D5); qa.md:31 (D2) | nothing |
| 6 | Widgets and Lock Screen missing | Builder A, Core | OWNED | ios-a.md:111 (D3); core.md:260 (D3); ios-a.md:74 retired | nothing |
| 7 | Siri intents cannot read or add | Core, Builder A, QA | PARTLY | core.md:259 (D2), :264 (D6 receipts) | snippet display in baseline language is not in any build line (design.md:152 D4 only reviews widget and snippet states); shortcut phrases for the new intents (Builder A) are not named |
| 8 | No lint for house rules | QA | OWNED | qa.md:31 (D1), :32 (D4); core.md:262 (D5 lands it) | nothing |
| 9 | Private notes in iCloud backup | Research, Design, Builder B | PARTLY | ios-b.md:170 (D8); design.md:152 (D2) | the decision is made (everything is included) but no line asks for a test covering it |
| 10 | Quiet failures have no surface | Builder B | OWNED | ios-b.md:169 (D7), storage and clear-on-success test at :174 | nothing |
| 11 | Miss log lacks file protection | Core | OWNED | core.md:261 (D4) | nothing |
| 12 | Task-reward flight beats unbuilt | Builder B, Motion lab, QA | OWNED | ios-b.md:168 (D6), tests at :174; motion.md:35; design.md:152 (D3, fleck stays) | nothing |
| 13 | Groceries shop finish has no line | Builder B, Kitchen | OWNED | ios-b.md:167 (D5), UNDO window at :174; raw impacts covered by :166 (D4) | nothing |
| 14 | No "what was sent" screen | Design, Builder B | OWNED | design.md:152 (D1); ios-b.md:171 (D9) | nothing |

## Unowned or partly owned

- Gap 4 (PARTLY): Add to Builder B D3 and Builder A D2: "Change PaintDab's doc line to data marks only, and add the no-dots.md recording or UI-test row for each touched screen."
- Gap 7 (PARTLY): Add to Core D2 and Builder A: "Each new Siri intent returns a snippet in the baseline language and gets a shortcut phrase in AppIntentsPackageLink, checked against Design's snippet states."
- Gap 9 (PARTLY): Add to Builder B D8 (with QA): "A test asserts the Backups copy contains private notes, weight and money, matching the line that says so."
