# 243 Weather room, first cut (his 12:29 AM Oct 24)
Board https://claude.ai/artifact/NyeaiLgka6cPQX3vqWZ1jj. Weather becomes its own app; tapping any weather word on Home's board opens it (doorway), that word's sentence first. Basic room + landing; the landing will follow whatever landing system he picks later.

Data: Open-Meteo (free, on by default, 0.1° rounding, 30 min cache): current, hourly 48 h, daily 7 d, apparent temp, gusts, UV; Open-Meteo air-quality API (free). WeatherCondition (Core) names every word; effects and colors = sheet 236 v2.4-2.8. Never show a city.

Landing (402x874):
- 54: "Weather" 40 pt 600 in sky amber (C9772E / E8A06A); time right, Outfit 15 ink2.
- 112: now temperature, Outfit 200 104 pt (degree 52 pt), colored by the current sky (condition color); right of it 15 pt ink2 "feels like 55°" / "high 61°, low 49°".
- 238: sentence line 1, 26 pt 500: "<Cloudy> now, <Rain> from 4 PM." (weather words with effects). 276: line 2, 17 pt ink2: "<Heavy rain> after 6 PM, clearing by midnight."
- 330: "Next hours" small caps ink2; 350: hour columns 59 pt wide (time 13 ink2, temp Outfit 300 24, one word 13/600 in its condition color); drag across OR up/down pages 3 hours; arrow keys.
- 456: "The week"; 476: one sentence 22 pt 500, line 34: "Saturday is Sunny, Sunday Partly cloudy, Monday Windy. Tuesday brings Rain again, and Thursday a Cold warning." Only notable days are named. Each weather word is a door (44 pt hit) to that day.
- 640: air line 15 pt ink2: "Air is good, UV 2, wind 9 mph from the west." (good in go green).
- 690: receipt line. Foot: action word "Rain alert" (rain color): tap toggles, receipt "You'll hear 30 minutes before rain." + Undo 10 s. Tess right.

Day page: "Weather" back word (ink2) at 54; day name 40 pt amber at 100; high Outfit 200 88 pt in the day's condition color, low 40 pt ink3; the day's sentence 24 pt with its weather word; "Hours" columns (same as landing); "Sunrise 7:25 AM, sunset 6:06 PM." Slides in from the right (spring .42 s); back by the word or the edge swipe 0-24 pt. Words on a covered screen don't animate.

Colors per page: amber (room), the condition colors (by meaning), ink/ink2, go green for good air.
