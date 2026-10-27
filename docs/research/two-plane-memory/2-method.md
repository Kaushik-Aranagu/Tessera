*Working paper, merged from three drafts and two audits (27 Oct 2026). Every number comes from the project brief, the drafts or the audits; each number names the script or study it came from. Nothing reported here was measured specifically for this document.*

**Claim labels.**
- **Definition**: fixes a term.
- **Proposition / Lemma**: proved here, by a full proof or a proof sketch that can be checked.
- **Remark (heuristic)**: an argument with an approximation in it. It is not a theorem.
- **Conjecture**: not proved.
- **Empirical result**: a measurement, given with its protocol.

**Statistics.**
- Unless stated otherwise, the metric is recall@10 of marked evidence turns on held-out LoCoMo chats: 5 folds, 8 training chats and 2 test chats per fold.
- LoCoMo yields 1,531 asks after parsing. The parser drops 5 asks whose evidence strings are malformed but recoverable (§8); a fixed parser gives 1,536. The effect on any mean is ≤0.003.
- LongMemEval-S results use the 428 of its 500 questions that have user-turn evidence (E7), scored with turn@10.
- Confidence intervals are 95% bootstrap intervals. Each CI is marked **[chat]** when chats are resampled. An unmarked CI resamples asks or visits as if they were independent, which is optimistic (§6.2, §8).

---

## 1 Problem and notation

### 1.1 Problem

A personal assistant has two planes:
- a **reasoning plane** $R$, which is an LLM;
- a **memory plane** $M$, which is a dynamic pyramid graph over everything the user has said or written.

Small learned **bridges** connect the two planes. Given an ask, the bridges must:
1. open the right nodes, at the right depth, within a budget, so that $R$ can answer;
2. place each new item in the graph;
3. reshape the graph over time: merge, split, collapse, rewrite, forget;
4. learn from use;
5. delete information exactly when the user asks.

The owner's requirements are:
- (i) a **common language**, so that the planes can react to each other in a coordinated and synchronised way;
- (ii) every component split into an **input front-end, a core and an output front-end**;
- (iii) every loss and every learning rule written as an explicit function whose behaviour can be analysed;
- (iv) a path toward training parts of the system **from scratch**.

**Measured starting point.** LoCoMo results are recall@10 on held-out chats; LongMemEval-S results are turn@10 with bridges trained on LoCoMo only.

| system | LoCoMo | LongMemEval-S (dense / hybrid with BM25) |
|---|---|---|
| BM25 | 0.563 | – |
| frozen encoder $f$ | 0.575 | 0.860 / 0.886 |
| full-rank bridges (Adam lr $10^{-3}$) | 0.610 | 0.822 / 0.881 |
| rank-16 bridges (Adam lr $10^{-3}$) | 0.657 | 0.864 / 0.891 |
| rank-16 + use-driven key updates, clean cites | 0.678 (+0.020; [+0.0146, +0.0267]; **[chat]** [+0.0092, +0.0300]) | – |
| … with 30% / 60% of cites wrong; with self-feedback | 0.654 / 0.634 / 0.634 | – |
| alias keys | 0.463 | – |
| parent = mean of its children (session routing) | 0.386 (BM25 session routing with hybrid inside: 0.649) | – |

The full-rank versus low-rank gap in this table is confounded by the learning rate (§6.6).

### 1.2 Notation (used throughout)

| Symbol | Meaning |
|---|---|
| $d=384$; $d_h=4096$; $r$ | dimension of the interface space; hidden width of the open LLM (Qwen3-8B, 36 layers); rank of a view |
| $\Sigma^{\ast}$; $\mathcal Z=\mathbb S^{d-1}$; $\mathrm n(x)=x/\lVert x\rVert$ | texts; the interface space (unit sphere); normalisation, which is also the Euclidean projection onto $\mathcal Z$ |
| $f:\Sigma^{\ast}\to\mathcal Z$ | frozen anchor encoder (bge-small-en-v1.5) |
| $G_\tau=(V_\tau,\mathcal E_\tau)$ | memory graph at version $\tau$ |
| $\mathrm{lev}(v)\in\{0..L\}$; $V^{(l)}$; $a_l(v)$ | level of node $v$ (0 is a leaf); the set of nodes at level $l$; the ancestor of leaf $v$ at level $l$ |
| $\mathcal C(v)$, $n_v$; $\mathrm{leaves}(v)$; $\mathcal N_{\rm rel}(v)$ | children and their number; leaves below $v$; lateral neighbours for relation $\mathrm{rel}\in\{\text{topic},\text{entity},\text{time}\}$ |
| $x_v$, $e_v=f(x_v)$ | node text (verbatim, or a gist) and its anchor vector |
| $q$; $x_q$, $e_q=f(x_q)$ | an ask, its text and its anchor vector |
| $P_q$, $N_q$, $n^+_q=\lvert P_q\rvert$ | evidence (positive) leaves, negatives, number of positives |
| $H_c=I+U_cB_c^\top$; $S$, $A$, $W$ | a view (with $U_c,B_c\in\mathbb R^{d\times r}$); the state, key and write views |
| $s=\mathrm n(Sz)$; $k^0_v=\mathrm n(Ae_v)$; $k_v$ | read state; base key; live key |
| $\phi_{v,i}$, $\Phi_v\in\mathcal Z^{m_f}$ | facets of an internal node, $i=1..m_f$ |
| $\alpha$ | logit scale (inverse temperature) |
| $\ell_{qv}=\alpha\langle s_q,k_v\rangle$; $\varsigma_v(q)=\langle k_v,s_q\rangle$ | logit; unscaled cosine score |
| $p_{qv}$, $p_t(v)$ | softmax over a candidate set or frontier |
| $Z^\pm_q=\sum_{v\in P_q/N_q}e^{\ell_{qv}}$ | positive and negative partition sums |
| $\mathrm{LSE}_\omega(\mathbf a)=\omega\log\sum_ie^{a_i/\omega}$; $\overline{\mathrm{LSE}}_\omega=\mathrm{LSE}_\omega-\omega\log\lvert\mathbf a\rvert$ | soft maximum (sum form, used throughout); its size-normalised (mean) form |
| $t=0..T$; $x^{\rm p}_t$; $z_t$; $F_t$, $O_t$ | reasoning step; probe text; anchor-view state; frontier and opened set |
| $C$, $C^\star$ | cites, accepted cites |
| $K=10$; $b_l$ | list size for recall; beam width at level $l$ |
| $\eta$; $\zeta$; $\nu$ | key step size; anchor cap; anchor weight (in units of cites) |
| $\bar s$, $\bar k$ | mean ask state and mean key of a chat |
| $p_{\rm w}$, $p^\star_{\rm w}$ | rate of wrong cites; break-even rate |
| $h$ | common-mode drift (§6.4) |
| $\mathbf h^{(j)}_t$; $j^\star$; $\mathbf h_t=\mathbf h^{(j^\star)}_t$ | open-LLM hidden state at layer $j$; tap layer; tapped state |
| $\Pi:\mathbb R^{d_h}\to\mathcal Z$; $\iota:\mathcal Z\to\mathbb R^{n_s\times d_h}$ | state projector; soft-token injector ($n_s$ tokens per vector) |
| $\psi_t$; $\mathrm{sig}$ | stop features; logistic sigmoid |
| $\lambda_{\cdot}$ | weight of a loss term (for example $\lambda_{\rm align}$, $\lambda_l$) |
| $\mu$ | a message (Definition 2.3) |
| $\mathsf G,\mathsf D,\mathsf C_+,\mathsf C_-$ | the recall-decomposition terms (Proposition 6.15) |

The code stores $\mathtt u\in\mathbb R^{d\times r}$ and $\mathtt v\in\mathbb R^{r\times d}$ and applies $I+\mathtt u\mathtt v$. So $U_c=\mathtt u$ and $B_c=\mathtt v^\top$. (Typewriter letters keep $u$ and $v$ free for nodes.)

---

## 2 Architecture

### 2.1 The two planes and the bridges

```
 user ─► R (LLM) ──state z_t (text-born or Π(h_t))──► read bridge ──► opened nodes ──► R
            ▲                                            │  ▲
            │ text / soft tokens ι(e)                    ▼  │ keys, facets (snapshot G_τ)
            └──────────── answer + cites ──► verifier ──► M (pyramid graph) ◄── write bridge ◄── new turn
                                                         ▲
                                       consolidation: reshape / distill / g / forget
```

### 2.2 The interface space $\mathcal Z$ (the common language)

**Definition 2.1 (interface space and anchor).**
- $\mathcal Z=\mathbb S^{d-1}$, with the Euclidean inner product.
- The anchor is $f$: bge-small-en-v1.5, with WordPiece tokens, 12 layers of width 384, CLS pooling and $\ell_2$ normalisation, about 33M parameters. $f(y)$ is by definition the canonical vector of the text $y$.

Every other vector in $\mathcal Z$ comes from one of three sources:
- (a) a near-identity *view* of the anchor;
- (b) a map trained against views or against the anchor ($g$, $\Pi$);
- (c) a rule that moves a vector toward another vector of $\mathcal Z$ (fast keys).

**Why the sphere, and why anchor it to $f$.**
- Scores are bounded, so one scale $\alpha$ sets the sharpness of every softmax.
- Key updates move along great-circle arcs.
- Norm hubs cannot occur. Angular hubs can (§6.5).
- A vector costs 768 B at fp16. Qwen3-8B's KV cache costs $36\cdot2\cdot8\cdot128\cdot2$ B = 147 KB per token.
- Content vectors, base keys and facets depend only on texts, so memory does not depend on the reasoning model. Fast keys depend on $R$ only through logged probe texts or anchor-view states $z_t$ (§2.5). So they can be recomputed when $R$ or the views change.

**Table 2.1: what lives in $\mathcal Z$.**

| object | definition | view | status |
|---|---|---|---|
| leaf / gist content | $e_v=f(x_v)$ | anchor | derived |
| base key | $k^0_v=\mathrm n(Ae_v)$ | $A$ | derived |
| live key | $k_v$ (use rule, §3.7) | $A$ | fast |
| facets | $\Phi_v=g(\cdot)$ | $A$ | derived |
| reasoning state | $z_t=f(x^{\rm p}_t)$ in instantiation (a); $\Pi(\mathbf h_t)$ in (b) (§2.6) | anchor | message |
| read state | $s_t=\mathrm n(Sz_t)$ | $S$ | message |
| content summary | $\hat c_t=\mathrm n\big(\sum_{v\in O_t}\tilde p_t(v)\,e_v\big)$ | anchor | message |
| key summary | $\hat k_t=\mathrm n\big(\sum_{v\in O_t\cap V^{(0)}}\tilde p_t(v)\,k_v\big)$ | $A$ | internal to the bridges |
| write query | $w_{\rm new}=\mathrm n(We_{\rm new})$ | $W$ | message |

Here $\tilde p_t$ is $p_t$ renormalised over $O_t$. An internal node contributes its gist vector $e_v$ to $\hat c_t$. $\hat k_t$ uses leaves only, because an internal node has facets and no single key.

**What does not live in $\mathcal Z$.**
- Control quantities are typed scalar or categorical fields of the message envelope: probabilities, depths, operation types, levels, times, counts, privacy and wall labels.
- Lexical evidence (BM25) is a second, symbolic channel. It is fused with dense ranks by $\mathrm{rrf}(v)=\sum_j1/(60+\mathrm{rank}_j(v))$.

**Definition 2.2 (view).** A view is $H_c=I+U_cB_c^\top$, acting as $z\mapsto\mathrm n(H_cz)$.
- At initialisation $U_c=0$ and $B_c$ is Gaussian with s.d. 0.01, so every view starts as the identity. An untrained bridge is exactly the frozen retriever.
- The read logit is $\ell_t(v)=\alpha\langle\mathrm n(Sz_t),k_v\rangle$.

**Design rule 2.1 (view discipline).**
- $S$-view states are scored only against $A$-view keys and facets.
- Anything written into memory as a key is first expressed in the $A$ view.
- Content sent to $R$ is the anchor content ($e_v$, $\hat c_t$, text), never a key.
- Every message carries its view tag.

Two current implementations break this rule:
- alias keys store $S$-view states as keys (§6.5);
- the move rule pulls an $A$-view key toward an $S$-view state (Prediction P2).

**A shared space is not a shared scale.** Proposition 6.18 shows that the read loss never calibrates ask-to-ask similarity against ask-to-key similarity. So any comparison *across* channels needs its own calibration step. Proposition 6.20 gives one, with a fire-rate guarantee that holds when the reference asks are exchangeable with new ones.

### 2.3 Messages, transparency and synchronisation

**Definition 2.3 (message).** A message is
$$\mu=(\text{channel},\ \text{view},\ t,\ \tau,\ Z_\mu\in\mathcal Z^{m_\mu},\ y_\mu\in\Sigma^{\ast},\ \mathrm{prov}_\mu,\ \mathrm{ctl}_\mu,\ \mathrm{ver}_\mu)$$
with these fields: channel; view tag; step $t$; graph version $\tau$; payload $Z_\mu$; text label $y_\mu$; provenance (node ids, versions, source leaves); typed control fields; and a hash of the producing module's parameters.

