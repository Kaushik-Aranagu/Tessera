# New on your phone

DRAFT. The v9 riders build after a36b161 has no pin yet. Every line below is merged on master (read at 5984f40).

- **The Day log** says "best" when a set beats your best: "Push A, 52 min. Bench 82.5 × 8, best."
- **Private notes** in the Notes list show only "Private note" and the time, and VoiceOver reads only that.
- **Not yet fixed:** a note written before a36b161 can still show its first line in the Day log. The fix is planned but not merged yet.
- **Not yet fixed:** a note that mentions "@Private note" can open that private note's page and show all of it. The fix is planned but not merged yet.
- **Not yet fixed:** a line typed in the Ask bar that ends with a question mark isn't checked for secrets, so it can be saved as a plain task. Keep secrets as plain statements until the next build.
- **Your data:** this build is still Catalog v9, so nothing you have changes.
- **Save a copy first:** Review, then The week, then Backups, SAVE A COPY. Save it outside the Backups folder and name it "Before" plus this build's code.
- **The way back** is a36b161. It opens your data just as it does today.
- **Never install 7b321d2 again.**

## Team appendix: the full list

What changes when this build goes in, compared with pin a36b161 (a36b161b7294596848a319c0cc0fc50a3b25f2ee,
Catalog v9). Read by hand on `origin/master` at 5984f40 (Merge #523), Fri Oct 16, 2026 (Pacific). Nothing was built
or run. Only three merges after the pin touch app or engine code (#403, #504, #508); the rest are docs and scripts.
This is the riders build (Product item AT, 1:43 pm): Catalog v9, no #407. The v10 build comes later, alone; its page
is `new-on-your-phone-v10.md`.

### Merged on master after a36b161

**Training and Review**
- **Day log best:** a workout line whose top set beat a best ends ", best." and VoiceOver says "Bench 82.5 by 8, best." (`TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift:225`; #504). The Day log is built when shown, so older days read "best" too. No stored text changes.
- **Review's tapped day** still reads "Bench best". It now finds that line by ", best." (`Features/Home/ReviewWeek.swift:175`; #504).

**Notes**
- **Private note rows:** the Notes list draws no second line under a private note, so the row is "Private note" and its time, and VoiceOver's combined row reads only those two (`Features/Notes/NotesView.swift:186`, `:216`, `:290-292`; test `TesseraTests/NoteEditorTests.swift`; #508). This closes N13 from the v9 page.
- **Still open:** a note from before #422 is not marked private, so the Day log can print "Note:" and its first line (`DayStory.swift:345-347`; no mark-private pass in `App/` or `TesseraCore/Sources/`). N15, Core 0aa.
- **Still open:** a plain note that mentions "@Private note" links to a private note, and that link opens the object page, which shows the whole body (`TesseraCore/Sources/TesseraCore/Notes/Notes.swift:35-43` has no private filter; QA review-508 M1). Also on a36b161. PN-MENTION, Core 0ad and Builder B 0r.

**Tess**
- **Tess's eyes are in the code but off** (#403): the only switch is the Simulator's `-tessEyes` flag (`App/AppModel.swift:98-99`), which the phone ignores, so on his phone nothing changes and there is no setting for them. Not a line for his top section.
- **Leaving the app** was meant to settle Tess back to rest (`Features/Tess/SoulRouter.swift:180-182`, QA L6), but nothing sends that event yet, so there is no change he can see.

**Your data.** No catalog change after a36b161: `SystemCatalog.swift:350` on master reads `version: 9`, and this build stays at 9. Save a copy first (Review, then The week, then Backups, SAVE A COPY), outside the Backups folder, named "Before <SHA>" (pin-checklist section 6, decisions 1:41 pm). After this build the rollback is a36b161, installed over the top. Both are Catalog v9, so a36b161 opens his data normally, with no launch note. 7b321d2 is never installed again: it has no newer-store check and it predates #422, so it would show private notes in plain text (decisions 1:41 pm, pin-checklist section 7).

**Things to try first**
1. Open the Day log on a day you set a best. The workout line ends ", best."
2. In Notes, type "wifi password is tacocat4417", open the private note it makes, add a second line "door code 4417", and go back. The row reads only "Private note" and the time. With VoiceOver on, it reads the same.

### Planned for this build, not merged yet

In this build only if merged before the pin is named. Full list, gate and owners: `next-build-v9r.md`.

- **Older notes marked private once at launch** (N15): Core 0aa.
- **"@Private note" never opens a private note's body** (PN-MENTION): Core 0ad, Builder B 0r.
- **Siri's Add a Task keeps money and body facts private** (P14): Core 0l (tests 0l-2).
- **Siri says "Body weight logged." without the number** (HW13): Core 0ac.
- **"sick", "unwell" and "feeling sick" stay on the phone** (HW19, with the CR1 slang mask): Core 0ac.
- **Siri writes ask for Face ID when locked** (HW9, P16): Core 0ac, under 0l.
- **"weighed 82.3 yesterday" is private, not a plain dated note** (HW11, N18): Core 0l-2, notes half Core 0aa.
- **Review's task and cooking bands count by each item's own zone**, before the Oct 26 trip: Core 0ae.
- **SAVE A COPY suggests "Before update <day>" and warns about the Backups folder**: Core 0af, Builder B 0t.
- **One UNDO slot, so UNDO takes back what its line names** (F1, F2): Core 0s, Builder B 0i, Builder A 0i.
- **Deleting a note gets a line and a 10 s UNDO** (F3): Builder B 0i, 0p.
- **Routines and the editor get real UNDO windows** (F4): Builder A 0i, 0f.
- **"paid rent 2100 fri" is a private dated note, kept out of the miss log** (F6): Core 0aa.
- **Private task titles read "Private task" off the row** (F7): Core 0y and 0l, Builder A 0e, Builder B 0n.
- **Rename gets the Claude key guard** (F8): Core 0k.
- **Notes writing line says "Note, kept." with a 4 s UNDO** (F9): Builder B 0p.
- **A pasted Claude key is stripped and the rest kept** (F10): Builder B 0p.
- **Backups "Stop using it" clears the folder** (F12): Builder B 0o.

Later, not this build: F5 (undoing a finish removes the Health workout), F11 (Recipe to Groceries windows), pack
size on Groceries rows (Builder B 0s), and everything v10 (#407, the eyes setting, the LOOK row, the `.backgrounded`
sender).

**Built from** (first-parent merges in `a36b161..origin/master`): code #403, #504, #508; docs and scripts #499, #500, #501, #502, #503, #505, #506, #509, #510, #511, #513, #514, #515, #516, #517, #518, #519, #520, #521, #522, #523. Not in this build: #407 and everything under "Planned" until it merges.

**To finish when the pin is named**
- [ ] Set the first line to "Build <sha> (pin <full sha>, Catalog v9)" and drop DRAFT.
- [ ] Rerun `git log --oneline --first-parent a36b161..<pin>` and move every planned item that merged into the merged list, with file:line read at the pin. Confirm no #407 merge and `version: 9`.
- [ ] If N15 is in, drop the first "Not yet fixed" line; if PN-MENTION is in, drop the second; if the "?" fix (B 0v, Core 0ah) is in, drop the third. If not, keep them.
- [ ] If the HW and P14 rows are in, add one top line each in his words (for example "Siri keeps a weigh-in private.").
- [ ] If Core 0ae is in, add a top line for the trip week; the pin must be on his phone before Oct 26.
- [ ] If Core 0af is in, the Save a copy line uses the new suggested name.
- [ ] Recheck the try list at the pin, and that "SAVE A COPY" is still reached through Review, then The week, then Backups.
- [ ] `scripts/test.sh` on the pin ends "All green".
- [ ] Both greps (the key prefix and the long dash) return 0.
