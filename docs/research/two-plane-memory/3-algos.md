## 9 Algorithms and latency

*Follows Section 8. Uses the notation of §1.2 and the data policy of §4.2. This version applies every correction from a skeptic's rerun of all benchmarks, and the results of the round-2 experiments (alias-hub fix, cite-noise fix, second-hop fix, and the embedding-pyramid prototype E8).*

**Scope.** How the two-plane memory is trained and run, what each step costs, and what to make faster first.

**Labels.** Every number carries one label.
- **[M]** measured here. Benchmarks ran on one x86 thread (CPU reported as Intel Xeon @ 2.10 GHz, Sapphire-Rapids class, AVX-512 and AMX, 260 MiB L3), in Python with NumPy/OpenBLAS and PyTorch eager. Recall numbers are held-out LoCoMo results from the named experiment.
- **[S]** from a source. The link is in §9.4.5.
- **[D]** derived by arithmetic from [S] or [M] numbers. The arithmetic is shown.
- **[X]** our own extrapolation, not verified.
- **[B]** from the project brief, not verified.

The container has no GPU and no Apple hardware. So every iPhone, Mac and GPU figure is [S], [D] or [X].

**Two runs.** Run 1 shared the host with a concurrent single-thread HNSW build. The rerun repeated every script unchanged, one at a time, with `OMP_NUM_THREADS=1` on an idle 4-core VM. Where they differ, both are given as "run 1 / rerun".
- Of the 54 medians quoted in the earlier draft, 44 fall within ±30% in the rerun [M].
- Over all 188 raw rows, 139 do. Of the 49 misses, 36 take under 1 ms, where Python overhead dominates [M].
- Every overlap and fidelity value reproduced exactly [M].

**Scripts.** Benchmarks `b1`–`b7` with `common.py` and `bm25lib.py`; the reviewer's side checks `s1_checks.py`, `s2_int8batch.py` and `s3_within_chat.py`; and the experiment scripts `alias_hub.py`, `fix_cite_noise.py`, `second_hop.py` and `e8_pyramid_encoder.py`. They are in `scripts/ai/small_models/` on branch `claude/project-thread-j9x62n` of the Tessera repository: benchmarks in `algos/bench/` (rerun copies in `algos/rerun/`), side checks in `algos/side/`, experiments in `fixes/` and `pyramid/`. Appendix 9.A has the full two-run table.

**Four measured findings shape the design.**

