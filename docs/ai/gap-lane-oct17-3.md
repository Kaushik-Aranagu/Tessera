# Gap lane, Oct 17, part 3: kept-link retry cost, AskSubjectPack check, what reaches Claude, parked questions, phrase-cap line

For: Product. From: AI architecture. Read against master 7b0cda7. No Claude calls were made; no key was used or read. **[code]** = read in Swift on master. **[docs]** = from a docs page, not re-read in code.

## 1. Cost model: kept links that retry once Claude is back

Today a kept link is read again only when he taps it (Kitchen ruling on #845). The proposal is an automatic retry. Numbers are for the recipe reader (`recipeLink`, Haiku 5.5).

- **Per read:** typical about $0.0013 (7,000 in, 1,200 out, assumed), worst **$0.0027** (7,000 in, 4,096 out at the token cap) `spend-projection.md`. A page that is not fetched costs nothing.
- **Shelf size:** at most 50 kept links (`RecipePasteLink.limit`) [code].
- **Worst day:** every kept link retried once = 50 x $0.0027 = **$0.14**. Worst month if that happened every day: $4.05, 8% of the cap. Typical (2 to 3 kept links) is under $0.01 a day.
- **Cap behavior:** `recipeLink` is priority "recipe" and keeps running at $40; at $50 the reserve refuses a call a little before the cap and the link stays kept with "Recipe link, kept until Claude is back." Nothing is lost and no row is written for a refused call.

**Rules that keep the cost small (recommended):**
1. Retry only for offline, Claude busy and Claude timeout, on the next time the app is open and Settings has the switch on. Never in the background.
2. Paused at the cap: no auto retry until the cap resets (the 1st, 4 AM house time), then the same rules. A tap still works the moment he wants it.
3. Bad or refused key: never retry; the line says to check the key. A retry loop on a bad key is a loop of 401s.
4. One automatic attempt per link per day, three links per app open, spaced; a second failure waits for his tap. This also keeps the site from seeing a burst (a 429 from the site is a "busy site", also kept).
5. Each retry is a normal ledger row (`recipeLink`), so What was sent lists it; no new wall, since the link was already pasted and read-checked.

**Why not retry harder:** a recipe link is a convenience, not a moment. Nothing waits on it.

## 2. AskSubjectPack spec: final check against the one-private-text ruling

Ruling: decisions 3:28 PM (stamped 5:40 PM Oct 17, Kitchen gap hunt 11, G105): one private-text function, the widest wall everywhere: health words, secret words, money, body facts and `PrivateWords` title words ("dentist", "therapy", "clinic"). Master has no `AskSubjectPack` yet [code], so this is the spec fix, not a bug.

`ask-subject-pack.md` still lists separate tests (secret word, then money or body) and says `name` is sent "after the walls pass on it". Changes for the spec:

| Spec line | Now | Change |
|---|---|---|
| Section 4, steps 2 and 3 | secret word, then money or body, in the question | One call, `isPrivateText(question)`; if true, no Claude event. Keep the two refusal lines by asking which kind it was only to pick the words: secret word "It's in your private notes."; everything else "That stays on this phone." |
| Section 3, `name` | sent after "the walls" | Sent only when `isPrivateText(name)` is false. A walled name sends the class word ("exercise", "ingredient") instead, so "Dentist cake" never leaves as a name. |
| Section 3, `fields` | public facts only | Unchanged; a field value also goes through the one function before it is packed (a value holding a title word is dropped, not reworded). |
| Section 6 tests | 6 | Add test 7: a question and a name holding each category (health, secret, money, body, a title word) build no Claude payload; the title-word case is the new one. |

Everything else (opt-in per class, Ingredient and Exercise only, $0.0046 worst, 20 asks a day, 8 s, no write tools, no step-aside) stands.

## 3. Every place text can reach Claude today, against the walls

From master 7b0cda7. Seven routes exist in code (`TessUse` and the clients). "Walls" = what stops a thing leaving. Pack contents for Plan my day, Home done and the recipe reader are from the pack builders [code] and `docs/ai` [docs].

| Route | Model | What leaves | Walls on it |
|---|---|---|---|
| Capture (`capture`), after #860 | Haiku 5.5, 512 tokens, 3 rounds | His phrase whole (money, body, health and secret words included, by his "all but the key"); the date line; the current exercise name and last set (kg x reps) if not walled; 11 tool definitions [code] | The key and key-shaped text refused in the router and again in the Claude route; Siri and Shortcuts never send; a walled phrase the grammar already answered stays; no notes, people, tasks, body weight or money in the pack; a walled phrase's reply is the masked receipt; not stored in the miss log or retry inbox; phrases over 600 characters are refused with "That's too long to send. Say it shorter." and a phrase with "timer" or "timers", or any phrase while a Cook is the running process, is read on the phone only (both built in Core #884, merged; the cook hold is wider than the ruling, see pre-review-notes-oct17.md section 2) |
| Question (`question`) | Haiku 5.5 | His question; counts come from the phone's `answerQuery` over an allow-list of classes [code for the tool, docs for the pack] | Same router walls as capture; `answerQuery` counts only allow-listed classes (never money, body or his own classes) |
| Paste (`paste`) | Haiku 5.5 [docs] | Pasted text the parsers could not read | Key-shaped paste cut or refused in the view; `SecretWords.cut`; open gaps G1 to G9 in Research #876 (stores without a key check) |
| Recipe link (`recipeLink`) | Haiku 5.5 | Page text, about 1,500 characters before the first "ingredient" and 22,000 after, cap 24,000 [code] | Lines that are key-shaped or walled dropped; `SecretWords.cut`; money spans stripped; a login or password line dropped; https only, no private hosts, redirects checked per hop with `safeURL` but not the key test (G9); `NoRedirects` on the client; reply checked for secret words |
| Plan my day (`plan`) | Sonnet 5.5 | A pack of about 400 tokens: task and routine titles and times [docs, code at `PlanWording.swift:47` and `:177`] | A title that is secret-worded or `HomeDonePack.isWalled` is dropped; the reply is checked with the same two tests; 20 s hard deadline |
| Home done (`lines`) | Sonnet 5.5, 6 s | One finished workout's counts, bests and routine title (the two slots) [code `HomeDonePack`] | A walled pack is refused whole (reviewed in #658); one call per workout id; steps aside at $40. **Open:** the phone's own Home line shows the real private routine title (part 2 of this lane, `HomeLines.swift:503`) |
| Key check (`keyCheck`) | count_tokens, Haiku fallback | The key, in the request header only; fallback body is "Hi" | Never in a body, a log or a file; the header is the one place the key goes |

**Not built on master (no text can leave from these yet):** week story, living colour, Ask about this (`askSubject`), Facts Claude may fill (`fillFacts`), grocery connect (`linkItems`).

**Gaps in this table, in one list for Core:** (1) and (2), the cook check and the 600-character cap, are built in Core #884 (merged); remaining: (3) the nine key-shape store gaps in #876; (4) Home done hero shows a private title on the phone; (5) the money screen in the router and `PrivateFacts` must agree on one list (ruling G105 makes that the same function).

## 4. Tess as first contact: open questions for when Kaushik unparks it

Parked ideas are in `parked.md`. Nothing here asks for research, calls or spend. When he says go, these need his answers first:

1. **Latency.** What is the longest a first reply may take? His own worry. A router that waits on Claude fails the "nothing waits on Claude" rule.
2. **Who decides what runs.** On the phone only, or a small Claude call per tap? His "very fast API call" or a local model: which, and what is the fallback when offline?
3. **Which model names he meant.** The notes mark "CLM", "Jev" and "Jeff" as dictation damage. Ask him what he named.
4. **What Tess may see of the screen.** Structured facts only (no images, said). Which screens, and does the walls table apply to screen facts the same as to packs?
5. **What an expert agent is.** A bounded job with its own pack, tool and validator (the AI-2 `TessJob` shape), or a longer conversation? The first keeps the walls; the second needs a new design.
6. **Memory ownership.** Today only the phone writes memory. Does Tess-as-coordinator keep any state Claude writes, and where?
7. **Spend.** How much of the $50 cap, if any, may a coordinator take? Does it step aside at $40 like the word jobs?
8. **What she may do unasked.** Writes stay ghost rows with UNDO. Does an agent ever commit without a tap?
9. **Roam and motion.** The Tess motion lab owns the near-term fix; does this replace it, or wait?
10. **Evals.** A job that decides what to show needs a test that cannot be passed by luck; who writes it and what is the bar?

## 5. The phrase cap: UI line (as built; replaces the 500-character draft)

Product's ruling, 4:14 PM Oct 17: the cap is what Core #884 built.

- **Trigger:** the capture phrase is over **600** characters.
- **Line:** "That's too long to send. Say it shorter." A refusal: no note offer, no KEEP or NOT NOW.
- **Nothing sent, nothing logged:** no Claude event, no ledger row, and not a miss-log line.
- **Siri and Shortcuts:** unchanged; they never send.
- **Tests:** in #884.
