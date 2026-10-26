# 195 Home v3 (supersedes 194 layout; 194 point 0 stands)
Board: https://claude.ai/artifact/UEKheTCP6e7Koy9mCsg5sV   Long lists: see 196 below.  Kaushik 02:46-02:51Z: no bands; better app representation; day sentence as right-aligned lines; better day graphic; apps picker with effects; keep colours, words tappable; he relaxed plain-words: few subtle icons/animations OK.

1 Day sentence: three lines (one clause each), right-aligned, ragged left. App-coloured words are buttons (1 pt underline in own accent): open that object. 25 pt Figtree 500.
2 Day line (replaces ruler graphic): ticks 6 am-midnight; ink to now; events named where they sit (stem + label, side chosen so labels never collide); app-coloured 6 pt segments. Cursor snaps to events within 9 pt, reads name, start to end, duration ("1 hr 35 min"); between events "free for N, then X"; haptic tick per snap/quarter hour; lift on an event opens it. Sunrise/sunset: two small open arcs on the line, drawn in once at launch; scrub onto them reads time and day length.
3 Apps (replaces the six bands and the fan): per-app drawing from its own data, fact in ink 2, name at right edge. Training week strokes; Kitchen three place levels; Money month line with today and the due day, NO amounts; Notes last lines, new coloured; Lists left vs done strokes; Routines day in three parts. Lens: press and slide, the row under the finger swells (flex-grow, font, drawing scale), others go ink 3; lift opens, accent circle opens out from the finger (clip-path, house spring). Arc: names on a quarter circle round the thumb, picked one 1.55x with its drawing and fact beside; both behind one Review switch "Home apps" (Lens/Arc as its values).
4 Settings entry (creative): a 22 pt line knob (ink 2, ink notch) before the word "Settings", always visible, 44 pt target. Gives one 40 degree turn at launch. Tap: knob turns 120 degrees, Settings opens as a circle from the corner (clip-path, house spring); Review row underlined. Word stays for VoiceOver and findability.
5 Mic: 22 pt line mic at the left of the write line; tap shows three ink bars (Tess blue) for the listening moment; reduced motion = still bars.
6 Reduce Motion: every move above = 150 ms crossfade or none. Haptics: tick scrub, soft marked, rigid finished (175).
Lanes: UI Builder B (Home, Settings knob, write line mic); Builder A (lens/arc picker motion, drawings for Training and Routines); Core: per-app facts and week/month data, sunrise/sunset from the system. Icons: knob, mic, sun arcs only. No others.

# 196 Long lists (board: https://claude.ai/artifact/28FpavJyjiLrtg5RHeb5Sk)
Rows keep a fixed 52 pt height; only content moves. Scroll modes (Review switch "List motion"): Focus (line at 1/3 height: row under it 1.38x and full ink, others lean and soften), Wheel (rotateX drum), Wake (rows trail sideways by scroll velocity, further rows later, settle), Plain. Swipe in steps: right 110 pt Done, 220 pt Done and again tomorrow; left 110 Not now, 220 Next week; tick per step, strike follows finger, words replace the line, one Undo (164). Place words slide: rows leave one after another (22 ms), next list enters from the other side (30 ms stagger, 12 rows max); count beside each word.

# 197 Home v4 (Kaushik 02:54Z: cluttered, not all left/right, change the line visual again, remove write/voice, apps as a small scrollable list). Supersedes 195 parts 2, 3, 5.
Board: see the thread. Page top to bottom, 30 pt gaps:
1 Date left, knob + Settings right (195 part 4 stands).
2 Day sentence, right-aligned, three lines, tappable coloured words (195 part 1). Everything below sits LEFT.
3 Day ring (replaces the line): 270 degree open ring, 6 am bottom-left over the top to midnight bottom-right; ink = already gone; 6 pt app-coloured stretches = things; thin outer arc = daylight (sunrise to sunset); now = radial tick; drawn in once at launch. Big time beside it (Outfit 200 56 pt, am/pm small) with one line of words. Turn a finger round the ring: number and words follow and snap to things, open circle cursor, tick per snap/quarter hour, lift on a thing opens it. Rest = now + "Free for 23 min, then Tacos."
4 Next: label + three swipe rows (right strike in ink, left not now), Tess line with Undo below.
5 NO write line, NO mic. (Removed.)
6 Apps: one small vertical scroller, 3 rows visible, snaps; middle row is the pick: name swells 1.3x in its accent, its drawing and one fact slide in from the right; others ink 3. Tick per change. Tap middle = open (accent circle from the finger), tap other = scroll it to the middle. Position ticks at the left edge. List grows with new apps without clutter. Review switch "Home apps".
Reduce Motion: no ring draw-in, no slides, 150 ms crossfade.
Lanes: Builder B Home page, ring, scroller; Builder A drawings and open transition; Core facts and sun times.