**Definition 2.4 (transparent coupling).** The coupling is transparent when four conditions hold.

- **T1 (completeness).** Every influence between $R$ and $M$ passes through a logged message.
- **T2 (decodability).** Every payload has a label and a logged fidelity.
  - The fidelity is $\mathrm{fid}(z,y)=\langle z,\mathrm n(H_cf(y))\rangle$ in view $c$, or $\langle z,f(y)\rangle$ in the anchor view.
  - A vector without a label is decoded by $D_{\rm nn}(z)=\arg\max_{y\in\mathfrak B}\langle z,f(y)\rangle$ over a bank $\mathfrak B$ of node texts and probes, or by a trained inverter.
- **T3 (replayability).** Every decision is a deterministic function of the logged messages, $G_\tau$ and the parameters.
- **T4 (attributability).** Every read logit is logged together with its exact parts:
$$\frac{\ell_t(v)}{\alpha}=\underbrace{\langle s_t,k^0_v\rangle}_{\text{bridge}}+\underbrace{\langle s_t,k_v-k^0_v\rangle}_{\text{use}},\qquad \langle s_t,k^0_v\rangle=\frac{z_t^\top e_v+z_t^\top\Delta_{SA}e_v}{\lVert Sz_t\rVert\,\lVert Ae_v\rVert}.$$
  Here $\Delta_{SA}=S^\top A-I$ (Proposition 6.1). Both norms are logged, together with the lexical and fused ranks. *(Correction: the anchor/learned split is exact only for the inner product before normalisation, so the norms must be logged as well.)*

**Definition 2.5 (snapshot protocol).**
1. Every read within ask $n$ uses the snapshot $G_{\tau(n)}$ committed before the ask started.
2. Writes, accepted cites and key updates from ask $n$ are buffered and committed atomically after the ask.
3. Consolidation runs between asks. Each commit carries a lineage map $\mathrm{lin}_\tau:V_\tau\to2^{V_{\tau+1}}$. A merge maps several nodes to one, a split maps one node to several, and a deletion maps a node to $\varnothing$.
4. A deletion takes priority over everything else. Its memory-state closure (§5.4) is committed before the next read.

   Trained parameters are a separate matter. Under the data policy of §4.2 they never contain personal data. Under the opt-in variant, they keep the deleted item's influence until the next retraining.

Under this protocol every read in an ask sees one consistent graph. Every logged reference $(v,\tau)$ resolves through the composed lineage maps.

### 2.4 Modules: input front-end, core, output front-end

Every module is written $\mathcal M=\mathsf{Out}\circ\mathsf{Core}\circ\mathsf{In}$. Only two cores carry pretrained competence: the LLM's transformer blocks (reasoning) and $f$ (the meaning of text). The memory plane's own core is the graph together with the internode encoder $g$. The bridges have thin cores, and all of their front-ends speak $\mathcal Z$.

| # | module | input front-end | core | output front-end | parameters |
|---|---|---|---|---|---|
| 1 | encoder $f$ | WordPiece ids, ≤512 | 12 blocks, width 384 | CLS pooling, then $\mathrm n$ | frozen |
| 2a | $R$, API model | prompt text | frozen LLM | text: a probe $x^{\rm p}_{t+1}$, or an answer with cites; state $z=f(x^{\rm p})$ | frozen |
| 2b | $R$, open model | token embeddings + soft tokens $\iota(\cdot)$ | 36 blocks + LoRA | LM head; state tap $\mathbf h_t$ at layer $j^\star$, then $\Pi$ | base frozen; LoRA, $\Pi$, $\iota$ trained |
| 3 | read bridge | $z_t$; frontier keys and facets; BM25 ranks | $S$ view; bilinear logits; per-level calibrated softmax; beam descent | opened nodes as text; $\hat c_t$ (and $\iota(e_v)$ in b) | $S,A$ trained; $\alpha$ fixed (§4.4); $k^0$ derived; $k$ fast |
| 4 | stop bridge | $\psi_t\in\mathbb R^7$ | logistic | stop / descend; an "insufficient" flag | trained |
| 5 | write bridge | $e_{\rm new}$; holders $\mathcal H$; near-duplicates $\mathcal U$ | $W$ view; softmax over a dynamic action set | an operation, link proposals, $k^0_{\rm new}$ | trained |
| 6 | reshape bridge | node geometry and usage counters | small MLP | proposals: keep / split / merge / collapse / rewrite | trained |
| 7 | forget bridge | metadata | logistic, plus fixed rules | keep / demote (soft forgetting only) | trained + fixed |
| 8 | internode encoder $g$ | child keys and facets; lateral facets | seeded set attention; lateral messages | $\Phi_v\in\mathcal Z^{m_f}$ | trained from scratch |
| 9 | gist distiller | children's texts | LLM | gist text, then $f$; coverage | frozen or LoRA |
| 10 | decoder $D$ | $z\in\mathcal Z$ | nearest neighbour or inverter | label and fidelity | none, or trained |

**Unified module specifications.**

**Read bridge (3).** For a frontier node $v$:
- if $v$ is a leaf, $\ell_t(v)=\alpha\langle s_t,k_v\rangle$;
- if $v$ is internal, $\ell_t(v)=\alpha\big(\mathrm{LSE}_\omega(\langle s_t,\phi_{v,1}\rangle,\dots,\langle s_t,\phi_{v,m_f}\rangle)-\beta_{\mathrm{lev}(v)}\big)$.

The offset $\beta_l$ is a per-level calibration, for example $\hat\sigma_l\xi_{m_f}+\omega\log m_f$, estimated from unrelated-node scores (Proposition 6.6).
- *Correction:* the frontier mixes levels, so the order-statistic lift of facet pooling does **not** cancel in one softmax. The alternatives are a per-level softmax, or scoring leaves in the same pooled form.

Descent works as follows:
- open the top $b$ nodes;
- replace each opened internal node by its children;
- repeat until the stop bridge says stop or only leaves remain;
- optionally fuse the result with BM25 by rrf.

**Stop bridge (4).** The feature vector is
$$\psi_t=\big(\langle s_t,\hat k_t\rangle,\ \max_{F_t\setminus O_t}\ell/\alpha,\ \text{gap}_t,\ \overline{\mathrm{Ent}}_t,\ \bar p_t,\ \mathrm{dep}_t/L,\ \mathbf 1[\text{a leaf was reached}]\big).$$
- $\text{gap}_t$ is the best unopened logit minus the worst opened logit, divided by $\alpha$.
- $\overline{\mathrm{Ent}}_t$ is the frontier entropy divided by $\log\lvert F_t\rvert$.
- $\bar p_t$ is the unopened mass.

The stop probability is $\pi^{\rm stop}_t=\mathrm{sig}(w_{\rm stop}^\top\psi_t+b_{\rm stop})$. With an open LLM, its answerability logit can be appended as an extra feature.

**Write bridge (5).** For a new leaf, the action set is
$$\mathcal A(x)=\{\mathrm{attach}(u)\}_{u\in\mathcal H}\cup\{\mathrm{new}(u)\}_{u\in\mathcal H}\cup\{\mathrm{merge}(v)\}_{v\in\mathcal U}\cup\{\mathrm{drop}\}.$$
- $\mathcal H$ holds the $n_{\mathcal H}$ level-1 nodes with the best facet scores, plus the current session node.
- $\mathcal U$ holds near-duplicate leaves.

The logits are:
- $\ell(\mathrm{attach}(u))=\alpha_W\max_i\langle w_{\rm new},\phi_{u,i}\rangle$;
- $\ell(\mathrm{new}(u))=\ell(\mathrm{attach}(u))+b_{\rm new}$;
- $\ell(\mathrm{merge}(v))=\alpha_W\langle w_{\rm new},k_v\rangle+b_{\rm merge}$;
- $\ell(\mathrm{drop})=b_{\rm drop}$.

Lateral link proposals come from timestamps (time), matched names (entity) and $\langle e_{\rm new},e_u\rangle\ge\kappa_{\rm topic}$ (topic). "Drop" is only for content-free turns. Privacy is never a learned write decision.

**Internode encoder (8).** The input is $X_v$: the keys $k_c$ of leaf children and the facets of internal children, all in the $A$ view. The facets are
$$\Phi_v=\mathrm n\Big(\mathrm{softmax}\big(Q_{\mathrm{lev}(v)}(X_vW_{g,K})^\top/\sqrt{d_k}\big)X_vH_{g,V}+\mathbf 1\,(W_{g,G}e_v)^\top\Big),$$
followed by $n_g$ rounds of lateral messages
$$\Phi_v\leftarrow\mathrm n\big(\Phi_v+\textstyle\sum_{\rm rel}\sum_{u\in\mathcal N_{\rm rel}(v)}a_{vu}\Phi_u\Gamma_{\rm rel}\big).$$
- $Q_l\in\mathbb R^{m_f\times d_k}$ are seed queries, with $d_k=64$ and $m_f=4$.
- $W_{g,K}\in\mathbb R^{d\times d_k}$.
- $H_{g,V}$, $W_{g,G}$ and $\Gamma_{\rm rel}$ are rank-16 maps (with $H_{g,V}=I+\cdot$).

The parameter count is about $7.5\times10^4$, and it assumes these rank-16 maps. The mean of the children is the special case $W_{g,K}=0$, $H_{g,V}=I$, $W_{g,G}=0$, $m_f=1$. Stored facets use $n_g=0$; lateral propagation happens at read time (§5.3).

**Forget bridge (7).** Its output is monotone (keep ≺ demote), and it never lowers a node's restriction. *Hard deletion is fixed code, never learned* (§5.4).

**Decoder (10).** Vectors can be inverted (vec2text-style attacks). So a vector in $\mathcal Z$ is personal data, and deletion covers vectors as well as texts.

### 2.5 Channel tables

**Read (one ask $n$, step $t$).**

| # | from → to | payload | when |
|---|---|---|---|
| R1 | user → $R$ | ask text | start of the ask |
| R2 | $R$ → read bridge | $z_t$ (anchor view) and its label $x^{\rm p}_t$ | every step |
| R3 | $G_{\tau(n)}$ → read bridge | frontier ids, keys or facets, levels, BM25 ranks | every expansion |
| R4/R5 | read ↔ stop bridge | $\psi_t$ / stop or descend with $\pi^{\rm stop}_t$ | every expansion |
| R6 | read bridge → $R$ | opened nodes as text, with probabilities and score parts; in (b) also $\iota(e_v)$ or $\iota(\hat c_t)$ | end of the read |
| R7 | $R$ → R2 | the next probe | if $R$ reads again |
| R8 | $R$ → user and verifier | answer $y$ and cites $(v,\tau)$ | end of the ask |

**Write.**

| # | from → to | payload | when |
|---|---|---|---|
| W1 | turn → $f$ | text | after each turn |
| W2 | $f$ → write bridge | $e_{\rm new}$ | after W1 |
| W3 | write bridge → $M$ | operation, links, $k^0_{\rm new}$ | committed after the ask |
| W4 | $M$ → distiller and $g$ | ancestors that are now stale | consolidation |

**Learning.**

| # | from → to | payload | when |
|---|---|---|---|
| L1 | verifier → $M$ | accepted cites $C^\star$, each with its **anchor-view state $z_t$ and probe text** (not $s_t$) | after the answer |
| L2 | use rule → $k_v$ | appended to $v$'s cite log; $k_v$ is a function of the log (§3.7) | committed after the ask |
| L3 | log → trainer | $(z_t,C^\star,O_t\setminus C,F_t)$ (negatives exclude every raw cite, as in algorithms C and D) | nightly, variant (B) only (§4.2) |
| L4 | trainer → bridges | new parameters, retrained from a fixed seed | nightly, variant (B) only |
| L5 | bridges → $M$ | recompute $k^0$ and $\Phi$; rebuild fast keys from their logs with the **current** $S$ | after any parameter change |
| L6 | trainer → $R$ (b) | LoRA, $\Pi$, $\iota$ | offline, public and synthetic data only |

**Maintenance.**

| # | from → to | payload |
|---|---|---|
| M1/M2 | $M$ ↔ reshape bridge | features / proposals (between asks) |
| M3/M4 | $M$ ↔ distiller | children's texts / gist, $e_v$, coverage |
| M5 | $M$ → $g$ | recompute $\Phi$ bottom-up along the dirty set |
| M6 | user → $M$ | delete, with its closure (takes priority) |
| M7 | $M$ → log | version $\tau+1$ and $\mathrm{lin}_\tau$ |

### 2.6 Two instantiations

**(a) Frozen API model: the LLM speaks text.**
- $z_t=f(x^{\rm p}_t)$, so every message from $R$ to $M$ is text-born and has fidelity exactly 1.
- No gradient passes through $R$. The only supervision $R$ provides is the discrete set of cites.

**(b) Open model trained jointly.**

