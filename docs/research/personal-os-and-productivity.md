# Personal OS and productivity: ideas from the field

For: Product lead (cross-functional)
Date: 2026-10-15

Ranked by (daily value x fit with the OS metaphor) / effort. Teams: P = Product, D = Design, E = Engineering, T = Tess/AI.

## Ideas

1. **Process list ("What's running").** One sheet shows open loops as processes: running (the workout), suspended (a half-done task), waiting (on someone). Each has one "resume" action. Ready-to-Resume becomes a view of this list, not a separate feature. Why: it externalises working memory, which is the core ADHD gap, and it is the OS metaphor made literal. P, D, E. **M1** (workout as the first process), full in M2. Effort M. [Ink & Switch, malleable software](https://www.inkandswitch.com/essay/malleable-software/)

2. **Time you can see.** Now's countdown is a draining bar, and the same bar lives on the Lock Screen as a Live Activity. Why: time blindness is the main ADHD complaint, and Tiimo won 2025 iPhone App of the Year mostly on visual time and transitions. D, E. **M1** (rest timer first). Effort S. [Tiimo newsroom](https://www.tiimoapp.com/newsroom)

3. **Memory pressure for the day.** When planned minutes exceed free time, the day strip shows "full" and offers to page items out to Later. Neutral colour, never red, one tap to accept. Why: Sunsama's workload warning is its most loved habit; overplanning is how ADHD days fail. P, D, T. **M2**. Effort S. [Sunsama daily planning](https://help.sunsama.com/docs/daily-planning)

4. **Context switch saves state.** Leaving an object (closing a task, quitting mid-set) stores "where you were and the next step" automatically; coming back shows it in one line. Why: re-entry cost is what stops ADHD users finishing things. E, D. **M1** (P1 Ready-to-Resume). Effort S. [Simply Psychology on time blindness](https://www.simplypsychology.org/adhd-time-blindness.html)

5. **First-step splitter.** When a task sits untouched, Tess offers one 2-minute first action ("open the doc and write the title"), never a lecture. Why: task initiation, not planning, is the bottleneck. T, P. **M2** (on-device), smarter in M4. Effort S.

6. **Notifications as interrupts.** Each notification has a priority. During a foreground process (a workout, a focus block) low ones are masked and queued, then delivered together at the next context switch. Why: a real OS concept that fixes real distraction. E, D, P. **M2**. Effort M. [Interactive snippets](https://www.nutrient.io/blog/wwdc25-snippet-intents/)

7. **Body double mode.** Tess "sits with you": a quiet Live Activity, a check-in at the halfway point, a one-line wrap-up. Why: a 2025 study found adults with ADHD finished faster and stayed focused longer with a human or AI body double. T, D. **M2**. Effort M. [arXiv 2509.12153](https://arxiv.org/abs/2509.12153)

8. **Time Machine.** Every typed action ("syscall") is already logged; expose it as a scrubbable history per day and per object, with undo. Why: trust, recovery from mistakes, and a free journal ("what did I do Tuesday"). E, D. **M2**. Effort M.

9. **Snippets everywhere.** Now, log-a-set and capture as interactive App Intent snippets in Siri, Spotlight and Control Center, sharing the same typed actions. Why: the "OS" escapes the app; the iOS 26 snippet API makes this cheap. E. **M2**. Effort M. [Superwall on snippets](https://superwall.com/blog/app-intents-interactive-snippets-in-ios-26)

10. **Daemons for automations.** Rules ("after a workout, log to Health and suggest protein") show up as named daemons in the process list, each with pause and a run log. Why: automations people can see and stop feel safe; hidden ones feel like Motion's reshuffling. E, T, P. **M4**. Effort M. [Motion review](https://www.morgen.so/blog-posts/motion-review)

11. **Remix with a gentle slope.** Remix a tile shows the same tile with three knobs; one more tap reveals the block view; one more the code view. Why: the malleable software essay's "gentle slope" from user to maker is exactly M3. D, E, P. **M3**. Effort L. [Ink & Switch](https://www.inkandswitch.com/essay/malleable-software/)

## Lessons from failed or stalled everything-apps

- **Arc:** fans loved it, but most users found too much to learn and barely used Spaces or Live Folders. Ship fewer, deeper features. [Letter summary](https://gigazine.net/gsc_news/en/20250608-letter-to-arc-members)
- **Glitch:** free hosting of user-built things was unsustainable and projects were stranded. Keep user apps local and exportable. [Slashdot/Verge](https://tech.slashdot.org/story/25/05/23/134214)
- **Mercury OS:** a beautiful concept with no path from today's habits; stayed a concept. Build on real daily use (Workouts first). [Mercury OS](https://uxdesign.cc/introducing-mercury-os-f4de45a04289)
- **Notion, Tana, Anytype:** power arrives as a complexity cliff (databases, supertags). Hide schema until asked.
- **Motion:** auto-scheduling that moves things without asking erodes trust. Tess proposes, the user accepts.
- **HyperCard:** the gentle slope worked; it died from neglect, not design. The idea is worth copying.

## Top 3 to act on now

1. Process list with workout as the first process (M1): the metaphor and Ready-to-Resume in one feature.
2. Visible time: draining Now bar plus rest-timer Live Activity (M1, small).
3. Context switch saves state automatically (M1 P1), the data the process list and Time Machine both need.
