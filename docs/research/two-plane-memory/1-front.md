Kaushik, you asked us to test whether your two-plane memory idea holds up: a reasoning LLM and a memory pyramid, joined by small learned bridges, with a memory that changes shape and learns from use. We tested it on public chat data and always scored on chats the bridges never saw: LoCoMo (10 chats, 1,531 questions) and LongMemEval-S (the 428 of its 500 questions that have user-turn evidence). We also wrote the math down, had it audited twice, had skeptics re-run the main experiments, and re-checked the literature. The bottom line is mixed but useful. Small bridges are a real and cheap gain: the share of marked evidence found in the top 10 rises from 0.575 to 0.657 on LoCoMo [M]. That gain barely carries to a second dataset (0.860 to 0.864 on LongMemEval-S) [M]. Memory that learns from use pays only when the cites are mostly right and point at things the system had missed. With realistic cites the best rules add +0.005 to +0.009 [M]. Once keyword search is fused in, no rule adds more than +0.006 even with oracle cites, and no more than +0.002 with realistic ones [M]. A learned encoder between memory nodes lost to simply scoring every child, and a second hop built from vectors alone did not help multi-hop questions [M]. The bookkeeping that keeps derived vectors in step as nodes are created, merged and forgotten, and as weights change, is exact and cheap [M]. That covers the derived cache only; deletion from keys that learn from use and from trained weights was not tested. Joint training with an open LLM is untested. Several things we told you earlier were wrong; they are listed below. The work is publishable as a careful systems-and-analysis paper, not as a new paradigm, and close prior work exists. The next decisive test is cheap: real cites and real follow-up probes written by Claude Haiku.

**How numbers are labelled.**
- **[M]** measured in this project, on this container. Each result names its run.
- **[S]** from an outside source. The link is given where the number appears, or in the prior-work table.
- **[X]** our extrapolation or estimate. Not measured.
- §9 (algorithms and latency) also uses **[D]**, derived by arithmetic from [S] or [M] numbers, and **[B]**, from the project brief and not verified.
- Design constants (dimension 384, rank 16, parameter counts computed from them) are definitions and carry no label.
- "Method §x" points to the method and analysis part that follows this front matter. Section 9 (algorithms and latency) comes after it.

**How intervals are labelled.** All intervals are 95% paired bootstraps.
- **[chat]** resamples the 10 test chats. This is the honest one, though 10 clusters is still few.
- **[ask]** resamples questions as independent. In runs where keys learn, a question's 3 visit orders stay together.
- **[visit]** resamples the 4,593 visits (3 orders of 1,531 questions) as independent. This is the most optimistic.
- **[unclustered]** treats asks or visits as independent; the source does not say which.
- **[seed]** is a mean ± s.d. over noise seeds with common random numbers.

**Metric.** Unless stated otherwise, the metric is recall@10: the share of a question's marked evidence turns found in the top 10, on held-out LoCoMo chats (5 folds, 8 training and 2 test chats per fold). "Multi-hop" is LoCoMo's 281-question multi-hop category.

---

## Verdict on the ideas

| idea | status |
|---|---|
| 1. Two planes joined by small learned bridges | supported with limits |
| 2. A shared latent language | supported with limits (text form); untested (hidden-state form) |
| 3. Small encoders between memory nodes, working in embeddings | not supported yet |
| 4. A memory that creates, merges and forgets nodes while embeddings change | supported with limits |
| 5. A memory that learns from use | supported with limits |
| 6. A read-again loop for multi-hop questions | not supported yet (vector form); untested (LLM-written probes) |
| 7. Joint training of memory and reasoning | untested |
| 8. Jev or CLM-style decision models as the bridges | supported with limits (CLM-style heads); untested (Jev) |

### 1. Two planes joined by small learned bridges

**Status: supported with limits.**
- **Evidence.** Rank-16 bridges trained on 8 chats lift held-out recall@10 from 0.575 to 0.657, a gain of 0.082 with [ask] interval 0.064 to 0.100 [M, E6 and E8]. Less than half of that lead survives BM25 fusion: 0.620 for the fused frozen encoder against 0.656, a lead of 0.036 [M, E6, no interval]. But on LongMemEval-S, bridges trained on LoCoMo barely move turn@10: 0.860 frozen, 0.864 at rank 16, 0.822 at full rank [M, E7, no interval]. The audit's conjecture is that at about 1k training questions much of what transfers is one corpus-wide correction: centring each chat's vectors, with no labels and no training, already gives 0.609, which is 37% of the rank-1 gain [M, method §6.6, Conjecture C2].
- **What would change the verdict.** Upgrade to supported if bridges trained on a mix of public and synthetic histories beat the frozen encoder on LongMemEval-S and on the Tessera test world, with an interval above zero. Downgrade if label-free centring matches the trained bridges there (method prediction P9, second part).

### 2. A shared latent language

**Status: supported with limits for the text form; untested for the hidden-state form.**
- **Evidence.** The language is now defined (method §2.2 and §2.3). Every message is a point on the unit sphere of one frozen encoder, and it carries a text label, a view tag and a graph version, so every exchange is logged, readable and replayable. In the text form the reasoner speaks in words, so its states decode exactly by construction. A trained key still decodes to its own turn 98.1% of the time, against 99.97% for the frozen encoder [M, method §6.1; confounded by step size]. The catch is that a shared space is not a shared scale. Training moved the cosine between the mean question and the mean key from 0.877 to 0.339 [M]. Two unrelated questions from one chat (cosine 0.308) look almost as alike as a question and its 10th-best node (0.350) [M]. That is why storing questions as keys collapsed recall to 0.463, and why a rank-calibrated version recovered it to 0.686 [M, alias-hub fix].
- **What would change the verdict.** Measure the round-trip error $\varepsilon$ of method Definition 2.6 with an open LLM (Qwen3-8B) and its tapped hidden state. If bridges trained on text states also work on hidden states, within a [chat] interval of the text result (prediction P11), the hidden-state form becomes supported. If $\varepsilon$ stays large at every layer (conjecture C3), it is not.

### 3. Small encoders between memory nodes, working in embeddings