The maps are
$$\Pi(\mathbf h)=\mathrm n\big(W_{\Pi,2}\,\mathrm{GELU}(W_{\Pi,1}\mathrm{LN}(\mathbf h))\big),\qquad\iota(z)=\mathrm{reshape}_{n_s\times d_h}\big(W_{\iota,2}\,\mathrm{GELU}(W_{\iota,1}z)\big),$$
with hidden width $d_p=1024$ (the output size of $W_{\Pi,1}$ and $W_{\iota,1}$). $\Pi$ has about 4.6M parameters. $\iota$ has about 4.6M at $n_s=1$ and grows by about 4.2M per extra soft token.

**Alignment choice, the same in every section:** $\Pi$ is aligned to the **anchor view** $f(x^{\rm p}_t)$. The read state is then $s_t=\mathrm n(S\,\Pi(\mathbf h_t))$, so the state view is applied once. This keeps memory independent of the model and lets the bridges trained in (a) be reused (Prediction P11).

$R$ still emits the probe text alongside the tap, so T2 holds.

**Definition 2.6 (shared language at level $\varepsilon$).** On a message distribution $\mathcal D$, the planes share a language at level $\varepsilon$ when both round trips are close to the identity:
$$\mathbb E_{z\sim\mathcal D}\langle z,f(D_\iota(z))\rangle\ge1-\varepsilon\qquad\text{and}\qquad\mathbb E_{z\sim\mathcal D}\langle z,\Pi(\mathbf h^{\rm probe}(\iota(z)))\rangle\ge1-\varepsilon.$$
- $D_\iota(z)$ is the text $R$ generates from the soft tokens $\iota(z)$.
- The second round trip is optimised directly by $\mathcal L_{\rm rt}$ (§3.8).
- The first goes through discrete decoding. Training reaches it only through the proxies $\mathcal L_{\rm recon}$ and $\mathcal L_{\rm kd}$, so it is only measured, not optimised.

---

## 3 Objectives

### 3.1 Read bridge with evidence sets

The candidates $F_q$ are all of the chat's leaves (or the current frontier). The probability is $p_{qv}=\mathrm{softmax}_{v\in F_q}\ell_{qv}$. There are three standard losses:
$$\mathcal L_{\rm out}(q)=-\tfrac1{n^+_q}\textstyle\sum_{p\in P_q}\log p_{qp},\qquad\mathcal L_{\rm in}(q)=-\log\textstyle\sum_{p\in P_q}p_{qp},\qquad\mathcal L_{\rm mask}(q)=\tfrac1{n^+_q}\textstyle\sum_{p\in P_q}\log\big(1+\sum_{n\in N_q}e^{\ell_{qn}-\ell_{qp}}\big).$$
- $\mathcal L_{\rm out}$ is SupCon's $L_{out}$ (a uniform soft target).
- $\mathcal L_{\rm in}$ is SupCon's $L_{in}$, also called MIL-NCE.
- $\mathcal L_{\rm mask}$ is per-positive InfoNCE with the other positives removed from the denominator.

All three are equal when $n^+_q=1$.

Gradients with respect to the logits, writing $\hat p_{qp}=e^{\ell_{qp}}/(e^{\ell_{qp}}+Z^-_q)$:
- $\partial\mathcal L_{\rm out}/\partial\ell_{qv}=p_{qv}-\mathbf 1[v\in P_q]/n^+_q$.
- $\partial\mathcal L_{\rm in}/\partial\ell_{qv}=p_{qv}-\mathbf 1[v\in P_q]\,p_{qv}/\sum_{P_q}p$.
- $\partial\mathcal L_{\rm mask}/\partial\ell_{qp}=-(1-\hat p_{qp})/n^+_q$ for a positive, and $\partial\mathcal L_{\rm mask}/\partial\ell_{qn}=\frac1{n^+_q}\sum_{p}e^{\ell_{qn}}/(e^{\ell_{qp}}+Z^-_q)$ for a negative.

All of these were verified against autograd by both audits.

**The loss the current code optimises** (`e5_bridges.train()`, verified line by line and numerically to within $10^{-6}$). It works on one chat at a time, with asks $\mathcal Q$:
$$\mathcal L_{e5}=\frac1{\lvert\mathcal Q\rvert}\sum_{q}\mathcal L_{\rm out}(q)\;-\;\frac1{\lvert\mathcal V_{\rm cit}\rvert}\sum_{v\in\mathcal V_{\rm cit}}\sum_q\pi(q\mid v)\log\frac{e^{\ell_{qv}}}{\sum_{q'}e^{\ell_{q'v}}}\;+\;0.01\big(\lVert S-I\rVert_F^2+\lVert A-I\rVert_F^2\big).$$
- $\mathcal V_{\rm cit}$ is the set of cited columns. ($\mathcal J$ is kept for the objective of §4.3 and Proposition 6.25.)
- $\pi(q\mid v)=\big(\mathbf 1[v\in P_q]/n^+_q\big)\big/\textstyle\sum_{q'}\mathbf 1[v\in P_{q'}]/n^+_{q'}$.
- For low-rank views the penalty equals $\lVert U_SB_S^\top\rVert_F^2+\lVert U_AB_A^\top\rVert_F^2$.

Training settings:
- AdamW with lr $10^{-3}$ and weight decay 0;
- 40 epochs of one step per chat, so 320 steps per fold;
- $\alpha=e^{\tilde\alpha}$ with $\tilde\alpha_0=\log20$.

There is no bug. The backward term's gradient flows into **both** $k_v$ and $s_q$ (so it also trains $S$). With respect to the key it is
$$\nabla_{k_v}=-\tfrac{\alpha}{\lvert\mathcal V_{\rm cit}\rvert}\Big(\textstyle\sum_q\pi(q\mid v)s_q-\bar s_v\Big),\qquad\bar s_v=\textstyle\sum_q\mathrm{softmax}_q(\ell_{qv})\,s_q,$$
which is a centring (anti-hub) direction.

**Recommended read loss.** Use $\mathcal L_{\rm mask}$ in the ask-to-node direction only, averaged per ask, with $\alpha$ fixed (§4.4).
- Remove teacher-marked equivalents from $N_q$, or use a debiased denominator, because $\mathcal L_{\rm mask}$ pushes false negatives harder than $\mathcal L_{\rm out}$ does.
- Use $\mathcal L_{\rm in}$ only for noisy positive sets where any one element suffices.

### 3.2 Read-again (multi-hop) residual loss

At hop $t$ the positives are the residual evidence $R_t=P_q\setminus O_{<t}$. Already-opened nodes are removed from both sides:
$$\mathcal L_{\rm hop}(q)=\sum_{t=0}^{T-1}\frac{\mathbf 1[R_t\neq\varnothing]}{\lvert R_t\rvert}\sum_{p\in R_t}\log\Big(1+\sum_{n\in F_q\setminus(P_q\cup O_{<t})}e^{\ell(z_t,n)-\ell(z_t,p)}\Big).$$
In (a) every hop is trained on the trajectory the system actually ran (on-policy, as in DAgger), and no gradient flows between hops.

### 3.3 Hierarchy: level-wise loss and label-free distillation for $g$

The level-$l$ positives are $P^{(l)}_q=\{a_l(v):v\in P_q\}$, with $n^{+(l)}_q=\lvert P^{(l)}_q\rvert$. The loss is
$$\mathcal L_{\rm hier}(q)=\sum_{l=0}^L\lambda_l\frac1{n^+_q}\sum_{v\in P_q}\log\Big(1+\sum_{u\in V^{(l)}\setminus P^{(l)}_q}e^{\ell_{qu}-\ell_{q\,a_l(v)}}\Big).$$
The weights $\lambda_l=1/\log(2+b_l-n^{+(l)}_q)$ come from Proposition 6.9.

**Label-free soft-OR distillation:**
$$\mathcal L_{\rm or}=\mathbb E_{s\sim\mathcal D_s}\sum_u\Big(\mathrm{LSE}_{\omega_p}\big(\langle s,\phi_{u,i}\rangle\big)_{i\le m_f}-\mathrm{sg}\big[\mathrm{LSE}_\omega(\langle s,k_v\rangle)_{v\in\mathrm{leaves}(u)}\big]-c_u\Big)^2,$$
where $\mathrm{sg}$ is stop-gradient and $\mathcal D_s$ is any distribution of past ask states.

**Normalisation (correction).** The sum-form target carries a subtree-size term $\omega\log\lvert\mathrm{leaves}(u)\rvert$:
- this term is 0.135–0.176 for sessions of 15–33.5 turns at $\omega=0.05$;
- the prototype side carries $\omega_p\log m_f$;
- the residual varies by about 0.04 across sessions, comparable to the cross-session score spread of 0.025–0.062.

Two settings of $c_u$:
- $c_u=0$ keeps a size prior: large parents are favoured, which is a hub bias.
- $c_u=\omega\log\lvert\mathrm{leaves}(u)\rvert-\omega_p\log m_f$ fits the size-normalised form.

The trade-off is in Proposition 6.8: the sum form composes across levels with no weights, and the normalised form composes with size weights. The measurements in §6.3 used $c_u=0$.

### 3.4 Stop

The label is $y_t=\mathbf 1[P_q\subseteq O_{\le t}]$, or, with a teacher, "$R$ answers correctly from $O_{\le t}$". The loss is
$$\mathcal L_{\rm stop}=-\frac1T\sum_t\big[y_t\log\pi^{\rm stop}_t+(1-y_t)\log(1-\pi^{\rm stop}_t)\big].$$
- Log loss is strictly proper. Calibrate the stop head with a temperature fitted on held-out asks, and report ECE and Brier score.
- **Decision rule.** One-stage look-ahead stops when $(1-\pi_t)C_{\rm miss}\le C_{\rm open}+\mathbb E[1-\pi_{t+1}\mid\psi_t]C_{\rm miss}$. If one more hop is assumed to complete the evidence, this becomes: stop iff $\pi_t\ge1-C_{\rm open}/C_{\rm miss}$.
- One-stage look-ahead is optimal only for monotone stopping problems (Chow, Robbins and Siegmund 1971).

### 3.5 Write

The policy is $\pi_W(a\mid x,G)=\mathrm{softmax}_{a\in\mathcal A(x)}\ell(a)$. It is trained by imitation of teacher labels $a^\star$, either with $-\log\pi_W(a^\star)$ or with the cost-sensitive loss $\sum_a\pi_W(a)\,C(a,a^\star)$, using $C(\mathrm{drop},a^\star)\gg C(\mathrm{attach},a^\star)$ because dropping cannot be undone.

### 3.6 Reshape and forget as policies

The reward is
$$r_t=\frac1{\lvert\mathcal Q^+_t\rvert}\sum_{q\in\mathcal Q^+_t}\big[\mathrm R@K(q;G_{t+1})-c_{\rm open}\,\mathrm{opens}(q;G_{t+1})\big]-c_{\rm size}\,\mathrm{size}(G_{t+1}).$$
The objective is $J=\mathbb E\sum_t\gamma^tr_t$, with REINFORCE gradient
$$\nabla J=\mathbb E\textstyle\sum_t\nabla\log\pi(a_t\mid G_t)(\hat R_t-b_t).$$
- **Assumption (exogenous asks):** future asks do not depend on the edit. Under it, the replay baseline $b_t=\hat R_t(\mathrm{noop})$ is valid.
- Retrieval is deterministic, so for one-step edits the gradient over all actions can be computed exactly by replay.
- **Recommended order:** first imitation of a teacher with DAgger; then exact replay (accept an edit only if its replayed reward beats noop); REINFORCE only for what replay cannot evaluate.
- IPS is undefined when the logging policy is deterministic.

### 3.7 Use-driven key learning

**Move rule.** $k_v\leftarrow\mathrm n(k_v+\eta(s-k_v))$. It is projected SGD on $1-\langle k_v,s\rangle$ (Proposition 6.12).

**Anchored rule** (as implemented in `e6_fixes.py`): move; then, if $\lVert k_v-k^0_v\rVert>\zeta$, set $k_v\leftarrow\mathrm n\big(k^0_v+\zeta(k_v-k^0_v)/\lVert k_v-k^0_v\rVert\big)$.

**Contrastive key loss** for one ask with opened set $O$, cites $C\subseteq O$, uncited set $U=O\setminus C$, and a bank $\mathcal B$ of past asks that **includes $s$**:
$$\mathcal L_{\rm key}(s)=\frac1{\lvert C\rvert}\sum_{v\in C}\log\Big(1+\sum_{u\in U}e^{\alpha\langle s,k_u\rangle-\alpha\langle s,k_v\rangle}\Big)-\frac1{\lvert C\rvert}\sum_{v\in C}\log\frac{e^{\alpha\langle s,k_v\rangle}}{\sum_{q'\in\mathcal B}e^{\alpha\langle s_{q'},k_v\rangle}}+\frac\nu2\sum_{v\in O}\lVert k_v-k^0_v\rVert^2.$$
Its gradients have three parts:
- a self-limiting pull, $(1-\hat p_v)\,s$;
- a push on hard uncited nodes, with weight $\chi_u=\frac1{\lvert C\rvert}\sum_{v\in C}e^{\alpha\langle s,k_u\rangle}/(e^{\alpha\langle s,k_v\rangle}+\sum_{U}e^{\cdot})$;
- a centring term toward $s-\bar s_v$.