# 198 Home v7 widgets (Kaushik 03:45Z: ring and line not his thing; wants weather or other widgets, swipe across). Supersedes 197 part 3.
Board: Home v7 (see thread). Row of widgets under the sentence: Weather, Day, Training, Kitchen, Money (list can grow). 300 pt wide, 28 pt gap, next one peeks; scroll-snap-x. Word row above (Weather Day Training Kitchen Money): current is ink, rest ink 3, tick on change, tap jumps. No cards, no dots, no bars. Charts are thin lines only: ink = past, ink 3 = ahead, open ring = now. Press and hold a chart then slide reads the value (temperature by hour; the day's things; bench by week); plain swipe turns the page.
Weather: big temp (Outfit 200 52), one line ("Cooling to 58° by 9 pm. Dry."), hourly line, high/low. CORE: use Apple's WeatherKit with a coarse location only; no third-party service; never pair location with any of his data. NEEDS the developer-account entitlement (none yet), so sample data until decided.
Day: the daylight line (rises sunrise to sunset), things stand on it, "Free 23 min, then Tacos."
Training: best lift number, six-week line, "Push A at 6:15". Kitchen: count to get and tonight. Money: WORDS OR COUNTS ONLY ("Fri, rent is due", "2 bills this week"), never an amount or balance. Health, body and calorie numbers never on Home widgets.
Colour: only the app words in the sentence and the one picked app in the list; everything else ink. Spacing tight (16 pt sections, sentence lines 4 pt apart).
Apps list: 3 rows, wraps round, Words/Number/Picture/None per app by press and hold; no position ticks. Next: tap a line for its why string (Core's Pick.why).
Review switch "Home widgets"; the order and which widgets show is his choice in Settings.

# 199 Home mosaic (Kaushik 03:48Z: graphics still not liked; wants Home beautiful, alive, fun; apps list optional). Supersedes 198 widget row (kept as a later option).
Board: https://claude.ai/artifact/APxYppcBouT8VNB2qvN7Zx
- A mosaic of today under the sentence: 18 columns (6 am to midnight) x 15 rows of 2 pt-rounded square tiles, 3 pt gaps, crisp (no blur, no gradient fills; each tile one flat colour). Column colour = sky at that hour (dawn peach, noon cream, afternoon sand, dusk rose, evening violet, night indigo) with small per-tile variation. Past columns set; future columns mixed 58% toward the page ground. Now column breathes (lightness +-7, slow). Reduce Motion: still.
- Life: a random tile turns over (flip about its vertical axis, 420 ms, back face a shade darker) every ~1.4 s.
- Touch: ripple of flips from the finger (delay = distance x 3.2 ms, radius 120 pt), soft tick; drag reads the column ("1:00 pm to 2:00 pm, Lunch."), that column lifts 1.18x. Lift releases on the house spring.
- Finish a Next item: a tile flies from the struck line to a free tile in the now column and is laid there, glazed (that hour's colour x 0.52). An app thing finished in its app lays a tile in its accent (e.g. the morning gym tile in Training's accent). The mosaic resets at midnight; yesterday's can be a Review option later.
- Apps list default off on Home; Settings > Home has "Apps list" to add it back. Colour elsewhere stays rationed.
Lanes: Builder A (Canvas/TimelineView drawing, flips, ripple, flying tile; motion via MotionPolicy), Builder B (Home layout, Settings toggle), Core (sky palette by sunrise/sunset times, finished-today events per hour). Review switch "Home mosaic".
