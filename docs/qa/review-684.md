# Review #684 (Core: key guard catches spaced dashes and a missing last dash)

Head 8cccb1a6, merge-tree clean against master 2a6dfd21. Package-only (ClaudeKeyGuard.swift and KeyShapeTests.swift). No screen change, so Design is not needed. Package tests are enough; an app-test run adds nothing (the change is two pure functions in TesseraCore, with no UI or app-target call shape touched).

**Verdict: QA PASS.**

## The three checks
1. **Only tightens.** The old test was "contains the prefix, any case". The new pattern is `sk\s*-\s*ant(?:\s*-|(?=[a-z0-9_-]{8}))` (any case). Every string the old test matched (prefix with its last dash) still matches the first branch, so `looksLikeClaudeKey` is a strict superset. `withoutClaudeKeys` is the same pattern followed by the same `\S*` and spaced-run tail; for an unspaced key the match and the removal are byte-for-byte what they were, and spaced shapes ("sk - ant - ...", "sk- ant-...", "the Claude key prefix" + body) now come out whole. Nothing that was caught is released.
2. **No literal prefix in the tests.** The test builds the prefix from "sk", "ant" and the dashes; the fill is "api03-TESTFAKE" plus repeated x. The only substring of the prefix family in the added lines is the near miss "dethe Claude key prefix" (no trailing dash, so not the premerge key pattern).
3. **Near misses.** I ran the pattern over the test's list and extras: "skant", "sk-and-x", "ask ant about the ski trip", "the Claude key prefix" and "dethe Claude key prefix" are all plain text; KS06 to KS10 and the dictation-spaced key are caught and fully removed.

## Low (over-blocking only, not a leak)
The no-last-dash branch needs 8 more key characters, so a hyphenated word that continues for 8 or more letters after "the Claude key prefix" is held back: "rithe Claude key prefix plan", "tathe Claude key prefix", "dethe Claude key prefix" all match (I checked with a Python port). The user would see "That looks like a Claude key" on a harmless phrase, and `withoutClaudeKeys` would cut from "sk" to the end of the word. Rare compounds, and over-blocking is the right side to err on. If it ever bites, require a digit in the following run (`(?=[a-z0-9_-]*\d)`; real key bodies carry "api03"). Also not covered: a non-ASCII hyphen (U+2011 or an en dash) in a pasted key.
