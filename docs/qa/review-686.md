# Review #686 (Builder B: private filter for scripts/kitchen-week-one.py)

Head 2ecd8d15, merge-tree clean against master 89908135. One file (the script). Not an app change, so no release and no Design.

**Verdict: QA PASS.** Static read; I did not run the self-test (no Python store fixture run here beyond reading it).

## House script rules
- sqlite opened `file:{path}?mode=ro` with `uri=True`; nothing writes except the self-test's fixture. No `exec(`, `eval(`, `subprocess`, `os.system`, `socket`, `requests`, `pickle` (the premerge PY_FORBIDDEN list finds nothing); the only `http` is a `startswith("http")` count over the miss log. No network, no key use, no env read. Queries bind class ids with `?` placeholders; the other f-strings carry constants.
- Reads only: classes in `READ_CLASSES` (recipe, cook, kitchenTimer, process, listItem, ingredient, task). No Note, Event, Training class, and the note query check in the self-test is a weak regex (low 3).
- Nothing printed carries a title unless `--titles`, and the miss log is only counted (source names and a link count), never quoted. `$` is stripped from the whole output.

## Filter
- `SECRET_WORDS` and the wifi rule match `SecretWords.words` and `secretIndexes` exactly (13 words; "wifi" only before ":" or "is"), and the tokenizer matches (lowercase, ":" as its own word, same trimmed punctuation). So no drift today; Builder B's drift note is the right worry.
- Money and body: any of `$ € £ ¥`, a number followed by kg, kgs, lb, lbs, cm, bpm, kcal or %, or any token of 3+ characters that starts with a digit and holds only digits, commas and dots. So "Rent 1200", "Weight 80 kg", "Pay $40 pasta", "Door code 4417 soup" and any decimal ("1.5") become "Private recipe"; a stand-in prints for them with `--titles`. Over-blocks, which is the right side for a week-one count.
- The self-test hash check proves the main file is unchanged; the live-path refusal fires on "application support" in the lowercased path.

## Lows
1. The PF12 refusal uses `os.path.abspath`, which does not resolve symlinks: a link to the live store passes. Use `os.path.realpath`. (mode=ro still keeps it from writing the main file.)
2. Gaps against PrivateFacts: the rupee sign is missing from the currency set; money verbs and words with a 1 or 2 digit amount ("Paid 40 pasta", "Tip 20") are not walled; spelled amounts and medicine or symptom words are not covered. Titles print only with `--titles`, on a local copy, so this is low; adding PrivateFacts' money words whenever a digit is present would close most of it.
3. The self-test's "no query on note" check is a regex that would not catch a real query; and the `-wal` and `-shm` files a read-only open of a WAL store copy can create are outside the hash check.
4. Drift: add a package test that parses the `SECRET_WORDS` set out of this script and compares it with `SecretWords.words` (it is internal; `@testable` reaches it) until Core exports the list.
5. The URI is built from the raw path: a path containing `?`, `#` or `%` would be misread. Quote it.

## Follow-up #687 at a2552d41: PASS
Delta against #686 (2ecd8d15 is an ancestor): realpath for the PF12 refusal plus a symlink self-test case; the rupee sign; MONEY_WORDS (mirrors PrivateFacts.moneyWords plus TessMemoryScreen's) walls a title that has a digit-led word and a money word ("Paid 40", "spent 12"), with clock times removed first so "Tacos 3pm" stays plain; the sqlite URI is built from the quoted absolute path (spaces, `?`, `#` and `%` are safe); the weak note check is replaced by three checks (queries touch only classdef, fielddef, object, link, op; the object query is limited by `classID IN`; no note, event, training or bodyWeight class named in code), which is what I meant. Lows 3 and 5 closed, 1 and 2 closed; low 4 (word-set drift test) waits on Core exporting the list. premerge reports `urllib` (parse and quote only, no network) as report-only, not a stop. A digit-led word beside a money word over-blocks harmlessly ("7-up pound cake" shows as Private recipe).
