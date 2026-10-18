# Settings motion (board 73): the pages, the CLAUDE page, Haptics, Quiet fact line, and the Review-foot SETTINGS entry

Lab spec for Builder B (Settings screens) and Builder A (haptics, Look). Docs only. Under Design's `settings-93.md`, `settings-place.md` and `claude-settings.md`; where a Product ruling disagrees with a sheet, the ruling wins and the line is listed in §7. Cites are to master `efb867b8` unless marked. Haptic names are the map in `DesignSystem/Haptics.swift`. Columns: **Normal / Reduce Motion (RM) / Low Power (LP)**. LP = RM everywhere (D5, DEC:991/1003/1023): a 150 ms crossfade, no offset, no scale, no blur, no stagger. The key itself is never drawn, echoed or measured (DEC:77): no tail, no length.

## 0. What exists on master
- There is no Settings screen and no page-turn code. `Features/Settings/` holds `ClaudeSection.swift` and `RestDaySentence.swift`; Look, Rest day and Claude sit inline on Review (`ReviewView.swift:219-228`), then a Backups push (`:231-238`). This spec is for the build.
- Every Settings animation routes through `withTesseraAnimation` / `.tesseraAnimation`, so RM is already one 150 ms ease-out (`MotionPolicy.swift:5-39`). LP is not read there yet (soul only); the Low Power flag PR via `PowerState` (Builder A's order) is what makes LP = RM true here.
- No Haptics on/off setting exists; `tesseraFeedback` (`Haptics.swift:178`) is the one place to gate it.

## 1. Entry: the SETTINGS word at Review's foot (HS35, DEC:1019)
| | Normal | RM and LP |
|---|---|---|
| Word | "SETTINGS", label word, `inkSecondary`, at Review's foot above the Backups line. Not a section of "The week". | same |
| Tap | An ink line draws under the word (150 ms). Review lifts away (scale 1.06, 3 pt blur, fade, 380 ms house curve). Settings grows from the word (0.94 to 1 from its centre, 420 ms, 60 ms delay). Page 1's rows rise 10 pt, 40 ms apart. | 150 ms crossfade, no line draw, no rise |
| Back | The reverse. The shared Tess line (§6) stays put across the whole move. | 150 ms crossfade |
| Haptic | none (a page change is not a write; his own tap on a plain word) | none |
| VoiceOver | "Settings", button. Focus lands on the page word ("Claude") on arrival. | same |
- Today Review pushes Backups with the system transition and no custom motion; the SETTINGS entry replaces the inline Look, Rest and Claude rows with this one word, so the inline rows move onto the pages below.
- Test: the SETTINGS word exists on Review; with RM on, the transition is an opacity change only (assert no scale/offset/blur modifier is active).

## 2. Page turn inside Settings (R1 to R4, DEC:925/933; D5)
- Four pages, each at most six rows: **Claude**, **Your day**, **Looks**, **Data** (DEC:1019 makes the first page Claude; sheet 93's "Tess" page is replaced). The rail on the right edge shows the page; the section word at the top is the only heading.
- A vertical swipe on plain text or empty space turns the page; on a stepper or dial row it steps that row instead (sheet 90b, DEC:1007 line "a swipe on an element is its action, else it turns the page"); a horizontal edge swipe is the side (settings-80 "what leaves the phone"). Rows that open keep their horizontal swipe.
- **R2: no haptic on any page turn.** The auto lead-turn plays none either.
- Page turn word chosen in Settings (Slide, Turn, Soften, Rotate; default Turn): row "Page turn" on the Looks page next to Look (placement is a default the lab picks; sheet 93 had it on page 1, which is now Claude).
  - Tap opens the four words in place (320 ms grow). Each word previews once on a mini page (1 s hold). Re-picking the word that is already set does not replay (R4).
  - The preview plays no haptic. Picking plays `.selection` once (his own tap).
  - RM and LP: every word previews as the same 150 ms crossfade, and the row says so with its value unchanged ("Turn"): the choice is stored and comes back when Reduce Motion and Low Power are both off. No separate "reduced" word.
- Rotate: rows rotate through N row slots in place; RM and LP show the next page's rows by crossfade, no rotation.
- Test: a page turn plays zero haptics in each of the four words; re-picking the current word does not start a preview; with LP on, each word's turn lasts 150 ms.

## 3. The CLAUDE page (page 1)
Rows top to bottom: **Tess asks Claude** (yes / no), **This month** (spend line), **key state** (Key saved / No Claude key yet.), **Receipts** one layer down. Copy per Research's table, third person ("Tess asks Claude: yes.", DEC:597). Cap is $50 (DEC:570); sheet text that says $10 is stale.

| Moment | Normal | RM and LP | Haptic | Code |
|---|---|---|---|---|
| Tess asks Claude flips | the value word crossfades yes/no (150 ms; today `.easeOut(0.18)`) | same crossfade | `.selection` (his tap). Today none. | `ClaudeSection.swift:191` literal 0.18 becomes the house 150 ms |
| Add a Claude key | a 0.5 pt cobalt writing line draws open under the row (360 ms house), rising 6 pt | line appears by crossfade | none | `:278`, `:310` |
| Paste lands | field clears at once; Tess says "Checking it with Claude." beside the soul; cloud wisps rise (3 wisps, 18 pt drift, 1.1 s, 220 ms apart) while the check is away | no wisps: the soul's thinking pose plus the line; nothing drifts | none | the wisps are the model-layer cloud mark in `claude-settings.md` |
| Check answers (works / not allowed / not checked / account paused) | the key row's status word crossfades; "works" lets the sentences below unfold (40 ms stagger, 10 pt rise) | crossfade, no stagger | none (information), except a failed save: `.notSaved` once | `:357` |
| Key refused ("That doesn't look like a Claude key. Paste it again?") | line empties and stays open, Tess's line under it | same | none (information) | |
| REMOVE (a tap, no confirm) | lines 1 to 5 fold away (220 ms) and the no-key state shows. Today `.easeInOut(0.22)`; the house curve is the lab's pick. Tess: "Claude key removed. Everything stays on this phone." with UNDO. | crossfade | `.selection` (his tap) | `:378-383` |
| UNDO within 10 s | "Claude key is back."; rows return as they were | crossfade | `.undo` alone | `:393-398`; the key is held only in memory (`:544`) |
| Add, replace or test a key | a plain receipt, no UNDO, no key content (DEC:1023). | same | none | |
| Month line | 6 pt stroke painted along a hairline to the share spent (500 ms draw, once) | full length shown at once | none | `:438` (`drawn \|\| reduceMotion`) |
| 80% / cap / rollover | stroke turns to `now` (amber, never red; text stays ink); at cap "Paused until Nov 1."; rollover drains back (500 ms) | colour step with no drain | none | |

- The characters of a pasted key never animate (no 9 ms drain, no `...a1B2` tail): `claude-settings.md` S4 is superseded by DEC:77 (9:53 PM Oct 15). The row reads "Key saved" or "No Claude key yet." in both the screen and the VoiceOver label.
- VoiceOver: the field announces "Claude key, secure field", never its contents or length; after the check Tess's line is spoken once; REMOVE speaks the receipt and offers UNDO as an action on the shared line, flat 10 s under VoiceOver.
- Test: after a paste, the accessibility tree contains no run of characters from the field; REMOVE then UNDO plays exactly one `.undo`; RM removes the stroke draw but not the amber/ink colour state.

## 4. "Haptics, on" (Looks page; H13, DEC:1019, 1045)
- A value row: name left, "on" or "off" right in `inkSecondary`. Tap flips it.
- **Off silences every app haptic except the one soft `.warning` for a failed save** (`Haptic.notSaved`). Timer-end and rest-end notifications still ring (they are the system's, not an app haptic).
- Turning it **off** plays one `.selection` as the last haptic (the flip is his touch, played before the gate closes); turning it **on** plays `.selection` after the gate opens. No other row haptic fires while off.
- RM and LP: the value word crossfades (150 ms); no scale or colour pop.
- Build note: `tesseraFeedback` is the one gate. Raw `.sensoryFeedback` calls bypass it: `LookSentence.swift:69-70` (selection, medium 0.8) are two of the 25 sites in the migration table and must move first, or "off" is a lie there.
- Test: with Haptics off, none of `.made .done .selection .pickedUp .undo .timeUp ...` fires, `.notSaved` still does once per failed save; the flip itself fires the one `.selection` above.

## 5. Your day page: the Quiet fact line (HS36, DEC:1017/1019)
- Quiet hours are fixed at 23:00 to 07:00 until he asks for a setting. There is **no tappable row and no clocks** (sheet 93's "Quiet hours" row is superseded). The page shows one plain fact line: "Quiet from 11 pm to 7 am" in `inkSecondary`.
- Motion: the line rises with the page's other rows (10 pt, 40 ms apart); RM and LP crossfade. It is information: no haptic, no tap response.
- What quiet hours do to motion elsewhere (Tess-initiated landings: no haptic, no sound, no new line; his touches and `.timeUp` always play) is in the index §3 Q2 and the cook-clock spec; Settings only states the fact.
- Test: the line's text equals the constant used by the quiet-hours check; there is no control in its accessibility element.

## 6. The shared Tess line and UNDO on Settings (GL19, U2, DEC:1023/1029/1045)
- Settings, Review and Backups covers fall under the one app-wide Tess line with UNDO (one slot). The line sits **directly above the key row, UNDO at its right**; on a page with no key row it sits above the bottom chrome. Never over a row. Rows scroll under a fade; the key row never moves.
- Windows: 4 s for a new write, 10 s for a change, flat 10 s under VoiceOver. A failed save here shows "Didn't save that. Try again." with one `.notSaved`. `RestDaySentence.swift:95` calls `TessVoice.say` with no haptic today, which is the gap; `:99` already uses the shared line with UNDO.
- Normal: the line blurs in over 300 ms with the page behind unchanged (error-notice spec); RM and LP: 150 ms fade.

## 7. Where sheets and rulings disagree (ruling wins; Design's files to fix)
| Sheet line | Ruling | Owner |
|---|---|---|
| `settings-93.md` page 1 "Quiet hours: 11 pm to 7 am", tap opens two clocks | fixed, fact line on Your day (HS36, DEC:1019) | Design |
| `settings-93.md` page 1 is "Tess" (Tess asks, Quiet, Page turn) | page 1 is Claude (DEC:1019) | Design |
| `settings-93.md` "Off is the default"; On/Off wording | code and DEC:683 default yes once a key is there; value words yes/no, but Haptics is "on" (DEC:1019); mixed wording is a Product question | Product |
| `claude-settings.md` S4 drains the key to `...a1B2`; "$10" | no tail anywhere (DEC:77); cap $50 (DEC:570) | Design |
| `settings-place.md:26` Look flood 250 ms under RM | 150 ms (HS43, DEC:1017); code `LookSentence.swift:119` literal 0.25 is dead because `withTesseraAnimation` already forces 150 ms | Design and Builder A |
| `settings-93.md` "Delete everything: two taps, a held confirm" | no ruling found; a hold key means named-action VoiceOver (DEC:1027/1039) | Product |
| Strings still saying "It goes in Review, under Claude." / "Turn this off on Review: Claude." | become "Settings, under Claude." / "Settings: Claude." when Settings ships (DEC:1019); capture-miss code already says "Settings: Claude" | Builder B |

## 8. Asks
1. Product: wording of Haptics (on/off vs yes/no), and whether Delete everything stays a held confirm (if so it is a named action under VoiceOver and plays `.done`-free: its completion is the delete receipt).
2. Product: confirm REMOVE keeps UNDO (code and `claude-settings.md` say yes; DEC:1023 "a key change gets no UNDO" reads as add/replace only).
3. Design: the Settings entry, `settings-93.md` and `claude-settings.md` edits in §7.
4. Builder A: migrate `LookSentence.swift:69-70` to the map, then gate `tesseraFeedback` on the Haptics setting; LP flag via `PowerState`.
