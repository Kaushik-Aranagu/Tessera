# 204 Mosaic switchboard: cues wired to effects (Oct 23, 9:40 AM PT)

Board: https://claude.ai/artifact/Lc5mhAxYvDnNdbF18a3rho. This answers Kaushik's ask on Oct 23: a library of every mood, moment and changeover, and a way to connect each one to the situations that trigger it. Those situations can come from Tess, from app events, from the time or the weather, or from a switch being turned. Builds on 200 (moods), 201 (moments) and 202 Revision 2 (the skin edge).

## Model (Core)
- `MosaicEffect`: a mood (morning, day, golden, running, rest, back, done, rain, night) or a moment (snow, fog, wind, storm, heat, announce, tess, timer, finished, best, reminder, delivery).
- `MosaicChangeover`: flip, wave, dissolve, wipe, fall, gather, melt. For a mood, this is how the mood comes in. For a moment, it is how the moment hands back.
- `MosaicCue`: a typed event with a source. The sources are clock, tess, app, outside and switch.
- `MosaicWire { cue, effect, changeover }`. A table of wires with defaults (below). Stored as an ordinary object so that it can later be edited in Settings with "Mosaic wiring" in Developer mode. On by default.
- `MosaicCueSource` (Core) emits cues. `MosaicMoodPicker` resolves the cues into one current mood plus a queue of moments. MosaicView (A) only plays what it is handed.

## When two cues land together
- A moment beats a mood.
- Source rank: Tess, then your apps, then the clock, then the weather.
- A moment never cuts into another moment. It queues and plays after the current one hands back. The queue holds at most 3; extra moments are dropped, oldest first.
- From 11 pm to 7 am, only timer and reminder moments play. The others are kept until 7 am, and only if they are still true then.

## Default wires
| Source | Cue | Effect | Changeover |
|---|---|---|---|
| clock | sunrise | morning | fall |
| clock | afternoon, nothing running | day | flip |
| clock | 20 min before sunset | golden | flip |
| clock | after 10 pm | night | flip |
| tess | a suggestion is ready | tess | gather |
| tess | rest day in the plan | rest | flip |
| tess | announcement (event in 15 min) | announce | melt |
| app | workout starts | running | wave |
| app | new best (TrainingLedger) | best | melt |
| app | kitchen timer ends | timer | wave |
| app | reminder due (Routines/Tasks) | reminder | dissolve |
| app | groceries marked Arrived | delivery | wave |
| app | something checked off | finished | gather |
| app | last thing today done | done | wave |
| app | first open after 3+ days away | back | gather |
| outside | rain / snow / fog / storm / heat / wind | same name | fall / melt / dissolve / melt / wave / dissolve |
| switch | a feature turned on | finished | flip |
| switch | Focus starts | rest | dissolve |

## Rules (never relax)
- Every cue is read on the phone. Tess's cues come from on-device reasoning; Claude never picks a mood or a moment.
- Outside cues need WeatherKit, which needs the paid entitlement. Until then those wires exist but never fire. Location is coarse and is never paired with his data.
- No money, health, body, calendar titles or private and walled items ever appear in a moment. A masked item cues the moment and shows nothing else.
- Reduce Motion: every changeover is a plain swap (no fade), and moments show their final still.
- No cue ever comes from health, calendar, body, calories or money data.
- The wiring page: each wire is one line of plain inline text, with tappable words shown only by weight or underline. No chips, and no rules between lines.

## Lanes
- Core: MosaicCue, MosaicWire table and defaults, MosaicCueSource, the priority rules in MosaicMoodPicker, quiet hours. Unit tests for priority and queueing.
- Builder A: MosaicView takes `(mood, changeover)` and `(moment, handBack)` from the picker instead of its own maps.
- Builder B: later, a "Mosaic wiring" page in Developer mode where each wire is one sentence with tappable words, like the board.