1. **The encoder dominates a memory hop, but less than the draft said.**
   - On the shipping path (flat leaf scoring, §9.3.1), one hop at $N=65{,}536$ leaves takes 35.9 / 39.7 ms. Memory work is 4.9 / 5.5 ms of that. So the encoder is about 86% of the hop [M].
   - At $N=10^5$ with fp32 keys and a cold cache, memory work is about 13 ms and the encoder about 67% [D from M]. With int8 keys (READ's path), memory work is about 3–4 ms cold and the encoder about 87% [D].
   - The encoder reaches 95% or more only on the pyramid path, or at $N\le$ about $10^4$ [M].
   - Quote one flat hop as **25–40 ms** on this CPU [M].
2. **Parents are better scored from their leaves than by a learned encoder.**
   - On LoCoMo, a learned shared parent encoder lost to the exact late-pooled score of its leaves by 0.160 recall@10, and to untrained k-means slots by 0.044 [M, E8].
   - Beam descent over untrained parents keeps 0.52–0.82 of the exact top-10 at beam 8, depending on the keys and the depth [M].
   - So below about $2\times10^5$ leaves [X] the pyramid chooses granularity (gist or leaf) and does not prune.
3. **Learning from cites is small on the shipping path.**
   - With cites limited to what the reasoning plane actually opened, contrastive pull and push gains +0.008 recall@10 dense-only, and the best rule tried (a slow adapter refit every 10 asks) +0.009 [M, fix-cite-noise].
   - Once BM25 is fused in, as READ does, contrastive gains +0.000 and no rule more than +0.002 [M].
   - The draft's +0.020 came from oracle cites that include evidence the reasoning plane never saw.
4. **Next to the reasoning plane, the memory plane is cheap.**
   - A memory hop takes milliseconds. Time to first answer token is 1.29 s for Claude Sonnet 5.5 at low effort and 2.99 s at medium effort [S].
   - So the latency budget is set by the number of LLM-driven hops, not by the memory engine.
   - On the Apple on-device path the binding limit is the context: 4,096 tokens per session [S].

### 9.1 Notation

This section uses the symbols of §1.2. The table lists the main ones, and the symbols this section adds.

| symbol | meaning | where defined |
|---|---|---|
| $f$ | frozen anchor encoder (bge-small-en-v1.5, $d=384$, unit norm) | §1.2 |
| $\mathrm n(x)=x/\lVert x\rVert$ | normalisation | §1.2 |
| $H_c=I+U_cB_c^\top$; $S$, $A$, $W$ | a view of rank $r$; the state, key and write views | §1.2 |
| $x^{\rm p}_t$; $z_t=f(x^{\rm p}_t)$, or $\Pi(\mathbf h_t)$ | probe text; anchor-view state at step $t$. At $t=0$, $z_0=e_q=f(x_q)$ | §1.2 |
| $s_t=\mathrm n(Sz_t)$ | read state | §1.2 |
| $k^0_v=\mathrm n(Ae_v)$; $k_v$ | base key and live (fast) key of leaf $v$ | §1.2 |
| $\alpha$ | logit scale, fixed at 20 | §1.2, §4.4 |
| $\ell_t(v)=\alpha\langle s_t,k_v\rangle$; $\varsigma_v=\langle s_t,k_v\rangle$ | logit; unscaled score | §1.2 |
| $\Phi_v=(\phi_{v,1},\dots,\phi_{v,m_f})$; $g$ | facets of an internal node; the internode encoder | §1.2, §2.4 |
| $x_v$, $e_v=f(x_v)$, internal $v$ | the gist text and its anchor vector | §1.2 |
| $k^{\rm g}_v=\mathrm n(Ae_v)$, internal $v$ | **gist key**: the gist expressed in the $A$ view | new |
| $L_v$ | **exact late-pooled parent score** (below); not the depth $L$ or a loss $\mathcal L$ | new (E8) |
| $\omega$; $b_{\rm sz}$ | LSE temperature; size weight of $L_v$ | §1.2; new |
| $F_b$ | **descent fidelity**: share of the exact top-10 that a pruned read with $b$ parents per level keeps (not the frontier $F_t$ of §1.2) | new |
| $\psi_t$; $\pi^{\rm stop}_t$ | stop features ($\mathbb R^7$); stop probability | §2.4 |
| $O$, $C$, $C^\star$, $U$ | opened set; raw cites; accepted leaf cites; opened but not cited | §1.2, §3.7 |
| $\eta$, $\eta_-$; $\nu$, $\beta_{\rm U}$; $\zeta$; $c_{\rm ctr}$ | pull and push steps; anchor and push weights of a log-defined key; anchor cap; centring switch | §1.2, §3.7; $\eta_-$, $c_{\rm ctr}$ new |
| $\bar s_\tau$ | mean ask state, frozen per committed version $\tau$ | §3.7 |
| $G_\tau$; $\mathrm{lin}_\tau$ | memory graph at version $\tau$; lineage map | §1.2, Def. 2.5 |
| $\theta$; $\theta_{\rm ship}$, $\theta_{\rm cur}$ | slow parameters (views, heads, $g$), written $\Theta$ in §4.3; the shipped bundle; the bundle in use. `theta_stop` in algorithm R is a separate stop threshold | new |
| $\mathcal T_{\rm fit},\mathcal T_{\rm sel},\mathcal T_{\rm gate}$; $\mathcal T_{\rm frz}$; $\mathcal P$ | time-ordered splits of the learning log; a frozen user evaluation set; the bundled public guard set | new |
| $\mathrm{Jnl}$ | journal of writes and forgets that arrive while consolidation runs ($\mathcal J$ stays the objective of §4.3 and Prop. 6.25) | new |

**Exact late-pooled parent score.** It is the soft maximum of the leaf scores under $v$, with an optional size correction (Prop. 6.8):
$$L_v(s)=\omega\log\sum_{i\in\mathrm{leaves}(v)}e^{\langle s,k_i\rangle/\omega}\;-\;b_{\rm sz}\,\omega\log\lvert\mathrm{leaves}(v)\rvert .$$
- With $b_{\rm sz}=0$ it is the sum form $\mathrm{LSE}_\omega$. With $b_{\rm sz}=1$ it is the size-normalised form $\overline{\mathrm{LSE}}_\omega$ of §1.2.
- It depends only on which leaves sit under $v$, not on how they are grouped. So merges and splits cannot corrupt it.
- When the leaves are scanned anyway, it costs one segmented pass over scores already computed.
- E8 chose $\omega=0.05$ in most folds and $b_{\rm sz}\in\{0,0.5,1\}$ per fold, on training chats only [M, E8].

**Read loss.** The recommended loss of §3.1 and §8 row 17: forward-only $\mathcal L_{\rm mask}$, averaged per ask, with $\alpha$ fixed.
$$\mathcal L_{\rm mask}(q)=\frac1{n^+_q}\sum_{p\in P_q}\log\Big(1+\sum_{n\in N_q}e^{\ell_{qn}-\ell_{qp}}\Big),\qquad \mathcal R=\sum_{c\in\{S,A,W\}}\lVert U_cB_c^\top\rVert_F^2 .$$
- It replaces the draft's bidirectional multi-positive loss. That loss kept the other positives in each denominator, and its backward term treated asks that share evidence as negatives.
- On the 409 multi-evidence asks the change gives +0.017, chat-clustered CI [+0.001, +0.038]. Overall it gives +0.002 [−0.006, +0.009] (§6.2) [M].

**Rank.** The views keep rank $r=16$ for cost ($2dr$ parameters per view) and for the rank-$2r$ attribution of Prop. 6.1. Not for accuracy: the low-rank advantage was a step-size effect. With the learning rate tuned per rank, all ranks land within ±0.005 (§6.6) [M]; those rates were scanned on test folds, so this shows the confound and is not a clean estimate. So $r$ and the learning rate are chosen together, on a dev split.

### 9.2 Training algorithms

#### 9.2.1 Offline bridge pretraining (algorithm A)

Public and synthetic data only (policy A, §4.2).

```text
ALGORITHM A  PRETRAIN-BRIDGES
Data: haystacks H = (leaves, asks Q_H, evidence P_q). Sources: LoCoMo folds, public multi-session dialogue sets with
      generated questions (check each licence), and synthetic persona histories written offline by an LLM with evidence
      ids. LongMemEval-S stays a held-out test set, as in E7 (confirm its data file first, §8 row 21). No Tessera data.
 1  cache e_v = f(x_v) for every leaf and e_q = f(x_q) for every ask (f is frozen, so this runs once)
 2  init U_c = 0 and B_c ~ N(0, 0.01^2) for c in {S, A, W}: every view starts as the identity (= the frozen retriever)
    alpha = 20, fixed (§4.4)
 3  split by haystack, never inside one: train / dev (10%) / test (evaluated once, at the end)
    choose (r, learning rate) jointly on dev, per rank (§6.6); never on test
 4  hardneg[q] <- {} for all q
 5  for epoch = 1 .. E_max:
 6      shuffle haystacks; batch = 1..4 haystacks
 7      for each batch:
 8          s_q <- n(S e_q);  k0_v <- n(A e_v)
 9          N_q <- (all nodes of q's own haystack ∪ 256 random nodes of the other haystacks in the batch ∪ hardneg[q])
                   minus P_q, minus teacher-marked equivalents          # L_mask pushes false negatives hard
10          loss <- L_mask (forward only) + 0.01 R + L_write + L_stop   # last two below
11          AdamW step (no weight decay; R is the regulariser)
12      every 5 epochs: MINE-HARD-NEGATIVES
13      dev <- recall@10 of READ, with the same fusion as shipped, on dev haystacks
14      keep the best theta; stop after 5 epochs without improvement
15  return theta (3 seeds; report the mean and a haystack-clustered bootstrap CI on test)

MINE-HARD-NEGATIVES
 1  for each ask q: cand <- top-20 by <s_q, k0_v> in its haystack ∪ top-10 by BM25(q)
 2      remove v in P_q; remove v with <e_v, e_p> > 0.95 for some p in P_q      # near-duplicate: likely a false negative
 3      remove v within ±1 turn of an evidence turn; remove v whose text contains the gold answer string
 4      hardneg[q] <- best 10 survivors

Write view (placement), same loop, LEAVE-ONE-OUT. For leaf v with true holder u* = parent(v):
  w_v <- n(W e_v)
  score(u) = LSE_omega of <w_v, k0_c> over c in children(u) \ {v}
             (or max_i <w_v, phi_{u,i}> if g serves level 1, with Phi_u recomputed without v)
  L_write = -log softmax_u( alpha * score(u) ) over the candidate holders u at that level
  # without masking v, its own key sits inside u's representation and the task is trivially solvable
  retrain W whenever algorithm B changes how parents are represented
Stop head, same loop, on teacher-forced reads:
  features psi_t (§2.4); label y_t = 1[P_q ⊆ O_<=t], or an offline LLM judge says the gist alone answers
  L_stop = binary cross-entropy (§3.4); then fit a temperature on dev and report ECE and Brier score
```

The leave-one-out placement score has not been tested; E8 measured $L_v$-style scoring only for routing asks.

Cost: one E5 fold (8 LoCoMo chats, about 4.7k nodes, 40 epochs, $r=16$) took 2.7 / 3.1 s, each a single run [M]. Pretraining is cheap. Labelled data is the scarce input.

#### 9.2.2 Parent scores and the internode encoder (algorithm B)

**What E8 measured.** Held-out LoCoMo, 5 folds, 1,531 asks. Sessions are the parents and the top 3 sessions are opened [M, E8].

| parent scorer | recall@10 | difference vs flat bridged leaves (0.657) |
|---|---|---|
| BM25 sessions, bridged hybrid inside (S2) | 0.667 | +0.010 [−0.012, +0.032] |
| exact late-pooled $L_v$, tuned $\omega$ and $b_{\rm sz}$ (S5) | 0.633 | −0.024 [−0.042, −0.007] |
| untrained k-means slots, $m_f=4$ (S4) | 0.517 | −0.141 |
| learned shared encoder $g$ (S6) | 0.473 | −0.185 |
| $\mathrm n$(mean of child keys) (S3) | 0.447 | −0.210 |

- Learned slots lose to $L_v$ by 0.160, CI [−0.182, −0.138], chat-clustered [−0.175, −0.146]. They lose to untrained slots by 0.044 in all 10 test chats [M, E8].
- The cause is overfitting. About $10^5$ weights trained on 8 chats per fold reach 0.95 session recall@3 on training chats. Held-out recall peaks at epoch 5–10 and then decays [M, E8].
- Early stopping on dev chats brings $g$ level with untrained slots (+0.006, CI spans 0). It stays about 0.12 below $L_v$ in that post hoc run (0.523 against 0.647; the main run's $L_v$ is 0.633) [M, E8, post hoc].
- Fusing the tree with the flat ranking adds nothing. The exact version scores +0.005 [−0.003, +0.012] over the fused flat ranking. Every top-3 routed arm loses heavily on multi-hop asks: S2 scores 0.319 against 0.475 flat [M, E8].
- The bookkeeping is sound. Streaming inserts, forgets, merges and splits leave the derived cache equal to a fresh build bit for bit, and a weight swap re-tags every cache entry so no old-version lookup hits. This covers the derived cache only: raw vectors stayed on disk and unlearning from weights was not tested [M, E8 review]. An insert costs 2 encoder calls. Re-deriving 5,882 leaf keys and 282 parents took 127 ms [M, E8].

**Descent fidelity of untrained parents.** Beam descent over a balanced k-means tree whose parents are the means of their children. The table gives the share of the exact top-10 kept [M; `b3k_kmeans_tree.py`, `s1_checks.py`, `s3_within_chat.py`].

| tree and keys | $b=1$ | 4 | 8 | 16 | 32 | 64 |
|---|---|---|---|---|---|---|
| synthetic leaf-shaped keys, $N=4096$, depth 3 | 0.15 | 0.40 | 0.56 | 0.71 | 0.84 | 0.94 |
| synthetic leaf-shaped keys, $N=65{,}536$, depth 4 | 0.16 | 0.39 | 0.52 | 0.64 | 0.76 | 0.85 |
| real LoCoMo turn vectors, $N=4096$ | 0.30 | 0.66 | 0.82 | 0.91 | 0.96 | 0.99 |
| inside one persona, $N=512$, fan-out 8, depth 3, its own asks | | | 0.74 (0.70–0.78) | | | |

- The synthetic keys (a convex mix of two real turns plus noise) understate fidelity. Inside one persona they give 0.57 at $b=8$, against 0.74 for real vectors [M].
- Still, no untrained tree reaches 0.95 at a small beam. On synthetic keys, fidelity falls with depth [M].
- A tree built to match the key geometry keeps 0.98–1.00 at every $b$, and a random grouping keeps 0.00–0.24 [M, `b3_pyramid.py`]. Real session and time groupings lie in between.

**The loss for $g$, when it is trained.** In the notation of §3.3:
$$\mathcal L_{\rm tree}=\mathcal L_{\rm hier}+\lambda_{\rm or}\mathcal L_{\rm or}+\lambda_{\rm gist}\sum_{v\ \text{internal}}\Big(1-\max_i\langle\phi_{v,i},k^{\rm g}_v\rangle\Big)+\lambda_{\rm reg}\mathcal R .$$
- $\mathcal L_{\rm hier}$ is the level-wise masked loss, with $\lambda_l=1/\log(2+b_l-n^{+(l)}_q)$ from Prop. 6.9.
- $\mathcal L_{\rm or}$ is the label-free soft-OR distillation toward the leaves' LSE, in one stated LSE form (§8 row 12).
- The gist term ties the facets to the gist key $k^{\rm g}_v=\mathrm n(Ae_v)$, in the $A$ view. The draft tied the parent to $e_v$ itself, which lives in the anchor space while facets are pooled from $A$-view keys.

```text
ALGORITHM B  PARENT-SCORERS (starts from the views of algorithm A)
 0  floors with no learned parameters, fitted on training haystacks only:
      (i)  exact late-pooled L_v: grid omega in {0.02, 0.05, 0.1} x b_sz in {0, 0.5, 1}, chosen by session recall@3
      (ii) untrained k-means slots: spherical k-means over child keys, m_f = 4, farthest-point seeds, 3 Lloyd steps
 1  build each training haystack's pyramid with the shipping grouping rule
    (leaves -> sessions or days -> weeks -> months; fan-out cap F, 32 in the E8 design)
    augment with random splits and merges; use far more structures than 8 chats (synthetic histories)
 2  once, offline: gist text x_v for each internal node (public or synthetic data only); e_v <- f(x_v); k^g_v <- n(A e_v)
 3  init g at floor (ii): output projection W_O = 0, so Phi_v starts as the k-means slots
 4  phase 1 (2 epochs): views frozen, train g only.  phase 2: joint, view learning rate x 0.1
 5  each epoch: Phi bottom-up for levels 1..L (differentiable); loss L_tree; step
 6  dev metrics each epoch, haystack-clustered:
      (a) parent recall@3 per level, against both floors
      (b) leaf recall@10 of the full READ path (must not fall below algorithm A's)
      (c) F_b at the shipping b, on dev pyramids of several depths
 7  early stop on (a), subject to (b)
 8  ship g for level l only if, on held-out haystacks, it beats floor (i) AND floor (ii) at level l
    (haystack-clustered CI above 0). Otherwise:
      a level whose leaves are scanned      -> score its parents with L_v (no parameters)
      a level whose leaves are not scanned  -> do not prune there; READ stays flat
 9  if g ships for pruning, F_b >= 0.95 must also hold on the user's own store at its real N, re-measured nightly
    (D step 6). Dev haystacks of about 600 leaves have depth about 2 and do not certify depth 4-5
```

Cost: a whole-tree recompute with a full $384\times384$ attention core takes 64 / 93 ms at $10^4$ leaves and 0.79 / 0.95 s at $10^5$ [M]. At $10^6$ it took 28.4 / 19.0 s in one shot, and 9.7 s when chunked by 65,536-leaf subtrees; all three are single runs [M].

#### 9.2.3 Per-ask online update of fast keys (algorithm C)

This update changes only memory state, never slow parameters. So it runs under both data policies (§4.2). Keys are functions of a per-node cite log (§3.7), so a deletion or a new state view rebuilds them exactly under the assumptions of Prop. 6.23. The log form has not been run, so this is untested (Prediction P10).

**Evidence.** Fix-cite-noise experiment, held-out LoCoMo, rank-16 baseline 0.657. Dense recall@10 differences with visit-level CIs (the front matter's [visit]); question-cluster CIs, marked q-CI (the front matter's [ask]), where they matter. None is chat-clustered [M].

| rule | oracle cites (include unopened evidence) | visible cites only (cites ⊆ opened top-10) | 30% wrong cites | 60% wrong | self-loop | visible, fused with BM25 |
|---|---|---|---|---|---|---|
| move, $\eta=0.1$ (E6) | +0.020 [+0.015, +0.027]; q-CI [+0.012, +0.030] | −0.002 [−0.007, +0.003] | −0.003 | −0.024 | −0.023 | −0.001 |
| contrastive pull and push | +0.026 [+0.020, +0.032] | +0.008 [+0.004, +0.013]; q-CI [+0.001, +0.015] | +0.014 [+0.008, +0.020] | +0.003 (CI spans 0) | −0.005 [−0.011, +0.000] | +0.000 |
| combo (centred pull, BM25 agreement, centred push) | +0.018 | +0.005 [+0.001, +0.010]; q-CI [−0.001, +0.011] | +0.009 | +0.000 | −0.001 | +0.001 |
| BM25 agreement alone | +0.004 (CI spans 0) | 0.000 | +0.002 | −0.002 | −0.006 | +0.002 |

The wrong-cite columns swap oracle cites, so they too include unopened evidence. The fused baseline is 0.656.

Three consequences.
- **The draft's evidence was misattributed.** Its +0.020 came from the unfiltered move rule with oracle cites, scored dense-only. Under the draft's own "cites ⊆ opened" rule, the same move rule gives −0.002. This is Prediction P1 of §7.
- **The draft's filter was vacuous.** With bridged rank-16 views on held-out chats, $\langle s,k_v\rangle\ge0.2$ holds for 99.97% of opened top-10 nodes (1st percentile 0.244) and for 90% of gold evidence [M, `s1_checks.py`]. It is the ranker's own score, not an independent signal, and after "cites ⊆ opened" it removes nothing. The draft's cap ("the 3 best by $\langle s,k_v\rangle$") favoured nodes that already rank high. Both are removed.
- **On the fused path, no rule has a measured gain.** So algorithm C ships in shadow mode. It keeps the logs and computes $k_v$, but READ scores with $k^0_v$ until the prequential check (D step 4b), run on real cites rather than oracle cites, shows a gain on the fused path.

**The alias rule is dropped.** Storing an $S$-view ask state as an extra key collapsed recall to 0.463 (§6.5) [M, E6]. Its measured repairs reached 0.686 (hub-corrected bonus, F3) and 0.687 (key-view alias plus that bonus, F5) with oracle cites; over the baseline their chat-level CIs are [+0.017, +0.038] and [+0.015, +0.041] [M, alias-hub fix]. Their edge over the move rule does not survive a chat-cluster bootstrap. Neither has been run with visible cites. Under BM25 fusion they score 0.662 and 0.661 against 0.656 [M]. They stay candidates, not the default.

```text
ALGORITHM C  ONLINE-UPDATE(ask n, probes (x^p_t, z_t), opened O, raw cites C, outcome)   # after the answer, off the critical path
 1  learning log: (time, ask id, z_t, probe text, O, the top-50 candidates with ranks and the score parts and norms of T4,
                   C, outcome, graph version tau, bundle version)   # log z_t, not s_t: refitting S needs the pre-view input
 2  if outcome in {regenerated, thumbs-down, verifier failed, answer withdrawn}: return   # logged, no key change
 3  C* <- leaves(C ∩ O)            # a node never shown cannot be a real cite; a cited gist credits no leaf
 4  if C* is empty: return          # no push without at least one accepted cite (as measured)
 5  U <- leaves(O) \ C              # opened but not cited; raw C, so a real cite is never pushed
 6  for v in C*: append (n, z_t, +1) to cite_log[v];   for u in U: append (n, z_t, -1) to cite_log[u]
 7  for v in C* ∪ U: k_v <- KEY(v); mark v's ancestors' cached child rows dirty
 8  never: change slow parameters online; learn from the system's own top hit without a cite (self-loop)

KEY(v)                              # §3.7: commutative, so it is rebuilt exactly after a forget or a new S
    a <- nu * k0_v
         + sum over (n, z, +1) in cite_log[v] of ( n(S z) - c_ctr * sbar_tau )
         - beta_U * sum over (n, z, -1) in cite_log[v] of n(S z)          # summed in ask-id order (D5)
    k <- n(a); optionally apply the anchor cap zeta = 0.3 (Prop. 6.13 then gives <k, k0> >= 0.954)
    return k
```

**Parameters.** The measured contrastive rule is sequential. For each cited $v$: $k_v\leftarrow\mathrm n(k_v+\eta(s-k_v))$. For each opened but uncited $u$: $k_u\leftarrow\mathrm n(k_u-\eta_-s)$. Dev tuning chose $\eta\in\{0.05,0.1\}$ and $\eta_-\in\{0.01,0.03\}$ [M]. KEY matches it exactly for the first cite and the first push when
$$\nu=\frac1\eta-1,\qquad \beta_{\rm U}=\nu\,\eta_- ,$$
for example $\nu=19$ and $\beta_{\rm U}=0.19$–$0.57$ at $\eta=0.05$ [D]. After more events the two differ at $O(\eta^2)$ (Prediction P10).
- $c_{\rm ctr}=0$ matches the uncentred measured rule. $c_{\rm ctr}=1$ matches the centred rule, but with $\bar s_\tau$ frozen per version instead of a running mean (§8 row 10).
- The log form itself has not been run.
- The rule pulls an $A$-view key toward an $S$-view state, which breaks design rule 2.1. The $A$-view target $\mathrm n(Ae_q)$ is Prediction P2, not yet tested.

Cost: the sequential update after one answer took 0.034 / 0.024 ms [M]. KEY costs $O(n_v\,d\,r)$ per node, and cited nodes have 1.65 cites on average (§6.4) [M]; KEY itself was not timed.

#### 9.2.4 Nightly consolidation (algorithm D)

Under policy A (the default), no slow parameter is fitted to personal data, so steps 3 and 4 do not run. They run only under the opt-in variant B. Variant B retrains from $\theta_{\rm ship}$ with a fixed seed and no warm start (§4.2).

**Gate (variant B).** The margin $\varepsilon_{\rm g}=0.005$ is a design choice. (The subscript keeps $\varepsilon$ for the round-trip error of Definition 2.6.)
$$\text{accept }\theta_{\rm new}\iff \mathrm{CI}^{95}_{\rm low}\big(\Delta_{\mathcal T_{\rm gate}}(\theta_{\rm new},\theta_{\rm cur})\big)\ge-\varepsilon_{\rm g}\ \wedge\ \Delta_{\mathcal P}(\theta_{\rm new},\theta_{\rm ship})\ge-\varepsilon_{\rm g}\ \wedge\ \Delta_{\mathcal T_{\rm frz}}(\theta_{\rm new},\theta_{\rm ship})\ge-\varepsilon_{\rm g} .$$
The two floor terms stop a ratchet. A margin of $\varepsilon_{\rm g}$ per night, measured only against $\theta_{\rm cur}$, would compound over many nights. $\mathcal T_{\rm frz}$ is a fixed set of the user's early asks with accepted cites. It is frozen once and never trained on.

**Why the draft's gate could not see an improvement.**
1. Gate positives are cites, and cites are a subset of $\theta_{\rm cur}$'s own top-10. So $\theta_{\rm cur}$ scores about 1 by construction, and any reordering can only lose. The gate measured agreement with $\theta_{\rm cur}$. Logging the top-50 candidates with their ranks lets gains show (recall@50, MRR). The public guard set $\mathcal P$ and interleaving judge real improvement.
2. The refit early-stopped on the same split that gated it, which is selection bias. Fit, selection and gate are now separate time splits.
3. Fast keys were learned from the gate split's own cites, so scoring with them leaks labels. Both arms are now gated on base keys $k^0$.

```text
ALGORITHM D  CONSOLIDATE   (iOS BGProcessingTask: charging + idle; resumable in chunks;
                            run time is not guaranteed, so every step checkpoints)
 0  open journal Jnl: every WRITE and FORGET from now on is applied live AND appended to Jnl
 1  snapshot G_tau (copy-on-write); reads keep using the version committed before each ask (Def. 2.5)
 2  STATISTICS: freeze sbar_{tau+1} from the retained asks (D6); recompute BM25 df, N and avgdl
 3  [variant B] REFIT from theta_ship, fixed seed, no warm start:
      time-ordered log split: T_fit = oldest 70%, T_sel = next 10%, T_gate = newest 20%
      positives C*; hard negatives O \ C (raw cites; weight 0.5, since "not cited" != "irrelevant");
      1024 sampled negatives and in-batch negatives; forward L_mask with alpha fixed;
      L2-SP pull lambda_sp * ||theta - theta_ship||^2; <= 5 epochs; early stop on T_sel only
                                                              # about 8-12 s per 1e4 asks x 5 epochs [X]
 4  [variant B] GATE on T_gate only (formula above); bootstrap over asks clustered by day
      both arms scored with base keys k0 (no fast-key terms)
      metrics from the logged top-50 candidates: recall@10, recall@50, MRR
      reject -> keep theta_cur; if theta_cur is tainted (F step 8) -> theta_ship, never theta_cur
 4b FAST-KEY CHECK (both policies), prequential: from the scores logged at ask time, compare recall with k against
      recall with k0 on each ask, where k uses only cites from earlier asks; READ switches between k and k0 on this
      evidence (this replaces the draft's "keep drift only if replay says it helps", which tested drift on its own
      training cites)
 5  RE-KEY, only if S or A changed: k0_v <- n(A e_v) for every leaf; k_v <- KEY(v) from its log with the new S (L5)
      # replaces the draft's "k0 + old drift", which added drift from the old key space and lacked n()
                                                              # 0.16-0.30 s per 1e5 keys [M]
 6  PARENTS: L_v needs no stored state. If g serves a level: recompute dirty paths by hash, or the whole tree if g changed.
      If pruning is on: measure F_b at the store's real N    # whole tree 0.79 / 0.95 s per 1e5 leaves [M]
 7  GISTS: stale = {v : gist provenance != current child hashes} ∪ blanked; priority = reads(v) x level
      draft <- distiller(children's texts or gists); never the old gist
      accept the draft only if every sentence is supported by a cited child (entailment check);
      else keep the old gist if it is still valid, or leave it blank (readers descend past it)
      then e_v <- f(x_v); k^g_v <- n(A e_v)                   # about 2.3 s per gist on an iPhone 15 Pro [D]
 8  STRUCTURE: proposals split / merge / move leaf / link (co-cited >= t times, or a shared entity)
      rank proposals on T_sel; apply at most a nightly cap to a shadow copy; recompute affected parents and gists
      accept on T_gate only if the granularity path does not degrade (gist-path recall and token cost),
      F_b does not drop when pruning is on, and J of Prop. 6.25 does not rise
      # while READ is flat, leaf recall cannot change, so "leaf recall does not drop" is not a test
      # ranking and accepting on different splits limits the winner's curse
 9  COMPACT: drop log rows past retention; rebuild the ANN index if one is used; checkpoint the WAL
10  COMMIT: replay Jnl onto G_{tau+1} (writes placed; forgets applied with their full closure);
      apply Jnl's forgets to the retained rollback copy G_tau as well;
      commit G_{tau+1} atomically with its lineage map lin_tau; keep G_tau for one-step rollback
```

Two more fixes are in this version.
- **Race.** The draft snapshotted $G_\tau$, committed $G_{\tau+1}$ atomically, and dropped everything that arrived in between. Writes were lost and forgotten items came back. Steps 0 and 10 fix this.
- **Unchecked gists.** The draft re-distilled gists with no faithfulness check, although gists are shown to $R$ and used as fallback keys. Step 7 adds one.

**Night budget at $N=10^5$ on this CPU:** re-key 0.16–0.30 s, whole tree 0.79–0.95 s, gate 0.67–0.77 s per 500 asks [M]; refit 8–12 s [X]. On the phone, gists dominate. At about 2.3 s each [D], 200 gists take about 7.7 min [D]. Before relying on nightly on-device gists, check two things: how long a BGProcessingTask actually gets, and whether Foundation Models calls are allowed or rate-limited in the background.

#### 9.2.5 Joint loop with an open LLM (algorithm E)

This is stage B of §4.3, after stage A. It is research only: cloud GPU, public and synthetic data only.

```text
ALGORITHM E  JOINT-OPEN-LLM
Model: R = Qwen3-8B (36 layers, d_h = 4096) + LoRA r = 16 on q, k, v, o (15.3M parameters, §4.1)
       Pi: tapped hidden state h_t (layer j*) -> Z, aligned to the anchor view f(x^p_t); read state s_t = n(S Pi(h_t))
       iota: Z -> n_s soft tokens; carries content (e_v or c_hat_t), never keys (design rule 2.1)
       S, A, W, the stop head and g (if it shipped) come from algorithms A and B; alpha fixed
 1  §4.3 stage A (R frozen): train Pi with L_align (symmetric InfoNCE, not regression); choose j* on held-out L_align (C3)
    train iota with L_recon + L_kd; check P11 (read recall from Pi(h) within the chat-clustered CI of text states)
 2  §4.3 stage B, for round = 1..rounds:
 3    C-step (structure fixed): sample an episode (haystack, question, gold evidence, gold answer)
 4      roll out READ-AGAIN: at hop t, R emits <read> and a probe text x^p_t; z_t <- Pi(h_t); READ with s_t
        (teacher forcing: missed gold injected with probability p_tf, decayed toward 0)
 5      loss (§3.8): L_LM + lambda_read L_hop + lambda_align L_align + lambda_hier L_hier + lambda_stop L_stop
                     + lambda_recon L_recon + lambda_kd L_kd + lambda_rt L_rt + lambda_dist L_dist + R_reg,
        with the stop-gradients of the §3.8 gradient-flow table
        optional: REINFORCE on the stop decision, reward = correct - lambda_h * hops
 6      update {LoRA, Pi, iota, S, A, W, stop head, g}; refresh k0 for the batch's haystacks; refresh all every K steps
 7    S-step (parameters fixed): re-key; recompute parents; re-distil stale gists with R;
        accept a structural edit only if it lowers J on the same replay set (Prop. 6.25)
 8    dev: answer accuracy, evidence recall@10, hops per answer, decision latency; early stop
 9  deployment: views trained on Pi(h) do not transfer to Claude or the Apple model. Keep the text-born set
    (z = f(x^p)) for those, and ship the Pi-based set only where Qwen runs (Mac or GPU)
```

**Why probes stay text in instantiation (a).** Building the next state from vectors alone lowered recall by 0.012 to 0.027 [M, second-hop fix]. Even with a gold first hop, the ask-plus-node vectors carried almost no second-hop signal: multi-hop recall was 0.427 with the plain ask state and 0.429 with the learned hop head [M, reviewer check]. Memory reacts only to what $R$ puts into words (Prop. 6.21). Whether $\Pi(\mathbf h_t)$ carries more is open.

### 9.3 Inference algorithms

$$\mathrm{rrf}(v)=\sum_{j\in\{\text{dense},\,\text{lex}\}}\frac1{60+\mathrm{rank}_j(v)}$$

#### 9.3.1 Read path (algorithm R)

```text
ALGORITHM R  READ(probe text x^p | hidden state h, exclude X, K = 10, N_flat ~ 2e5 [X])
 1  z <- f(x^p)  (algorithm E: z <- Pi(h));  s <- n(S z)          # encoder 26-30 ms here [M]; view 5-6 us [M]
 2  LEAVES (live leaves minus X; X is removed BEFORE ranking)
      if N <= N_flat or pruning is not certified (F_b < 0.95 at this N):
          dense <- top-50 over ALL live leaves: int8 scan, top-100, fp32 re-rank
                                                    # 0.40 ms at 1e4, 2.27 ms at 1e5, top-10 overlap 1.000 [M]
      else (pruned, IVF-style):
          score every level-1 parent (facets of g, or k-means slots); keep the top b' globally
          (no hierarchical beam: every parent is scored anyway); dense <- exact scores over their leaves
          HNSW only if it meets the same 0.95 top-10 bar at this N (ef = 128 gave 0.92 at 1e6 [M])
 3  lex <- BM25 top-50 over the ask's tokens (SQLite FTS5 bm25() on device)
                                                    # 0.03-0.04 ms at 1e4, 0.34-0.58 ms at 1e5 [M]
 4  fused <- top-K of rrf(dense, lex)               # over top-50 lists: 0.02 ms [M];
                                                    # re-measure recall against full-list RRF before shipping
 5  GRANULARITY (leaf scores are now known)
      for each scanned parent v: L_v from the leaf scores (segmented LSE)
      for the best parents v by L_v whose gist is present and fresh (not blank; gist provenance = child hashes):
          psi <- stop features of §2.4, from leaf and parent scores already in hand
          if pi_stop(psi) > theta_stop: emit v as a GIST item
      de-duplicate: an emitted gist replaces its descendant leaves in fused; those leaves stay listed by id
      under the gist, so R can open them with one more read and no re-encoding
 6  ctx <- [(node id, level, text or gist, time, parent id) for fused ∪ gists], within the token budget
      Apple on-device R: instructions + prompt + tools + response <= contextSize (4,096 tokens per session [S]);
      read SystemLanguageModel.contextSize at run time and size ctx to fit
 7  log: O = ids(ctx); the top-50 candidates with ranks; per-candidate score parts and norms (T4); z, x^p, tau
 8  return ctx; R must cite node ids from ctx
```

At personal scale the pruned branch does not run. The frontier descent of §5.1 is its general form.

**What changed from the draft.**
- The stop decision used a leaf-max feature before any leaf was scored, and in pruned mode that feature was undefined. Leaves are now scored first.
- The draft emitted gists with no staleness check, although its write path said readers must descend past stale gists. Step 5 skips blank and stale gists, and de-duplicates a gist against its descendants.
- The draft's hierarchical beam threw away information, since every parent was scored exactly anyway. Pruned mode now takes the top $b'$ parents globally.
- HNSW was accepted at overlap 0.92 while the pyramid needed 0.95. One bar now applies to both. HNSW keys also go stale under fast-key updates.
- The draft's timing for step 2 (1.9 ms at $10^5$) covered only the int8 matrix product. The path READ specifies (int8 scan, top-100, fp32 re-rank) measures 2.27 ms at $10^5$ and 0.40 ms at $10^4$ [M].

#### 9.3.2 Read-again loop (algorithm RA)

```text
ALGORITHM RA  READ-AGAIN(ask, H_max)        # H_max = 2 with Claude (one LLM-driven hop); 3 in research
 1  state <- ask; seen <- {}; ctx_all <- []
 2  for i = 1 .. H_max:
 3      ctx <- READ(state, exclude = seen)  # seen is removed before top-K, so a hop never comes back short
 4      if ctx is empty: break
 5      seen ∪= ids(ctx); ctx_all += ctx
 6      if i = H_max or the token budget of ctx_all is spent: break   # no "what is missing?" call on the last hop
 7      thought <- R(ask, ctx_all, "what is still missing?")           # one LLM call
 8      if thought = ANSWER: break
 9      state <- ask ⊕ thought              # keep the ask: the thought alone drops the ask's entities from BM25
10  return ctx_all                          # hop 1 runs serially before the first LLM request
```

- The loop terminates because $i\le H_{\max}$.
- Skipping the probe call on the last hop saves one time to first token in the worst case.
- The draft's memory-only mode is removed. It re-encoded the ask with the two best new snippets and stopped on undefined "global features". Its evidence is weak: two-hop pseudo-relevance feedback scored 0.641 in E1 (no bridges), below one bridged read (0.657), and vector-only second hops lowered recall by 0.012–0.027 [M]. Its timings stay in §9.4.2 as a cost reference.

#### 9.3.3 Write path (algorithm W)

```text
ALGORITHM W  WRITE(item)         # after the answer or on capture; never on the read critical path;
                                 # buffered and committed after the ask (Def. 2.5)
 1  e <- f(text); k0 <- n(A e); cite_log <- {} (so k = k0); w_new <- n(W e)
 2  PLACE (write bridge of §2.4, loss of §3.5):
      holders H <- top n_H level-1 nodes by score(w_new, u), plus the current session node; near-duplicates U
      score(w_new, u) = max_i <w_new, phi_{u,i}> if g serves level 1, else LSE_omega of <w_new, k0_c> over c in C(u)
      a <- argmax of pi_W over attach(u) / new(u) / merge(v) / drop      # drop only for content-free turns
      if a = new(u) or the holder is full: queue a structure proposal for D step 8; attach to the best holder now
      privacy labels and walls are fixed rules, never a learned write decision
 3  ONE TRANSACTION through ObjectStore: leaf row, placement, FTS5 row, ancestor stale flags and hashes, op-log row
 4  ancestors bottom-up: leaf count, lexical signature, hash(v) = HASH(level, weight version, sorted child hashes);
    facets along the path only where g serves a level (2 encoder calls per insert in E8 [M])
 5  for each ancestor v: gist_stale[v] <- (gist provenance of v != current child hashes)
    gists are not rewritten now; READ skips stale gists and descends; D step 7 rewrites them
```

Measured: 36–40 ms with the encoder and 0.34–0.55 ms without it; a BM25 add plus remove takes 0.11–0.15 ms at $10^4$ [M]. In E8 the vector work per insert (3 key models, 4 parent encoders, hashing, BM25 and the op log) took 2.5 ms, or 8.6 ms under contention [M, E8].

#### 9.3.4 Forget path (algorithm F)

```text
ALGORITHM F  FORGET(target)      # the memory-state closure commits before the next read (Def. 2.5, rule 4)
 1  resolve targets through the derived-from provenance index: a leaf, a subtree, a predicate, or an ask
 2  per-node state: text, e_v, k0_v, cite_log[v] and k_v, lateral links (co-citation links included),
    FTS5 / BM25 postings; ANN tombstone (rebuilt tonight)
 3  fast keys of OTHER nodes: delete every cite_log entry whose ask is the target, or whose z or probe text
    derives from it; recompute KEY(u) for each affected u         # the draft left this drift in place
 4  statistics: BM25 df, N and avgdl (exact integer update, or recompute); sbar_tau and calibration levels (D6)
 5  ancestors: leaf counts, lexical signatures, hashes; facets along the path if g serves a level;
    blank every ancestor gist whose provenance includes the target (this reaches the root);
    queue each for regeneration from the surviving children, never from the old gist; readers descend past blanks
 6  logs: delete learning-log rows whose ask, z, probe text, O or C contain or derive from the target
    (node -> rows index); apply the selection-closure policy of §5.4 step 2; drop it from replay and guard buffers;
    invalidate cached LLM contexts that hold it
 7  if CONSOLIDATE is running: append to its journal Jnl (D step 10 applies it to G_{tau+1} and to the rollback G_tau)
 8  weights: policy A, nothing to do (Prop. 6.24a).
    variant B: theta_cur and every checkpoint fitted on a log that held the target are tainted;
    switch to theta_ship now and rebuild fast keys with its S        # re-key 0.16-0.23 s at 1e5 [M]
    tonight's refit starts from theta_ship on the purged log
 9  storage: SQLite secure_delete; FTS5 secure-delete (needs SQLite >= 3.44: check the iOS SQLite version);
    PRAGMA wal_checkpoint(TRUNCATE), since secure_delete does not scrub the WAL; redact op-log rows;
    VACUUM tonight; backups and exports
10  verify: query the provenance index for any record derived from the target id; it must return no rows
    (a content-hash search cannot find embeddings or paraphrased gists)
11  out of reach: copies already sent to Claude (prompt cache, provider retention); say so in the UI
```

**Measured synchronous part:** 12.0–16.5 ms with a naive scan of a $10^4$-row log; the purge is 11.3 ms of that [M]. With the node-to-rows index a lookup takes 0.5 µs [M], so about 1–2 ms remains on this CPU [D: 12.6–13.2 ms minus 11.3 ms]. The key rebuilds of step 3 were not timed. Regenerating a blanked gist is an LLM call of about 2.3 s on device [D], off the read path.

**A side effect that needs a design decision.** Every forget blanks all ancestor gists up to the root. A root gist inside Claude's cached prompt prefix would therefore invalidate that cache after every forget. So keep gists out of the cached prefix and cache only the system prompt and tools. On current Claude models (Opus 5.5, Sonnet 5.5, Haiku 5.5) the minimum cacheable prefix is 512 tokens [S].

### 9.4 Latency

#### 9.4.1 Cost model

$$T_{\rm hop}=T_{\rm enc}(n_{\rm tok})+T_{\rm view}+T_{\rm leaf}(N)+T_{\rm lex}(N)+T_{\rm parent}+T_{\rm fuse}+T_{\rm fetch}$$
$$T_{\rm ask}=T^{(1)}_{\rm hop}+\sum_{i=2}^{H_{\max}}\Big(T^{(i-1)}_{\rm probe}+T^{(i)}_{\rm hop}\Big)+T_{\rm TTFT}+T_{\rm gen}$$

- $T^{(1)}_{\rm hop}$ runs serially before the request is sent. It overlaps only request assembly and a prompt-cache pre-warm. (The draft marked it "prefetched", which was misleading.)
- $T_{\rm probe}$ is one LLM call that writes the next probe: about one time to first token plus a short generation.
- Writes, online updates and consolidation are off the critical path.

**Hot and cold cache.** The timing loops re-scan the same keys, and the 260 MiB L3 holds the fp32 keys at $10^4$ (15 MB) and $10^5$ (154 MB). So those rows ran cache-resident.
- With a 768 MB sweep before each scan, an fp32 scan takes 1.32 ms at $10^4$ (0.60 hot) and 12.4 ms at $10^5$ (7.3 hot) [M].
- Cold, a scan streams about 12–13 GB/s on one thread here: 154 MB in 12.4 ms at $10^5$, and 1.54 GB in 118 ms at $10^6$ [D from M]. The draft's "memory-bound at 13 GB/s" argument held only for the $10^6$ row.
- Phone caches are far smaller than 260 MiB, so project from the cold numbers. An int8 key set at $10^5$ is 38 MB, so a cold int8 scan would take about 3 ms at this rate [D].

#### 9.4.2 Key measurements (one x86 thread; medians in ms, run 1 / rerun) [M]

| what | $10^3$ | $10^4$ | $10^5$ | $10^6$ |
|---|---|---|---|---|
| exact fp32 scan (GEMV), hot cache | 0.08 / 0.02 | 0.72 / 0.65 | 7.1 / 6.8 | 118 / 118 |
| exact fp32 scan, cold cache (rerun only) | | 1.32 | 12.4 | already memory-bound |
| exact bf16 scan | 0.06 / 0.03 | 0.57 / 0.52 | 4.8 / 4.8 | 96 / 82 |
| int8 scan alone (top-10 overlap with fp32) | 0.08 / 0.02 (0.96) | 0.29 / 0.29 (0.97) | 1.9 / 1.9 (0.95) | 36 / 37 |
| **int8 scan + top-100 + fp32 re-rank, READ's path (overlap)** | | **0.40 (1.000)** | **2.27 (1.000)** | |
| 1-bit codes + fp32 re-rank of top-200 (overlap) | 0.07 / 0.05 (0.98) | 0.32 / 0.39 (0.88) | 3.1 / 2.6 (0.76) | 46 / 45 |
| top-10 by argpartition (full argsort, as e5 and e6 do) | 0.009 / 0.007 (0.019 / 0.021) | 0.024 / 0.024 (0.65 / 0.66) | 0.18 / 0.14 (8.8 / 8.8) | 3.4 / 3.0 |
| HNSW M=16, query at ef = 64 and 128 (overlap) | | 0.13 and 0.25; rerun 0.12 and 0.23 (0.96, 0.99) | 0.17 and 0.32; rerun 0.16 and 0.29 (0.95, 0.98) | 0.22 and 0.41; rerun 0.23 and 0.38 (0.84, 0.92) |
| HNSW build, whole index (single runs) | | 1.9 / 2.0 s | 37 / 37 s | 501 / 480 s |
| BM25 postings, top-50 | 0.017 / 0.042 | 0.039 / 0.032 | 0.34 / 0.58 | |
| BM25 as e1 does it (score every document in Python) | 0.60 / 0.95 | 6.5 / 6.4 | | |
| internode whole-tree recompute, full $384\times384$ (low-rank $r=32$) | | 64 / 93 (37 / 40) | 794 / 946 (715 / 697) | 28,352 / 18,986 (21,512 / 16,141); chunked 9,680; single runs |

The run-1 rows at $10^3$ keys read about 3x high, probably from contention [M].

| what | median ms, run 1 / rerun [M] |
|---|---|
| encode 1 short ask (13 tokens), end to end | 26.0 / 30.4 (rotating over 1,531 asks: 26.1 / 26.0) |
| transformer forward at 16 / 32 / 64 / 128 / 256 / 512 tokens | run 1: 23.6 / 23.6 / 42.4 / 70.6 / 130 / 258; rerun: 23.7 / 30.4 / 44.4 / 70.6 / 125 / 257 |
| encode 1 leaf unbatched; batched 64 fp32; batched 64 bf16 (AMX), per leaf | 34.7 / 35.1; 21.4 / 22.4; 7.2 / 7.5 |
| int8 dynamic-quantised encoder, 1 ask | 12.8 / 13.6 (cosine to fp32 0.970; top-10 overlap 0.73: not usable as is) |
| state view $r=16$, 1 vector; full $384\times384$ | 0.006 / 0.005; 0.012 / 0.009 |
| key view re-key, $10^4$ and $10^5$ keys | 14.0 / 12.5; 296 / 232 (in place, chunked by 4,096 at $10^5$: 157) |
| beam descent $b=8$ at depth 3 / 4 / 5 ($N$ = 4k / 65k / 1M) | run 1: 0.036 / 0.055 / 0.13; rerun: 0.044 / 0.066 / 0.10. Flat: 0.28 / 4.5 / 136; rerun 0.30 / 4.6 / 143 |
| internode path recompute, with cached child K/V; without | 0.27–0.52 / 0.17–0.48; 1.2–1.7 / 0.89–2.16 |
| RRF over two full $10^4$ lists; over two top-50 lists | 7.4 / 5.1; 0.024 / 0.020 |
| one read hop, $N=4096$, flat (memory work only) | 24.7 / 27.0 (0.46 / 0.45) |
| **one read hop, $N=65{,}536$, flat (memory work only)** | **35.9 / 39.7 (4.9 / 5.5)** |
| one read hop, $N=65{,}536$, pyramid $b=8$ (memory work only, without the state view and the context fetch) | 27.4 / 25.7 (0.35 / 0.51) |
| read-again, 2 and 3 hops, memory-only re-entry, $N=65{,}536$ | 76 / 80; 143 / 143 (p95 of 3 hops: 196 / 178) |
| write path, with encoder; without encoder and BM25 | 38.7 / 40.2; 0.51 / 0.55 |
| forget path, naive log scan, $N=4096$ and $N=65{,}536$ | 12.0 / 12.6; 16.5 / 13.2 (purge alone 11.3; indexed lookup 0.0005) |
| online key update, sequential rule, 3 cites | 0.034 / 0.024 |
| nightly refit step, 64 asks, $r=16$; full view | 10.8 / 10.6; 14.7 / 15.3. Per $10^4$ asks × 5 epochs: 8.3–8.4 s and 11.5–11.9 s [X, extrapolated from 50 steps] |
| replay gate, 500 asks × $10^4$ and $10^5$ keys | 57 / 45; 673 / 771 |

**Batched decisions** (one pass over $10^5$ keys; per-query cost in ms) [M]:

| keys | $Q=1$ | $Q=4$ | $Q=16$ |
|---|---|---|---|
| int8 (fbgemm), run 1 / rerun | 2.28 / 1.86 (three repeats: 1.7–3.3) | 0.61 / 1.12 (three repeats of the 4-query pass: 2.5–3.4 total) | 0.28 / 0.40 |
| fp32: single GEMV for $Q=1$; best batched product for $Q>1$ | 6.8–7.1 | 5.3 / 4.3 (torch) | 1.85 / 1.65 (torch) |

So the int8 per-query cost falls about 2x at 4 queries and 4–5x at 16. At $10^6$, 4 int8 queries cost 63–66 ms in one pass against 34–36 ms for one [M]. The fp32 gain at 16 queries is about 4x against the single GEMV. A 4-query numpy fp32 pass (24.6–27 ms) gains nothing over 4 × 6.8 ms [M]. (The draft compared against a 10 ms single-query matrix product, not the 6.8–7.1 ms GEMV.)

#### 9.4.3 Per-step budget for three deployments (per ask unless noted)

| step | here [M] | iPhone: memory on device, Claude as $R$ | Mac edge: Qwen3-8B local | cloud GPU, research |
|---|---|---|---|---|
| encode ask (32 tokens or fewer) | 26–30 ms | 3–10 ms, Core ML fp16 on the ANE [X]. Anchor: 3.47 ms for a 66M-parameter DistilBERT at 128 tokens on the iPhone 13 ANE [S] | 2–6 ms [X] | 1–3 ms; 0 in algorithm E [X] |
| encode re-entry state (64–128 tokens) | 42–71 ms | 4–15 ms [X] | 3–10 ms [X] | 1–3 ms [X] |
| state view | 0.005–0.006 ms | about 0 | about 0 | about 0 |
| leaves, $10^4$, exact | 0.40 ms on READ's int8 path; fp32 0.60–0.72 hot, 1.32 cold | 0.3–1.5 ms [X] | 0.2–1 ms [X] | under 0.1 ms [X] |
| leaves, $10^5$, exact | 2.27 ms on READ's int8 path (hot); fp32 6.8–7.3 hot, 12.4 cold | about 3 ms cold if one core streams like this one [D]; measure | 0.5–3 ms [X] | under 0.5 ms [X] |
| leaves, $10^6$ | exact int8 34–37 ms; HNSW 0.38–0.41 ms but overlap 0.92 fails the bar | not needed at personal scale (§9.5 item 8) | same | about 1 ms exact on GPU [X] |
| parent scores $L_v$ from leaf scores | not timed (one pass over $N$ scores, no key reads) | below the scan time [X] | same [X] | same [X] |
| BM25 top-50 | 0.03–0.04 ms at $10^4$; 0.34–0.58 ms at $10^5$ | SQLite FTS5 `bm25()`: not measured; 1–5 ms [X] | same [X] | n/a |
| fuse + fetch 10 texts | 0.02 ms + fetch (not measured) | 0.1–1 ms through GRDB [X] | same [X] | n/a |
| **one memory hop** | **25–40 ms (flat)** | **5–20 ms [X]** | **3–12 ms [X]** | **2–5 ms [X]** |
| LLM time to first answer token | n/a | Claude Sonnet 5.5: 1.29 s at low effort, 2.99 s at medium; Haiku 5.5 at medium: 11.39 s [S]; plus the mobile round trip (not measured). Apple on-device: 0.6 ms per prompt token (2024 model), so about 1.2 s for 2,000 tokens [D]; context cap 4,096 tokens per session [S] | Qwen3-8B Q4_K_M on M4 Max: 657 ms warm; at about 737 tokens/s prefill, about 2.7 s for a 2,000-token prompt [D from S estimates] | 8B on an H100 with vLLM: 0.05–0.2 s at 2k tokens [X, rule of thumb] |
| each LLM-driven extra hop | n/a | Claude: about one more time to first token, so 1.29 s or more at Sonnet 5.5 low [D]. Apple: about 0.3 s to prefill 500 new tokens plus about 0.7 s to write a 20-token probe [D: 500 × 0.6 ms; 20 / 30 tokens/s] | 0.3–1 s with a KV cache [X] | in-model decision (CLM-8B): 16.5 ms [B]; hosted decision model (Jev): 70–500 ms [S, vendor claim, unverified] |
| 150-token answer | n/a | Sonnet 5.5 at 109 tokens/s: about 1.4 s; Haiku 5.5 at 174 tokens/s: about 0.9 s [D]. Apple at 30 tokens/s (2024 model, iPhone 15 Pro): about 5 s [D] | M4 Max at about 80 tokens/s: about 1.9 s; M3 Max at 51.3 tokens/s: about 2.9 s [D from S estimates] | about 1 s [X] |
| write (after the answer) | 36–40 ms (0.34–0.55 ms without the encoder) | 5–15 ms [X] | 3–10 ms [X] | n/a |
| forget, synchronous part | 12–17 ms naive; about 1–2 ms with the log index [D] | under 5 ms [X], plus about 2.3 s per blanked gist, off the read path [D] | same | n/a |
| nightly, $N=10^5$ | re-key 0.16–0.30 s; whole tree 0.79–0.95 s; gate 0.67–0.77 s [M]; refit 8–12 s [X] | 1–3 min of compute [X], plus about 2.3 s per gist: 200 gists take about 7.7 min [D] | less [X] | n/a |

**Gist cost [D].** We assume a gist call reads about 1,000 prompt tokens and writes about 50. At 0.6 ms per prompt token and 30 tokens/s, that is 0.6 s + 1.7 s, about 2.3 s. These are the 2024 model's iPhone 15 Pro figures [S], a proxy for the iOS 27 model. The token counts are assumptions. The 4,096-token context also caps how many children one gist call can read, so large holders must be gisted in chunks.

**Proposed iPhone p95 targets** (design choices, not measurements): a memory hop of at most 20 ms; at most 60 ms of memory work per ask; at most one LLM-driven hop with Claude; nightly work split into resumable chunks rather than one fixed 10-minute window.

**End to end on iPhone with Claude, one hop.** Memory (5–20 ms [X]) runs serially before the request is sent. Against Sonnet 5.5's 1.29 s time to first token at low effort [S], that is 0.4–1.6% [D]. Even at a hypothetical 0.35 s time to first token it would be at most 5.7% (20 / 350) [D]. So memory is at most about 6% of the time to first token. Each LLM-driven hop adds about one more time to first token, so hop policy and effort level are the levers.

#### 9.4.4 How these numbers convert

- All [M] numbers come from one x86 thread under Python. Rows under 1 ms are dominated by interpreter overhead and should shrink in Swift with Accelerate [X].
- Cold scans are memory-bound, at 12–13 GB/s here [D from M]. They should carry over to an Apple P-core within roughly 0.5–2x [X]. Measure on the phone.
- The encoder row moves the most. Apple reports latency roughly constant across sequence lengths 32, 64 and 128 at batch 1 for ANE-optimised transformers, with 3.47 ms at length 128 on the iPhone 13 ANE for DistilBERT (66M parameters) [S]. bge-small has about 33M parameters (§2.2), so the 3–10 ms range [X] is plausible. It must be measured with the Core ML performance report.
- First ANE model loads can be very slow. An Apple developer forum thread reports first Core ML loads on the iPhone 18 Pro ANE up to 65x slower than on the iPhone 17 Pro. Per a search summary (the thread itself sits behind a bot check), the poster also reports that later loads were not cached on that device [S, unverified]. Measure the first and the second load on the target phone, and pre-warm at launch.
- Noise. Run 1 shared the host with an HNSW build; the rerun ran on an idle VM. The $10^6$ whole-tree recompute, the HNSW builds and the E5 fold are single runs, so read them as orders of magnitude. A 4-thread encoder run was oversubscribed (about 1 s per ask) and was discarded. The brief's figure of about 6 ms per turn on 4 cores [B] is consistent with 21–22 ms per leaf batched on one thread [M].

#### 9.4.5 External numbers and their status

| claim | value | status | source |
|---|---|---|---|
| Apple on-device model, iPhone 15 Pro | about 0.6 ms per prompt token to first token; 30 tokens/s | verified. It describes the 2024 model; used here as a proxy | [Apple ML Research, 2024](https://machinelearning.apple.com/research/introducing-apple-foundation-models) |
| Apple on-device context window | 4,096 tokens per session, covering instructions, prompt, tools and response; read `SystemLanguageModel.contextSize` at run time (iOS 26.4+) | checked by the reviewer | [TN3193](https://developer.apple.com/tutorials/data/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window.md) |
| ANE-optimised transformers | latency roughly constant at sequence 32, 64 and 128, batch 1; 3.47 ms at 128 on the iPhone 13 ANE (0.454 W) for DistilBERT, 66M parameters | verified | [Apple ML Research](https://machinelearning.apple.com/research/neural-engine-transformers) |
| Claude Sonnet 5.5, low effort | 1.29 s to first token; 109 tokens/s | Artificial Analysis, fetched 2026-10-27 | [AA, low](https://artificialanalysis.ai/models/comparisons/claude-haiku-5-5-vs-claude-sonnet-5-5-low) |
| Claude Sonnet 5.5 and Haiku 5.5, medium effort | Sonnet: 2.99 s at 109 tokens/s. Haiku: 11.39 s at 174 tokens/s | same | [AA, medium](https://artificialanalysis.ai/models/comparisons/claude-haiku-5-5-medium-vs-claude-sonnet-5-5-medium) |
| Claude thinking controls | Opus 5.5: thinking cannot be disabled; effort is the control (default medium). Sonnet 5.5: thinking off only with `thinking: {type: "between_tools"}`, at effort high or below. Haiku 5.5: off only at high or below. So any "no reasoning" time to first token must be stated per model | checked against Anthropic's API reference (snapshot of 2026-10-06) | [adaptive thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking) |
| Claude prompt-cache pre-warm | a `max_tokens: 0` request writes the cache; rejected with `stream: true`, structured output, forced tool choice, or inside a batch; must match the real request's thinking and effort settings; TTL 5 min by default, 1 h optional; minimum cacheable prefix 512 tokens on Opus 5.5, Sonnet 5.5 and Haiku 5.5, and 4,096 on Haiku 4.5 | checked against the same reference | [prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) |
| Qwen3-8B Q4_K_M on Apple silicon | M4 Max: about 80 tokens/s decode, 657 ms warm to first token, about 737 tokens/s prefill. M3 Max: 51.3 tokens/s | llama.cpp model estimates, not measurements | [willitrunai](https://willitrunai.com/can-run/qwen-3-8b-on-m4-max-96gb) |
| first Core ML load on the ANE | up to 65x slower on iPhone 18 Pro than on iPhone 17 Pro; loads of about 113 s; later loads not cached | the thread exists; its content comes from a search summary only | [Apple forum 850058](https://developer.apple.com/forums/thread/850058) |
| CLM-8B read decision | about 16.5 ms per decision, local GPU, cached action vectors | from the brief, unverified | [model card](https://huggingface.co/Contrastive-LM/CLM-v0.1-8B) |
| Jev hosted decision model | 70–500 ms end to end | vendor claim (also in the brief), unverified | [TypeSafe AI](https://typesafe.ai/); [Jev-Mem](https://arxiv.org/abs/2609.23986) |
| BGProcessingTask run time; Foundation Models in the background | no guaranteed duration; background calls may be rate-limited | not yet checked; verify before relying on nightly on-device gists | Apple documentation |

**Dropped from the draft.**
- "Sonnet 5.5 about 1.05 s at low effort, 4.5–12 s at medium". It does not match the source, and it mixed Haiku 5.5 at medium into the Sonnet figure.
- "Haiku 5.5 and Sonnet 5.5 at 137 and 99 tokens/s". Stale.
- "Haiku 4.5 time to first token 0.35–0.71 s". Neither cited page shows a figure, and Haiku 4.5 is the previous generation.
- "iPhone 17 Pro at 70–86 tokens/s". No URL.
- "Qwen3-8B time to first token 2.3–3.7 s". Not on the cited page.
- "Begin your visible answer immediately" is a prompt technique, not a documented feature.

### 9.5 Performance plan (ranked)

1. **Move the encoder to the ANE and start it early.**
   - It is 86% of a flat hop at 65k leaves [M].
   - Convert bge-small to Core ML fp16 with fixed shapes 16, 32, 64 and 128. Keep it resident and pre-warm it at launch. Measure the first and the second load (§9.4.4).
   - Encode the ask while the request is being assembled.
   - Expected: several-fold faster [X], anchored by Apple's 3.47 ms DistilBERT figure [S].
   - Do not ship naive dynamic int8: it measured cosine 0.970 and top-10 overlap 0.73 against fp32 [M]. bf16 matched fp32 (cosine 1.000) and was 3x faster batched, but not faster for one ask [M].
2. **Cut LLM-driven hops, and overlap what can be overlapped.** Each costs about one time to first token, 1.29 s or more with Sonnet 5.5 [S], against milliseconds for memory.
   - Always run hop 1 before the first LLM call.
   - Skip the "what is missing?" call on the last hop (RA step 6).
   - Let one tool call carry several read queries (item 6).
   - On Claude: use low effort. Cache a stable prefix (system prompt and tools, not gists; §9.3.4). Pre-warm it with `max_tokens: 0` using the real request's thinking and effort settings, and re-warm within the 5-minute TTL or use the 1-hour TTL [S]. A prefix shorter than the model's minimum (512 tokens on current models [S]) will not cache.
   - On the Apple model: fit the memory context and everything else into 4,096 tokens [S].
   - Prefetching hop-2 candidates while the LLM streams is a latency trick only. Vector-only second hops lowered recall [M], so show prefetched items only when $R$ asks for them.
3. **Fix the research code's hot spots.**
   - BM25 scoring loop to postings: 6.4–6.5 ms down to 0.03–0.04 ms at $10^4$ [M]. Same top-10 up to ties (agreement 0.988) [M], so this is a pure speed fix.
   - Full argsort to argpartition: 8.8 ms down to 0.14–0.18 ms at $10^5$ [M]. A pure speed fix, ties aside.
   - RRF over full lists to RRF over top-50 lists: 5.1–7.4 ms down to 0.02 ms [M]. **Not** a pure speed fix: it changes the ranking. Re-measure recall@10 against the full-list RRF that E1, E5 and E6 used before adopting it.
   - On iPhone, use SQLite FTS5 `bm25()` through GRDB rather than a custom index.
4. **Cache keys, and rebuild them only after a bundle change.** A read is then one scan. Re-key in place in chunks: 0.16 s at $10^5$ against 0.23–0.30 s in one shot [M]. If $g$ ships, cache child K/V: a path recompute takes 0.17–0.52 ms with the cache and 0.89–2.16 ms without [M].
5. **Store keys as int8 and re-rank the top 100 in fp32.** READ's path measured 0.40 ms at $10^4$ and 2.27 ms at $10^5$, with top-10 overlap 1.000 against fp32 [M]. Memory drops 4x. The raw int8 overlap (0.95–0.97) understates this. Skip 1-bit codes: overlap fell to 0.76 at $10^5$ even with a 200-item re-rank [M].
6. **Batch the read, stop and multi-query decisions into one pass over the keys.** With int8, the per-query cost falls about 2x at 4 queries and 4–5x at 16 [M]. With fp32, 16 queries in one pass cost 1.65–1.85 ms each against 6.8–7.1 ms for one GEMV, about 4x; 4 queries in one numpy pass gain nothing [M]. The stop head reuses scores already computed.
7. **Prune only with certified parents.** At levels whose leaves are scanned, score parents with $L_v$ (no parameters; E8). Prune only above $N_{\rm flat}$, and only if $F_b\ge0.95$ holds at the store's real $N$, measured nightly. Pick the top $b'$ level-1 parents globally rather than with a hierarchical beam.
8. **Add an ANN index only above about $2$–$3\times10^5$ leaves**, when an exact int8 scan would exceed about 5 ms on the phone [X], and only if it meets the same 0.95 bar.
   - At $10^6$, HNSW at ef = 128 measured 0.38–0.41 ms with overlap 0.92, which fails that bar [M].
   - Every re-key changes all keys and forces a rebuild: 37 s at $10^5$ and 480–501 s at $10^6$ on one thread, single runs [M]. Fast keys also drift between rebuilds.
   - At an assumed 50–100 items per day, a store holds about $0.9$–$1.8\times10^5$ leaves after five years [D: 50 × 365 × 5 = 91,250; 100 × 365 × 5 = 182,500]. So the flat path holds for years.
9. **Recompute parents incrementally by hash, and chunk any whole-tree pass by subtree.** At $10^6$ a one-shot pass took 19.0–28.4 s and a chunked pass 9.7 s, all single runs [M]. The draft's "35x the $10^5$ time for 10x the data" did not reproduce: the rerun gives 20x [M].
10. **No Core ML or ANE for the views and $g$ on the read path.** The state view takes 5–6 µs [M], and ANE dispatch would cost more [X]. It could help only a nightly whole-tree batch.
11. **No fused BM25 and dense kernel.** BM25 already takes 0.03–0.58 ms [M].

**Do not optimise yet.**
- ANN indexes, or IVF and PQ, at personal scale.
- GPU or ANE for scans and views.
- Fused kernels.
- 1-bit codes.
- An int8 encoder without calibration and a recall check.
- Multithreading the memory plane.
- Nightly training speed (seconds).
- In-model read serving (algorithm E), until stages A and B of §4.3 show quality gains on held-out benchmarks.

Spend the effort on hop policy, encoder placement, and a real-cite test of the online update. Descent fidelity is a quality problem, not a speed problem, and at personal scale it can be avoided by not pruning.

### Appendix 9.A: raw benchmark table

Both runs, on one x86 thread. Medians and p95 in ms; `runs` is the number of timed repetitions. "differs >30%" marks rows whose rerun median lies outside ±30% of run 1.

Notes.
- Keys are synthetic but shaped like real bge-small leaf vectors: a convex mix of two real LoCoMo turn vectors plus noise. Queries are real LoCoMo asks. "Overlap" means agreement with the exact fp32 top-10, not task recall. Synthetic keys understate descent fidelity (§9.2.2).
- In `b3_pyramid.py`, the clustered and random layouts bracket descent from the best and the worst side. `b3k_kmeans_tree.py` is the realistic middle.
- The `b7` "minus encoder" rows exclude the state view and the context fetch.
- In run 1, the run counts of `b2`, `b4` and `b2h` were rewritten after the runs, because a key collision in the first `Recorder` had stored the problem size in that field. The timings were untouched, and `common.py` is fixed. The rerun used the fixed code.
- hnswlib 0.8.0 was installed into a vendor folder only.
- The reviewer's side checks are not in this table: cold-cache scans, READ's int8 and re-rank path, the real-vector and within-persona trees, the chunked re-key, the indexed log purge, and the chunked $10^6$ whole tree (`s1_checks.py`, `s2_int8batch.py`, `s3_within_chat.py`). Their results are quoted in the text.

| script | what | run 1 median | run 1 p95 | rerun median | rerun p95 | runs | note |
|---|---|---:|---:|---:|---:|---:|---|
| b1_encoder.py | encode 1 ask, sentence-transformers end to end (13 tokens) | 26.00 | 34.48 | 30.38 | 35.51 | 100 |  |
| b1_encoder.py | encode 1 ask, rotating over 1531 LoCoMo asks (median ~10 words) | 26.08 | 33.68 | 25.97 | 39.25 | 300 |  |
| b1_encoder.py | tokenizer only, 1 ask | 0.1040 | 0.1624 | 0.0482 | 0.0715 | 200 | differs >30% |
| b1_encoder.py | transformer forward only, 1 sequence of 16 tokens | 23.60 | 29.22 | 23.74 | 30.58 | 40 |  |
| b1_encoder.py | transformer forward only, 1 sequence of 32 tokens | 23.60 | 30.02 | 30.38 | 31.51 | 40 |  |
| b1_encoder.py | transformer forward only, 1 sequence of 64 tokens | 42.43 | 44.48 | 44.39 | 64.34 | 40 |  |
| b1_encoder.py | transformer forward only, 1 sequence of 128 tokens | 70.65 | 79.70 | 70.62 | 88.49 | 40 |  |
| b1_encoder.py | transformer forward only, 1 sequence of 256 tokens | 130.30 | 153.36 | 125.01 | 142.26 | 15 |  |
| b1_encoder.py | transformer forward only, 1 sequence of 512 tokens | 257.65 | 263.29 | 257.23 | 319.63 | 15 |  |
| b1_encoder.py | encode 640 LoCoMo turns, batch 64 -> per leaf | 21.44 | 22.98 | 22.36 | 22.43 | 5 | per-leaf ms |
| b1_encoder.py | encode 1 LoCoMo turn unbatched (write path), rotating | 34.73 | 50.90 | 35.09 | 53.57 | 300 |  |
| b1_encoder.py | encode 1 ask, int8 dynamic-quantized Linear layers | 12.84 | 18.38 | 13.65 | 18.32 | 100 | mean cos to fp32 0.9701; top-10 overlap on chat 0 0.730 |
| b1_encoder.py | encode 640 turns batch 64, int8 dynamic -> per leaf | 12.02 | 12.72 | 12.21 | 13.43 | 5 | per-leaf ms |
| b1_encoder.py | encode 1 ask, bf16 autocast (AMX on this CPU) | 34.61 | 46.61 | 36.10 | 45.85 | 100 | mean cos to fp32 1.0000 |
| b1_encoder.py | encode 640 turns batch 64, bf16 autocast -> per leaf | 7.20 | 7.34 | 7.46 | 7.82 | 5 | per-leaf ms |
| b2_scoring.py | state head, low-rank r=16, 1 vector (numpy) + normalise | 0.0060 | 0.0065 | 0.0049 | 0.0053 | 2000 |  |
| b2_scoring.py | state head, full 384x384, 1 vector (numpy) + normalise | 0.0116 | 0.0138 | 0.0095 | 0.0115 | 2000 |  |
| b2_scoring.py | state head, low-rank r=16, 1 vector (torch eager) | 0.0130 | 0.0197 | 0.0095 | 0.0143 | 2000 | differs >30% |
| b2_scoring.py | action head, low-rank r=16, recompute N=1e+04 keys (after refit) | 14.05 | 14.26 | 12.47 | 14.11 | 30 |  |
| b2_scoring.py | action head, low-rank r=16, recompute N=1e+05 keys (after refit) | 296.48 | 339.95 | 232.01 | 298.01 | 10 |  |
| b2_scoring.py | score N=1e+03: fp32 GEMV numpy (OpenBLAS) | 0.0755 | 0.1365 | 0.0234 | 0.0485 | 400 | differs >30% |
| b2_scoring.py | score N=1e+03: fp32, 4 queries in one GEMM (batched reads) | 0.2189 | 0.2949 | 0.1199 | 0.1646 | 400 | differs >30% |
| b2_scoring.py | score N=1e+03: fp32 torch.mv | 0.1054 | 0.8041 | 0.0302 | 0.0476 | 400 | differs >30% |
| b2_scoring.py | score N=1e+03: fp16 torch.mv (CPU) | 0.3107 | 0.4301 | 0.1783 | 0.2335 | 400 | differs >30% |
| b2_scoring.py | score N=1e+03: bf16 torch.mv (CPU) | 0.0608 | 0.1506 | 0.0267 | 0.0423 | 400 | differs >30% |
| b2_scoring.py | score N=1e+03: int8 keys, fbgemm dynamic-quant Linear | 0.0774 | 0.1322 | 0.0228 | 0.0394 | 400 | top-10 overlap with fp32 0.964; differs >30% |
| b2_scoring.py | score N=1e+03: 1-bit codes popcount + fp32 rerank top-200 | 0.0696 | 0.1677 | 0.0500 | 0.0944 | 400 | top-10 overlap with fp32 0.982; differs >30% |
| b2_scoring.py | top-10 of N=1e+03: argpartition + sort k | 0.0092 | 0.0136 | 0.0068 | 0.0106 | 400 | differs >30% |
| b2_scoring.py | top-10 of N=1e+03: torch.topk | 0.0045 | 0.0066 | 0.0040 | 0.0063 | 400 |  |
| b2_scoring.py | top-100 of N=1e+03: argpartition + sort k | 0.0077 | 0.0131 | 0.0071 | 0.0121 | 400 |  |
| b2_scoring.py | top-100 of N=1e+03: torch.topk | 0.0033 | 0.0083 | 0.0042 | 0.0051 | 400 |  |
| b2_scoring.py | full argsort of N=1e+03 (what e5/e6 do today) | 0.0185 | 0.0240 | 0.0211 | 0.0387 | 100 |  |
| b2_scoring.py | score N=1e+04: fp32 GEMV numpy (OpenBLAS) | 0.7172 | 0.8435 | 0.6453 | 0.7297 | 400 |  |
| b2_scoring.py | score N=1e+04: fp32, 4 queries in one GEMM (batched reads) | 1.67 | 1.86 | 1.55 | 1.68 | 400 |  |
| b2_scoring.py | score N=1e+04: fp32 torch.mv | 0.7298 | 0.7936 | 0.7316 | 0.8305 | 400 |  |
| b2_scoring.py | score N=1e+04: fp16 torch.mv (CPU) | 1.70 | 3.48 | 1.22 | 1.83 | 400 | differs >30% |
| b2_scoring.py | score N=1e+04: bf16 torch.mv (CPU) | 0.5720 | 0.6341 | 0.5208 | 1.19 | 400 |  |
| b2_scoring.py | score N=1e+04: int8 keys, fbgemm dynamic-quant Linear | 0.2917 | 0.3575 | 0.2932 | 0.3893 | 400 | top-10 overlap with fp32 0.966 |
| b2_scoring.py | score N=1e+04: 1-bit codes popcount + fp32 rerank top-200 | 0.3201 | 0.3789 | 0.3853 | 0.6504 | 400 | top-10 overlap with fp32 0.884 |
| b2_scoring.py | top-10 of N=1e+04: argpartition + sort k | 0.0235 | 0.0317 | 0.0238 | 0.0311 | 400 |  |
| b2_scoring.py | top-10 of N=1e+04: torch.topk | 0.0203 | 0.0264 | 0.0203 | 0.0259 | 400 |  |
| b2_scoring.py | top-100 of N=1e+04: argpartition + sort k | 0.0238 | 0.0313 | 0.0241 | 0.0313 | 400 |  |
| b2_scoring.py | top-100 of N=1e+04: torch.topk | 0.0346 | 0.0485 | 0.0348 | 0.0491 | 400 |  |
| b2_scoring.py | full argsort of N=1e+04 (what e5/e6 do today) | 0.6547 | 0.6845 | 0.6599 | 0.6939 | 100 |  |
| b2_scoring.py | score N=1e+05: fp32 GEMV numpy (OpenBLAS) | 7.07 | 10.40 | 6.81 | 11.05 | 60 |  |
| b2_scoring.py | score N=1e+05: fp32, 4 queries in one GEMM (batched reads) | 26.97 | 36.72 | 24.56 | 29.79 | 60 |  |
| b2_scoring.py | score N=1e+05: fp32 torch.mv | 9.11 | 11.38 | 7.71 | 8.55 | 60 |  |
| b2_scoring.py | score N=1e+05: fp16 torch.mv (CPU) | 19.83 | 25.37 | 17.14 | 19.26 | 60 |  |
| b2_scoring.py | score N=1e+05: bf16 torch.mv (CPU) | 4.84 | 5.38 | 4.79 | 5.14 | 60 |  |
| b2_scoring.py | score N=1e+05: int8 keys, fbgemm dynamic-quant Linear | 1.91 | 1.98 | 1.93 | 2.25 | 60 | top-10 overlap with fp32 0.954 |
| b2_scoring.py | score N=1e+05: 1-bit codes popcount + fp32 rerank top-200 | 3.12 | 3.19 | 2.58 | 3.46 | 60 | top-10 overlap with fp32 0.756 |
| b2_scoring.py | top-10 of N=1e+05: argpartition + sort k | 0.1806 | 0.2183 | 0.1425 | 0.1791 | 60 |  |
| b2_scoring.py | top-10 of N=1e+05: torch.topk | 0.2345 | 0.2781 | 0.1741 | 0.2142 | 60 | differs >30% |
| b2_scoring.py | top-100 of N=1e+05: argpartition + sort k | 0.1787 | 0.2205 | 0.1354 | 0.1711 | 60 | differs >30% |
| b2_scoring.py | top-100 of N=1e+05: torch.topk | 0.2607 | 0.2939 | 0.2754 | 0.3494 | 60 |  |
| b2_scoring.py | full argsort of N=1e+05 (what e5/e6 do today) | 8.76 | 8.87 | 8.82 | 9.33 | 15 |  |
| b2_scoring.py | score N=1e+06: fp32 GEMV numpy (OpenBLAS) | 118.07 | 148.66 | 118.05 | 165.37 | 12 |  |
| b2_scoring.py | score N=1e+06: fp32, 4 queries in one GEMM (batched reads) | 285.23 | 353.55 | 281.26 | 335.41 | 12 |  |
| b2_scoring.py | score N=1e+06: fp32 torch.mv | 151.39 | 181.90 | 144.32 | 169.29 | 12 |  |
| b2_scoring.py | score N=1e+06: fp16 torch.mv (CPU) | 190.24 | 234.34 | 177.88 | 233.55 | 12 |  |
| b2_scoring.py | score N=1e+06: bf16 torch.mv (CPU) | 95.96 | 107.52 | 82.01 | 98.90 | 12 |  |
| b2_scoring.py | score N=1e+06: int8 keys, fbgemm dynamic-quant Linear | 35.81 | 36.47 | 37.38 | 43.56 | 12 |  |
| b2_scoring.py | score N=1e+06: 1-bit codes popcount + fp32 rerank top-200 | 46.15 | 56.92 | 44.68 | 48.95 | 12 |  |
| b2_scoring.py | top-10 of N=1e+06: argpartition + sort k | 3.39 | 3.59 | 2.97 | 3.38 | 12 |  |
| b2_scoring.py | top-10 of N=1e+06: torch.topk | 3.14 | 3.58 | 3.19 | 3.65 | 12 |  |
| b2_scoring.py | top-100 of N=1e+06: argpartition + sort k | 2.78 | 3.13 | 2.92 | 3.59 | 12 |  |
| b2_scoring.py | top-100 of N=1e+06: torch.topk | 3.30 | 3.33 | 3.22 | 3.58 | 12 |  |
| b2b_batch.py | N=1e+05, Q=1 queries in one pass, numpy K @ S.T | 13.56 | 21.01 | 12.87 | 26.03 | 40 | 13.56 ms per query |
| b2b_batch.py | N=1e+05, Q=1 queries in one pass, numpy S @ K.T | 10.21 | 15.21 | 9.07 | 13.06 | 40 | 10.21 ms per query |
| b2b_batch.py | N=1e+05, Q=1 queries in one pass, torch S @ K.T | 11.10 | 14.85 | 7.33 | 8.59 | 40 | 11.10 ms per query; differs >30% |
| b2b_batch.py | N=1e+05, Q=1 queries in one pass, int8 fbgemm | 2.28 | 2.42 | 1.86 | 2.51 | 40 | 2.28 ms per query |
| b2b_batch.py | N=1e+05, Q=4 queries in one pass, numpy K @ S.T | 27.05 | 40.01 | 24.56 | 36.15 | 40 | 6.76 ms per query |
| b2b_batch.py | N=1e+05, Q=4 queries in one pass, numpy S @ K.T | 32.80 | 39.55 | 33.97 | 41.83 | 40 | 8.20 ms per query |
| b2b_batch.py | N=1e+05, Q=4 queries in one pass, torch S @ K.T | 21.26 | 25.11 | 17.23 | 25.58 | 40 | 5.31 ms per query |
| b2b_batch.py | N=1e+05, Q=4 queries in one pass, int8 fbgemm | 2.45 | 2.57 | 4.49 | 5.94 | 40 | 0.61 ms per query; differs >30% |
| b2b_batch.py | N=1e+05, Q=16 queries in one pass, numpy K @ S.T | 33.60 | 39.75 | 33.72 | 38.04 | 40 | 2.10 ms per query |
| b2b_batch.py | N=1e+05, Q=16 queries in one pass, numpy S @ K.T | 42.04 | 47.60 | 32.76 | 52.24 | 40 | 2.63 ms per query |
| b2b_batch.py | N=1e+05, Q=16 queries in one pass, torch S @ K.T | 29.65 | 34.86 | 26.44 | 30.72 | 40 | 1.85 ms per query |
| b2b_batch.py | N=1e+05, Q=16 queries in one pass, int8 fbgemm | 4.40 | 5.49 | 6.38 | 7.98 | 40 | 0.28 ms per query; differs >30% |
| b2b_batch.py | N=1e+06, Q=1 queries in one pass, numpy K @ S.T | 126.42 | 132.97 | 124.67 | 133.11 | 8 | 126.42 ms per query |
| b2b_batch.py | N=1e+06, Q=1 queries in one pass, numpy S @ K.T | 115.82 | 149.82 | 123.88 | 149.75 | 8 | 115.82 ms per query |
| b2b_batch.py | N=1e+06, Q=1 queries in one pass, torch S @ K.T | 147.98 | 170.02 | 167.23 | 194.27 | 8 | 147.98 ms per query |
| b2b_batch.py | N=1e+06, Q=1 queries in one pass, int8 fbgemm | 35.59 | 37.11 | 34.12 | 37.89 | 8 | 35.59 ms per query |
| b2b_batch.py | N=1e+06, Q=4 queries in one pass, numpy K @ S.T | 278.06 | 300.09 | 285.38 | 353.59 | 8 | 69.52 ms per query |
| b2b_batch.py | N=1e+06, Q=4 queries in one pass, numpy S @ K.T | 331.97 | 399.13 | 321.38 | 377.57 | 8 | 82.99 ms per query |
| b2b_batch.py | N=1e+06, Q=4 queries in one pass, torch S @ K.T | 291.14 | 297.94 | 288.19 | 307.79 | 8 | 72.79 ms per query |
| b2b_batch.py | N=1e+06, Q=4 queries in one pass, int8 fbgemm | 65.69 | 73.31 | 63.36 | 64.06 | 8 | 16.42 ms per query |
| b2b_batch.py | N=1e+06, Q=16 queries in one pass, numpy K @ S.T | 279.22 | 383.53 | 315.89 | 362.59 | 8 | 17.45 ms per query |
| b2b_batch.py | N=1e+06, Q=16 queries in one pass, numpy S @ K.T | 411.46 | 418.89 | 423.98 | 460.63 | 8 | 25.72 ms per query |
| b2b_batch.py | N=1e+06, Q=16 queries in one pass, torch S @ K.T | 346.28 | 367.61 | 349.49 | 352.07 | 8 | 21.64 ms per query |
| b2b_batch.py | N=1e+06, Q=16 queries in one pass, int8 fbgemm | 137.82 | 154.47 | 144.07 | 168.34 | 8 | 8.61 ms per query |
| b2h_hnsw.py | HNSW build N=1e+04 (M=16, efC=100), whole index | 1,934 | 1,934 | 1,995 | 1,995 | 1 | 193 us per insert; single run: order of magnitude only |
| b2h_hnsw.py | HNSW query N=1e+04 ef=32, top-10 | 0.0854 | 0.1423 | 0.0635 | 0.1195 | 400 | top-10 overlap with exact 0.905; differs >30% |
| b2h_hnsw.py | HNSW query N=1e+04 ef=64, top-10 | 0.1299 | 0.2088 | 0.1214 | 0.1958 | 400 | top-10 overlap with exact 0.964 |
| b2h_hnsw.py | HNSW query N=1e+04 ef=128, top-10 | 0.2452 | 0.3569 | 0.2290 | 0.3017 | 400 | top-10 overlap with exact 0.985 |
| b2h_hnsw.py | HNSW build N=1e+05 (M=16, efC=100), whole index | 37,007 | 37,007 | 36,776 | 36,776 | 1 | 370 us per insert; single run: order of magnitude only |
| b2h_hnsw.py | HNSW query N=1e+05 ef=32, top-10 | 0.0900 | 0.1640 | 0.1099 | 0.2009 | 400 | top-10 overlap with exact 0.886 |
| b2h_hnsw.py | HNSW query N=1e+05 ef=64, top-10 | 0.1656 | 0.2389 | 0.1585 | 0.2570 | 400 | top-10 overlap with exact 0.948 |
| b2h_hnsw.py | HNSW query N=1e+05 ef=128, top-10 | 0.3171 | 0.4471 | 0.2909 | 0.4188 | 400 | top-10 overlap with exact 0.978 |
| b2h_hnsw.py | HNSW build N=1e+06 (M=16, efC=100), whole index | 501,310 | 501,310 | 480,174 | 480,174 | 1 | 501 us per insert; single run: order of magnitude only |
| b2h_hnsw.py | HNSW query N=1e+06 ef=32, top-10 | 0.1387 | 0.2470 | 0.1373 | 0.2536 | 400 | top-10 overlap with exact 0.721 |
| b2h_hnsw.py | HNSW query N=1e+06 ef=64, top-10 | 0.2171 | 0.3939 | 0.2303 | 0.3667 | 400 | top-10 overlap with exact 0.837 |
| b2h_hnsw.py | HNSW query N=1e+06 ef=128, top-10 | 0.4057 | 0.6173 | 0.3806 | 0.5963 | 400 | top-10 overlap with exact 0.924 |
| b3_pyramid.py | flat score + top-10, N=16^3=4096 | 0.2804 | 0.4198 | 0.2974 | 0.3695 | 300 |  |
| b3_pyramid.py | beam descent B=1, depth 3 (N=4096), 48 dot products | 0.0220 | 0.0439 | 0.0218 | 0.0404 | 1000 | overlap vs flat: clustered 1.00, random 0.02 |
| b3_pyramid.py | beam descent B=4, depth 3 (N=4096), 144 dot products | 0.0280 | 0.0635 | 0.0279 | 0.0437 | 1000 | overlap vs flat: clustered 1.00, random 0.07 |
| b3_pyramid.py | beam descent B=8, depth 3 (N=4096), 272 dot products | 0.0357 | 0.0599 | 0.0444 | 0.0744 | 1000 | overlap vs flat: clustered 1.00, random 0.12 |
| b3_pyramid.py | beam descent B=16, depth 3 (N=4096), 528 dot products | 0.0764 | 0.6994 | 0.0712 | 0.1291 | 1000 | overlap vs flat: clustered 1.00, random 0.24 |
| b3_pyramid.py | flat score + top-10, N=16^4=65536 | 4.54 | 7.27 | 4.57 | 6.68 | 300 |  |
| b3_pyramid.py | beam descent B=1, depth 4 (N=65536), 64 dot products | 0.0390 | 0.0999 | 0.0526 | 0.0969 | 1000 | overlap vs flat: clustered 0.99, random 0.00; differs >30% |
| b3_pyramid.py | beam descent B=4, depth 4 (N=65536), 208 dot products | 0.0530 | 0.0885 | 0.0759 | 0.1476 | 1000 | overlap vs flat: clustered 1.00, random 0.01; differs >30% |
| b3_pyramid.py | beam descent B=8, depth 4 (N=65536), 400 dot products | 0.0546 | 0.1075 | 0.0658 | 0.1039 | 1000 | overlap vs flat: clustered 1.00, random 0.02 |
| b3_pyramid.py | beam descent B=16, depth 4 (N=65536), 784 dot products | 0.1921 | 0.2955 | 0.1141 | 0.2182 | 1000 | overlap vs flat: clustered 1.00, random 0.04; differs >30% |
| b3_pyramid.py | flat score + top-10, N=16^5=1048576 | 135.53 | 160.47 | 143.32 | 165.20 | 15 |  |
| b3_pyramid.py | beam descent B=1, depth 5 (N=1048576), 80 dot products | 0.0817 | 0.1429 | 0.0531 | 0.0878 | 1000 | overlap vs flat: clustered 0.98, random 0.00; differs >30% |
| b3_pyramid.py | beam descent B=4, depth 5 (N=1048576), 272 dot products | 0.1039 | 0.1676 | 0.0720 | 0.1156 | 1000 | overlap vs flat: clustered 1.00, random 0.00; differs >30% |
| b3_pyramid.py | beam descent B=8, depth 5 (N=1048576), 528 dot products | 0.1305 | 0.2412 | 0.1011 | 0.5425 | 1000 | overlap vs flat: clustered 1.00, random 0.00 |
| b3_pyramid.py | beam descent B=16, depth 5 (N=1048576), 1040 dot products | 0.1695 | 0.2911 | 0.1700 | 0.2745 | 1000 | overlap vs flat: clustered 1.00, random 0.01 |
| b3k_kmeans_tree.py | beam descent B=1, depth 3 (N=4096), k-means tree, 48 dots | 0.0290 | 0.0449 | 0.0215 | 0.0295 | 500 | overlap vs flat 0.15; differs >30% |
| b3k_kmeans_tree.py | beam descent B=4, depth 3 (N=4096), k-means tree, 144 dots | 0.0366 | 0.0599 | 0.0272 | 0.0374 | 500 | overlap vs flat 0.40; differs >30% |
| b3k_kmeans_tree.py | beam descent B=8, depth 3 (N=4096), k-means tree, 272 dots | 0.0472 | 0.0782 | 0.0346 | 0.0578 | 500 | overlap vs flat 0.56; differs >30% |
| b3k_kmeans_tree.py | beam descent B=16, depth 3 (N=4096), k-means tree, 528 dots | 0.0711 | 0.1424 | 0.1183 | 0.1990 | 500 | overlap vs flat 0.71; differs >30% |
| b3k_kmeans_tree.py | beam descent B=32, depth 3 (N=4096), k-means tree, 784 dots | 0.1341 | 0.2136 | 0.2187 | 0.3481 | 500 | overlap vs flat 0.84; differs >30% |
| b3k_kmeans_tree.py | beam descent B=64, depth 3 (N=4096), k-means tree, 1296 dots | 0.3427 | 0.4110 | 0.4244 | 1.19 | 500 | overlap vs flat 0.94 |
| b3k_kmeans_tree.py | beam descent B=1, depth 4 (N=65536), k-means tree, 64 dots | 0.0402 | 0.0697 | 0.0404 | 0.0704 | 500 | overlap vs flat 0.16 |
| b3k_kmeans_tree.py | beam descent B=4, depth 4 (N=65536), k-means tree, 208 dots | 0.0386 | 0.0575 | 0.0543 | 0.1461 | 500 | overlap vs flat 0.39; differs >30% |
| b3k_kmeans_tree.py | beam descent B=8, depth 4 (N=65536), k-means tree, 400 dots | 0.0513 | 0.0799 | 0.0676 | 0.1312 | 500 | overlap vs flat 0.52; differs >30% |
| b3k_kmeans_tree.py | beam descent B=16, depth 4 (N=65536), k-means tree, 784 dots | 0.1838 | 0.2703 | 0.1165 | 0.2027 | 500 | overlap vs flat 0.64; differs >30% |
| b3k_kmeans_tree.py | beam descent B=32, depth 4 (N=65536), k-means tree, 1296 dots | 0.3024 | 0.3782 | 0.3296 | 0.5850 | 500 | overlap vs flat 0.76 |
| b3k_kmeans_tree.py | beam descent B=64, depth 4 (N=65536), k-means tree, 2320 dots | 0.7619 | 1.04 | 0.8867 | 1.03 | 500 | overlap vs flat 0.85 |
| b4_bm25.py | BM25 N=1e+03: e1-loop (score every doc in Python + full sort) | 0.5972 | 0.8393 | 0.9507 | 1.49 | 100 | differs >30% |
| b4_bm25.py | BM25 N=1e+03: postings + argpartition top-50 | 0.0167 | 0.0291 | 0.0418 | 0.0722 | 300 | differs >30% |
| b4_bm25.py | BM25 N=1e+03: scipy CSC column sum + top-50 | 0.0630 | 0.0869 | 0.0694 | 0.1440 | 300 |  |
| b4_bm25.py | BM25 N=1e+03: add + remove one leaf in postings (write/forget) | 0.0954 | 0.1183 | 0.1360 | 0.1938 | 200 | differs >30% |
| b4_bm25.py | BM25 N=1e+04: e1-loop (score every doc in Python + full sort) | 6.53 | 11.11 | 6.43 | 12.31 | 30 |  |
| b4_bm25.py | BM25 N=1e+04: postings + argpartition top-50 | 0.0389 | 0.0636 | 0.0317 | 0.0594 | 300 |  |
| b4_bm25.py | BM25 N=1e+04: scipy CSC column sum + top-50 | 0.1003 | 0.1348 | 0.0786 | 0.1185 | 300 |  |
| b4_bm25.py | BM25 N=1e+04: add + remove one leaf in postings (write/forget) | 0.1482 | 0.1800 | 0.1128 | 0.1473 | 200 | differs >30% |
| b4_bm25.py | RRF fuse two full rankings of N=1e4 (e1/e5 fuse today) | 7.37 | 13.21 | 5.06 | 5.88 | 50 | differs >30% |
| b4_bm25.py | RRF fuse two top-50 lists | 0.0240 | 0.0321 | 0.0198 | 0.0293 | 2000 |  |
| b4_bm25.py | BM25 N=1e+05: postings + argpartition top-50 | 0.3360 | 0.5299 | 0.5758 | 0.9660 | 300 | differs >30% |
| b4_bm25.py | BM25 N=1e+05: scipy CSC column sum + top-50 | 0.4470 | 0.9746 | 0.6342 | 1.17 | 300 | differs >30% |
| b4_bm25.py | BM25 N=1e+05: add + remove one leaf in postings (write/forget) | 0.5664 | 0.9209 | 0.5096 | 0.6772 | 200 |  |
| b5_internode.py | internode path recompute, depth 3, full 384x384, no cache | 1.22 | 1.68 | 0.8875 | 1.63 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 3, full 384x384, cached child K/V | 0.3319 | 0.5616 | 0.1728 | 0.2773 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 4, full 384x384, no cache | 1.70 | 2.43 | 1.15 | 1.76 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 4, full 384x384, cached child K/V | 0.2735 | 0.3715 | 0.2518 | 0.4816 | 300 |  |
| b5_internode.py | internode path recompute, depth 5, full 384x384, no cache | 1.54 | 1.89 | 2.16 | 3.05 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 5, full 384x384, cached child K/V | 0.5166 | 1.28 | 0.4784 | 0.7034 | 300 |  |
| b5_internode.py | internode whole-tree recompute N=1e+04, full 384x384, fp32 | 64.45 | 122.77 | 93.22 | 98.80 | 5 | differs >30% |
| b5_internode.py | internode whole-tree recompute N=1e+04, full 384x384, bf16 autocast | 40.65 | 41.71 | 45.52 | 49.26 | 5 |  |
| b5_internode.py | internode whole-tree recompute N=1e+05, full 384x384, fp32 | 794.03 | 1,214 | 946.01 | 969.62 | 3 |  |
| b5_internode.py | internode whole-tree recompute N=1e+05, full 384x384, bf16 autocast | 704.45 | 1,260 | 699.26 | 705.16 | 3 |  |
| b5_internode.py | internode whole-tree recompute N=1e+06, full 384x384, fp32 | 28,352 | 28,352 | 18,986 | 18,986 | 1 | differs >30%; single run: order of magnitude only |
| b5_internode.py | internode whole-tree recompute N=1e+06, full 384x384, bf16 autocast | 20,884 | 20,884 | 16,330 | 16,330 | 1 | single run: order of magnitude only |
| b5_internode.py | internode path recompute, depth 3, low-rank r=32, no cache | 0.5396 | 0.8260 | 0.4162 | 0.7012 | 300 |  |
| b5_internode.py | internode path recompute, depth 3, low-rank r=32, cached child K/V | 0.2794 | 0.4731 | 0.2164 | 0.4556 | 300 |  |
| b5_internode.py | internode path recompute, depth 4, low-rank r=32, no cache | 1.28 | 1.59 | 0.7973 | 1.71 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 4, low-rank r=32, cached child K/V | 0.9172 | 1.47 | 0.3270 | 1.17 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 5, low-rank r=32, no cache | 1.16 | 2.02 | 0.6410 | 0.8199 | 300 | differs >30% |
| b5_internode.py | internode path recompute, depth 5, low-rank r=32, cached child K/V | 0.5549 | 1.16 | 0.4567 | 0.7330 | 300 |  |
| b5_internode.py | internode whole-tree recompute N=1e+04, low-rank r=32, fp32 | 37.03 | 45.73 | 39.74 | 41.37 | 5 |  |
| b5_internode.py | internode whole-tree recompute N=1e+05, low-rank r=32, fp32 | 714.52 | 768.71 | 696.99 | 830.11 | 3 |  |
| b5_internode.py | internode whole-tree recompute N=1e+06, low-rank r=32, fp32 | 21,512 | 21,512 | 16,141 | 16,141 | 1 | differs >30%; single run: order of magnitude only |
| b6_train.py | online key update after one answer (3 cites, draft filter + anchored move; sequential rule) | 0.0335 | 0.0710 | 0.0240 | 0.0402 | 2000 | differs >30% |
| b6_train.py | nightly refit step, low-rank r=16, 64 asks x (64 in-batch + 10 hard + 1024 neg) | 10.80 | 11.46 | 10.65 | 16.42 | 50 | extrapolated [X]: 1e4 logged asks × 5 epochs about 8.4 s; rerun: 8.3 s |
| b6_train.py | nightly refit step, full 384x384, 64 asks x (64 in-batch + 10 hard + 1024 neg) | 14.67 | 26.68 | 15.29 | 34.75 | 50 | extrapolated [X]: 1e4 logged asks × 5 epochs about 11.5 s; rerun: 11.9 s |
| b6_train.py | E5 pretraining, one fold (8 LoCoMo chats ~4.7k nodes, 40 epochs, r=16) | 2,741 | 2,741 | 3,073 | 3,073 | 1 | single run: order of magnitude only |
| b6_train.py | replay eval gate: 500 asks x N=1e+04 keys, recall@10 | 57.28 | 79.63 | 44.89 | 47.38 | 20 |  |
| b6_train.py | replay eval gate: 500 asks x N=1e+05 keys, recall@10 | 673.41 | 2,644 | 771.34 | 1,338 | 5 |  |
| b7_paths.py | read hop, pyramid descent B=8, N=4096 | 24.80 | 31.65 | 22.30 | 32.67 | 100 |  |
| b7_paths.py | read hop, flat scoring, N=4096 | 24.73 | 31.30 | 26.98 | 36.08 | 100 |  |
| b7_paths.py | read hop minus encoder (descent + BM25 + RRF; excludes state head and context fetch), N=4096 | 0.1147 | 0.1660 | 0.1104 | 0.1754 | 500 |  |
| b7_paths.py | read hop minus encoder, flat, N=4096 | 0.4621 | 0.5245 | 0.4509 | 0.8170 | 300 |  |
| b7_paths.py | read-again loop, 2 hops, pyramid, N=4096 | 84.49 | 124.31 | 78.63 | 110.88 | 60 |  |
| b7_paths.py | read-again loop, 3 hops, pyramid, N=4096 | 137.96 | 208.61 | 135.33 | 181.05 | 60 |  |
| b7_paths.py | write path (encode + place + ancestors + dirty + BM25), N=4096 | 36.24 | 56.69 | 35.74 | 50.18 | 100 |  |
| b7_paths.py | write path minus encoder and BM25 (place + ancestors + dirty), N=4096 | 0.3381 | 0.4463 | 0.3960 | 0.6003 | 300 |  |
| b7_paths.py | forget path (tombstone + BM25 + ancestors + purge 1e4-entry log), N=4096 | 12.03 | 12.48 | 12.59 | 15.96 | 40 |  |
| b7_paths.py | read hop, pyramid descent B=8, N=65536 | 27.42 | 36.95 | 25.74 | 35.05 | 100 |  |
| b7_paths.py | read hop, flat scoring, N=65536 | 35.87 | 39.45 | 39.69 | 55.50 | 100 |  |
| b7_paths.py | read hop minus encoder (descent + BM25 + RRF; excludes state head and context fetch), N=65536 | 0.3489 | 0.5996 | 0.5124 | 0.6837 | 500 | differs >30% |
| b7_paths.py | read hop minus encoder, flat, N=65536 | 4.93 | 6.62 | 5.53 | 7.23 | 300 |  |
| b7_paths.py | read-again loop, 2 hops, pyramid, N=65536 | 76.24 | 105.55 | 80.18 | 105.90 | 60 |  |
| b7_paths.py | read-again loop, 3 hops, pyramid, N=65536 | 142.76 | 196.21 | 143.39 | 178.26 | 60 |  |
| b7_paths.py | write path (encode + place + ancestors + dirty + BM25), N=65536 | 38.73 | 59.21 | 40.20 | 55.29 | 100 |  |
| b7_paths.py | write path minus encoder and BM25 (place + ancestors + dirty), N=65536 | 0.5147 | 0.6767 | 0.5549 | 0.8835 | 300 |  |
| b7_paths.py | forget path (tombstone + BM25 + ancestors + purge 1e4-entry log), N=65536 | 16.52 | 24.60 | 13.23 | 15.50 | 40 |  |
