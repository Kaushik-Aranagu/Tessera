# Review #688 (head b47b6c5f): PASS
- Copy: Groceries summary "Rice, on Groceries" / "N things on Groceries"; Lists summary and receipt "<thing>, on <list>", private "Private item, on <list>"; Tess capture lines end with a full stop, receipts do not. Matches lists-copy-sweep-oct17.md (thing first, "on").
- Medicine on Groceries: line says "Private item, on Groceries." via EngineWall.isHealth (now public); test covers "buy advil".
- Key guard: prefix now needs a dash or a digit within 8 letters after the prefix letters, dashes widened to U+2010-2014 and U+2212. Only loosening: digit-less no-dash text ("rithe Claude key prefix"), intended. Everything else caught before is still caught.
- Tests build key shapes from parts; no literal prefix added.