These match autograd. The full $\mathcal L_{\rm key}$ has not been run.

**Keys as functions of a log (required for deletion and for retraining).** Each node stores an ordered cite log of anchor-view states $z$, or of the probe texts. Its key is a deterministic function of $(A,S,f,\text{log},\bar s_{\tau})$. The commutative form is
$$k_v=\mathrm n\Big(\nu\,k^0_v+\textstyle\sum_{t\in\mathcal T_v}\big(\mathrm n(Sz_t)-\bar s_\tau\big)-\beta_{\rm U}\sum_{t\in\mathcal U_v}\mathrm n(Sz_t)\Big).$$
- $\mathcal T_v$ are the citing asks, and $\mathcal U_v$ the asks that opened $v$ but did not cite it.
- $\bar s_\tau$ is the mean ask state, **frozen per committed version $\tau$**.
- The sum is recomputed from the log in a canonical order (§6.9).

### 3.8 Joint objective with an open LLM

$$\mathcal L=\mathcal L_{\rm LM}+\lambda_{\rm read}\mathcal L_{\rm hop}+\lambda_{\rm align}\mathcal L_{\rm align}+\lambda_{\rm hier}\mathcal L_{\rm hier}+\lambda_{\rm stop}\mathcal L_{\rm stop}+\lambda_{\rm recon}\mathcal L_{\rm recon}+\lambda_{\rm kd}\mathcal L_{\rm kd}+\lambda_{\rm rt}\mathcal L_{\rm rt}+\lambda_{\rm dist}\mathcal L_{\rm dist}+\mathcal R_{\rm reg}.$$

The terms:
- $\mathcal L_{\rm LM}=-\sum_j\log p_{\theta_0+\Delta\theta}(y_j\mid y_{<j},x,\mathrm{ctx}(O))$: the answer's log-likelihood.
- $\mathcal L_{\rm hop}$: the read loss of §3.2, with $s_t=\mathrm n(S\Pi(\mathbf h_t))$.
- $\mathcal L_{\rm align}$: symmetric InfoNCE between $\Pi(\mathbf h_i)$ and $f(x^{\rm p}_i)$ (the anchor view), over a batch of $N_b$ thoughts with logit scale $\alpha_a$:
$$\mathcal L_{\rm align}=\frac1{2N_b}\sum_i\Big[-\log\frac{e^{\alpha_a\langle\Pi(\mathbf h_i),f(x^{\rm p}_i)\rangle}}{\sum_je^{\alpha_a\langle\Pi(\mathbf h_i),f(x^{\rm p}_j)\rangle}}-\log\frac{e^{\alpha_a\langle\Pi(\mathbf h_i),f(x^{\rm p}_i)\rangle}}{\sum_je^{\alpha_a\langle\Pi(\mathbf h_j),f(x^{\rm p}_i)\rangle}}\Big].$$
- $\mathcal L_{\rm recon}=-\sum_v\sum_k\log p_R(x_{v,k}\mid\iota(e_v),\langle\text{verbalise}\rangle,x_{v,<k})$: makes $\iota$ a decoder of $\mathcal Z$ through $R$ (the xRAG reconstruction stage).
- $\mathcal L_{\rm kd}=\mathbb E_u\,\mathrm{KL}\big(\mathrm{sg}[p_\theta(\cdot\mid x_u,\text{probe})]\,\Vert\,p_\theta(\cdot\mid\iota(e_u),\text{probe})\big)$: next-token distillation from text to soft tokens. *(This was called $\mathcal L_{\rm cyc}$ in one draft. Renamed.)*
- $\mathcal L_{\rm rt}=\mathbb E_z\big[1-\langle z,\Pi(\mathbf h^{\rm probe}(\iota(z)))\rangle\big]$: the round trip of Definition 2.6. *(Also called $\mathcal L_{\rm cyc}$ in the other draft. Renamed.)*
- $\mathcal L_{\rm dist}=\mathrm{KL}\big(\mathrm{sg}[Q(\cdot\mid x,y)]\,\Vert\,p(\cdot\mid z_0)\big)$ over the retrieved candidates, where $Q(v)\propto p(v\mid z_0)\,p_\theta(y\mid x,v)$ is the exact E-step posterior.
  - Atlas's perplexity distillation is this posterior under a uniform prior over the retrieved set.
  - REPLUG's LSR target is $\mathrm{softmax}_v\big(p_\theta(y\mid x,v)/\beta\big)$, with the likelihood rather than the log-likelihood in the exponent (to be checked against the paper before submission).
- $\mathcal R_{\rm reg}=0.01\sum_c\lVert H_c-I\rVert_F^2$ plus weight decay on $\Delta\theta$, $\iota$ and $g$.

**Why $\mathcal L_{\rm dist}$ is an EM step.**
$$\log p(y\mid x)\ge\sum_vQ(v)\big[\log p(v\mid x)+\log p_\theta(y\mid x,v)\big]+H(Q),$$
with equality iff $Q$ is the posterior. Restricting the sum to the retrieved top-$b$ nodes biases the bound, as in REALM and Atlas.

**Gradient flow** (corrected; soft tokens carry content only).

| loss | $\Delta\theta$ (LoRA) | $\Pi$ | $S$, $A$ | $g$ | $\iota$ | $f$ |
|---|---|---|---|---|---|---|
| $\mathcal L_{\rm LM}$ | yes | no (selecting the top $b$ is discrete) | only through $\tilde p_t$ inside $\iota(\hat c_t)$, if $\hat c_t$ is fed | no | yes | no |
| $\mathcal L_{\rm hop}$ | yes, through $\mathbf h_t$ | yes | yes | if parents are candidates | no | no |
| $\mathcal L_{\rm dist}$ | yes, through $z_0$ | yes | yes | if parents are candidates | no | no |
| $\mathcal L_{\rm align}$ | yes | yes | no | no | no | no |
| $\mathcal L_{\rm hier}$, $\mathcal L_{\rm or}$ | through $z$ when states come from $R$ | yes | yes | yes | no | no |
| $\mathcal L_{\rm stop}$ | no (detached state) | no | no | no | no | no |
| $\mathcal L_{\rm recon}$, $\mathcal L_{\rm kd}$ | **no: explicit stop-gradient on $\Delta\theta$ in the student pass** | no | no | no | yes | no |
| $\mathcal L_{\rm rt}$ | no (stop-gradient) | yes | no | no | yes | no |

So $\Delta\theta$ is trained by $\mathcal L_{\rm LM}$, $\mathcal L_{\rm hop}$, $\mathcal L_{\rm dist}$, $\mathcal L_{\rm align}$ and, when states come from $R$, $\mathcal L_{\rm hier}$. *(Correction: an earlier draft claimed the read loss was the only path.)*

The stop-gradients on $\Delta\theta$ in $\mathcal L_{\rm recon}$, $\mathcal L_{\rm kd}$ and $\mathcal L_{\rm rt}$ are deliberate. They force $\iota$ to speak the base model's input language instead of letting the LoRA learn a private code.

**Calibration across channels.** Any score that compares ask-to-ask with ask-to-key similarity, for example an alias bonus, uses the calibrated form of Proposition 6.20.

*(Correction: an earlier claim that the uniformity term of $\mathcal L_{\rm align}$ removes the shared ask direction is withdrawn. $\mathcal L_{\rm align}$ contains no node key, and Proposition 6.18 shows the read loss is blind to that offset.)*

---

## 4 Training procedure

### 4.1 Parameter status

| part | status | origin | size |
|---|---|---|---|
| $f$ | frozen | pretrained | about 33M |
| $R$ | frozen; LoRA in (b) | pretrained | rank-16 LoRA on all attention projections: $36\cdot16\cdot(2\cdot8192+2\cdot5120)=15.3\,\mathrm M$ |
| views $S$, $A$, $W$ | trained, starting at the identity | from scratch | $2dr$ per view ($12{,}288$ at $r=16$; $768$ at $r=1$) |
| stop, write, forget heads | trained | from scratch | tens of parameters |
| reshape MLP | trained | from scratch | small |
| $g$ | trained | from scratch | about $7.5\times10^4$ |
| $\Pi$, $\iota$ | trained | from scratch | about 4.6M each |
| distiller | frozen, or LoRA | pretrained | – |
| fast keys | fast (functions of cite logs) | from use | $d$ per node |
| $k^0$, $\Phi$, gists, statistics ($\bar s_\tau$, $\bar k_\tau$, BM25, calibration levels) | derived | – | – |

### 4.2 Data policy (one policy, used throughout)

**(A) Default policy.** Every slow parameter is trained only on public or synthetic data: views, heads, $g$, $\Pi$, $\iota$, LoRA. Personal adaptation lives only in the **memory state**: structure, fast keys, per-user statistics such as $\bar s_\tau$, and calibration levels. Deletion from the memory state is exact up to selection effects (Proposition 6.23). The trained weights have exactly zero dependence on personal data (Proposition 6.24(a)).

The cost of this policy is that the bridges are not fitted to the user. The evidence suggests the transferable part is a per-corpus common-mode correction (§6.6). That correction can be implemented as a per-user statistic, which is deletable.

**(B) Opt-in variant.** The bridges are retrained nightly on the personal log, from a fixed initialisation and seed, with no warm start. The guarantee is then Proposition 6.24(b): exact retraining with a delay of at most one period, subject to the selection-effect caveat.

Channels L3 and L4 exist only under (B).

### 4.3 Schedule

- **Stage 0 (now, API model).** Train the views and heads on public chats with the recommended read loss (§3.1). Train $g$ as in algorithm B (§9.2.2): start from untrained k-means slots, train on $\mathcal L_{\rm tree}$ (which contains $\mathcal L_{\rm hier}$ and $\mathcal L_{\rm or}$) with the views frozen, then jointly, and ship it at a level only if it beats both parameter-free floors there. Fast keys learn from accepted cites.
- **Stage A (open model, LLM frozen).** Train $\Pi$ on $\mathcal L_{\rm align}$, and $\iota$ on $\mathcal L_{\rm recon}+\mathcal L_{\rm kd}$. Choose $j^\star$ on held-out $\mathcal L_{\rm align}$ (Conjecture C3).
- **Stage B.** Add the LoRA and train the joint loss of §3.8 on public and synthetic data only.
- **C-step / S-step alternation.** C-step: descend on the continuous parameters with the structure fixed, on a replay set $\mathcal D$. S-step: accept a structural edit only if it lowers $\mathcal J(G,\Theta)=\mathbb E_{\mathcal D}\mathcal L+c_{\rm size}\,\mathrm{size}(G)$ on the same $\mathcal D$ (Proposition 6.25).
- **Fast path, per ask.** Append to the cite logs, and recompute the affected keys.

### 4.4 Hyperparameters

- **$\alpha$ is effectively fixed.** Under Adam at lr $10^{-3}$, $\tilde\alpha$ moves at most about $10^{-3}$ per step. After 320 steps, $\alpha\in[14.5,27.5]$, and the measured final value is 24.46–24.63 in every fold.
  - The gradient asks for a larger $\alpha$ on 94% of steps at rank 16 and on 100% at full rank. With the heads held fixed, the loss-optimal value would be 28.2 (rank 16) or 36.5 (full rank).
  - Letting $\alpha$ learn fast (lr $3\times10^{-2}$) drives it to 49–55 and changes recall by −0.017 [−0.026, −0.008].
  - Fixing $\alpha=20$ changes recall by +0.004 [−0.001, +0.010].
  - **Decision:** treat $\alpha$ as a hyperparameter (for example 20). The slow drift of $\alpha$ acted as an implicit regulariser inside the reported 0.657.
- **No validation split exists.** The lr, epochs, rank, penalty 0.01, $\eta=0.1$ and $\zeta=0.3$ were fixed in code with only the test folds in view. **Decision:** select hyperparameters on a dev split carved out of the training chats, separately for each rank (§6.6).

### 4.5 What is trained from scratch, and why

The parts trained from scratch are the views, the heads, $g$, $\Pi$, $\iota$ and, later, a memory-native encoder $f_M$.
- Nothing pretrained exists for these jobs.
- Their inputs already live in $\mathcal Z$.
- Starting at the identity means "from scratch" does not mean "from noise". An untrained bridge equals the frozen retriever, and training adds a correction of rank at most $2r$ (Proposition 6.1).

Training $f$ or $R$ from scratch is out of scope. A good $f$ needs on the order of $10^8$ text pairs, and the LLM has 8B parameters.

There are two ways to keep $\mathcal Z$ stable while training $f_M$:
- an anchor term $\mathbb E_x[1-\langle f_M(x),f(x)\rangle]$, annealed as the task losses take over;
- migration: every message carries its text label (T2), so all derived vectors and cite logs can be re-encoded with $f_M$ and replayed (T3).

$f_M$ replaces $f$ only if it beats $f$ on held-out data.

---

## 5 Inference

### 5.1 Read loop (ask $n$, snapshot $G_{\tau(n)}$)

