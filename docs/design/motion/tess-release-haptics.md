# Haptic and soul beats for release 1 and the surfaces just before it (lab, board REFILL 2 item 3)

One haptic per moment, always from `DesignSystem/Haptics.swift`'s `Haptic` map (no new case unless named below). Done
never changes. Sources: `docs/research/new-on-your-phone-v9r.md`, #580, #583, #553, #576. Values are lab defaults for Design
to overrule; "none" is a decision, not a gap.

| Surface | Moment | Haptic | Tess |
|---|---|---|---|
| Plan my day (#529) | Swipe right arms (the commit is about to happen) | `.selection` once at the arm threshold | Nothing. She is not part of the planning |
| | The row is kept | `.made` ("a plan is kept"), once | If a line shows ("Plan kept. Push A is up."), it lands as any line does |
| | Swipe left: skip | `.notNow` ("the row moves"), once; nothing is written | Nothing |
| | Hold "Start with ..." keeps them all | One `.made`, never one per row | The same |
| | UNDO on the plan | `.undo` | Nothing |
| | The offer is spent (hero swipe left) | None | Nothing |
| Receipts, thing first (#547) | A line like "Bench press, moved to 3." | None for the line itself; the action that made it already played its haptic | The line lands in her band as any line |
| | "Push A, taken back." (UNDO) | `.undo`, once | Nothing |
| Day log "best" (#512) | A set beats his best | `.newBest` at the set (in place of the tap), not again when the Day log shows "best" | The §14 beat as built. Reading the log is silent |
| Time words (#507, #546) | 12-hour text everywhere | None | None |
| Late nights, 4 am day (#507) | A workout past midnight reads Friday | None | None. The 04:00 day boundary is the same one idea 2's wake uses |
| Resume key progress (#546) | The ink line fills by planned sets | None (the set's own `.setLogged` stays) | None |
| Tess stretches on Home (#558) | The first open of the day | None | Idea 2, as built and passed |
| Private notes (#580, #583) | The "Private note" label, a private row, the foot line on Review | None | None. No glance, no pause, no beat, and no difference from a note that isn't private (tess-sides-motion.md) |
| | A secret question, "It's in your private notes." | None for the line | The line lands as any line; no extra beat |
| Review foot line (#583) | The line sits above her band | None | It stays above 736 and never shares the band, so nothing of hers moves for it |
| Quiet hours and the night fall-back (#553, #576) | Her times never land 23:00 to 07:00; the night's end moves with the clock change | None | Idea 5's sleep window is 23:00 to 07:00 and follows the same hours; on a 25-hour night she wakes at 07:00 clock time, not by elapsed hours |
| Siri asks for Face ID | The sheet | System's own | Nothing |
| Siri private save: "Private note, kept." | The line | None | Calm, as a private label |

## Tests
- A kept plan plays one `.made` however many rows it holds. A skip plays one `.notNow` and writes nothing.
- A private label, a private count and a non-private one produce identical soul events.
- On the DST fall-back night, idea 5 still wakes her at 07:00 local time.
