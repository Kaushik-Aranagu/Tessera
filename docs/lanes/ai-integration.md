# AI integration lane: lessons

Scope: Tess, routes to Claude, on-device models, anything that reads or writes in natural language.

- Walls: money, health, body and calorie facts never reach Claude, logs, backups, exports or widgets. A private thing is
  its label ("Private workout"); use `ObjectPrivacy.shownLabel` and `isPrivateWord`; walled titles never appear in a sentence.
- Landing sentences and the day sentence are computed on the phone from fixed templates. Nothing in them is sent anywhere.
- On-device Foundation Models only break ties for lines that are not walled; Claude is never used for tie-breaks.
- Tess's receipts name the thing first and where it went, with no amount (the amount shows only inside Money) and Undo for 10 s.
- Say "best", never "record"; never streak, lost, broke, or down.
- A helper never posts to the project thread; it reports to the session that started it.