```
z_0 ← f(x_q) [a]  or  Π(h_0) [b]
for t = 0..T:
    s_t ← n(S z_t);  F ← top-level nodes (or the BM25-seeded frontier)
    repeat: score F (leaves by key; internal nodes by LSE over facets minus β_lev)
            open top b; replace opened internal nodes by their children
    until stop bridge says stop or F holds only leaves
    send opened nodes (texts, probabilities, score parts) and ĉ_t to R
    R answers (with cites) → exit,  or emits a probe x^p_{t+1} → z_{t+1}
```

**Cost per step**, for fan-in $\bar n$, depth $L$ and $m_f$ facets:
- $O(d\,r)$ to form $s_t$;
- $O(L\,b\,\bar n\,m_f\,d)$ inner products for the descent;
- versus $O(Nd)$ for a flat scan of $N$ leaves.

**Ceiling.** If the evidence spans more than $b_l$ parents at level $l$, no scorer can reach full recall (Proposition 6.9). So $b_l$ must adapt to the ask, and the read-again loop covers the rest.

### 5.2 Write path

```
e_new ← f(x)
H ← top n_H level-1 nodes by facet score, plus the current session node
U ← near-duplicate leaves
a ← argmax over A(x) of π_W
buffer the operation, its links and k⁰_new = n(A e_new);  commit after the ask
mark the ancestors dirty
```

Cost: $O(n_{\mathcal H}m_fd+\lvert\mathcal U\rvert d)$, plus one call to $f$: about 35 ms per leaf unbatched and 21 to 22 ms per leaf batched on one CPU thread (§9.4.2). The brief's figure of about 6 ms per turn assumes 4 cores.

### 5.3 Structural operations and recomputation

The dirty set $D(\mathcal X)$ of an edit that changes the node set $\mathcal X$ is the **closure of $\mathcal X$ under the dependency DAG**. That means:
- all ancestors;
- for a re-parent, the ancestors of both the old and the new parent;
- with $n_g\ge1$ lateral rounds, the lateral neighbourhoods, iterated to a fixed point.

*(Correction: the earlier formula $\mathrm{Anc}(N_{n_g}(\mathrm{Anc}(\mathcal X)))$ is not closed.)*

| change | recompute | cost |
|---|---|---|
| insert or delete a leaf | the root path | $O(\bar nC_g\log_{\bar n}N)$. Empirical (E8): 2.00 encoder calls per insert; keys identical to a batch build. |
| merge, split or re-parent | the new nodes plus the old and new ancestors | $O(\bar nC_g\log_{\bar n}N)$ |
| lateral rounds $n_g\ge1$ in stored states | the closure | up to $O(\Delta_{\rm lat}^{n_g}\log N)$, so stored states use $n_g=0$ |
| new weights for $g$ | all internal states | $O(\lvert V_{\rm int}\rvert\bar nC_g)$ |
| new $A$ | all leaf keys, **and every internal state built from them** | $O(Ndr)$ + one pass of $g$ |
| new $S$ | every fast key, rebuilt from its log | $O(\sum_vn_vdr)$ |
| new $f$ | re-encode all text | the only expensive case |

Empirical (E8): a full recompute took 127 ms for 5,882 leaf keys and 282 parents. Extrapolated, that is 6.9 s for 100k leaves and 20k nodes.

Content addressing makes the dirty set checkable: $\mathrm{hash}(v)=\mathrm{hash}(\mathrm{level},\ \text{weight version},\ \text{sorted child hashes})$.

### 5.4 Deletion procedure

To delete item $x$:
1. Remove $x$ and its **data-flow closure**: its vector; its cite-log entries, wherever $x$ was the citing ask; ancestor gists, which are regenerated from the surviving children without seeing the old gist; facets; sums such as $\bar s_\tau$, BM25 statistics and calibration levels; caches; and log records whose label or provenance contains $x$.
2. Handle its **selection closure**: records produced while $x$ was present and whose *selection* depended on $x$. These are opened sets and frontiers, probes $R$ wrote after reading $x$, and cites of other nodes in those asks. Policy: drop these records, or keep them and record a named residual influence (Proposition 6.23).
3. Re-evaluate the structural decisions that $x$ triggered, by replaying the operation log or by using a canonical structure.
4. Scrub storage: SQLite `secure_delete` or `VACUUM`, a WAL checkpoint, backups and exports.
5. Text already sent to a third-party API in instantiation (a) is outside the guarantee.

---

## 6 Analysis

### 6.1 Geometry of the views

**Proposition 6.1 (rank of the learned correction).** Let $S=I+U_SB_S^\top$ and $A=I+U_AB_A^\top$. Then
$$\Delta_{SA}=S^\top A-I=B_SU_S^\top+U_AB_A^\top+B_SU_S^\top U_AB_A^\top\quad\text{and}\quad\operatorname{rank}\Delta_{SA}\le2r.$$
*Proof.* The columns of $\Delta_{SA}$ lie in $\mathrm{span}(B_S)+\mathrm{span}(U_A)$. $\square$

- For $z$ orthogonal to the column space of $\Delta_{SA}$, the score before normalisation equals the frozen score.
- *Empirical:* for the trained rank-16 views, $\Delta_{SA}$ has exactly 32 non-zero singular values in each of the 5 folds.
- *Empirical (shared lr):* rank-16 views stay closer to the anchor than full-rank views. The mean cosine between a view and the anchor is 0.784 for asks and 0.653 for turns, against 0.676 and 0.553. A bridged key decodes to its own turn in 98.1% of cases (full rank 96.8%; anchor 99.97%). Both results are confounded by step size (§6.6).

### 6.2 Read losses

**Proposition 6.2 (the masked loss bounds the miss rate).** If $n^+_q\le K$, then
$$1-\mathrm R@K(q)\le\frac{\mathcal L_{\rm mask}(q)}{\log(2+K-n^+_q)}\le\frac{\mathcal L_{\rm out}(q)}{\log(2+K-n^+_q)}.$$
*Proof.* If positive $p$ is missed, at least $K-n^+_q+1$ negatives score at or above it, so its term is at least $\log(2+K-n^+_q)$. Average over the positives. The second inequality holds term by term. $\square$

Neither audit found a violation (20,000 random instances; the largest miss-to-bound ratio was 0.66–0.77).

**Proposition 6.3 ($\mathcal L_{\rm out}$ = ranking loss + equaliser).**
$$\mathcal L_{\rm out}=\mathcal L_{\rm mask}+\mathrm{Eq}_q,\qquad\mathrm{Eq}_q=\frac1{n^+_q}\sum_{p\in P_q}\log\frac{Z^+_q+Z^-_q}{e^{\ell_{qp}}+Z^-_q}\ge0.$$
As $Z^-_q/Z^+_q\to0$, $\mathrm{Eq}_q\to H(\mathrm{unif}(P_q),\mathrm{softmax}_{P_q}\ell_q)\ge\log n^+_q$. $\square$

- Recall does not care how the positives are ordered among themselves, so the equaliser spends gradient pulling the easiest positive down.
- *Correction:* the equaliser does **not** bound $\alpha$ in general. For $n^+_q=1$ (73% of asks), $\mathrm{Eq}_q=0$, and on a separable ask $\mathcal L_{\rm out}$ decreases strictly in $\alpha$. It bounds $\alpha$ only when some multi-positive asks have unequal positive cosines. In the runs, $\alpha$ was pinned by the step budget (§4.4).

**Empirical result 6.1 (read loss).** Rank-16 views, three seeds, 1,531 held-out asks, $\mathcal L_{e5}$ as the baseline.

| loss | all | $n^+\ge2$ (409) | multi-hop (281) | $n^+=1$ (1,122) |
|---|---|---|---|---|
| $\mathcal L_{e5}$ (bidirectional $\mathcal L_{\rm out}$) | 0.655 | 0.470 | 0.472 | 0.723 |
| $\mathcal L_{\rm out}$, forward only | 0.656 | 0.482 | 0.487 | 0.720 |
| $\mathcal L_{\rm in}$, bidirectional | 0.658 | 0.475 | 0.476 | 0.724 |
| $\mathcal L_{\rm mask}$, bidirectional | 0.657 | 0.474 | 0.479 | 0.724 |
| $\mathcal L_{\rm mask}$, forward only (recommended) | 0.657 | 0.487 | 0.492 | 0.719 |

Paired differences on the 409 asks with $n^+\ge2$:

| comparison | difference | ask-level CI | chat-clustered CI |
|---|---|---|---|
| recommended vs $\mathcal L_{e5}$ | +0.017 | [+0.006, +0.029] | **[chat]** [+0.001, +0.038] |
| drop the backward term | +0.012 | [+0.001, +0.024] | **[chat]** [−0.0017, +0.0295] |
| masking alone (forward only) | +0.0055 | [+0.0003, +0.0111] | **[chat]** [−0.0001, +0.0118] |

- Overall, the recommended loss changes recall by +0.002 [−0.006, +0.009].
- **Conclusion:** only the combined change is supported when CIs are clustered by chat. Neither component is significant on its own.

**Conjecture C1.** The backward term hurts multi-evidence asks because labels are incomplete in the ask direction: a turn is marked for only some of the asks it answers.

### 6.3 Parent representations

**Lemma 6.4 (norm of a mean).** For unit children with mean pairwise cosine $\bar\rho$,
$$\lVert\bar x\rVert^2=\frac1{n}+\Big(1-\frac1{n}\Big)\bar\rho.$$
*Empirical:* over 272 LoCoMo sessions (mean 21.6 turns), $\bar\rho=0.687$ and $\lVert\bar x\rVert=0.838$ in the frozen space, and 0.319 and 0.592 in the bridge space. The identity holds to $1.3\times10^{-7}$.

**Proposition 6.5 (one vector cannot be an OR).**
- (i) Let $d\ge2$, let a parent have children $c_1,c_2$, and let a competitor have one vector $b$, with $c_1-b$ and $c_2-b$ non-zero and not positive multiples of each other. Then no $k$ satisfies, for every $s\in\mathbb S^{d-1}$, $\langle k,s\rangle>\langle b,s\rangle\iff\max_i\langle c_i,s\rangle>\langle b,s\rangle$.
- (ii) For any $w$: $\sup_{\lVert s\rVert=1}\lvert\langle s,w\rangle-\max_c\langle s,k_c\rangle\rvert\ge\tfrac12\max_{c,c'}\lVert k_c-k_{c'}\rVert$.

