# QA review: #548, key-prefix comment in words (Builder A)

Head reviewed: 3179952 (one line; merge-tree clean). **PASS**

- WorkoutParts.swift:384's comment now says "looks like a Claude API key". The code still calls `looksLikeClaudeKey`.
- Low **R1**: BottomChrome.swift:457 still has the prefix literal in a comment. ClaudeSection.swift:321 has it in code,
  which needs it. If the docs rule covers code comments, the BottomChrome one is the last comment left.