**Status: not supported yet.**
- **Evidence.** In the embedding-pyramid prototype (E8), one shared attention encoder (99,456 weights in E8; the method's design for $g$ in §2.4 counts about $7.5\times10^4$) built each session's vectors from its children. On held-out chats it routed worse than untrained k-means slots: 0.473 against 0.517, a difference of −0.044 with [chat] interval −0.057 to −0.032, worse in all 10 chats [M]. It did far worse than the exact log-sum-exp of the children's own scores: 0.633, a difference of −0.160 with [chat] interval −0.175 to −0.146 [M]. It overfits: on training chats its session recall@3 climbs to 0.95 [M]. Early stopping only brings it level with k-means (0.523, post hoc) [M]. Several slot vectors per node do beat one mean vector: +0.069, [chat] +0.042 to +0.098 [M].
- **What would change the verdict.** A node encoder trained on far more structures (thousands of public or synthetic histories, not 8 chats) that beats the exact late-pooled score at a level whose leaves are not scanned anyway. No numbered prediction covers this; P7 only bounds what a fixed pool can gain over the mean. Gists and features for structural operations are still untested uses.

### 4. A memory that creates, merges and forgets nodes while embeddings change

**Status: supported with limits.** The bookkeeping is supported. Learned decisions about when to create, merge or forget are untested.
- **Evidence.** Treat every derived vector as a cache entry keyed by its level, the weight version and its children's hashes. Then 5,882 streaming inserts cost exactly 2 encoder calls each and match a batch build bit for bit. 3,534 forgets leave parent vectors and BM25 statistics equal to a fresh build on the survivors. Merges, splits and their undos are exact. Swapping in new weights re-derives 5,882 leaf keys and 282 parents in 127 ms, with no text re-encoded [M, E8, reproduced bit for bit by the skeptic]. The limits: this covers the derived cache only. Raw vectors stayed on disk, unlearning from trained weights was not tested, and "trainable" was shown only as offline retrains swapped in whole [M, E8 review]. Keys that move with use break exact deletion unless they are rebuilt from a per-node cite log (method Proposition 6.23).
- **What would change the verdict.** Learned write and reshape heads that beat the current count rules, and REALM-style prompted rewiring, on replay. Prediction P10 (byte-exact deletion with log-defined keys) passing on the full memory state.

### 5. A memory that learns from use

**Status: supported with limits.**
- **Evidence.** With oracle cites (the benchmark's own marked evidence), moving keys toward the questions that cited them adds +0.020, [chat] +0.009 to +0.030 [M, E6 and audit]. A pull-plus-push rule adds +0.026 and a hub-corrected alias bonus +0.029, [chat] +0.017 to +0.038 [M]. But oracle cites include evidence the system never showed. Limit the cites to the opened top 10 and the plain rule adds −0.002, the best rules +0.005 to +0.009 [M, cite-noise fix]. With BM25 fused, no rule adds more than +0.006 even with oracle cites, and no more than +0.002 with opened-only cites [M]. No rule gains when the system cites its own top hit, and at 60% wrong cites the best rules only break even [M]. The analysis explains why (method §6.4). Each pull also lifts the node a little on every unrelated question, and that common-mode cost eats the gain once more than about 24% to 27% of cites are wrong at step size 0.1 [M, method P3; no interval, and it rests on an untested assumption].
- **What would change the verdict.** Real cites from Claude Haiku on held-out chats (predictions P1 and P3). Upgrade if a rule gains with a [chat] interval above zero on cites the reasoner actually produced, and keeps a gain after BM25 fusion. Downgrade to not supported if no rule beats zero there.

### 6. A read-again loop for multi-hop questions

**Status: not supported yet in vector form; untested with LLM-written probes.**
- **Evidence.** Three vector-only second hops (the question combined with the first hit) all lowered multi-hop recall@10. The learned hop lost 0.017, [chat] −0.031 to −0.003; the untrained ones lost 0.025 and 0.027 [M, second-hop fix]. Even when the first hop is forced onto a gold turn, the hop vectors add nothing: multi-hop 0.427 for the plain question against 0.429 for the learned hop [M, skeptic's check]. Opening only the top 3 sessions costs multi-hop 0.134, [chat] −0.164 to −0.100, because multi-hop evidence spans 2.68 sessions on average [M]. Any router that opens 3 sessions is capped at 0.939 coverage on multi-hop (method Proposition 6.9) [M].
- **What would change the verdict.** Claude Haiku writing the next probe from what it has read. Upgrade if multi-hop recall@10 rises above the single-read 0.475 with a [chat] interval above zero.

### 7. Joint training of memory and reasoning

**Status: untested.**
- **Evidence.** Only math so far. The joint loss and a corrected gradient-flow table are written out (method §3.8). Alternating parameter steps and structure steps gives an objective that never rises, but no global optimum (method Proposition 6.25). Prior work gives two warnings [S]. CLM-8B's heads are locked to its frozen backbone, and LongMem kept its backbone frozen so that cached memory would not go stale. A LoRA on the reasoner makes every key computed from it stale.
- **What would change the verdict.** The stage 3 runs: P11 (bridges warm-start on hidden states), C3 (which layer to tap), then a joint LoRA that beats a frozen LLM with trained bridges on held-out answer accuracy and evidence recall over 3 seeds.

### 8. Jev or CLM-style decision models as the bridges

**Status: supported with limits for CLM-style heads; untested for Jev.**
- **Evidence.** Our bridges are CLM-style: identity-plus-low-rank state and action heads, trained with InfoNCE in both directions, on a 33M-parameter encoder, with 12,288 weights per head at rank 16. They are what gives the gain in idea 1 [M]. None of CLM-8B's own training carries over, because its heads are locked to Qwen3-8B [S, model card]. Jev is a closed hosted model. Its vendor latency is 70 to 500 ms [S, unverified]; it cannot be fine-tuned, and walled data cannot go to it. Our memory plane takes 25 to 40 ms per hop on one CPU thread, mostly the encoder [M, algorithms review], against 1.29 s to the first token of Claude Sonnet 5.5 at low effort [S, [Artificial Analysis](https://artificialanalysis.ai/models/comparisons/claude-haiku-5-5-vs-claude-sonnet-5-5-low), fetched 27 Oct 2026].
- **What would change the verdict.** Run CLM-8B's heads directly against our bridges on the same held-out chats (stage 2). Run a Jev trial on non-private routing decisions against Haiku.

---

## Corrections to what we said earlier

These are claims we made earlier in this thread or in the design drafts, that the audits or the re-runs overturned or narrowed. The audits are the referee audit and the code-against-math audit (`audits/wf4_results.json`), the skeptic reviews (`audits/wf1_results.json`, `audits/wf2_results.json`) and the benchmark re-run (`audits/algos_review.md`).

1. **Low-rank bridges.** *Said:* low-rank bridges fix overfitting, raising recall from 0.610 (full rank) to 0.657 (rank 16), and 0.822 to 0.864 on LongMemEval-S. *Now:* this is mostly a step-size effect. Every rank used Adam at learning rate $10^{-3}$ for 320 steps, so a full head travels further: mean $\lVert W-I\rVert_F$ is 1.54 at rank 1, 4.07 at rank 16 and about 6.0 at full rank [M]. Full rank at learning rate $10^{-4}$ reaches 0.667, which is +0.010 against rank 16, [unclustered] −0.002 to +0.023; it reaches 0.663 at $3\times10^{-5}$ [M]. Rank 16 at $3\times10^{-4}$ reaches 0.664, and rank 1 reaches 0.667 at the shared $10^{-3}$ [M]. Tuned, all ranks are within ±0.005 [M]. These learning rates were scanned on the test folds, so they show the confound and are not clean estimates. The parameter-count explanation is withdrawn. Low rank is kept for cost, for clean attribution and because an untrained bridge equals the frozen encoder, not for accuracy. The LongMemEval-S comparison was not re-run.
2. **Confidence intervals.** *Said:* intervals were "paired bootstrap over questions"; E6's were over 4,593 visits. *Now:* none were clustered by chat, so all were too narrow. Re-clustered by chat [M]:
   - clean move rule: visit-level +0.0146 to +0.0267 becomes [chat] +0.0092 to +0.0300 (still positive);
   - recommended read loss on 409 multi-evidence questions: +0.017, [ask] +0.006 to +0.029, becomes [chat] +0.001 to +0.038 (still positive);
   - dropping the backward loss term alone: +0.012, [ask] +0.001 to +0.024, becomes [chat] −0.0017 to +0.0295 (no longer significant);
   - masking alone: +0.0055, [ask] +0.0003 to +0.0111, becomes [chat] −0.0001 to +0.0118 (no longer significant);
   - alias bonus against the move rule: +0.0065, [chat] −0.0036 to +0.0153 (no longer significant);
   - pyramid of top 3 sessions: +0.025, [ask] +0.004 to +0.046, becomes [chat] −0.000 to +0.050 (fragile; 4 of 10 chats lose).
   
   One noise draw also moves an arm's mean by s.d. 0.0035 to 0.0037, about the size of E6's bootstrap s.e., and no visit bootstrap captures that [M]. The earlier +0.035 (bridges over frozen, [ask] +0.017 to +0.054) and +0.038 (key learning over bridges, [ask] +0.024 to +0.051) have not been re-clustered.
3. **Alias keys.** *Said (design draft):* each node's key is $k_v=Ae_v+r_v$, and a cited node takes the question's state as an alias key. *Now:* raw alias keys collapse recall to 0.463 [M, E6]. The cause is a scale mismatch, not narrow hubness: unrelated same-chat questions have cosine 0.308, close to a question's 10th-best key at 0.350, so an alias enters an unrelated question's top 10 in 40.4% of pairs while only 1.1% of question pairs share evidence [M, alias-hub fix]. A hub-corrected bonus fixes it (0.686) [M].
4. **Keys that learn from use.** *Said:* letting keys learn from cites "adds more on top" (+0.038, E5 at step size 0.3). *Now:* that used oracle cites, including evidence the system never opened. With cites limited to the opened top 10, the move rule gives −0.002 and the best rules +0.005 to +0.009; with BM25 fused, at most +0.006 with oracle cites and +0.002 with opened-only cites [M, cite-noise fix].
5. **Transfer to LongMemEval.** *Said:* results carry over to LongMemEval. *Now:* rank-16 bridges move turn@10 from 0.860 to 0.864 and full-rank bridges drop it to 0.822 [M, E7, no interval]. That is not a transfer of the LoCoMo gain.
6. **The novelty gap.** *Said:* "nobody has shown bridges that are open, cheap to fine-tune and trained from the reasoning plane's own feedback, on a memory that also learns its own structure." *Now:* RMM (2025) already trains small heads on a frozen retriever from the answering LLM's own cites, HAGE (2026) already learns edge structure from evidence reward, and REALM (2026) rewires topology after each use [S]. The real gap is narrower (see "Prior work and novelty").
7. **Rows of our prior-work table** [S, prior-art check]:
   - HAGE does learn structure (a trainable vector per edge); "RL variance" was our guess, not a problem HAGE reports.
   - Jev-Mem's code is public; only the Jev model is closed. CLM-8B exposes Jev's typed interface, so an open controller is nearly a drop-in.
   - CLM-8B is not "our design scaled down": none of its training carries over, and its state head reads a pooled embedding of the state text, not the generating model's per-step hidden state.
   - The LoCoMo audit is a Penfield Labs blog post with a repo, not a paper. It also found citation errors that make the marked evidence wrong for about 4% of questions.
   - The Titans and TTT-E2E row mixed two papers.
   - RAG and Atlas already kept the document encoder fixed, so "freeze the encoder, train the heads" is the standard workaround.
   - The original Memory Networks were not fully differentiable.
   - In complementary learning systems, interference is the problem the theory solves, not one it hit.
8. **The temperature.** *Said:* the logit scale is learned. *Now:* the step budget pins it. It ends at 24.46 to 24.63 in every fold; with the heads held fixed, the loss alone would choose 28.2 (rank 16) or 36.5 (full rank); letting it learn fast changes recall by −0.017, [unclustered] −0.026 to −0.008 [M]. It is a fixed hyperparameter.
9. **Anchored against plain move under noise.** *Said:* the anchored rule beats move at 30% wrong cites (0.658 against 0.654). *Now:* with common random numbers the gap is +0.0009 ± 0.0006 [seed] [M]. It was noise.
10. **Anchored keys "stay decodable".** *Now:* the cap only guarantees $\langle k,k^0\rangle\ge\sqrt{1-\zeta^2}=0.954$ for $\zeta=0.3$, a fidelity to the base key. After renormalisation $\lVert k-k^0\rVert$ can reach 0.30352, above the stated cap. The decode rate of live keys has not been measured.
11. **"The move rule has no hub problem."** *Now:* common-mode drift is its main cost. At step size 0.1 the common-mode loss per visit (0.0296) is more than half the re-ask gain (0.0500) [M, method §6.4].
12. **Exact deletion.** *Said:* deleting an item gives the state that would exist had it never been stored, and subtracting one term from a key sum is exact. *Now:* deletion gives exactly the state rebuilt from the retained records. Records selected while the item was present (opened sets, later probes) carry a residual unless they are dropped. In float32, $(s+x)-x$ differed from the sum $s$ that never held $x$ in 100% of 20,000 trials [M]. A running mean makes every centred key depend on every question.
13. **The alignment loss.** *Said:* its uniformity term removes the shared question direction. *Now:* withdrawn. The loss contains no node key, and the read loss is provably blind to that offset (method Proposition 6.18).
14. **"The equaliser keeps the temperature bounded."** *Now:* false for questions with one evidence turn (73% of questions), where the equaliser is zero.
15. **Self-feedback as noise with $p=1-P@1=0.748$.** *Now:* the predictions used the realised wrong-cite share of each run: 0.652, 0.683, 0.748 and 0.821 at step sizes 0.02, 0.05, 0.1 and 0.2 [M].
16. **The additive centred rule and the centred move rule "differ only for the 15% of cited nodes with at least 3 cites".** *Now:* they agree to first order and differ at second order for every node with at least 2 cites, which is 41% of cited nodes [M].
17. **The rank-selection rule $r^\star(n)$** was stated as a proposition. Only an inequality is proved; the rule is a heuristic.
18. **Attribution.** 0.657 and 0.678 come from E6 (rank 16, step size 0.1), not E5, whose own run uses full rank and step size 0.3.
19. **Question count.** The parser drops 5 recoverable questions; a fixed parser gives 1,536 instead of 1,531. The effect on any mean is at most 0.003 [M].
20. **Selection effects.** *Said:* "the key learning rate was picked from two values on the same chats, a mild selection effect." *Now:* there was no validation split at all. Learning rate, epochs, rank, penalty, key step size and cap were all fixed with only the test folds in view.
21. **The sessions-first read.** *Said:* BM25 sessions then hybrid (0.649) is "the pyramid's sessions-first read", shown as a gain. *Now:* it is level with the flat bridges overall and costs multi-hop recall: 0.297 against 0.475 [M, E8]. Every router that opens 3 sessions loses heavily on multi-hop; for the best one the loss is 0.156, [unclustered] 0.112 to 0.200 [M].
22. **The fixed alias rule "matches or beats move at every cite condition".** *Now:* the clean-cite win over move is not significant by chat. Against move with a properly tuned step size it is a tie in the self-loop, and the alias bonus does slight harm there at visit level (−0.004, [visit] −0.007 to −0.000) [M, alias-hub review].
23. **The prototype's "deletions provably leave nothing derived behind" and "changing embeddings are trainable".** *Now:* shown empirically for the derived cache only, and training was shown only as offline retrains swapped in whole [M, E8 review].
24. **The algorithms and latency draft** [M, algos_review.md]:
    - "The encoder is at least 95% of a memory hop": on the flat path it is 86% at 65k leaves (39.7 ms total, 5.5 ms memory) and about 67% at 100k with a cold cache. Quote a hop as 25 to 40 ms.
    - "Descent over untrained parents loses most of the exact top 10": on real vectors a k-means tree keeps 0.82, 0.96 and 0.99 of it at beam 8, 32 and 64 (0.56, 0.84 and 0.94 on the synthetic keys).
    - "Memory is under 2% to 5% of time to first token": up to about 6%.
    - The Claude latency figures did not match their source. Artificial Analysis on 27 Oct 2026 shows Sonnet 5.5 at 1.29 s (low effort) and 2.99 s (medium), and Haiku 5.5 at 11.39 s (medium) [S].
    - The online-update evidence was misattributed: under its own "opened nodes only" rule the move rule gives −0.002 [M]. Its score filter passes 99.97% of opened nodes, so it filters nothing.
    - Batching int8 queries is not "four for the price of one": per-query cost falls about 2 times at 4 queries and 4 to 5 times at 16.

**Claims that held up under audit.** The training code computes exactly the written loss, to within $10^{-6}$ [M]. The frozen baseline is fair: adding BGE's query instruction gives 0.569 against 0.575, and the bridge gain is unchanged (+0.084 against +0.082) [M]. The mean-pooling collapse (0.386) really comes from the parent score, not from the ranker inside the sessions: swapping in the hybrid ranker changes it by only +0.007, [ask] −0.004 to +0.018 [M]. The clean move-rule gain survives clustering by chat. The numbers from E6, the three round-2 fixes and E8 were reproduced exactly by a skeptic or an audit. E7 (LongMemEval-S) and the E5 key-learning run have not been re-run.

---

## Results

### (a) LoCoMo retrieval arms (E1, E5, E6)

All numbers [M]. Sources: the E1 and E5 runs, `e6_result.txt`, the E8 reproductions (`pyramid/results.json`), the code-against-math audit (`audits/wf4_results.json`) and method §4.4, §6.2 and §6.6. "With BM25" is recall@10 after reciprocal-rank fusion with BM25.

| arm | recall@10 | multi-hop | with BM25 | difference and interval |
|---|---|---|---|---|
| BM25 | 0.563 | 0.255 | – | −0.094 vs rank-16 bridges, −0.119 to −0.069 [ask] |
| frozen bge-small | 0.575 | 0.385 | 0.620 | −0.082 vs rank-16 bridges, −0.100 to −0.064 [ask] |
| frozen, with BGE's query instruction | 0.569 | – | – | – |
| frozen, each chat centred, no labels | 0.609 | – | – | – |
| BM25 picks 3 sessions, frozen hybrid inside | 0.649 | 0.297 | – | −0.008, −0.031 to +0.014 [ask] |
| mean frozen vector picks 3 sessions | 0.386 | 0.227 | – | −0.271, −0.296 to −0.245 [ask] |
| two-hop pseudo-relevance (E1) | 0.641 | – | – | – |
| full-rank bridges, Adam lr $10^{-3}$ | 0.610 | 0.405 | 0.637 | −0.047 vs rank 16, −0.057 to −0.037 [visit] |
| full-rank bridges, lr $10^{-4}$ (audit) | 0.667 | – | – | +0.010 vs rank 16, −0.002 to +0.023 [unclustered]; lr scanned on test folds |
| **rank-16 bridges, lr $10^{-3}$ (reference)** | **0.657** | **0.475** | **0.656** | – |
| rank-16 bridges, lr $3\times10^{-4}$ (audit) | 0.664 | – | – | – |
| rank-1 bridges, lr $10^{-3}$ (rank sweep) | 0.667 | – | – | best in 5 of 5 folds at the shared lr |
| rank 16, recommended read loss (forward-only, masked) | 0.657 | – | – | overall +0.002, −0.006 to +0.009 [unclustered]; 409 multi-evidence questions +0.017, +0.001 to +0.038 [chat] |
| rank 16, temperature fixed at 20 | – | – | – | +0.004, −0.001 to +0.010 [unclustered] |
| rank 16, temperature learned fast | – | – | – | −0.017, −0.026 to −0.008 [unclustered] |
| full-rank bridges + key move (step 0.3, E5), oracle cites | 0.648 | 0.432 | – | +0.038 vs full-rank bridges, +0.024 to +0.051 [ask] |
| rank 16 + key move (step 0.1, E6), oracle cites | 0.678 | 0.503 | 0.661 | +0.020, +0.009 to +0.030 [chat] |
| rank 16 + raw alias keys (E6), oracle cites | 0.463 | 0.342 | 0.649 | −0.195, −0.209 to −0.180 [visit] |

Notes.
- Fused with BM25, the rank-16 bridges keep a lead of 0.036 over the fused frozen encoder (0.656 against 0.620), with no interval [M].
- In the rank sweep, rank 16 scored 0.650 and full rank 0.611 at the shared learning rate with 1,225 training questions. The sweep is a separate run from E6. The train-to-test gap there was 0.045 (rank 1), 0.220 (rank 16) and 0.386 (full) [M].
- Learning rates in the audit rows were scanned on test folds. They show the confound; they are not clean estimates.

### (b) Memory-learning rules under cite noise

All numbers [M], from the cite-noise fix (`fixes/cite-noise/`) and the alias-hub fix (`fixes/alias-hub/`). Skeptics reproduced both exactly. Each cell is the change in recall@10 against rank-16 bridges with no learning (0.657).
- *Clean:* cites are the benchmark's marked evidence (oracle).
- *30% / 60% wrong:* that share of cites is swapped for a non-evidence node from the top 10.
- *Self-loop:* the system cites its own top hit.
- *Opened only:* clean cites, but only those inside the opened top 10. This is the realistic case.
- *Clean, with BM25:* recall@10 after BM25 fusion (baseline 0.656).

| rule | clean | 30% wrong | 60% wrong | self-loop | opened only | clean, with BM25 |
|---|---|---|---|---|---|---|
| move, step 0.1 (E6 rule) | +0.020 | −0.003 | −0.024 | −0.023 | −0.002 | 0.661 |
| move, step tuned on dev chats (mostly 0.02) | +0.008 | +0.004 | −0.002 | −0.004 | +0.001 | 0.657 |
| contrastive pull + push | +0.026 | +0.014 | +0.003 | −0.005 | +0.008 | 0.660 |
| combo (centred pull, BM25 agreement, small push) | +0.018 | +0.009 | +0.000 | −0.001 | +0.005 | 0.659 |
| simulated verifier, then move | +0.018 | +0.008 | −0.002 | −0.011 | −0.002 | 0.661 |
| simulated verifier, then combo | +0.019 | +0.009 | +0.0005 | −0.003 | +0.002 | 0.661 |
| hub-corrected alias bonus (F3) | +0.029 | +0.017 | +0.003 | −0.004 | not run | 0.662 |
| key-view alias + bonus (F5) | +0.030 | +0.019 | +0.007 | −0.001 | not run | 0.661 |
| raw alias keys (E6 rule) | −0.195 | −0.229 | −0.265 | −0.090 | not run | 0.649 |

Intervals for the cells that decide the verdict:
- move, clean: [visit] +0.0146 to +0.0267; [ask] +0.012 to +0.030; [chat] +0.009 to +0.030.
- move, opened only: [ask] −0.010 to +0.005.
- contrastive: clean [ask] +0.018 to +0.034; 30% wrong [ask] +0.006 to +0.022; 60% wrong [ask] −0.005 to +0.011; self-loop [ask] −0.012 to +0.003; opened only [ask] +0.001 to +0.015.
- combo: 60% wrong [ask] −0.006 to +0.007; self-loop [ask] −0.006 to +0.005; opened only [ask] −0.001 to +0.011.
- verifier then move, self-loop: [ask] −0.018 to −0.005.
- F3 against no learning, clean: [chat] +0.017 to +0.038, up in 9 of 10 chats. F5: [chat] +0.015 to +0.041.
- F3 against move at step 0.1, clean: +0.0065, [chat] −0.0036 to +0.0153. F5: +0.0070, [chat] −0.0049 to +0.0177.
- F3 against dev-tuned move: 60% wrong +0.005, [visit] +0.0003 to +0.009; self-loop +0.001, [visit] −0.003 to +0.004.
- F3, self-loop: −0.004, [visit] −0.007 to −0.000.

Notes.
- The alias rows come from a separate run with its own noise draws. There, move at step 0.1 scored −0.001 at 30% wrong. Noise draws alone move these point estimates by about ±0.002 [M, cite-noise review].
- Other rules tried [M]: centred pull (+0.023 clean, −0.005 self-loop); a slow adapter refit every 10 questions (+0.016 clean, +0.009 opened only); surprise weighting, which looked robust but fails when wrong cites come from the top 50 (−0.017); BM25 agreement alone (+0.004 clean).
- The noise model is idealised: wrong cites are uniform picks from the top 10. A real LLM probably errs on the most plausible distractor. The verifier is simulated with independent errors (it catches 70% of wrong cites and drops 10% of right ones), so the verifier rows are optimistic.
- Break-even wrong-cite rates from method §6.4: about 0.24 to 0.27 for move at step 0.1, 0.38 to 0.42 at step 0.05 or less, 0.55 for the centred rule, and 0.57 for a rank-gated rule with far noise [M, no interval, and it rests on an untested identifying assumption].
- Under the "only discoveries pay" test (method §6.4), clean cites restricted to evidence already in the top 10 change recall by −0.0024, [unclustered] −0.007 to +0.002. A rule that only moves cited nodes ranked below 10 keeps 90% of the clean gain (+0.0183, [unclustered] +0.013 to +0.024) [M].

### (c) Second-hop attempts

All numbers [M], from the second-hop fix (`fixes/second-hop/`), reproduced exactly by the skeptic. No keys learn here, so each question is scored once. Differences are against rank-16 bridges with one read: 0.657 overall and 0.475 multi-hop.

| arm | recall@10 | difference and interval | multi-hop | difference and interval |
|---|---|---|---|---|
| one read, rank 16 | 0.657 | – | 0.475 | – |
| hop on the average of question key and first hit (bridge space) | 0.634 | −0.023, −0.035 to −0.011 [ask] | 0.450 | −0.025, −0.052 to −0.001 [chat] |
| hop on the average of question and first hit (encoder space) | 0.630 | −0.027, −0.039 to −0.016 [chat] | 0.448 | −0.027, −0.048 to −0.007 [ask] |
| learned hop head, tuned on dev chats | 0.646 | −0.012, −0.020 to −0.003 [chat] | 0.458 | −0.017, −0.031 to −0.003 [chat] |
| open the top 3 BM25 sessions, bridges inside | 0.682 | +0.025, −0.000 to +0.050 [chat] | 0.341 | −0.134, −0.164 to −0.100 [chat] |
| same, plus the untrained hop | 0.671 | +0.013, −0.008 to +0.034 [ask] | 0.334 | −0.141, −0.186 to −0.098 [ask] |
| same, plus the learned hop | 0.680 | +0.023, +0.002 to +0.045 [ask] | 0.340 | −0.134, −0.179 to −0.090 [ask] |
| fuse the session list with the flat list (post hoc) | 0.715 | +0.058, +0.040 to +0.074 [chat] | 0.418 | −0.057, −0.092 to −0.020 [ask] |
| earlier E1: two-hop pseudo-relevance | 0.641 | – | – | – |

Notes.
- The first hop lands on an evidence turn for only 36% of all questions and 33% of multi-hop ones [M]. When the first hop is forced onto a gold turn, multi-hop recall@10 is 0.427 for the plain question, 0.426 for the averaged hop, 0.429 for the learned head and 0.442 when the hop list is fused with the plain list [M, skeptic's check]. The vectors carry almost no second-hop signal.
- The top 3 BM25 sessions hold 42.7% of multi-hop evidence when averaged per question, or 39.7% counted over evidence turns. Multi-hop evidence spans 2.68 sessions on average, and 17% of multi-hop questions span more than 3 [M].
- The last data row was designed after seeing test results. It is a lead for a fresh pre-registered test, not a result.
- No read-again loop with probes written by an LLM has been run yet.

### (d) Embedding-pyramid prototype (E8)

All numbers [M], from `pyramid/results.json`, reproduced bit for bit by the skeptic. Sessions are the parent level. Routed arms open 3 sessions. The arm names (R0 to R4, S0 to S7, H1, H2) are E8's own labels. They are not the read channels R1 to R8 or the views $S$ and $H_c$ of the method.

| arm | what it is | recall@10 | multi-hop |
|---|---|---|---|
| R0 | BM25, flat | 0.563 | 0.255 |
| R1 | frozen encoder, flat | 0.575 | 0.385 |
| R2 | rank-16 bridges, flat (comparator) | 0.657 | 0.475 |
| R3 | BM25 fused with R2, flat | 0.656 | 0.377 |
| R4 | bridges trained jointly with the parent loss, flat | 0.662 | 0.482 |
| S0 | BM25 picks sessions, frozen hybrid inside | 0.649 | 0.297 |
| S1 | mean frozen vector picks sessions, frozen dense inside | 0.386 | 0.227 |
| S1h | as S1, hybrid inside | 0.393 | 0.214 |
| S2 | BM25 picks sessions, bridged hybrid inside | 0.667 | 0.319 |
| S3 | mean of bridged keys picks sessions | 0.447 | 0.269 |
| S4 | untrained k-means slots, 4 per session | 0.517 | 0.343 |
| S5 | exact log-sum-exp over the children's scores | 0.633 | 0.401 |
| S6 | learned slots from a shared encoder (99,456 weights) | 0.473 | 0.284 |
| S6h | S6 plus a label-free heap loss | 0.503 | 0.310 |
| S6a | S6 with adaptive opening (5.49 sessions on average) | 0.545 | 0.324 |
| H1 | S6 routing fused with R2 | 0.492 | 0.315 |
| H2 | leaf score plus the S6 tree prior, fused with BM25 | 0.646 | 0.356 |
| H2-lse | H2 with the exact score as the prior | 0.661 | 0.375 |
| S6, early-stopped (post hoc) | epochs chosen on dev chats | 0.523 | 0.307 |

Key differences [M]:
- S4 − S3, slots against one mean vector: +0.069, [chat] +0.042 to +0.098.
- S6 − S4, learning against untrained slots: −0.044, [chat] −0.057 to −0.032, negative in all 10 chats.
- S6 − S5, learning against the exact score: −0.160, [chat] −0.175 to −0.146. With S5 untuned (0.630), the gap is −0.157, so S5's tuning does not explain it.
- S6h − S6: +0.030, [ask] +0.015 to +0.046.
- H2 − R3: −0.010, [chat] −0.021 to −0.002. With leaf keys matched to H2's, [chat] −0.020 to +0.001.
- H2-lse − R3: +0.005, [ask] −0.003 to +0.012.
- S2 − R2: +0.010, [ask] −0.012 to +0.032 overall, but −0.156 on multi-hop, [unclustered] −0.200 to −0.112.
- S1h − S1: +0.007, [ask] −0.004 to +0.018.

Dynamic tests. These "P0 to P5" are the prototype's own pass lines, not the method's predictions.

| test | result [M] | prototype pass line |
|---|---|---|
| reproductions | R0 0.563, R1 0.575, R2 0.657, S0 0.649, S1 0.386, all exact | P0 pass |
| batch path against canonical path | largest difference $6.3\times10^{-8}$ | pass |
| streaming build | 5,882 inserts at exactly 2.00 encoder calls each (a batch build costs 28.2 per chat); every vector and top 10 equal to the batch build | P4 pass |
| forget 20% of items, 3 seeds | 3,534 forgets; parent vectors and BM25 statistics equal a fresh build; 0 of 795 sessions that lost a child kept their old vector; H2 against R2 shifts by −0.004, [ask] −0.011 to +0.004 | P4 pass; P5 forget pass |
| merge and split, with undo | exact; 2 encoder calls per merge, 3 per split | P4 pass |
| merge usefulness | at a matched leaf budget, S6 drops 0.079 against 0.057 for S2; S5 drops 0.028 to 0.033; H2 does not drop | P5 merge fail |
| weight swap | 5,882 keys and 282 parents re-derived in 127 ms with 0 encoder calls; about 6.9 s at 100k leaves and 20k nodes [X, linear extrapolation] | P4 pass |
| seed stability | new seed against old: S6 +0.004, H2 +0.005; top-10 overlap 0.56 and 0.81 | P5 weights pass |
| parent representation | S6 (0.473) below S2 (0.667) | P1 fail |
| learning earns its place | S6 − S5 = −0.160 | P2 fail |
| tree adds recall when fused | H2 − R3 = −0.010 | P3 fail |

Skeptic caveats [M, E8 review]: some checks pass by construction (the version guard compares two different strings). Deletion is shown for the derived cache only; raw vectors stayed on disk. "Trainable" was shown only as offline retrains swapped in whole.

### (e) LongMemEval-S transfer (E7)

All numbers [M], from `e7_result.txt`. 428 questions with user-turn evidence; bridges trained on LoCoMo only; bge-small encoder. No intervals were computed. The rank comparison here shares the learning-rate confound of table (a) and has not been re-run.

| arm | turn@5 | turn@10 | session@5 |
|---|---|---|---|
| BM25 | 0.750 | 0.826 | 0.886 |
| frozen | 0.745 | 0.860 | 0.951 |
| full-rank bridges | 0.693 | 0.822 | 0.900 |
| rank-16 bridges | 0.723 | 0.864 | 0.920 |
| frozen + BM25 | 0.796 | 0.886 | 0.943 |
| full-rank bridges + BM25 | 0.781 | 0.881 | 0.933 |
| rank-16 bridges + BM25 | 0.805 | 0.891 | 0.948 |

turn@10 by question type:

| type (questions) | BM25 | frozen + BM25 | full-rank + BM25 | rank-16 + BM25 |
|---|---|---|---|---|
| knowledge update (72) | 0.956 | 0.995 | 0.988 | 0.995 |
| multi-session (125) | 0.757 | 0.831 | 0.845 | 0.847 |
| single-session, assistant (5) | 0.600 | 1.000 | 1.000 | 1.000 |
| single-session, preference (30) | 0.578 | 0.750 | 0.694 | 0.694 |
| single-session, user (64) | 0.969 | 0.953 | 0.953 | 0.953 |
| temporal reasoning (132) | 0.817 | 0.873 | 0.859 | 0.887 |

Reading. Rank-16 bridges add +0.004 turn@10 over the frozen encoder and full-rank bridges lose 0.038 [M, no interval]. Fused with BM25, the three arms span 0.881 to 0.891. Multi-session questions, the closest thing to multi-hop, move from 0.831 to 0.847, and preference questions drop from 0.750 to 0.694. No key-learning, read-again or pyramid arm has been run on LongMemEval-S.

---

## Prior work and novelty

All facts in this table are [S], from the linked pages, as checked by our prior-art review on 27 Oct 2026. The review's corrections to our earlier table are folded in.

| work | year | link | what it does | how it bears on this |
|---|---|---|---|---|
| RMM: Reflective Memory Management (Tan et al.) | 2025 (ACL) | [arXiv 2503.08026](https://arxiv.org/abs/2503.08026) | Residual linear question and memory heads on a frozen retriever (Contriever or GTE), trained online with REINFORCE from the answering LLM's own cites: +1 if cited, −1 if retrieved but not cited. Memory at utterance, turn and session level. | The closest prior work to our learning-from-use pass. It found that RL straight on the retriever hurt (forgetting) and that the cite labels were valid. It is a required baseline. |
| HAGE | 2026 (May) | [arXiv 2605.09942](https://arxiv.org/abs/2605.09942) | A trainable relation vector on every edge plus a router, trained by REINFORCE from gold-evidence reward. Frozen all-MiniLM-L6-v2; 5-fold cross-validation over LoCoMo chats. | Already learns structure (edges), with our held-out protocol and the same supervision as our oracle cites. It lacks topology change and learned node keys, and needs an LLM classifier and judge. |
| Jev-Mem | 2026 (Sep) | [arXiv 2609.23986](https://arxiv.org/abs/2609.23986); [code](https://github.com/libingzheren/Jev-Mem) | Three planes: Jev, called zero-shot through typed prompts, controls a graph memory; an LLM reasons. LoCoMo judge score 0.777 with a gpt-4o-mini judge, LoCoMo only. | The architecture closest to the two-plane idea. Its controller does not learn. Only the Jev model is closed; the code is public. |
| Jev (TypeSafe AI) | 2026 (Sep) | [typesafe.ai](https://typesafe.ai/) | Hosted "System One" decision model. It answers typed true/false, choice and score questions with calibrated probabilities. Vendor latency 70 to 500 ms. | The fast decision model in the idea. It cannot be fine-tuned and cannot see walled data, so it cannot learn from use in Tessera. Latency unverified. |
| CLM-8B (Contrastive-LM) | 2026 (Sep) | [Hugging Face](https://huggingface.co/Contrastive-LM/CLM-v0.1-8B) | Contrastive state and action heads on a frozen Qwen3-8B, InfoNCE in both directions, Apache 2.0. Trained on about 60M pairs, 30M hard negatives and 1M agentic trajectories. Exposes Jev's typed interface and claims zero-shot parity. | Same loss family and head form as our bridges. None of its training carries over to a 384-d encoder. Its state head reads a pooled embedding of the state text, not the per-step hidden state. A LoRA on its backbone would make keys stale. It makes an open Jev-Mem controller nearly a drop-in. |
| MAGMA | 2026 (Jan; ACL) | [arXiv 2601.03236](https://arxiv.org/abs/2601.03236) | Memory as semantic, temporal, causal and entity graphs, retrieved by policy-guided traversal. | The base of HAGE and Jev-Mem, from the same group. It shows their path toward a trained controller. |
| REALM: memory reconsolidation | 2026 (Sep) | [arXiv 2609.16053](https://arxiv.org/abs/2609.16053) | After each query an LLM agent rewires the activated subgraph (adds, removes and retypes edges) from retrieval and answer feedback: +2.0 on LoCoMo and +2.1 on LongMemEval, most on multi-hop. | Already a memory that learns its structure from use, by prompting. Our learned reshape and write bridges must beat it. |
| EARM | 2026 | [arXiv 2608.22767](https://arxiv.org/abs/2608.22767) | Stores the LLM's past question-to-memory relevance scores and fills the gaps by matrix completion, so retrieval improves over the agent's life. | A direct alternative to per-question alias keys. A baseline for "keys learn from cites". |
| MemRL (and Memento) | 2026 | [arXiv 2601.03192](https://arxiv.org/abs/2601.03192); [Memento 2508.16153](https://arxiv.org/abs/2508.16153) | Frozen LLM; each memory entry carries a learned utility updated from task reward, and retrieval ranks by it. | Prior art for a per-node quantity that learns from use while the reasoner stays frozen. |
| HORMA | 2026 | [arXiv 2606.11680](https://arxiv.org/abs/2606.11680) | A file-system-like hierarchy of summaries over raw records; a 4B navigator trained with GRPO on an evidence-overlap reward. Tested on LoCoMo, LongMemEval and ALFWorld. | The closest learned router over a pyramid. It flags the credit-assignment gap when building and reading memory train together from task reward, the same risk as our alternation. |
| Does memory need graphs? | 2026 (ACL) | [arXiv 2601.01280](https://arxiv.org/abs/2601.01280) | A unified framework and controlled comparison of long-term dialog memory. Tested on LongMemEval and HaluMem. | Many claimed gains come from basic settings. Our E8 result agrees: the session tree added no recall over a flat scan fused with BM25. |
| AgentMemRec (and ConvMemory) | 2026 | [arXiv 2610.34673](https://arxiv.org/abs/2610.34673); [ConvMemory 2605.28062](https://arxiv.org/abs/2605.28062) | An LLM-free cascade with a LightGBM ranker trained on gold evidence; reports +10 to 31 points over A-Mem, HippoRAG 2 and others on LongMemEval multi-session. ConvMemory, a 3.6M-parameter reranker, failed its own five-seed ablation. | Cheap learned-ranking baselines the bridges must beat. ConvMemory warns that a learned head's gain can be plain distillation. |
| REPLUG | 2023 | [arXiv 2301.12652](https://arxiv.org/abs/2301.12652) | Trains a retriever from a frozen black-box LM, by how much each document lowers its perplexity. | The standard way to train from a frozen API reasoner, our stage 1. A denser signal than binary cites. |
| LongMem | 2023 (NeurIPS) | [arXiv 2306.07174](https://arxiv.org/abs/2306.07174) | Frozen backbone as memory encoder, with a trainable side network as retriever and reader, to avoid stale memory. | Precedent for stage 3. Our joint LoRA plan brings the staleness problem back. |
| RAG; Atlas | 2020; 2022 | [arXiv 2005.11401](https://arxiv.org/abs/2005.11401); [arXiv 2208.03299](https://arxiv.org/abs/2208.03299) | RAG keeps the document encoder and index fixed. Atlas tests question-side fine-tuning with no re-indexing. | "Freeze the encoder, train the heads" is this standard workaround, not new. Atlas warns the cost of a fixed document side varies by task. |
| Query association (Scholer and Williams), and doc2query | 2002; 2019 | [doi 10.1145/584792.584846](https://doi.org/10.1145/584792.584846); [arXiv 1904.08375](https://arxiv.org/abs/1904.08375) | Stores past queries with the documents they retrieved, as surrogates or expansions. | Our per-question alias keys are a learned form of it. Its known failure, associations piling onto popular documents, is the alias collapse we measured. |
| Unbiased learning to rank | 2017 (WSDM) | [arXiv 1608.04468](https://arxiv.org/abs/1608.04468) | Corrects position and exposure bias in click feedback with propensity weights. | Cites come only from what was opened, so a node never opened can never become a positive. Needs propensity weights or exploration. |
| Adversarial hubness | 2024 | [arXiv 2412.14113](https://arxiv.org/abs/2412.14113) | One crafted item becomes the top result for thousands of unrelated queries. | Nodes that collect many keys drift into hubs, and a hostile cited message could be planted as one. Needs per-node caps and hubness checks. |
| Titans | 2024 (arXiv, 31 Dec) | [arXiv 2501.00663](https://arxiv.org/abs/2501.00663); [re-implementation 2510.09551](https://arxiv.org/abs/2510.09551) | Neural memory written into weights at test time. An independent re-implementation found it does not always beat baselines because of chunking, though its memory beat attention-only models. | Weight memory is hard to delete. We keep test-time learning in per-node keys. |
| TTT-E2E | 2025 (arXiv, 29 Dec) | [arXiv 2512.23675](https://arxiv.org/abs/2512.23675) | End-to-end test-time training, public code. Full attention far outperforms it on needle-in-a-haystack tests, and training latency is a stated limitation. | Lossy recall is a poor fit for exact personal facts. |
| LoCoMo audit (Penfield Labs; blog and repo) | 2026 (Apr) | [blog](https://dev.to/penfieldlabs/we-audited-locomo-64-of-the-answer-key-is-wrong-and-the-judge-accepts-up-to-63-of-intentionally-33lg); [repo](https://github.com/dial481/locomo-audit) | 99 of 1,540 non-adversarial questions (6.4%) have gold-answer errors. The gpt-4o-mini judge accepted 62.81% of vague-but-topical wrong answers. 57 wrong-citation errors and 4 malformed evidence ids. | Our labels (marked evidence) are wrong for about 4% of questions. Scoring evidence instead of a judge moves the label noise; it does not remove it. The audit also argues LongMemEval-S (about 115K tokens per question) fits in a modern context window. |
| Memory Networks; end-to-end MemNN, NTM, DNC | 2014 to 2016 | [arXiv 1410.3916](https://arxiv.org/abs/1410.3916); [arXiv 1503.08895](https://arxiv.org/abs/1503.08895) | The original Memory Networks used hard addressing with supervision on supporting facts. The end-to-end version, NTM and DNC are fully differentiable. | We keep the graph discrete and inspectable and learn only the scorers. |
| Complementary learning systems | 1995 | [doi 10.1037/0033-295X.102.3.419](https://doi.org/10.1037/0033-295X.102.3.419) | A fast hippocampal store replayed slowly and interleaved into the neocortex. That is how the theory avoids interference. | Our fast per-question keys plus slow offline training follow the same split. |

The review also checked these and found our earlier descriptions accurate: Memory-R1 (Aug 2025), AgeMem (Jan 2026) and RETRO.

### Novelty judgment

The prior-art review's judgment, drawn from the sources in the table: the claimed gap is real but much narrower than we said, and most of its parts already exist. RMM has small heads on a frozen encoder trained from the reasoner's own cites. HAGE learns structure and a router from evidence reward under our exact LoCoMo protocol. REALM changes topology after each use. MemRL and EARM keep a per-memory usefulness that learns over time. Jev-Mem is the three-plane architecture itself. Our alias keys are a learned form of query association from 2002. What nobody appears to have published as of 27 Oct 2026 is the specific combination: CLM-style contrastive heads used as one family for read, stop, write, reshape and forget; learned rather than prompted topology operations; per-node keys updated per question; a read-again loop driven by the reasoner's thoughts; and joint LoRA training with heads that read the reasoner's hidden states. That is a solid, publishable systems combination, not a new paradigm.

Our own update, after this round's results (our judgment, not measured): two pieces of that combination now have negative evidence on LoCoMo (the learned node encoder, and the vector-only second hop), and three are untested (learned topology operations, LLM-driven read-again, joint LoRA). What is both new and backed by measurements today is narrower:
- an analysis of when memory learning from use pays: the split into re-ask gain and common-mode cost, the break-even wrong-cite rates, the result that only discoveries pay, and the self-feedback take-off (method §6.4);
- the finding that a shared embedding space is not a shared scale, with a rank-calibrated cross-channel bonus whose fire rate is bounded when the reference questions are exchangeable with new ones (method §6.5). The measured F3 used training-chat references, which are not exchangeable, and fired at a rate of 0.193;
- a memory whose every derived vector is a content-addressed cache entry, so inserts, merges, splits and deletions leave the derived cache equal to a fresh build, and a weight swap is one cheap recompute (E8; derived cache only, raw vectors and trained weights not covered);
- a pull-plus-push key rule that still gains at 30% wrong cites (+0.014, [ask] +0.006 to +0.022), although those cites are drawn from oracle evidence that includes turns the system never opened.

Each has close neighbours (query association, RMM, unbiased learning to rank, the hubness literature, machine unlearning), so the paper must cite them and beat their baselines.

### Closest work

RMM (Tan et al., ACL 2025) is the closest match for learning from use: small residual heads on a frozen retriever, trained online from the answering LLM's own cites, with uncited reads as negatives. Close behind are HAGE (learned edge structure and router from evidence reward, cross-validated on held-out LoCoMo chats) and Jev-Mem (the three-plane architecture with a closed zero-shot controller). REALM is the closest for structure learned from use, though it rewires by prompting an LLM.

### Scooping risk

High for the "trained controller for graph memory" framing (our judgment). One group (Dongming Jiang, Yi Li, Bingzhe Li) went from MAGMA (Jan 2026) to HAGE (May 2026, learned) to Jev-Mem (Sep 2026, System One controller) [S]. A trained System One controller is their obvious next paper. CLM-8B exposes Jev's typed interface with open weights [S], so swapping in a trainable open controller is close to a drop-in change for anyone. Our judgment: the risk is lower for the analysis angle (when use-learning pays, calibration across channels, exact deletion), which none of the listed works addresses. Two things weaken our position today. Our learning results still use the benchmark's gold evidence as cites, which is HAGE's supervision too, and those labels are wrong for about 4% of questions [S]. The claim becomes defensible once real Haiku or Claude cites replace gold evidence and the bridges beat RMM-style cite-trained heads, HAGE, REALM and an LLM-free learned ranker on held-out data.

---

## What to do next

Each stage has a pass bar fixed in advance and maps to the falsifiable predictions in method Section 7 (P1 to P12, conjecture C3). A stage starts only if the one before it passes.

Before any new arm, fix the code (method §8): a dev split carved from the training chats; learning rate tuned per rank; temperature fixed; common random numbers across arms; chat-clustered bootstraps; the parser that keeps 1,536 questions; a mean question vector frozen per graph version; and per-node cite logs of encoder-space states. One data note [M, checked here]: the audit could not find the LongMemEval-S file under the name `longmemeval_s_cleaned.json`, but the working copy `lme_s.json` (not in the repo) holds 500 LongMemEval questions (277 MB) next to an embedding cache. Confirm it is the same file before the re-runs. E7 scored 428 questions, those with user-turn evidence.

### Stage 1: cheap and decisive (CPU, plus small Haiku spend)

The earlier design draft estimated the Haiku runs at a few million tokens and a few dollars [X, not re-checked].

| # | test | pass bar | fails if | prediction |
|---|---|---|---|---|
| 1.1 | Rank sweep with the learning rate tuned per rank on dev chats, rank in {1, 16, 64, full}, on LoCoMo and LongMemEval-S | held-out recall varies by less than 0.01 across ranks, and the LongMemEval-S gap between ranks closes; label-free centring beats frozen on LongMemEval-S (above 0.860) | a rank effect above 0.01 survives tuning, with a [chat] interval | P9 |
| 1.2 | Real cites: Haiku answers LoCoMo and LongMemEval-S questions from the opened top 10 and cites node ids; a check against the gold answer labels each cite. Measure the wrong-cite rate $\hat p_{\rm w}$, then run move, contrastive and combo on those cites | P1: move gains at most +0.005. P3: learning helps iff $\hat p_{\rm w}$ is below break-even (0.24 to 0.27 for move at step 0.1; 0.38 to 0.42 at step 0.05 or less; 0.55 centred), within ±0.05. For idea 5 to be upgraded: some rule gains with a [chat] interval above zero and keeps a gain after BM25 fusion | P1: a significant gain above +0.005 from opened-only cites. P3: interior arms miss the line beyond the method's tolerances. Idea 5: no rule beats zero | P1, P3 |
| 1.3 | Real read-again: Haiku writes the next probe after each read (probe text plus the question for BM25); at most 3 hops | multi-hop recall@10 above the single-read 0.475 with a [chat] interval above zero, with no overall loss | no multi-hop gain; read-again then stays a reasoning-side habit, not a memory feature | none numbered; tests method §6.7. Adaptive opening tests P8 |
| 1.4 | Move rule toward the key-view target $\mathrm n(Ae_q)$ instead of the state-view state | the self-feedback loss shrinks from −0.023 at step 0.1, while the clean gain stays near +0.020 | the clean gain falls, or the self-feedback loss does not shrink | P2 |
| 1.5 | Self-feedback stream of at least 1,500 self-cited questions | take-off at about 60 questions at step 0.1 (method §6.4: predicted 61, direct estimate 60), scaling as 1/step within a factor of 3; the plain rule's loss grows without bound; centred saturates near −0.04 and capped near −0.08 | take-off scale or saturation outside these | P5 |
| 1.6 | Hub cost against step size on LongMemEval-S, using that dataset's own drift, gap, spread and cite counts | cost ratios within 25% of method Remark 6.1 | ratios grow linearly (2.5, 5, 10) | P4 |
| 1.7 | Alias bonus calibrated on the same user's earlier questions only | fires on unrelated questions at most $2K/(n_{\rm ref}+1)$ of the time and beats F3 (+0.029) | either part fails | P6 |
| 1.8 | Deeper pyramids (session, week, month) on both datasets, with every routing table recomputed in one stated log-sum-exp form | mean pooling loses detectability per level as roughly $n^{-0.4}$ to $n^{-0.5}$; log-sum-exp keeps at least 90% of the leaf value; no fixed pool beats the mean by more than $\sqrt{n/n_{\rm eff}}$; no top-3 router exceeds 0.939 on multi-hop | any of these is beaten | P7, P8 |
| 1.9 | Exact deletion with keys defined from cite logs (canonical sum, frozen mean) | every byte of the memory state equals the rebuild from the retained records; a move-rule key with no log fails; the additive centred rule's clean gain is within ±0.005 of the centred move rule | any byte differs | P10 |
| 1.10 | Pre-registered re-test of "fuse the session list with the flat list" (+0.058 post hoc) on LongMemEval-S | a gain over flat rank-16 bridges with an interval above zero and no multi-hop loss | no gain | none; confirms a post hoc lead |
| 1.11 | Prior-art baselines on the same cites: RMM-style residual heads trained by REINFORCE, and an LLM-free learned ranker (AgentMemRec style) | our best rule at least matches them, [chat] | a baseline wins | none; required for the paper |

### Stage 2: the Mac (and the phone)

| # | test | pass bar | prediction |
|---|---|---|---|
| 2.1 | bge-small as a fixed-shape Core ML model on the Neural Engine; latency, first and second load | memory hop at most 20 ms and memory at most 60 ms per question at p95 on the phone (targets from the algorithms draft). The estimate is 3 to 10 ms per encode [X]; Apple reports 3.47 ms for a 66M-parameter model at sequence length 128 on the iPhone 13 Neural Engine [S, [Apple ML Research](https://machinelearning.apple.com/research/neural-engine-transformers)] | none |
| 2.2 | Larger frozen encoders (Qwen3-0.6B embeddings, EmbeddingGemma) against bge-small, with bridges | beat bge-small with a [chat] interval at acceptable phone latency | none |
| 2.3 | CLM-8B's own heads as the bridge, if the Mac can run Qwen3-8B | beat our bge-small bridges on held-out chats with a [chat] interval | none; tests idea 8 |
| 2.4 | First steps of stage A, if the Mac can hold Qwen3-8B: cache hidden states for probes, train the state projector $\Pi$ on the alignment loss, scan the tap layer | the best layer sits near two thirds of the depth; bridges trained on text states work on projected hidden states within the [chat] interval of the text result | C3, P11 |
| 2.5 | A vec2text-style inverter for bge-small (may need a GPU) | report token F1 on held-out LoCoMo turns; a high F1 confirms that vectors are personal data and must be deleted like text | P12 |
| 2.6 | Read bridge wired into the pyramid router behind a flag, with the current rule as fallback; the Tessera test world as a third benchmark | no recall loss against the rule on the test world | none |

### Stage 3: rented GPUs (only if stage 1 shows a gain from real cites or real probes)

| # | test | pass bar | prediction |
|---|---|---|---|
| 3.1 | Stage A: train $\Pi$ on the alignment loss and the soft-token injector $\iota$ on reconstruction and distillation, LLM frozen; measure both round trips of method Definition 2.6 | round-trip error $\varepsilon$ small enough that P11 holds | C3, P11 |
| 3.2 | Stage B: LoRA plus the joint loss of method §3.8, public and synthetic data only | beats a frozen LLM with trained bridges on held-out answer accuracy and evidence recall, 3 seeds, and on LongMemEval-S | none numbered; the test of idea 7 |
| 3.3 | Node encoder trained on thousands of public and synthetic structures | beats the exact late-pooled score at a level whose leaves are not scanned | none numbered; P7 bounds fixed pools |
| 3.4 | Learned write and reshape heads, accepted only through the replay gate | beat the count rules and REALM-style prompted rewiring on replay | none |

**What stage 3 needs (estimates, not measured).**
- The frozen Qwen3-8B in bf16 is about 16 GB of weights [X, 8B parameters times 2 bytes].
- Trained parts are small: a rank-16 LoRA on attention (15.3M parameters), $\Pi$ and $\iota$ (about 4.6M each, $\iota$ with one soft token per vector), views and heads (under 0.1M) (method §4.1). Their Adam state is well under 1 GB [X].
- The KV cache costs 147 KB per token (method §2.2), so a 16k-token episode needs about 2.4 GB [X].
- So one 80 GB-class GPU should hold a training step. Activation memory for back-propagation through 36 layers at long context is not estimated here [X].
- Time: the earlier design draft's rough figure, never checked, is hours on one GPU for heads-only runs and a few GPU-days for the joint LoRA run [X]. Treat it as a placeholder until a one-day pilot measures tokens per second.
- Data: public long-memory sets plus synthetic histories with evidence ids. CLM-8B trained on about 60M pairs [S]; we will not come close, which is one more reason to keep the heads small and start them at the identity.
- Generating synthetic histories with an LLM has a cost that is not estimated here.
