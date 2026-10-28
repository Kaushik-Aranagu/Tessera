# Lookout, Level 1 and Level 2: what still differs from the board

Checked on Oct 28 against Builder A's `ios/deck-levels` at a08a8a3d (the root shell, where the Lookout is `LookoutRoomContent` with `LookoutRoomDriver`) and against master. The contract is sheet 284 (`docs/design/levels-284.md`). The board is https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp v114: open the Lookout, turn the dial, tap a door, then tap the 7 PM row.

## Where it stands

- On `ios/deck-levels` the Lookout sits in the root shell. The plate, the skypiece and the caption stay put when a door opens, which is right
- Level 1 is a plain `.list` of one-line strings ("7 PM 60° rain", "Thursday mainly clear, high 68°, low 56°")
- There is no level 2. In the root shell a row tap does nothing (`LookoutRoomDriver.handle`: "a page row has nothing deeper yet"). In `LookoutShellHost` it opens `LookoutDetailPage` as a sheet
- On master (and behind `-classicBridge`), a door still pushes `WeatherDoorPage`. That page has the back word "Lookout", the door name in amber, and plain lines on the house background, so the sky leaves

## The move

1. **Build both levels on the kit, as with the Deck**
   - Level 1 uses `RankedPage`, not `.list`
   - Level 2 uses `ItemPage` on the shell's level 2 route, not a sheet
   - The kit-wide fixes in `docs/design/levels/deck-checklist.md` apply here too: units, settle, and captions per door
2. **No full stop at the end of any shown line.** `LookoutRoomContent.Facts.detail(forRow:)` still has:
   - "Dry." (twice)
   - "Wet. Take a coat", which should read "Wet, take a coat"
   - "Wet. Plan for rain", which should read "Wet, plan for rain"

   The landing's own lines are already clean on this branch

## The frame

3. **Nav word.** It reads "Doors" at level 1 and the door's name at level 2. Today it reads "Lookout"
4. **Door title.** The name is 34 pt bold in ink, over its line at 15 pt in ink 2.
   - Today the name takes the dial's color: the hour's condition color, rain blue, or the good-air green
   - The three biggest words (Title, Door title, first row) never share a color, and the room's amber title is already one of them
5. **Caption.** Each door has its own caption, at both levels. Each one says what the glass does on that door:

   | Door | Caption |
   |---|---|
   | Hours | "The glass beads up an hour before rain" |
   | Tonight | "The sky darkens with the hour" |
   | This week | "Swipe the sky across for each day" |
   | Air | "The clouds move with the wind" |
   | Sky | "Night comes into the glass at sunset" |

   Use a caption only once the skypiece really does what it says. Until then, keep the landing's brief there, because a caption must stay true
6. **Foot, level 1 (new on the board in v114).** "Alert" with "before rain", then "Ask" with "Tess about {door}".
   - The other rooms say "Add" here, but the Lookout has nothing to add to
   - Alert's receipt is "Rain alert on, you’ll hear 30 minutes before", with Undo
   - Today the landing's three steps (Alert, Hours, Walk) show at every level, and "Hours, Next 12 hours" sits on the Hours page itself
7. **Foot, level 2.** It shows the hour's own verbs: "Alert" with "30 min before", then "Walk" with "before 6:30"
8. **Tess.** Tess stays bottom-right at every level. The root shell draws her through `BottomChrome`, so she's there. `LookoutRoomDriver.tessRoom` is nil, so she doesn't know which room she's in. Give her the Lookout if `AppID` can carry it

## The doors (level 1)

9. The board has five doors: Hours, Tonight, This week, Air and Sky. The app has three.
   - "Week" becomes "This week"
   - Add Tonight and Sky once the facts below exist
   - Until then, show only the rows the snapshot can answer. The rank weights still fill the block

   Each door below gives its line, then its rows (a row is title, sub, value):
   - **Hours**: "Rain from 7, clear by 1 am", which is the change said short
     - One row per hour: "7 PM", with the word as its sub ("Rain starts", "Rain", "Rain, steady", "Easing"), and the temperature as its value
   - **Tonight**: "Rain until midnight"
     - Rain, "From 7 until midnight", 90 %
     - Low, "Around 3 am", 54 °
     - Clear, "By 1 am, stars after 2", 1 AM
     - Wind, "Gusts ease after 10", 9 mph
   - **This week**: "Driest on Thursday"
     - One row per day from tomorrow: the weekday, its word ("Dry and bright", "Clouds by afternoon"), and the high
   - **Air**: "Clean air, a light wind"
     - Wind, "From the west, gusting", 9 mph
     - Humidity, "Rising toward rain", 58 %
     - Air, "Clean", 21 AQI
     - Pressure, "Falling slowly", 29.9 in
   - **Sky**: "Sunset at 6:08"
     - Sunset, "Behind the rain", 6:08 pm
     - Moon, "Waxing, half", Half
     - Sunrise, "Tomorrow", 7:24 am
     - Daylight, "Two minutes less", 10:44 h
10. **Rows.**
    - The first row is bold, in the Lookout's amber mixed 58% with ink. The rest are ink
    - Values are Outfit Light at 0.82 of the title size and stay ink. The unit (°, %, mph, AQI, in, am, pm, h) is set at half the value's size
    - The sub is 13 pt in ink 2, and shows only on rows taller than 40 pt
    - Never name a city or a place

## What the snapshot can't answer yet (for Core)

11. **Today's `WeatherSnapshot` holds:** each hour's temperature and condition word, the week's highs, lows and words, an air word ("good"), the UV index and one wind number
12. **Core's unmerged `core/weather` (`WeatherReport`) already reads:** each hour's chance of rain, gusts, wind direction, sunrise and sunset, and the US AQI. Merging it, and adapting the snapshot, answers Tonight, the Air rows except humidity and pressure, and Sky's sunset, sunrise and daylight
13. **Nothing reads these yet:**
    - Humidity and pressure. Both are free in the same Open-Meteo call: `relative_humidity_2m` and `pressure_msl`
    - The moon's phase, which can be worked out on the phone with no call at all
14. **Sample data.** The sample snapshot needs the same facts, since sample data stays on until production

## The hour page (level 2)

15. **Title.** A row opens its item page. The Item title is the hour ("7 PM") over "Rain starts, 60 degrees". Across goes to the next hour
16. **Facts.** Three columns: 60 ° temp (the first in the room color), 90 % rain, and 9 mph wind
17. **Body: the `hours` kind.** This is a new kind next to `SetsBody` in the kit.
    - It shows four rows, from the hour before to two hours after: 6, 7, 8 and 9 PM
    - Each row is 44 pt tall. The time is 14 pt in ink 2, the word is 17 pt in ink 2, and the temperature sits on the right in Outfit Light 20 in ink
    - The opened hour's row is in ink, with its temperature in the room color at weight 400
    - Under the rows, one advice line in Figtree 15/22 in ink 2: "Take the umbrella if you go out after 6:30". It has no full stop (the board had one, fixed in v114)
18. **Other rows.** Rows on the other doors open the siblings body from the kit until their own page is drawn. That body lists the door's rows with this one in the room color, and its foot is "Open" and "Ask"
