# Review #684 (Core: key guard catches spaced dashes and a missing last dash)

Head 8cccb1a6, merge-tree clean against master 2a6dfd21. Package-only (ClaudeKeyGuard.swift and KeyShapeTests.swift). No screen change, so Design is not needed. Package tests are enough; an app-test run adds nothing (the change is two pure functions in TesseraCore, with no UI or app-target call shape touched).

**Verdict: QA PASS.**

## The three checks
1. **Only tightens.** The old test was "contains the prefix, any case". The new pattern matches the Claude key prefix in any case, with or without its last dash (an optional-dash branch that needs 8 more key characters). Every string the old test matched (prefix with its last dash) still matches the first branch, so `looksLikeClaudeKey` is a strict superset. `withoutClaudeKeys` is the same pattern followed by the same `\S*` and spaced-run tail; for an unspaced key the match and the removal are byte-for-byte what they were, and spaced shapes (the prefix with spaces around its dashes, or with a space after the first dash) now come out whole. Nothing that was caught is released.
2. **No literal prefix in the tests.** The test builds the prefix from its parts (the two words and the dashes) and fills the body with a fake marker plus repeated filler. No substring of the prefix family appears in the added lines except a near miss with no trailing dash, so the premerge key pattern does not match it.
3. **Near misses.** I ran the pattern over the test's list and extras: run-together words, a hyphenated "and" word, ordinary sentences with the same letters are all plain text; KS06 to KS10 and the dictation-spaced key are caught and fully removed.

## Low (over-blocking only, not a leak)
The no-last-dash branch needs 8 more key characters, so a hyphenated word that continues for 8 or more letters right after the prefix letters is held back (a few rare compounds match; I checked with a Python port). The user would see "That looks like a Claude key" on a harmless phrase, and `withoutClaudeKeys` would cut from the first prefix letter to the end of the word. Rare compounds, and over-blocking is the right side to err on. If it ever bites, require a digit in the following run (a lookahead for a digit in the following run; real key bodies carry one). Also not covered: a non-ASCII hyphen (U+2011 or an en dash) in a pasted key.
