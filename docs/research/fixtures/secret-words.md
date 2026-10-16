# Secret words (board item 134)

For: Core (the NE1 rule, `TessGrammar`, `TessCaptureEngine`, `DayStory`, `TessMemory`) and QA. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). The rule, from `decisions.md` 3:34 AM PT Oct 16 (NE1/NE2):
- A line with a secret word (password, PIN, passcode, wifi password, code) becomes a private note on the phone.
- It never reaches the model, Claude, memory or the miss log.

The "master today" column is a hand trace of master 0bff60b. Nothing was run, and every value below is a made-up placeholder.

**Summary:**
- On master, every secret line in this file reaches the router. With "Tess asks Claude" on, it goes to Claude. With Claude off it is a miss, and the miss log keeps it.
- "note: wifi password is …" is worse. It is written as a plain note, and its title flows on into memory and Claude's packs. `DayStory` prints one note as "Note: {title}" (`DayStory.swift:345`). The 04:00 turnover copies that into the next morning's recent line (`TessMemory+Turnover.swift:61`). `pack` sends recent lines because they aren't private (`TessMemory.swift:464-478`). Any Claude job that reads recent lines then carries the password.
- The value test below keeps the near-misses ("password reset email Friday") as ordinary tasks, as the board item asks.

## 1. The rule as fixtures read it

| # | Part | Default proposed |
|---|---|---|
| R1 | **Where it runs** | First in `TessGrammar.parse`, after the wake word and **before** `parseNote`, the pasted recipe and the question rule. "note: …" and "what's the wifi password?" are caught too. The engine must not call the router or the miss log on this result |
| R2 | **Secret words** | password, passcode, pin, wifi password, code, plus "combo", and "wifi" when a colon or "is" follows it. Whole words only (`tess-memory.md` taught that: "pin" must not catch "pinch" or "spinach") |
| R3 | **A value** | One of these after a secret word, or after "is" / ":" following it: a token with a digit, a token mixing letters and digits or symbols, 3 or more spoken digits ("one two three four"), or any word after "is". A value makes the line a **private note** |
| R4 | **No value** | The ordinary rules read it: a task shape (a day, a time, "todo") becomes a task. With no task shape, it's a private note **without** going to the model. Nothing with a secret word ever leaves the phone, value or not |
| R5 | **The private note** | Title "Private note" everywhere outside the note itself: Day log, Review, Home, widgets, the Lock Screen, Spotlight, the recent memory line. Never in a pack. The body opens only on the Notes page |
| R6 | **Tess's line** | "Private note, kept." with UNDO for 4 s (a new capture, Product's AQ15). She never repeats the value |
| R7 | **Memory** | "remember the wifi password is …" is never a memory line. It becomes the private note (R5), and Tess says "Private note, kept. It stays out of my memory." (Design's catch, Oct 16: the old line contradicted itself) |

## 2. Twenty lines

| # | He types or says | Lands (expected) | Must never reach | Master today |
|---|---|---|---|---|
| S1 | wifi password is tacocat | Private note | model, Claude, memory, miss log | Router; Claude if on, else a miss and the log |
| S2 | wifi: TacoNet / tacocat24 | Private note ("wifi:" plus a value, R2 and R3) | same | Router |
| S3 | door code 4417 | Private note | same | Router (no lift resolves "door code") |
| S4 | the gate code is 2580 | Private note | same | Router |
| S5 | my PIN is 0420 | Private note | same | Router |
| S6 | Spoken: "my passcode is one two three four" | Private note. The value is the spoken digits | same, and the speech transcript buffer | Router |
| S7 | note: wifi password is tacocat | Private note (R1 runs before `parseNote`) | same | **A plain note titled with the password.** Day log "Note: wifi password is tacocat", tomorrow's recent memory line, Claude packs |
| S8 | remember the wifi password is tacocat | Private note, "Private note, kept. It stays out of my memory." (R7) | memory above all | Router. `TessMemory.refusal` only refuses the Claude key prefix (`TessMemory.swift:133`) |
| S9 | netflix password hunter2 | Private note | same | Router |
| S10 | alarm code 9 9 1 2 | Private note | same | Router |
| S11 | what's the wifi password? | Opens the private note it matches, read on the phone. Nothing to the model | model, Claude | Question rule, then the model with the text |
| S12 | password reset email friday | **Task** "Password reset email", Friday 9 am. No value, task shape (R4) | Claude (the grammar writes it; nothing is sent) | Task ✓ (`parseTask`) |
| S13 | change the wifi password tomorrow | Task "Change the wifi password", tomorrow | same | Task ✓ |
| S14 | todo: reset my PIN | Task "Reset my PIN" | same | Task ✓ |
| S15 | call mom about the wifi password | Private note, since there's no task shape and the model is never called (R4). Inferred: rare | model, Claude | Router |
| S16 | zip code 94110 | Private note. A false positive, but harmless: nothing leaves the phone | same | Router |
| S17 | promo code SAVE20 for target | Private note (harmless false positive) | same | Router |
| S18 | code review friday 3pm | Task "Code review", Friday 3 pm. No value (R3: "review" isn't after "is") | none | Task ✓ |
| S19 | pinch of salt | Not a secret line. "pin" is a whole word only | none | Kitchen or the router, as before |
| S20 | garage 4417 (no secret word) | **Not caught.** It goes to the router as before. Listed so QA doesn't expect a catch | none | Router |

## 3. What QA greps after S1 to S10

Type S1 to S10 on the Simulator, then search each of these for the placeholder values (tacocat, 4417, 2580, 0420, hunter2, 9912). Every search must come back empty except the note bodies:
- the miss log file;
- each `memory` object's text, after a forced 04:00 turnover;
- the capture op summaries and the Day log lines (they must say "Private note");
- a Claude request snapshot for Plan my day, Home wording and the week story, with "Tess asks Claude" on;
- the export JSON (it may hold the note body, see Q1).

## 4. Gaps for Core

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| SW1 | No secret rule. Every row reaches the router | `TessGrammar.parse`, `TessCaptureEngine.capture:46-58` | R1 to R4. The engine skips the router and the miss log for a private note | Core |
| SW2 | A note's title flows into memory and Claude packs | `DayStory.swift:345`, `TessMemory+Turnover.swift:61` | Private notes read "Private note" in DayStory. As a second guard, the turnover drops any line holding a secret word | Core |
| SW3 | Memory refuses only the key prefix | `TessMemory.refusal` | Add `.secret`, line "Private note, kept. It stays out of my memory." (the same list as R2) | Core (AI-8) |
| SW4 | A private-note flag doesn't exist | `SystemCatalog` note class | An additive `isPrivate` field on note (catalog bump, additive only, per the data-safety rules) | Core |
| SW5 | The op summary holds the text | `CreateNote.summary` | The summary of a private note is "Private note" | Core |

## 5. One question for Product

Q1. Does a private note ride in the iCloud Drive backup? ★Yes. It's his own iCloud, and losing a door code on a reinstall is worse. The Claude key is the only thing kept out of backups by design. No: the note stays on this phone only and is gone after a delete.

**Answered (Product 3c2ea39e, Oct 16):** yes. A private note goes in his iCloud backup and never into memory, recent lines, packs or the miss log. SW2 is folded into the NE1 fix.
