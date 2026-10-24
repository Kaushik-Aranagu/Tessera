# Weather room handoff (Codex checkpoint, Oct 24)

## State
- **#1401** `claude/project-thread-kyu5l0`, head `a6f28164`: the room (landing, Day page, hour strip, sample forecast, `WeatherForecastSource` seam), QA's FIX FIRST items folded in. Cloud-written, NOT COMPILED. Core must compile it, run swiftformat and swiftlint, and run `WeatherSentencesTests` and `WeatherRoomUITests`.
- **#1402** `claude/weather-adapter`, head `0a78f359`, base `core/weather`: Core's `WeatherReport` mapped onto the room (`WeatherCoreAdapter`, `CoreWeatherSource`), #1401 merged in, one wind rule. QA passed the earlier head with notes; the notes are folded in. Not compiled.
- `HomeLink.weather` (title and destination) is the only edit outside `Features/Weather/`; `-openLink weather` opens the room for UI tests. Builder A owns Home routing and the weather-word effects (`WeatherSentenceText` is the only place they replace the plain color).
- Merge order: `core/weather` (Core), then #1402 (it carries #1401), or #1401 to master first and re-target #1402.

## Left to wire
- **Location:** the host reads the phone's coordinate once and passes it to `CoreWeatherSource(source: OpenMeteoSource(), coordinate: ...)`. The room still defaults to `SampleWeatherSource`. Nothing may keep the coordinate, and no city is ever shown or stored. Location never reaches backups, logs or widgets.
- **Rain alert:** the room toggles `weather.rainAlert` in UserDefaults and calls `onRainAlert(Bool)`. Core must schedule or cancel the "30 minutes before rain" notification (use `WeatherReport.nextPrecipitation(after:)`).
- **Wind direction:** Core has none, so the air line reads "wind 9 mph" without "from the west". Add a direction to `WeatherReport.Now` and set `WeatherAir.windFrom` in the adapter.
- Hours past the 48-hour window have no columns; the Day page hides the strip for those days.

## Rules in force
Two colors for conditions (rain color for everything that falls, one slate for the rest), amber title, big type never shares a color, temperatures in ink, "good" in ink2. Sentence case, no cards, pills, bars or middle dots. Reduce Motion cuts. GestureTuning for every swipe; every tap target has a UI tap test (G11-G13). The hour strip owns drags that start on it (high priority, across or up and down).

## Sheet 243 spec (board https://claude.ai/artifact/NyeaiLgka6cPQX3vqWZ1jj)
Landing (402x874):
- y 54: "Weather" 40 pt, weight 600, sky amber C9772E/E8A06A; the time at right, Outfit 15, ink2.
- y 112: current temperature, Outfit 200 at 104 pt (degree sign 52 pt). To its right, 15 pt ink2: "feels like 55°" and "high 61°, low 49°".
- y 238: line 1, 26/500: "<Cloudy> now, <Rain> from 4 PM." (weather words).
- y 276: line 2, 17 pt ink2: "<Heavy rain> after 6 PM, clearing by midnight."
- y 330: "Next hours". y 350: hour columns, 59 pt wide: time (13 ink2), temperature (Outfit 300 at 24), one word (13/600 in its color). Dragging across or up/down pages 3 hours at a time.
- y 456: "The week". y 476: one sentence, 22/500, line height 34, naming only the notable days; each weather word is a door to its day, 44 pt hit area.
- y 640: "Air is good, UV 2, wind 9 mph from the west." 15 pt ink2.
- Foot: action word "Rain alert" in the rain color 557A93/9DBACE, at least 28 pt from the left edge. A tap toggles it and shows "You'll hear 30 minutes before rain." with Undo for 10 s. Tess sits on the right.

Day page:
- Back word "Weather", then the day name at 40 pt amber.
- High in Outfit 200 at 88 pt; low at 40 pt in ink3.
- The day's sentence at 24 pt, the hour columns, then "Sunrise 7:25 AM, sunset 6:06 PM."
- Slides in from the right with a .42 s spring; back is the word or an edge swipe in the 0-24 pt zone.
