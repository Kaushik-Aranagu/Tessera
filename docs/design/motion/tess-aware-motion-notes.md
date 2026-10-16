# Tess's motion, aware of the screen: notes for later

Kaushik, 8:53 AM PT Oct 16, in the motion thread. Parked by his call: "for now, keep it in notes; we'll pursue it when we have the effort, time, resources and credits."

## What he said
- The weak link is the working state's pattern: it goes out well, but once the lights spread, the paths are predictable and hard-coded.
- He wants her motion to depend on what is on the screen and how he is interacting, not only on fixed rules.
- Bigger idea: Tess as an agent of her own, the way this project runs. One coordinator (Tess) that keeps and grows its own context and memory, and keeps track of every agent, thread and task it runs. Something like Siri, but Tess.
- She should know what is on the screen and how he is interacting with it. A fast model call could then pick her next motion (roam, where the lights go, what she looks at) instead of a deterministic check.
- Models to research: fast Claude calls, and small on-device language models that could be fine-tuned or trained with reinforcement learning locally. Tessera is not general purpose: a few baseline scenarios, everything else built from them, so a small model may be enough.
- No screenshots or images sent anywhere. He knows latency may make it infeasible; that is part of the research.

## How it could fit what exists (lab notes, not decisions)
- Section 14's event contract is the seam. Today the router turns events into states with fixed rules. A model would only choose among the same states and places, never invent motion, so every safety rule in tess-motion.md still holds (never over words, nothing on the page moves for her, one haptic per moment, Done never changes).
- The input is already structured: the page's declared free ground, the row rects and their kinds, the current event, the time of day, what he last touched. That is text, not pixels.
- Latency budget: her choices land on beats she already has (the 900 ms split, the 760 ms roam arc), so a decision that arrives within about 300 ms can steer the next beat; a late one is dropped and the rule decides.
- A first step with no model at all: drive the lights from the page itself (go to the words that just changed, wander on smooth noise instead of a fixed loop). This is idea 11 on the motion idea board.

## Who would pick this up
- AI architecture thread: the agent shape, the model research (fast Claude calls vs. small on-device models, fine-tuning, RL), cost under the monthly AI budget.
- Motion lab: the decision interface on the router, the latency budget, and the no-model first step.