*Proof.* (i) The right-hand side is a union of two distinct open hemispheres, whose measure exceeds 1/2, while the left-hand side is one hemisphere or empty. (ii) Take $s=\mathrm n(k_c-k_{c'})$ at the diameter; then $F(s)+F(-s)\ge\lVert k_c-k_{c'}\rVert$, while the linear part cancels. $\square$

- In high dimension, the OR region in (i) has measure $\tfrac12+\varphi/(2\pi)$, where $\varphi$ is the angle between $c_1-b$ and $c_2-b$. The referee measured 0.6598, against the exact value 0.6603.
- $m_f$ prototypes with covering radius $\delta$ under-score the max by at most $\delta$.

**Proposition 6.6 (order-statistic lift).** If an unrelated node's $m_f$ facet scores are i.i.d. $\mathcal N(c_0,\sigma^2)$, then
$$\mathbb E\max_i=c_0+\sigma\xi_{m_f},\qquad\xi_2=0.564,\ \xi_4=1.029,\ \xi_{16}=1.766,\ \xi_{64}=2.344,\qquad\xi_m\le\sqrt{2\ln m}.$$
The sum-form $\mathrm{LSE}_\omega$ adds up to a further $\omega\log m_f$.

- *Empirical:* frozen anchor, $\sigma\approx0.066$. The measured lift over $m$ random non-evidence turns is within 5% of $\sigma\xi_m$ for $m=2$–$64$ (ratio 0.957–0.992).
- The script `arch-latent/checks.py` compares against $\sigma\sqrt{2\ln m}$. The $\xi_m$ ratios were computed separately.
- Consequence: facet counts must be fixed for each level and kept small, and levels mixed in one frontier need the offset $\beta_l$ (§2.4).
- Alias sets break both conditions: their size grows with use.

**Proposition 6.7 (dilution and detail attenuation in mean pooling).** Model a child's score as $\langle s,x_i\rangle=\text{topic}_u+\varepsilon_i$, plus a boost $\Delta$ on one evidence child, with $\varepsilon_i$ of variance $\sigma^2$.
- The mean-pooled score keeps the topic and contributes $\Delta/n$ from the evidence child.
- Its detectability is therefore $d'_{\rm mean}=d'_{\rm leaf}/\sqrt n$.
- The max keeps $\Delta$ and pays an extreme-value lift of about $\sigma\sqrt{2\ln n}$.

Under a mean + topic + detail model with uncorrelated parts, parent keys crowd together:
$$\cos(\bar x_u,\bar x_{u'})\to\frac{\lVert\bar e\rVert^2}{\lVert\bar e\rVert^2+s_{\rm top}^2},$$
which exceeds the cosine between children of different parents. $\square$

Empirical:
- Parent-key cosines are 0.946 (frozen) and 0.756 (bridge). Turns of different sessions have 0.665 and 0.267. The model predicts 0.948 and 0.762.
- The evidence margin in mean pooling is 0.0075 against a cross-session spread of 0.025 (frozen), and 0.022 against 0.062 (bridge).
- In the bridge space, $d'_{\rm mean}/d'_{\rm leaf}$ falls from 0.68 to 0.48 as the evidence session grows from 15 to 33.5 turns (fit $n^{-0.43}$). Max/leaf stays at 0.91–1.00. In the frozen space the ratio is flat.
- BM25's term saturation and length normalisation dilute much less, though they do dilute. That is why BM25 session routing (0.649) beats mean-pooled vectors (0.386).

**Proposition 6.8 (soft OR across levels).**
- (i) $\max\le\mathrm{LSE}_\omega\le\max+\omega\log n$.
- (ii) The sum form composes without weights: $\mathrm{LSE}_\omega(\mathrm{LSE}_\omega(\text{leaves of }c))_{c\in\mathcal C(u)}=\mathrm{LSE}_\omega(\text{leaves of }u)$.
- (iii) The size-normalised form composes only with size weights:
$$\overline{\mathrm{LSE}}_\omega(u)=\omega\log\sum_{c}\frac{\lvert\mathrm{leaves}(c)\rvert}{\lvert\mathrm{leaves}(u)\rvert}\,e^{\overline{\mathrm{LSE}}_\omega(c)/\omega}.$$
  Without the weights it fails: the referee found 0.1126 against 0.1231 for unequal subtrees.

*Proof.* Expand the sums. $\square$

So the sum form carries a subtree-size prior of $\omega\log\lvert\mathrm{leaves}(u)\rvert$, and the normalised form removes it at the price of weighted composition. The $\omega\to\infty$ limit is the mean only for the normalised form.

**Empirical result 6.2 (session routing).** Sessions act as parents, on held-out chats; the score is the share of each ask's evidence sessions found in the top 3.

| parent score (LSE form) | vectors per parent | all | multi-hop |
|---|---|---|---|
| mean of children | 1 | 0.500 | 0.321 |
| one vector fitted to the soft OR (ridge, sum form, no labels) | 1 | 0.556 | 0.387 |
| k-means, $m_f=4$ / 8 (scored by sum-form LSE) | 4 / 8 | 0.571 / 0.641 | 0.381 / 0.448 |
| soft-OR-distilled, $m_f=4$ / 8 | 4 / 8 | 0.628 / 0.653 | 0.436 / 0.454 |
| max over children | $n_u$ | 0.707 | 0.489 |
| $\mathrm{LSE}_{0.05}$ over children (sum form) | $n_u$ | 0.724 | 0.513 |

These come from the bridge space, one seed, no intervals (`objectives/sessions*.py`). A second instance appears in `theory/pool.py`, which reports the share in the top 1 and uses the **normalised** form:
- bridge: mean 0.288, normalised LSE 0.520, max 0.512, BM25 0.570;
- frozen top 1: normalised LSE 0.459 against sum-form LSE 0.446 (`arch-latent`).

**These tables mix the two LSE forms and must be recomputed with one form (§8).**

**Proposition 6.9 (coverage bound).** Assume a strict tree, in which each leaf has exactly one ancestor per level. Let beam search keep the top $b_l$ nodes at each level, with $b_l\ge n^{+(l)}_q$ and $\lambda_l=1/\log(2+b_l-n^{+(l)}_q)$. Then
$$1-\mathrm R^{\rm tree}(q)\le\mathcal L_{\rm hier}(q).$$
*Proof.* If every ancestor of $v$ is in the global top $b_l$ of its level, then $v$ is retrieved (by induction from the root). Apply a union bound over levels and Proposition 6.2. $\square$

- The referee found no violation on 3,000 random three-level trees.
- **Ceiling:** 3.9% of all asks and 17.4% of multi-hop asks have evidence in more than 3 sessions. So any top-3 session router has coverage at most 0.986 (all asks) and 0.939 (multi-hop).

**Proposition 6.10 (the best query-independent pool).** Model a child's score as $b+\Delta\mathbf 1[i=J]+\varepsilon_i$ with $J\sim\pi$. For a pool $\sum_i\beta_ix_i$ with weights $\beta$ independent of $q$:
$$\mathbb E_J\Big[\frac{\beta_J\Delta}{\sigma\lVert\beta\rVert_2}\Big]\le\lVert\pi\rVert_2\frac{\Delta}{\sigma}\quad\text{(Cauchy–Schwarz)},$$
with equality iff $\beta\propto\pi$. If relevance is uniform over $n_{\rm eff}$ children (the support of $\pi$), the best possible gain over the mean is $\sqrt{n/n_{\rm eff}}$. $\square$

*Empirical:* a learned softmax pool, whose weight participation ratio is 0.44–0.54 (this is not the support of $\pi$), moves top-1 session share from 0.288 to 0.303 (bridge) and from 0.286 to 0.278 (frozen). There is no reliable gain. Only query-dependent pooling escapes the bound.

### 6.4 Use-driven key learning

**Lemma 6.11 (one move).** Let $k,s,q\in\mathcal Z$ with $c=\langle k,s\rangle>-1$, $a=\langle k,q\rangle$ and $\rho=\langle s,q\rangle$, and let $k'=\mathrm n((1-\eta)k+\eta s)$. Then
$$\langle k',q\rangle-a=\eta(\rho-ac)+\eta^2(1-c)\big(\rho-2a+\tfrac32a(1-c)\big)+O(\eta^3).$$
Also $\langle k',s\rangle\ge c$, and the first-order gain on $s$ itself is $\eta(1-c^2)$. $\square$

*Check:* over 20,000 triples at $\eta=0.1$, the mean error is $2.6\times10^{-3}$ at first order and $1.1\times10^{-4}$ at second order.

**Proposition 6.12 (the move rule is projected SGD; its fixed point).**
- (i) $\mathrm n(k+\eta(s-k))=\mathrm n\big(k-\eta\nabla_k\tfrac12\lVert k-s\rVert^2\big)=\mathrm n\big(k+\eta's\big)$ with $\eta'=\eta/(1-\eta)$. So the rule is projected SGD on $1-\langle k,s\rangle$.
- (ii) Over the sphere,
$$\arg\min_{\lVert k\rVert=1}\sum_t\tfrac12\lVert k-s_t\rVert^2+\tfrac\nu2\lVert k-k^0\rVert^2=\mathrm n\Big(\sum_ts_t+\nu k^0\Big).$$
  Here $\nu$ is the anchor weight in cite units, and the formula is the vMF posterior mode with $\nu=\kappa_0/\kappa$. The move rule reaches it exactly with steps $\eta_t=1/(1+\lVert u_t\rVert)$, where $u_t$ is the running sum.
- (iii) With a constant $\eta$, the content key keeps weight $(1-\eta)^n$ after $n$ cites, before normalisation.
- (iv) Unrolled: $k^{(J)}=\mathrm n(u^{(J)})$ with $u^{(j+1)}=(1-\eta)u^{(j)}+\eta\lVert u^{(j)}\rVert s^{(j+1)}$, so the result depends on the order of the cites.

*Proof.* Algebra, plus induction for (iv). $\square$

The referee verified the sum form of (ii) and the step rule. `objectives/checks.py` C5 tests only the expectation form, $\mathrm n(\bar s+(\nu/n)k^0)$.

For stationary citing asks with mean $m_v\ne0$, the fixed point of (iii) is $\mathrm n(m_v)$. Almost-sure convergence with Robbins–Monro steps needs, beyond Bonnabel's theorem, the antipodal stationary point to be unstable; that is stated here as an assumption.

**Proposition 6.13 (anchored rule: a fidelity bound).** Under the anchored rule with $\zeta<1$, every live key satisfies
$$\langle k_v,k^0_v\rangle\ge\sqrt{1-\zeta^2}\qquad(0.954\text{ for }\zeta=0.3),$$
equivalently $\lVert k_v-k^0_v\rVert\le2\sin(\tfrac12\arcsin\zeta)=0.30352$. $\square$

- The bound is attained in simulation: minimum 0.9539392014.
- *Correction:* the cap is applied before normalisation, so $\lVert k-k^0\rVert\le\zeta$ does **not** hold.
- This is a fidelity bound to the base key. It is not a decoding guarantee: nearest-neighbour decoding also needs a margin over other texts (frozen turn-to-turn cosine averages 0.663). The decode rate of live keys has not been measured.
- *Empirical, common random numbers, 8 noise seeds:* anchored minus move is +0.0009 ± 0.0006 at $p_{\rm w}=0.3$ and +0.0028 ± 0.0007 at $p_{\rm w}=0.6$. With clean cites both gain +0.020. The earlier 0.658 against 0.654 was mostly noise: one noise draw moves an arm's mean with s.d. 0.0035–0.0037.

**Common-mode drift.** Let $q$ be a later ask, independent of $s$. Then
$$\mathbb E_q[\Delta\varsigma_k(q)]\approx\eta h,\qquad h=\langle s,\bar s\rangle-c\langle k,\bar s\rangle.\tag{6.1}$$
- In the bridge space $\lVert\bar s\rVert=0.56$. The mean ask–ask cosine is 0.31 and the mean ask–node cosine is 0.10.
- Measured $\bar h=0.266$ for clean cites, and $-0.028$ with the centred target $\mathrm n(s-\bar s)$.
- *Correction:* the drift of a single update is small (about 0.03), but it accumulates into the dominant cost of noisy learning (below).

**Proposition 6.14 (margin of a re-ask).** Let $q$ share evidence $e$ with $s$. Assume $\rho\ge a_dc_d$ for wrong nodes $d$; the referee found this violated in 0.34% of random trials. Then, to first order,
$$\mathbb E[\Delta\mathrm{mg}_q(e)]=(1-p_{\rm w})\,\eta\,\mathbb E(\rho-a_ec_e)-p_{\rm w}\,\mathbb E[\Delta\vartheta_K],\qquad0\le\Delta\vartheta_K.$$
Here $\vartheta_K(q;e)$ is the $K$-th best score among the other nodes and $\mathrm{mg}_q(e)=\varsigma_e(q)-\vartheta_K(q;e)$. $\square$

*Empirical*, over 2,936 re-ask triples at $\eta=0.1$:
- $g_+=0.0441$ and $g_-=0.0011$, so the margin break-even is 0.976;
- direct competition on the re-ask cannot explain a break-even near 0.3.

**Proposition 6.15 (affine response; identification is conditional).** Assume:
- (A1) superposition: the effects of separate updates add;
- (A2) cite coins independent of the visit order and the keys.

Then
$$\Delta R(p_{\rm w})=(1-p_{\rm w})(\mathsf G-\mathsf C_+)-p_{\rm w}(\mathsf D+\mathsf C_-),\qquad p^\star_{\rm w}=\frac{\mathsf G-\mathsf C_+}{\mathsf G+\mathsf D+\mathsf C_--\mathsf C_+}.$$
- $\mathsf G$ is the re-ask gain from correct pulls and $\mathsf D$ the re-ask loss from wrong pulls.
- $\mathsf C_\pm$ is the common-mode loss **per visit, on every visit**, from correct ($+$) and wrong ($-$) pulls. All four are in units of $\Delta R$.

**Identifying assumption (untested):** the common-mode loss per visit is the same on re-ask visits (44.4% of visits) as on unrelated visits. Under it, the $p_{\rm w}=0$ and $p_{\rm w}=1$ arms identify all four terms.

| rule, $\eta$ | $\Delta R$ at $p_{\rm w}$ = 0 / .3 / .6 / 1 | $\mathsf G$ | $\mathsf D$ | $\mathsf C_+$ | $\mathsf C_-$ | $p^\star_{\rm w}$ (LS line / eq.) | $\mathsf G/(\mathsf G+\mathsf D)$ |
|---|---|---|---|---|---|---|---|
| move 0.02 | +.0060 / +.0011 / −.0024 / −.0085 | .0106 | .0031 | .0046 | .0054 | 0.41 / 0.41 | 0.77 |
| move 0.05 | +.0143 / +.0048 / −.0067 / −.0233 | .0266 | .0111 | .0123 | .0123 | 0.42 / 0.38 | 0.71 |
| move 0.1 | +.0204 / −.0029 / −.0232 / −.0636 | .0500 | .0175 | .0296 | .0462 | 0.27 / 0.24 | 0.74 |
| move 0.2 | −.0016 / −.0443 / −.0826 / −.1476 | .0859 | .0381 | .0876 | .1095 | none | 0.69 |
| centred 0.1 | +.0235 / +.0086 / −.0013 / −.0198 | .0317 | .0072 | .0082 | .0126 | 0.55 / 0.54 | 0.81 |

Findings:
- $\mathsf G/(\mathsf G+\mathsf D)$ stays at 0.69–0.81, while the common-mode terms pull $p^\star_{\rm w}$ down: $\mathsf C_+/\eta$ goes 0.23, 0.25, 0.30, 0.44 across $\eta$.
- Centring cuts $\mathsf C_+$ by 72% and costs 37% of $\mathsf G$.

Caveats (from the audit):
1. **Unexplained disagreement.** The margin analysis gives a direct-competition ratio of $g_-/g_+=0.025$; the decomposition gives $\mathsf D/\mathsf G=0.35$ at $\eta=0.1$. That is a 14-fold gap, and the identifying assumption is the prime suspect.
2. **$p^\star_{\rm w}$ has no CI and depends on the noise seed.** Changing only the coin seed moves the endpoint estimate from 0.414 to 0.38 at $\eta=0.02$ (s.d. of $\Delta R(1)$ is 0.0014).
3. **The interior fit misses at $\eta=0.1$.** Predicting $p_{\rm w}=0.6$ from the two endpoints misses by 0.0051 (referee replay) to 0.0068 (draft).
4. **$R^2$ is weak evidence.** It is 0.987–0.999, but on 3 points, so 1 degree of freedom.

**Remark 6.1 (heuristic: the hub cost is convex in $\eta$).** Suppose a node with $n_v$ cites rises by $\bar h\eta n_v/2$ on unrelated asks. With a Gaussian gap $g_{\rm gap}=0.253$ to the $K$-th place and spread 0.127, the intrusion probability is $\bar\Phi\big((g_{\rm gap}-\bar h\eta n_v/2)/0.127\big)$, where $\bar\Phi=1-\Phi$ is the upper tail of the standard normal.
- Predicted $\mathsf C_+$ ratios to $\eta=0.02$: 2.69, 6.08, 15.5 at $\eta=0.05$, 0.1, 0.2.
- Measured: 2.67, 6.43, 19.0. A linear cost would give 2.5, 5, 10.
- Reaching a typical top 10 takes about 19 cites at $\eta=0.1$ (95 at $\eta=0.02$). The cite counts are mean 1.65, 41% of nodes with at least 2 cites, maximum 7, so the cost comes from the tail.

**Empirical result 6.3 (only discoveries pay).** All runs at $\eta=0.1$.
- *Visible cites only* (clean cites restricted to evidence already in the top 10): $\Delta R=-0.0024$ [−0.007, +0.002]. Here $\mathsf G_{\rm vis}=0.0165$ against $\mathsf C_+=0.0189$ per visit.
- *Rank-gated rule* (move only cited nodes that ranked below $K$): clean gain +0.0183 [+0.013, +0.024], which keeps 90% of the gain. The common-mode loss carried by unrelated visits ($0.556\,\mathsf C_+$) falls from 0.0165 to 0.0063.
- *Far noise* (wrong cites drawn from ranks 11–50): the gated rule gives +0.0082 at $p_{\rm w}=0.3$ and −0.0008 at 0.6, a break-even near 0.57. The ungated rule's break-even under the same model is about 0.34.

**Proposition 6.16 (self-feedback loop).** Assume:
- (B1) each visit's top-1 node takes a move step;
- (B2) each win raises the node's mean score by $\eta h$;
- (B3) Gumbel competition with scale $\beta_{\rm G}$.

Then, while the win share $\varpi\ll1$,
$$\varpi(n)=\varpi^0e^{\kappa_{\rm fb}n},\qquad\kappa_{\rm fb}=\eta h/\beta_{\rm G},$$
and the win count diverges at $t^\star=\beta_{\rm G}/(\eta h\varpi^0)$. If $h\le0$, if the drift is capped, or if steps decay, there is no runaway. $\square$

Two **remarks**, stated without proof:
- If $h$ were constant, the process would be a Pólya urn with exponential reinforcement, and Rubin's embedding gives monopoly almost surely.
- In practice the loop saturates near ask-cluster centroids, as in online spherical k-means.

*Empirical*, using one $\varpi^0$ throughout (the mean of each chat's top 5 winners, 0.034), with $\beta_{\rm G}=0.048$ and $h=0.229$:
- **$\eta=0.1$:** predicted $t^\star=61$; a direct estimate gives 60. The leader's share rose from 0.047 to 0.24 within the first pass. The recall loss grew to −0.169 after 10 passes.
- **$\eta=0.02$:** predicted $t^\star=304$, against a direct estimate of 153, a 2-fold disagreement. Premise (B2) holds for only 34% of top winners here (92% at $\eta=0.1$).
- **Centred rule:** no take-off; the loss saturates at −0.037.
- **Cap 0.3:** the loss saturates at −0.075.

*Correction:* self-feedback is not "noise with $p_{\rm w}=1-P@1$". The predictions use the **realised** wrong-cite share of each run (0.652, 0.683, 0.748, 0.821 at $\eta=0.02$, 0.05, 0.1, 0.2), multiplied by the cite-count ratio 4,593/7,035, and they use the **LS line**:
- predicted −0.0022, −0.0061, −0.0225, −0.074;
- measured −0.0038, −0.0116, −0.0232, −0.042.

Proposition 6.15 with $\mathsf G,\mathsf D,\mathsf C$ gives −0.0277 at $\eta=0.1$.

### 6.5 Hubness and calibration across channels

**Lemma 6.17.** The mean ask–ask cosine over distinct pairs is $(n\lVert\bar s\rVert^2-1)/(n-1)$, and the mean ask–node cosine is $\langle\bar s,\bar k\rangle$. $\square$

Both identities are exact on the data.

| space | ask–ask (all / unrelated / sharing evidence) | ask–node | ask to its own evidence | 10th-best key | $\lVert\bar s\rVert$ | $\cos(\bar s,\bar k)$ |
|---|---|---|---|---|---|---|
| frozen | 0.548 / 0.546 / 0.717 | 0.530 | 0.679 | 0.668 | 0.742 | 0.877 |
| bridge | 0.311 / 0.308 / 0.575 | 0.100 | 0.396 | 0.350 | 0.560 | 0.339 |

(The ask-to-own-evidence cosine in the bridge space appears elsewhere as 0.379 in the alias study and 0.389 averaged over re-ask triples. The averaging units differ and must be fixed; see §8.)

**Proposition 6.18 (the read loss is blind to the ask–key offset).** Write $s_q=\bar s+\tilde s_q$ and $k_v=\bar k+\tilde k_v$.
- The forward softmax (over nodes) is invariant to row offsets.
- The backward softmax (over asks) is invariant to column offsets.
- Neither term ever compares an ask with an ask.

So $\langle\bar s,\bar k\rangle$ and the geometry of asks among themselves are unconstrained. $\square$

Training moved $\cos(\bar s,\bar k)$ from 0.877 to 0.339. **A shared space is not a shared scale.**

**Proposition 6.19 (alias entry rate).** An alias $a$ (an $S$-view ask state stored as a key) enters an unrelated ask's top $K$ with probability approximately
$$\mathbb E\,\bar\Phi\big((\vartheta_K-\rho_{ss})/\sigma_{ss}\big),$$
where $\rho_{ss}$ and $\sigma_{ss}$ are the mean and spread of the cosine between unrelated asks. $\square$

*Empirical:*
- The Gaussian approximation gives 0.397; the measured rate is 0.414 (0.404 in the alias study). An ordinary key has $K/N\approx0.017$.
- Recall collapses to 0.463 in the sequential run, and to 0.476 in the static run.
- Storing aliases through the key view, as $\mathrm n(Aa)$, brings the unrelated cosine down to 0.120 and the entry rate to 5.8%. The alias rule then changes recall by +0.017 instead of −0.195 (margin tuned on dev data).
- CSLS corrects location but not the inflation from taking a max: $\mathbb E\max(X,Y)-\mathbb EX=\sigma_{Y-X}/\sqrt{2\pi}$. Measured CSLS-max 0.566, z-scored max 0.615, the sequential CSLS alias rule (alias-study arm F2) 0.609.

**Proposition 6.20 (calibrated alias bonus).** The bonus fires when $\langle a,q\rangle>r_K(a)$, where $r_K(a)$ is the $K\text{-th}$ largest cosine of $a$ with $n_{\rm ref}$ reference asks. If $q$ is exchangeable with the reference set and independent of $a$, then
$$\Pr\big[\langle a,q\rangle>r_K(a)\big]\le\frac{K}{n_{\rm ref}+1}\quad\text{(rank argument)}.\ \square$$

Measured fire rates:
- in-chat references: 0.026 (bound about 0.067);
- training-chat references, which are not exchangeable: 0.193.

Sequential F3 with training-chat references reached 0.686 (+0.029).

### 6.6 Rank, step size and what the bridges learn

**Empirical result 6.4 (rank sweep at a shared Adam lr of $10^{-3}$, 320 steps).**

| training asks | r=1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 | full |
|---|---|---|---|---|---|---|---|---|---|
| 274 | **0.628** | 0.612 | 0.596 | 0.587 | 0.588 | 0.591 | 0.594 | 0.598 | 0.607 |
| 587 | **0.652** | 0.636 | 0.634 | 0.626 | 0.611 | 0.602 | 0.606 | 0.600 | 0.602 |
| 1,225 | **0.667** | 0.666 | 0.662 | 0.659 | 0.650 | 0.650 | 0.636 | 0.630 | 0.611 |

Rank 1 is best in all 5 folds at every size. The train–test gap is 0.045 (r=1), 0.220 (r=16) and 0.386 (full).

**But the comparison is confounded by step size (audit correction).** Under Adam each entry moves about lr per step, so heads with more free entries travel further.
- Mean $\lVert W-I\rVert_F$ is 1.54 at rank 1, 4.07 at rank 16 and about 6.0 at full rank.
- Full rank at lr $10^{-4}$ reaches 0.667 (+0.010 [−0.002, +0.023] against rank 16 at $10^{-3}$), and 0.663 at $3\times10^{-5}$.
- Rank 16 at $3\times10^{-4}$ reaches 0.664.
- Tuned, all ranks are within ±0.005.

These learning rates were scanned on test folds, so they show the confound; they are not clean estimates.

So "low rank beats full rank" (0.657 against 0.610; 0.864 against 0.822 on LongMemEval-S) is **unsupported** until the comparison is repeated with learning rates tuned per rank on a dev split. The parameter-count explanation is withdrawn as evidence. The LongMemEval-S comparison has not been re-run. The audit did not find the data file under its expected name; the working copy `lme_s.json` (not in the repo) holds 500 LongMemEval questions and must be confirmed as the same file first.

The design keeps a low-rank parametrisation for three reasons that do not depend on accuracy:
- it is cheap ($2dr$ parameters per view);
- it gives the rank-$2r$ attribution of Proposition 6.1;
- its start at the identity gives a guarantee: an untrained bridge is the frozen retriever.

The value of $r$ is a hyperparameter to be selected.

**Remark 6.2 (heuristic, previously stated as a proposition): spikes against noise.** At $W=I$, consider the per-ask gradients, which here include the forward term only and pool the held-out chats.
- Only 2 singular values (action head) and 1 (state head) of their mean $\bar\Gamma$ clear the sampling-noise edge.
- The noise edge scales as $n^{-0.49}$.
- The leading directions are the mean directions: $\lvert\cos\rvert$ 0.998 with $\bar k$ and 0.999 with $\bar s$.

What is proved is only the inequality
$$\lVert\hat\Gamma_r-\bar\Gamma\rVert_F\le\lVert\bar\Gamma-\bar\Gamma_r\rVert_F+2\sqrt{2r}\big(\sigma_{r+1}(\bar\Gamma)+\lVert\Xi_n\rVert_{\rm op}\big).$$
The rule $r^\star(n)=\#\{i:\sigma_i>\kappa c_\Xi n^{-1/2}\}$ does not follow from an upper bound. Its premise is incremental learning under gradient flow, but training uses Adam. And $\bar\Gamma$ was estimated from 1,531 asks, whose own noise of about 0.135 hides any direction below that level. Counts for $n$ up to 4,800 are extrapolated by resampling.

**Conjecture C2.** At about 1k asks, what the bridges learn that generalises is a common-mode shrinkage that is specific to the corpus.
- Rank-1 heads shrink one direction close to the mean by factors of 0.24 (state head) and 0.11 (action head).
- Centring with each chat's own means, without labels, recovers 37% of the rank-1 gain (0.609, against 0.575 frozen and 0.667 rank 1).
- This would explain the weak transfer to LongMemEval-S (0.860 → 0.864).

### 6.7 The probe is a bottleneck in instantiation (a)

**Proposition 6.21.** $z_t=f(x^{\rm p}_t)$, so $I(z_t;\Omega_t)\le I(x^{\rm p}_t;\Omega_t)$, where $\Omega_t$ are $R$'s internal activations. Memory can react only to what $R$ puts into words. $\square$

*Separate evidence, not a test of the inequality:* building the next state from vectors alone, as the ask plus the first hop's key, lowered recall against a single read. The loss was −0.023 [−0.035, −0.011] untrained and −0.012 [−0.019, −0.004] with a learned hop map.

### 6.8 Inductive internode encoders

**Proposition 6.22.** Suppose $g$ is permutation-invariant and its weights are shared across all nodes. Then every state is a fixed function of the graph and the leaf texts:
- a new node needs only evaluation, with no retraining;
- a state does not depend on the order in which children arrived;
- with the weights fixed, exactly the dirty set of §5.3 changes. $\square$

### 6.9 Deletion

**Proposition 6.23 (exact removal from the memory state, data-flow closure).** Assume:
- (D1) every derived quantity is a deterministic function of the parameters and its inputs;
- (D2) provenance is recorded;
- (D3) structural decisions are re-evaluated on deletion;
- (D4) storage is scrubbed;
- (D5) sums are recomputed from the log in a canonical order, or accumulated exactly (integer or fixed point);
- (D6) statistics that keys depend on, such as $\bar s_\tau$, are frozen per version and recomputed in the closure.

Then deleting $x$ and recomputing its data-flow closure yields, bit for bit on a fixed floating-point path, **the state rebuilt from the retained records**.

*Proof.* Induction over the dependency DAG in topological order. $\square$

E8 checked this for the derived cache only: after forgetting 20% of leaves with 3 seeds, session and root vectors and BM25 statistics equalled a fresh build on the survivors, and merges and splits were exact. Raw vectors stayed on disk, and keys that learn from use, logs and weights were not part of the test (E8 review).

It is **not** in general the state that would exist had $x$ never been stored. Opened sets, frontiers, probes written after reading $x$, cites of other nodes, and the user's later asks were all *selected* while $x$ was present. The residual selection effect vanishes only if those records are dropped (§5.4, step 2).

Corrections and requirements:
- **Floating point.** $(\sum+x)-x$ differs bitwise from the sum that never contained $x$ in 100% of 20,000 float32 trials. Subtraction is not exact deletion. Use (D5).
- **Running means.** A live mean ask makes every centred term depend on every ask, so deleting one ask is not $O(d)$. Use (D6). The cost is one rebuild of the affected keys, $O(\sum_vn_vdr)$.
- **The move rule without a log** is order-dependent and cannot be inverted. It violates (D1)–(D2). Replay costs $O(n_vd)$ per affected node.
- **Logs of $S$-view states** would go stale after retraining and would carry the old $S$, which was trained under variant (B). So logs store $z_t$ or probe texts (L1).
- **Gists** are exact only with deterministic decoding and a pinned model; otherwise they are equal only in distribution.
- **Splits and merges** of sessions leave update-log replay undefined unless the cite log is keyed by leaf.

**Proposition 6.24 (weights).**
- (a) Under policy (A) (§4.2), the parameters are a function of public data and randomness only, so their distribution is the same with or without $x$: zero influence.
- (b) Under variant (B), exact unlearning means retraining from scratch with the same seeds, which takes about 3 s per fold here. The deleted item's influence persists for at most one retraining period, subject to the selection effect above.
- (c) DP-SGD bounds the influence by $(\varepsilon_{\rm dp},\delta_{\rm dp})$.
- (d) Certified approximate removal needs a strongly convex loss. It does not apply to normalised heads.

Audits such as canary exposure or membership inference can detect a failure but never prove removal. $\square$

### 6.10 Joint training

**Proposition 6.25 (monotone alternation).** Suppose C-steps do not increase $\mathcal J$ on $\mathcal D$, and S-steps accept only edits that decrease it on the same $\mathcal D$. Then $\mathcal J$ is non-increasing and, being bounded below by 0, converges. $\square$

This gives no global optimum. It holds only approximately with SGD or subsampled replay. New asks and deletions are exogenous edits, so the real system tracks a moving target. Defining keys as functions of the log removes the stale-key problem and the two-timescale stability conditions it would otherwise need.

**Proposition 6.26 (alignment).**
- Each direction of $\mathcal L_{\rm align}$ gives $I\ge\log N_b-\mathcal L_{\rm NCE}$, a bound capped at $\log N_b$.
- Asymptotically the loss splits into an alignment term and a uniformity term (Wang and Isola 2020).
- Regression with both sides trainable collapses to a constant. $\square$

---

## 7 Falsifiable predictions

Each prediction gives its test and what would falsify it. Tolerances come from the measured noise-draw and seed variation.

- **P1 (only discoveries pay).** With cites produced by $R$ from what it read, the move rule gains at most +0.005. The gain scales with the number of cites whose evidence first ranked below $K$, up to about +0.018 (the gated oracle). *Falsified* by a significant gain above +0.005 (chat-clustered CI) from visible-only cites.
- **P2 (view-consistent target).** Using the $A$-view target $\mathrm n(Ae_q)$ in the move rule shrinks the self-feedback penalty (now −0.023 at $\eta=0.1$) without lowering the clean gain (+0.020). *Test:* the e6 protocol with common random numbers. Not implemented yet.
- **P3 (break-even).** With the measured wrong-cite rate $\hat p_{\rm w}$, learning helps iff:
  - move at $\eta=0.1$: $\hat p_{\rm w}<0.24$–$0.27$ (±0.05);
  - move at $\eta\le0.05$: $\hat p_{\rm w}<0.38$–$0.42$ (±0.05);
  - centred at $\eta=0.1$: $\hat p_{\rm w}<0.55$;
  - gated, with far noise: $\hat p_{\rm w}<0.57$.

  On LongMemEval, fitting the endpoints predicts the interior arms within 0.003 at $\eta\le0.05$ (about twice the noise-draw s.d. of 0.0014). At $\eta=0.1$ no interior tolerance below 0.008 is claimed, because the LoCoMo miss is already 0.005–0.007. *Falsified* by misses beyond these tolerances. Also test the identifying assumption by measuring drift on re-ask visits with $e$'s own update removed.
- **P4 (hub cost is convex in $\eta$).** On a second dataset, Remark 6.1 with that dataset's own $\bar h$, gap, spread and cite counts predicts the cost ratios within 25%. *Falsified* by linear ratios (2.5, 5, 10).
- **P5 (self-feedback).** On a stream of at least 1,500 self-cited asks, take-off happens on the scale $t^\star$ (about 61 asks at $\eta=0.1$ with the stated $\varpi^0=0.034$; the direct estimate was 60) and scales as $1/\eta$ within a factor of 3, *for $\eta$ where most top winners have $\Delta\varpi>0$*. The plain rule's loss grows without bound; the centred (about −0.04) and capped (about −0.08) losses saturate.
- **P6 (same-user calibration).** An alias bonus calibrated on the same user's *earlier* asks fires on unrelated asks at a rate of at most $2K/(n_{\rm ref}+1)$ and beats F3 (+0.029).
- **P7 (query-dependent pooling).** In deeper pyramids (session, week, month), mean pooling loses detectability per level by about $n^{-0.4}$ to $n^{-0.5}$. LSE, in one stated form, keeps at least 90% of the leaf $d'$. No query-independent pool beats the mean by more than $\sqrt{n/n_{\rm eff}}$.
- **P8 (coverage ceiling).** A top-$b$ router cannot exceed $\mathbb E[\min(n^{+(l)}_q,b)/n^{+(l)}_q]$, which is 0.939 for multi-hop at $b=3$. Only an adaptive $b$ can pass it.
- **P9 (rank, with matched optimisation).** With lr tuned per rank on a dev split, held-out recall varies by less than 0.01 across $r\in\{1,16,64,\text{full}\}$ on LoCoMo, and the LongMemEval-S transfer gap between ranks also closes. *Falsified* by a rank effect above 0.01 that survives tuning (chat-clustered CI). Also: label-free per-corpus centring beats frozen on LongMemEval-S (above 0.860).
- **P10 (exact deletion).** After forget plus closure, every byte of the memory state equals the rebuild from the retained records, including keys stored as cite logs with a canonical sum and a frozen $\bar s_\tau$. A move-rule key with no log fails this test.

  The additive centred rule with $\eta'=\eta/(1-\eta)$ agrees with the centred move rule to first order in $\eta$ and differs at $O(\eta^2)$ for every node with at least 2 cites (41% of cited nodes). Its clean gain matches within ±0.005. *(Corrected from "differs only for nodes with ≥3 cites".)*
- **P11 (warm start).** After stage A, the read bridge from (a) works on $s_t=\mathrm n(S\Pi(\mathbf h_t))$: held-out recall is within the chat-clustered CI of the text-state recall, to the extent that held-out $\mathcal L_{\rm align}$ is low.
- **P12 (inversion).** A vec2text-style inverter for bge-small recovers a substantial share of the content of short turns. *Test:* token F1 on held-out LoCoMo turns.
- **C3 (conjecture, tap layer).** A middle-to-late layer of Qwen3-8B, around two thirds of the depth, aligns with $\mathcal Z$ better than the last layer.

*Withdrawn:* "$\alpha$ grows under $\mathcal L_{\rm mask}$ but not under $\mathcal L_{\rm out}$". It cannot be tested at 320 steps under Adam lr $10^{-3}$, because $\alpha$ cannot move far enough. Test it only with a separate, larger lr for $\tilde\alpha$.

---

## 8 Known errors in the current code and what changes

| # | where | error | change |
|---|---|---|---|
| 1 | all rank comparisons (e5, e6, `theory/rank.py`) | all ranks share Adam lr $10^{-3}$ for 320 steps, so rank is confounded with distance travelled ($\lVert W-I\rVert_F$ 1.54 / 4.07 / 6.0) | tune lr per rank on a dev split, or match $\lVert W-I\rVert_F$; re-run LoCoMo and LongMemEval-S |
| 2 | `train()` | $\alpha$ is called learned but is pinned by the step budget (final 24.5) | fix $\alpha$ (e.g. 20) as a hyperparameter, or give it its own lr |
| 3 | e5, e6 | no validation split; hyperparameters fixed with test folds in view | carve a dev split out of the training chats |
| 4 | e6 | one shared random stream across arms, so no common random numbers | pre-draw coins per (visit, evidence slot); average over noise seeds; report paired differences |
| 5 | e6, `noise.py`, `multipos3.py` | bootstrap over visits or asks treats 4,593 visits (3 orders × 1,531 asks, 10 chats) as independent | chat-clustered bootstrap |
| 6 | `e5_bridges.load()` | exact string match drops 5 recoverable asks and 1 evidence id | parse with `D:?(\d+):(\d+)` and strip leading zeros (gives 1,536 asks) |
| 7 | `e6_fixes.py` anchored docstring | "shift capped at --cap" is false after renormalisation (max 0.30352) | state the invariant $\langle k,k^0\rangle\ge\sqrt{1-\zeta^2}$ |
| 8 | alias rule | stores $S$-view states as keys (a view violation), causing hubs (0.463) | drop it, or use the key view $\mathrm n(Aa)$ plus the calibrated bonus (Prop. 6.20) |
| 9 | move rule | $A$-view key pulled toward an $S$-view state | test P2 |
| 10 | centred rule in `noise.py` and `fix_cite_noise.py` | running mean blended with 10 pseudo-asks at the training mean; order-dependent; breaks deletion | freeze $\bar s_\tau$ per version |
| 11 | key updates | no cite log; logs (as designed) store $s_t$ | keep a per-node log of $z_t$ or probe texts; define keys from the log (§3.7) |
| 12 | `arch-latent/checks.py` C4 (sum form), `theory/pool.py` (mean form), `objectives/sessions*.py` (sum form) | "LSE" means two different scorers | recompute every routing table with one stated form |
| 13 | `arch-latent/checks.py` C5 | compares against $\sigma\sqrt{2\ln m}$, not $\sigma\xi_m$ | compare against $\sigma\xi_m$ |
| 14 | `objectives/checks.py` C5 | tests the expectation form of Prop. 6.12(ii), not the sum form | test the sum form, stating $\nu$ |
| 15 | `theory/rank.py` | forward-term gradients only; pooled held-out chats; $n$ up to 4,800 resampled from 1,531 | include the backward term, use training chats, and report the resolution limit |
| 16 | `noise.py` self-feedback | $p_{\rm self}$ labelled $1-P@1$ | report the realised share per $\eta$ and state which model each prediction uses |
| 17 | read loss | bidirectional $\mathcal L_{\rm out}$: not a bug, but it costs recall on multi-evidence asks | switch to forward-only $\mathcal L_{\rm mask}$ (+0.017, chat-clustered CI [+0.001, +0.038]) |
| 18 | design page `two-plane.html` | recommends alias keys and $k_v=Ae_v+r_v$ | describe the anchored or centred move rule (or log-defined keys) and record that aliases failed |
| 19 | citations of results | 0.657 / 0.678 attributed to e5 | cite e6 (rank 16, $\eta=0.1$); e5's `run()` uses full rank and $\eta=0.3$ |
| 20 | measured constants | ask-to-own-evidence cosine 0.379 / 0.389 / 0.396; turns per session 21.6 (mean over 272 sessions) vs 22.8 (`sessions.py`, different weighting) | define the averaging unit and use one value per quantity |
| 21 | data | the LongMemEval-S file was not found as `longmemeval_s_cleaned.json`; `data/lme_s.json` holds 500 LongMemEval questions | confirm it is the same file before any transfer re-run |

The frozen baseline is fair: adding BGE's query instruction gives 0.569 against 0.575, and the bridge gain is unchanged (+0.084 against +0.082).
