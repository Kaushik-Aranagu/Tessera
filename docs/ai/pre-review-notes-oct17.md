# Pre-review notes, Oct 17: AskSubjectPack change and Core's cook-hold narrowing

For: Product, then Core's builder. From: AI architecture. Read against master and Core #884 at 5665c60. No Claude calls; no key use. Rulings used are in `product/decisions.md` (the one-private-text ruling, 5:40 PM stamp; the 4:14 cap ruling; 6:44 PM weight units; 6:00 PM size words; 7:37 PM Pantry state words). Only the weight-unit ruling touches a wall; the title rule, size words and sticky Pantry mask are Recipes and Pantry display rules and change no wall.

## 1. AskSubjectPack: the change and the checks the builder should pass

**The change (spec in `ask-subject-pack.md` sections 3, 4 and 6, with part 3 of the gap lane):**
1. One private-text function. The question and the name go through `isPrivateText` (health, secret, money, body, `PrivateWords` title words) once. No separate secret test, money test or body test.
2. A walled name sends the class word. If `isPrivateText(name)` is true, the payload's `name` is the lower-case class word ("ingredient", "exercise"), never the name. A walled question builds no Claude payload at all.
3. Refusal wording follows the kind, chosen after the one test: secret word "It's in your private notes."; everything else "That stays on this phone."

**Walls checks (each is a test; none needs a key or a live call):**
- W1. Question holds each category (health word, secret word, money amount, body fact, a title word such as "dentist"): no Claude payload, no event, the right refusal line.
- W2. Name holds each category ("Dentist cake" as an Ingredient, "Therapy ball" as an Exercise): the payload carries the class word only; the question still goes if it is clean.
- W3. A clean name and question on an opted-in Ingredient or Exercise: the payload has the name, the handle (not the id) and only fields marked "Claude yes".
- W4. Class not opted in, switch off, demo, or no key: no Claude payload.
- W5. 21st ask in a day: no request, no ledger row.
- W6. Key shape in the question (any case, split, zero-width form from #876 part A): refused before everything, no event.
- W7. Weight units are not money words (6:44 PM): "how much protein in 2.25 kg rice" is not walled by money; "I weigh 180 pounds" is walled by the body rule. Both through the same function.
- W8. Payload body never passes 1,200 bytes for any AW pack; the real id never appears in any payload.
- W9. No receipt, UNDO line or log row holds a walled name: they show "Private ..." labels (the existing masks).

**Review stance:** I expect one finding class: any place the builder calls an older test (`SecretWords.mentions`, `PrivateFacts.isWalled`) directly instead of the one function. Grep for both in `AskSubjectPack` before sending.

## 2. Core's cook-hold narrowing

**Today in #884 (5665c60):** a phrase with "timer" or "timers" never goes to Claude, and while any cook is running, **no** capture phrase goes to Claude (`cooking` skips the whole Claude route). That is wider than the ruling, which only protects cook phrases (Research #880 N21 to N26: "8 mins", "pasta 10", "finished cooking", "how long left", "stop the rice", "step 3"). With a cook running, "call mom at seven" should still be readable by Claude.

**The narrowing:** while a cook runs, only a **cook-shaped** phrase stays on the phone. Other misses may go to Claude under the usual walls and the 600-character cap ("That's too long to send. Say it shorter.").

**Design for the predicate (so it does not depend on the grammar having failed):** a phrase is cook-shaped when it is short and matches one of: a number with a time unit ("8 mins", "10 minutes"); a bare word and a number ("pasta 10"); "step" and a number; "how long" or "time left"; "stop", "pause" or "skip" and "the" and a word; "finished cooking", "done cooking". Use shapes, not the grammar's result: the grammar missed these phrases by definition, which is why they reached the router. If the predicate is too narrow a cook phrase leaks to Claude, which has no timer tool and wastes a call; if too wide a real task stays unread. Prefer too wide by a little: a task phrase with a cook running that is cook-shaped by accident is read by the phone's grammar or ghost row, not lost.

**Walls checks for the builder:**
- C1. With a cook running, the six N21 to N26 phrases make zero requests (existing test `cookPhraseNeverReachesClaude`, keep).
- C2. With a cook running, "call mom at seven", "add milk to groceries" and "bench 80 for 8" are sent to Claude (one request each) if the key and switch allow. This is the new test.
- C3. With no cook running, any phrase containing "timer" or "timers" stays local; "8 mins" alone follows the normal route.
- C4. The cook check runs after the key refusal and the 600-character cap, before any availability check, and writes no miss-log line and no ledger row.
- C5. Walls still apply to a phrase sent while cooking: a walled phrase's receipt is the masked one (existing `theReceiptsHoldNoWordOfAWalledPhrase`).
- C6. Siri and Shortcuts never send, cook or not.
- C7. "Cooking" means a running Cook process only; a paused or finished cook does not hold phrases.

**Docs to refresh once this lands:** `architecture.md` never-leaves bullet (change "anything said while a cook is running" to "a cook-shaped phrase while a cook is running") and the gap-lane reach table row for capture.
