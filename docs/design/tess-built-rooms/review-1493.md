# Design review: #1493, Chart room R1 step 1 (Core)

From: Design, Oct 27 2026, 5:20 PM PDT. Read against `r1-spec.md` and sheets 357 to 368. Only the look and wording rules are reviewed here. The engine code is Core's.

## Holds up

- Text: 80 characters a line, and a trailing full stop is stripped before anything is written (`RoomPatchValidator.cleaned`). The kit description sent to the model says so too
- Key-shaped text is refused in every word of a patch, with a plain reason
- Money: `pool`, `inflow`, `poolMove`, `spend` and `rateNote` (and subclasses) can't be written, with "Rooms can't change money"
- Single-occupant places (title, glyph, actionWord), 24 parts at most, 4 colors at most, colors as roles and never hex
- Reasons read as plain sentences, never "error" or "invalid", which matches sheet 361

## Needs a change

1. **Ember is in `RoomKit.colorRoles`.** Ember is Tess's own color, and nothing a room draws may sit within ΔE 10 of it. Cobalt is Tess's voice (`AppAccents`, `AreaColour`). Take `ember` and `cobalt` out of the roles a room can use. A request for either gets the 361 refusal with an offer: "That's Tess's color. Slate instead?"
2. **A room's own color must not be another room's** (sheet 365, now in `r1-spec.md` section 4). The room's own color must sit ΔE76 20 or more from every other room's color, in light and dark. Of today's roles, only `slate` and `olive` pass. `ochre` is the Galley's, `sage` the Purse's, `dusk` the Watch's, `violet` the Notes accent and `rain` is 15.9 from the Purse in dark. Those can still color a part inside the room (counted in the 4), but not `RoomDocument.color`. Teal isn't a role, which is right: it sits 6.8 from the Purse
3. **Fixture:** once the room is named "Plants" it's olive (sheet 365), so set `"color": "olive"` in `fixture-chart-room.json`. The keystone number's unit `"d"` should be the word `"days"`. Units are words shown at half the numeral size, as on the board ("6 days")

## For Builder A, from the same read

- `colorsInUse` counts the room's own color plus each part's. The board's plant room uses olive (the title and Watered), slate (the Say word), wine (the glow) and ink, with ink 2 counted as ink. That's four, at the limit, so a fifth role is refused, which is what the board expects
