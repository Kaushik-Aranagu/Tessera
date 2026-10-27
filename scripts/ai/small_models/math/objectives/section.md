## Objectives and training

This section writes down every loss the system trains, what each term does to the parameters, and which of them the current code implements. Losses are stated per ask (or per event) and are averaged over a batch unless noted. Everything marked **Proposition** is proved here; checks C1 to C8 in `/tmp/claude-0/math/objectives/checks.py` test the derivations numerically on synthetic data (all pass). Everything marked **Conjecture** is not proved. Measured numbers are recall@10 of marked evidence turns on held-out LoCoMo chats (5 folds, train on 8 chats, test on 2) unless stated.

### 0. Notation (defined once, used throughout)

| Symbol | Meaning | Shape / range |
|---|---|---|
| $G=(V,E)$ | memory graph; $V_\ell$ = nodes at level $\ell$, $V_0$ = leaves (verbatim items) | |
| $\mathrm{ch}(u)$, $a_\ell(v)$ | children of $u$; ancestor of leaf $v$ at level $\ell$ ($a_0(v)=v$) | |
| $f$ | frozen text encoder (bge-small-en-v1.5) | text $\to\mathbb S^{d_f-1}$, $d_f=384$ |
| $e_v=f(x_v)$, $e_q=f(x_q)$ | encoder view of node text $x_v$ and ask text $x_q$ | $\mathbb R^{d_f}$, unit norm |
| $S,A$ | state head and action head | $\mathbb R^{d_z\times d_f}$, currently $d_z=d_f$ |
| $W=I+UV^\top$ | low-rank head ($W\in\{S,A\}$), $U,V\in\mathbb R^{d_f\times r}$ | $r=16$ |
| $\mathrm{unit}(x)$ | $x/\lVert x\rVert$ | |
| $s_q=\mathrm{unit}(Se_q)$, $k_v=\mathrm{unit}(Ae_v)$ | ask state and node key in the shared space $Z=\mathbb S^{d_z-1}$ | unit vectors |
| $\alpha=e^{\varsigma}$ | inverse temperature (learned log-scale $\varsigma$) | $\alpha>0$ |
| $\ell_{qv}=\alpha\langle s_q,k_v\rangle$ | logit of node $v$ for ask $q$ | $[-\alpha,\alpha]$, dimensionless |
| $\mathcal C_q$ | candidate set (the chat's leaves, or the current frontier) | |
| $P_q\subseteq\mathcal C_q$, $N_q=\mathcal C_q\setminus P_q$, $m_q=\lvert P_q\rvert$ | evidence (positives), negatives, number of positives | |
| $p_{qv}=e^{\ell_{qv}}/\sum_{u\in\mathcal C_q}e^{\ell_{qu}}$ | read-bridge softmax | |
| $Z_{N_q}=\sum_{n\in N_q}e^{\ell_{qn}}$, $Z_{P_q}=\sum_{p\in P_q}e^{\ell_{qp}}$ | negative and positive partition sums | |
| $\mathrm{R@}k(q)=\lvert P_q\cap \mathrm{top}_k(q)\rvert/m_q$ | recall@k of evidence | $[0,1]$ |
| $\mathcal Q$ | the asks in one training batch (one chat) | |
| $H^{(j)}_t$ | open-LLM hidden state at layer $j$, reasoning step $t$ | $\mathbb R^{d_h}$, $d_h=4096$ for Qwen3-8B |

All scores are dimensionless inner products of unit vectors times $\alpha$; every head maps into $\mathbb R^{d_z}$ and is followed by $\mathrm{unit}$, so all losses below compare like with like.

---

### 1. Read bridge: contrastive loss with evidence sets

#### 1.1 Three formulations

An ask can have several evidence turns (LoCoMo: 1,122 of 1,531 asks have $m_q=1$; multi-hop asks average $m_q=3.1$). Three standard ways to train with a set of positives:

**(a) Uniform soft-target cross-entropy** (identical to the asymmetric form of SupCon's $L_{out}$, Khosla et al. 2020):
$$\mathcal L_{out}(q)=-\frac1{m_q}\sum_{p\in P_q}\log p_{qp}=H(y_q,p_q),\qquad y_{qv}=\frac{\mathbb 1[v\in P_q]}{m_q}.$$

**(b) SupCon $L_{in}$ / MIL-NCE** (Miech et al. 2020): the log of the total positive mass,
$$\mathcal L_{in}(q)=-\log\sum_{p\in P_q}p_{qp}.$$
(SupCon writes $-\log\frac1{m_q}\sum_p p_{qp}$; the extra $\log m_q$ is a constant.)

**(c) Per-positive InfoNCE with the other positives masked out of the denominator:**
$$\mathcal L_{mask}(q)=\frac1{m_q}\sum_{p\in P_q}\log\Big(1+\sum_{n\in N_q}e^{\ell_{qn}-\ell_{qp}}\Big)=-\frac1{m_q}\sum_{p\in P_q}\log\frac{e^{\ell_{qp}}}{e^{\ell_{qp}}+Z_{N_q}}.$$

When $m_q=1$ all three are the same function.

#### 1.2 Gradients and what each term does

Gradients are taken with respect to the logits; the chain rule to the heads is $\partial\ell_{qv}/\partial s_q=\alpha k_v$, $\partial\ell_{qv}/\partial k_v=\alpha s_q$, followed by the normalization Jacobian $(I-ss^\top)/\lVert Se_q\rVert$ (and likewise for $k$), which removes the radial component.

- **(a)** $\dfrac{\partial\mathcal L_{out}}{\partial\ell_{qv}}=p_{qv}-y_{qv}$. The target is fixed and uniform over positives. A positive that already holds more than $1/m_q$ of the mass is pushed **down**: positives compete with each other.
- **(b)** $\dfrac{\partial\mathcal L_{in}}{\partial\ell_{qv}}=p_{qv}-\tilde y_{qv}$ with $\tilde y_{qv}=\mathbb 1[v\in P_q]\,p_{qv}/\pi_q$ and $\pi_q=\sum_{p\in P_q}p_{qp}$. The target is the model's own posterior over positives. On a positive the gradient is $-p_{qv}(1-\pi_q)/\pi_q$, proportional to its current probability: hard positives get almost no gradient (rich get richer).
- **(c)** $\dfrac{\partial\mathcal L_{mask}}{\partial\ell_{qp}}=-\dfrac{1-\sigma_{qp}}{m_q}$ with $\sigma_{qp}=\dfrac{e^{\ell_{qp}}}{e^{\ell_{qp}}+Z_{N_q}}$, and $\dfrac{\partial\mathcal L_{mask}}{\partial\ell_{qn}}=\dfrac1{m_q}\sum_{p\in P_q}\dfrac{e^{\ell_{qn}}}{e^{\ell_{qp}}+Z_{N_q}}$. Each positive is only asked to beat the negatives; the weakest positive gets the largest pull; a negative is pushed in proportion to how much it threatens the weakest positives. Because $e^{\ell_{qp}}+Z_{N_q}\le Z_{P_q}+Z_{N_q}$, the push on every negative is at least as large as under (a).

Minima: $\mathcal L_{out}\ge\log m_q$ (Gibbs), with equality only if all positive logits are equal and negatives carry no mass. $\inf\mathcal L_{in}=0$, approached as soon as $\pi_q\to1$, including when all the mass sits on a single positive. $\inf\mathcal L_{mask}=0$, approached iff every positive's logit exceeds $\log Z_{N_q}$ by a growing margin, i.e. every positive outranks every negative.

#### 1.3 Two propositions that decide the choice

**Proposition 1.1 (the masked loss bounds the recall miss rate).** If $m_q\le k$, then
$$1-\mathrm{R@}k(q)\;\le\;\frac{\mathcal L_{mask}(q)}{\log(2+k-m_q)}\;\le\;\frac{\mathcal L_{out}(q)}{\log(2+k-m_q)}.$$
*Proof.* If positive $p$ is outside the top $k$, at least $k$ candidates are ranked above it, of which at most $m_q-1$ are positives, so at least $k-m_q+1$ negatives have $\ell_{qn}\ge\ell_{qp}$, each contributing $e^{\ell_{qn}-\ell_{qp}}\ge1$. Hence the term of $p$ is at least $\log(2+k-m_q)$, so $\mathbb 1[p\text{ missed}]\le(\text{term of }p)/\log(2+k-m_q)$. Average over $p\in P_q$. The second inequality is termwise: $-\log p_{qp}=\log\big(1+\sum_n e^{\ell_{qn}-\ell_{qp}}+\sum_{p'\ne p}e^{\ell_{qp'}-\ell_{qp}}\big)$. $\square$ (C2: no violation in 20,000 random instances; the largest observed miss-to-bound ratio is 0.66, so the bound is valid but loose.)

**Proposition 1.2 (L_out = ranking loss + an equalizer).**
$$\mathcal L_{out}(q)=\mathcal L_{mask}(q)+\mathcal E_q,\qquad \mathcal E_q=\frac1{m_q}\sum_{p\in P_q}\log\frac{Z_{P_q}+Z_{N_q}}{e^{\ell_{qp}}+Z_{N_q}}\ge0,$$
and as $Z_{N_q}/Z_{P_q}\to0$, $\mathcal E_q\to H\big(\mathrm{unif}(P_q),\mathrm{softmax}_{P_q}(\ell_q)\big)\ge\log m_q$, with equality iff all positive logits are equal. *Proof:* subtract the two definitions term by term. $\square$

So $\mathcal L_{out}$ is the ranking surrogate of (c) plus a term that penalizes spread **among** positives. For recall@k the order among positives does not matter, so the equalizer only spends gradient pulling the easiest evidence turn down toward the hardest. It has one useful side effect: it keeps $\alpha$ finite (sharpening the softmax increases $\mathcal E_q$ when positive cosines differ), whereas $\mathcal L_{mask}$ on separable data keeps rewarding larger $\alpha$.

#### 1.4 Recommendation

Use **$\mathcal L_{mask}$ in the ask-to-node direction only** for the read bridge whenever positives are gold or verified evidence (all of them are needed: the semantics of multi-hop asks and of recall@k), averaged per ask so that every ask has weight 1, with $\alpha$ clamped (e.g. $\alpha\le100$) or fixed. Move the node-to-ask (anti-hub) effect out of head training and into key learning (Section 4.3), where it measured positive. Use $\mathcal L_{in}$ only when the positive set is a noisy superset in which any one element suffices (for example "nodes opened during an answer the verifier accepted"), because there the model should be free to choose which positive to credit. Under $\mathcal L_{mask}$, false negatives (unmarked turns that also contain the answer) are pushed harder than under $\mathcal L_{out}$ (Section 1.2), so remove candidates a teacher marks as equivalent from $N_q$, or use a debiased denominator (Chuang et al. 2020).

**Measured** (`/tmp/claude-0/math/objectives/multipos3.py`: rank-16 heads, everything else exactly as in `e5_bridges.train`, seeds $\{0,100,200\}+$fold, recall@10 averaged over seeds, 1,531 held-out asks; seed 0 of the first row reproduces the published 0.657):

| Read loss | all (1,531) | $m_q\ge2$ (409) | multi-hop (281) | $m_q=1$ (1,122) | final $\alpha$ |
|---|---|---|---|---|---|
| $\mathcal L_{out}$, both directions (current `e5`) | 0.655 | 0.470 | 0.472 | 0.723 | 24.5 |
| $\mathcal L_{out}$, forward only | 0.656 | 0.482 | 0.487 | 0.720 | 24.5 |
| $\mathcal L_{in}$, both directions | 0.658 | 0.475 | 0.476 | 0.724 | 25.2 |
| $\mathcal L_{mask}$, both directions | 0.657 | 0.474 | 0.479 | 0.724 | 24.9 |
| $\mathcal L_{mask}$, forward only | 0.657 | 0.487 | 0.492 | 0.719 | 24.8 |

Paired differences (bootstrap over asks, 95%; chats are not resampled):
- masking the other positives, forward only: $+0.0055$ $[+0.0003,+0.0111]$ on $m_q\ge2$, $-0.0015$ $[-0.0045,+0.0015]$ on $m_q=1$, as Proposition 1.2 predicts (the two losses are the same function at $m_q=1$);
- dropping the backward term ($\mathcal L_{out}$): $+0.012$ $[+0.001,+0.023]$ on $m_q\ge2$, $+0.015$ $[+0.003,+0.027]$ on multi-hop, $-0.002$ $[-0.012,+0.007]$ on $m_q=1$;
- recommended versus current: $+0.017$ $[+0.006,+0.029]$ on $m_q\ge2$, $+0.020$ $[+0.008,+0.032]$ on multi-hop, $+0.002$ $[-0.006,+0.009]$ overall.

On $m_q\ge2$ each of these orderings (forward-only above bidirectional, masked above uniform) holds in every one of the 3 seeds. The overall number does not move because 73% of asks have one evidence turn. The clamp never binds within 320 steps. The backward-term cost was not predicted by the theory. **Conjecture 1.3:** it comes from incomplete labels in the ask direction (an evidence turn is marked for some of the asks it answers and pushed away from the others), and it falls hardest on multi-evidence asks because their evidence turns are topically shared.

#### 1.5 What `e5_bridges.py` `train()` actually implements, and whether it is correct

One optimizer step is one training chat; the candidates are all its turns, the asks are all its questions that have evidence. Lines 114 to 122 compute
$$\mathcal L_{e5}=\underbrace{\frac1{\lvert\mathcal Q\rvert}\sum_{q\in\mathcal Q}\mathcal L_{out}(q)}_{\texttt{forward}}\;+\;\underbrace{\frac1{\lvert V^+\rvert}\sum_{v\in V^+}\Big(-\sum_{q\in\mathcal Q}\pi(q\mid v)\log\frac{e^{\ell_{qv}}}{\sum_{q'\in\mathcal Q}e^{\ell_{q'v}}}\Big)}_{\texttt{backward}}\;+\;0.01\big(\lVert S-I\rVert_F^2+\lVert A-I\rVert_F^2\big),$$
where $V^+=\{v:\exists q,\ v\in P_q\}$, and $\pi(q\mid v)=\dfrac{\mathbb 1[v\in P_q]/m_q}{\sum_{q'}\mathbb 1[v\in P_{q'}]/m_{q'}}$ is the column-normalized `pos` matrix.

Findings:

1. **Forward term = $\mathcal L_{out}$** (uniform soft target, positives compete in the denominator). It is not $\mathcal L_{in}$ and not $\mathcal L_{mask}$.
2. **Backward term is a correct cross-entropy.** Both targets are conditionals of one joint coupling $\pi(q,v)=\frac{1}{\lvert\mathcal Q\rvert}\frac{\mathbb 1[v\in P_q]}{m_q}$: forward uses $\pi(v\mid q)=y_{qv}$, backward uses $\pi(q\mid v)$. In the backward direction the "positives" are the asks that share evidence $v$, and they also compete ($\mathcal L_{out}$ again). The backward term does not enter the test-time ranking (which ranks nodes for a fixed ask); it shapes the keys. Its gradient on a key is, up to the factor $1/\lvert V^+\rvert$,
$$\nabla_{k_v}=-\alpha\sum_q\pi(q\mid v)\big(s_q-\bar s_v\big),\qquad \bar s_v=\sum_{q'}\mathrm{softmax}_{q'}(\ell_{q'v})\,s_{q'},$$
so it pulls an evidence key toward its own asks **minus the (softmax-weighted) mean of all asks**: a specificity, anti-hub term. Section 4.3 shows the "centered" key update is the same gradient. Measured in Section 1.4: removing it gains $+0.012$ on multi-evidence asks and changes single-evidence asks by $-0.002$ (not significant).
3. **The penalty is what the design says.** For `LowRank`, `weight` $=I+UV$ with `u` $\in\mathbb R^{d\times r}$, `v` $\in\mathbb R^{r\times d}$, so `near` $=\lVert UV\rVert_F^2$ per head, an identity-anchored ridge. For full-rank heads the same line is $\lVert W-I\rVert_F^2$, so the full-rank versus low-rank comparison differs only in rank. It penalizes the product, not the factors, so the gauge $(U,V)\mapsto(UG,VG^{-\top})$ is unregularized (harmless for the function; AdamW weight decay is 0). Since the outputs are normalized, $W$ and $cW$ give the same scores; the identity anchor removes that ambiguity. Init $U=0$, $V\sim\mathcal N(0,10^{-4})$ gives $W=I$ exactly at step 0 (the bridge starts as the frozen encoder), and only $U$ gets gradient on the first step (the LoRA initialization).
4. **Temperature.** $\alpha=e^{\varsigma}$ starts at 20, is learned and unclamped. With $\mathcal L_{out}$ the equalizer bounds it; the measured final value is about 24.5 after 320 steps.
5. **Weighting.** Asks are averaged within a chat and each chat is one step, so chats with more questions do not dominate. The backward term averages over evidence nodes uniformly, not by how many asks cite them.
6. **Negatives** are in-chat only (all turns of the chat), which matches the test-time candidate set. Unmarked relevant turns are treated as negatives (false negatives); nothing corrects for that.

**Verdict:** the code is a correct implementation of a bidirectional, joint-coupled $\mathcal L_{out}$ with an identity-anchored ridge on the heads. There is no bug. Two choices in it cost recall on multi-evidence asks: the uniform target (1), which optimizes a looser surrogate than $\mathcal L_{mask}$ ($-0.006$), and the backward term (2) ($-0.012$). Together they cost $0.017$ on the 409 multi-evidence asks and nothing measurable overall.

#### 1.6 Read-again (multi-hop): the hop-wise residual loss

At hop $t$ the state $z_t$ (the ask at $t=0$, then each thought) is scored against the frontier; $O_{<t}$ is what earlier hops opened. Training hop $t$ to re-find what is already open wastes the hop, so the positives at hop $t$ are the **residual evidence** $R_t=P_q\setminus O_{<t}$ and already-opened nodes are removed from both sides:
$$\mathcal L_{hop}(q)=\sum_{t=0}^{T-1}\frac{\mathbb 1[R_t\ne\emptyset]}{\lvert R_t\rvert}\sum_{p\in R_t}\log\Big(1+\sum_{n\in\mathcal C\setminus(P_q\cup O_{<t})}e^{\ell(z_t,n)-\ell(z_t,p)}\Big).$$
With a frozen LLM, $z_{t+1}$ is computed from generated text, so no gradient flows from hop $t+1$ back to hop $t$: each hop is supervised on the trajectory the system actually ran (on-policy data, as in DAgger). With an open LLM and soft reads (Section 5), the gradient can flow through $z_{t+1}$ into the hop-$t$ read.

---

### 2. Hierarchical loss and the internode aggregator $g$

#### 2.1 Level-wise positives

A parent is positive for an ask if its subtree holds evidence: $P_q^{(\ell)}=\{a_\ell(v):v\in P_q\}$, $m^{(\ell)}_q=\lvert P^{(\ell)}_q\rvert$, $N^{(\ell)}_q=V_\ell\setminus P^{(\ell)}_q$. A parent $u$ is scored by one key, $\ell_{qu}=\alpha\langle s_q,k_u\rangle$, or by $m$ prototype keys, $\ell_{qu}=\alpha\max_j\langle s_q,k^{(j)}_u\rangle$ (or a soft maximum).

#### 2.2 Why the mean of the children fails

Let $k_u=\mathrm{unit}(\bar h_u)$ with $\bar h_u=\frac1{n_u}\sum_{c\in\mathrm{ch}(u)}k_c$, $n_u=\lvert\mathrm{ch}(u)\rvert$. Then
$$\langle s,k_u\rangle=\frac{\frac1{n_u}\sum_c\langle s,k_c\rangle}{\lVert\bar h_u\rVert},\qquad \lVert\bar h_u\rVert^2=\frac1{n_u}+\frac{n_u-1}{n_u}\bar\rho_u,$$
with $\bar\rho_u$ the mean pairwise cosine of the children.

**Proposition 2.1 (dilution).** Swapping one ordinary child for an evidence child $c^\star$ changes the numerator by $\big(\langle s,k_{c^\star}\rangle-\langle s,k_{c_0}\rangle\big)/n_u$, so the evidence contributes a parent-level margin of about $\Delta_u=\dfrac{\langle s,k_{c^\star}\rangle-\overline{\langle s,k_c\rangle}}{n_u\lVert\bar h_u\rVert}$, which shrinks like $1/n_u$. The spread of parent scores across parents for the same ask comes from the topic-level average $\overline{\langle s,k_c\rangle}_u/\lVert\bar h_u\rVert$, which does not shrink with $n_u$. The factor $1/\lVert\bar h_u\rVert$ also inflates parents whose children are diverse (small $\bar\rho_u$): a built-in hub. (Exact algebra; numerical check C8.)

Measured on LoCoMo sessions as parents (`sessions.py`, 22.8 turns per session): in the frozen space $\Delta=0.0075$ against a cross-session score spread (std) of $0.025$; in the rank-16 bridge space $\Delta=0.022$ against $0.062$. The evidence signal is about one third of the spread, so mean-pooled parents route mostly by session topic.

BM25 on a concatenated session does not dilute: a rare term's contribution depends on its frequency in the session with sublinear length normalization, not on the share of turns that contain it. BM25 aggregates like a soft OR, which is why BM25 session routing (0.649 end to end) beats mean-pooled vectors (0.386).

**Proposition 2.2 (one vector cannot be a maximum).** For unit children $k_1,\dots,k_n$ and any $w\in\mathbb R^{d_z}$,
$$\sup_{\lVert q\rVert=1}\Big\lvert\langle q,w\rangle-\max_c\langle q,k_c\rangle\Big\rvert\;\ge\;\tfrac12\max_{c,c'}\lVert k_c-k_{c'}\rVert.$$
*Proof.* Let $F(q)=\max_c\langle q,k_c\rangle$, take $c,c'$ at the diameter and $q=\mathrm{unit}(k_c-k_{c'})$. Then $F(q)+F(-q)\ge\langle q,k_c\rangle-\langle q,k_{c'}\rangle=\lVert k_c-k_{c'}\rVert$, while $\langle q,w\rangle+\langle-q,w\rangle=0$, so one of the two errors is at least half the diameter. $\square$ (C7 illustrates it: the best linear fit to a 5-child maximum leaves residual std 0.115 against a target std of 0.165.)
With $m$ prototypes such that every child is within distance $\delta$ of some prototype, $\max_c\langle q,k_c\rangle\le\max_j\langle q,k^{(j)}_u\rangle+\delta$ for all unit $q$ (Cauchy–Schwarz), so prototypes trade storage ($m$ vectors per parent) for accuracy, reaching exactness at $m=n_u$.

The bound is a worst case over all directions. Asks occupy a small region of $Z$ (unrelated asks in one chat have mean cosine 0.31 in the bridge space), so a parent representation can be accurate **where asks land** if it is trained for that region. The mean is not trained for anything.

**Proposition 2.3 (the soft OR composes across levels).** With $\mathrm{LSE}_\tau(x_1,\dots,x_n)=\tau\log\sum_i e^{x_i/\tau}$: $\max_i x_i\le\mathrm{LSE}_\tau\le\max_i x_i+\tau\log n$, and for a parent $u$ the LSE over its children's subtree LSE values equals the LSE over all leaves below $u$. (Direct from $\log\sum_c\exp\log\sum_{v\in c}=\log\sum_v$.) So "the soft maximum of my leaves' scores" is one consistent target at every level.

Measured session routing (rank-16 bridge space, held-out chats; share of each ask's evidence sessions found in the top 3 sessions; `sessions.py`, `sessions2.py`, `sessions3.py` in `/tmp/claude-0/math/objectives/`; one seed, no intervals):

| Parent representation | vectors per parent | child scores needed at query time | all | multi-hop |
|---|---|---|---|---|
| mean of children | 1 | no | 0.500 | 0.321 |
| one vector fitted to the soft OR (ridge, no labels) | 1 | no | 0.556 | 0.387 |
| k-means prototypes, $m=4$ | 4 | no | 0.571 | 0.381 |
| soft-OR-distilled prototypes, $m=4$ (no labels) | 4 | no | 0.628 | 0.436 |
| k-means prototypes, $m=8$ | 8 | no | 0.641 | 0.448 |
| soft-OR-distilled prototypes, $m=8$ (no labels) | 8 | no | 0.653 | 0.454 |
| max over children | $n_u\approx23$ | yes | 0.707 | 0.489 |
| $\mathrm{LSE}_{0.05}$ over children | $n_u$ | yes | 0.724 | 0.513 |

Prototypes are scored by $\mathrm{LSE}_{0.05}$ over the prototypes. Distillation starts from the k-means prototypes and fits $\mathcal L_{or}$ below, using only the training chats' ask states. In the frozen space the mean scores 0.506 and the max 0.670. Read with Proposition 2.2: one vector closes a quarter of the gap between mean and soft OR, and 8 distilled prototypes close 68% of it, with no labels at all.

#### 2.3 The objective for the aggregator

$h_u=g_\gamma\big(\{k_c\}_{c\in\mathrm{ch}(u)},e^{gist}_u\big)$, shared across levels. A concrete $g$ that contains the mean as a special case is attention pooling with $m$ learned seeds $\omega_j\in\mathbb R^{d_z}$ (as in Set Transformer pooling):
$$k^{(j)}_u=\mathrm{unit}\Big(\sum_{c\in\mathrm{ch}(u)}\mathrm{softmax}_c\big(\langle\omega_j,W_Kk_c\rangle/\sqrt{d_z}\big)\,W_Vk_c+W_Ge^{gist}_u\Big),\quad j=1,\dots,m,$$
with $W_K,W_V\in\mathbb R^{d_z\times d_z}$, $W_G\in\mathbb R^{d_z\times d_f}$ (low rank in practice). $W_K=0$, $W_V=I$, $W_G=0$, $m=1$ is the mean.

Two terms train it.

**(i) Level-wise masked contrastive loss with leaf-count weights:**
$$\mathcal L_{hier}(q)=\sum_{\ell=0}^{L}\lambda_\ell\,\frac1{m_q}\sum_{v\in P_q}\log\Big(1+\sum_{u\in N^{(\ell)}_q}e^{\ell_{qu}-\ell_{q\,a_\ell(v)}}\Big).$$

**Proposition 2.4 (coverage bound).** Consider beam search that keeps the top $b_\ell$ nodes at level $\ell$ among the children of the previous beam and returns the top $k=b_0$ leaves. If $b_\ell\ge m^{(\ell)}_q$ for every $\ell$ and $\lambda_\ell=1/\log(2+b_\ell-m^{(\ell)}_q)$, then
$$1-\mathrm R^{tree}(q)\le\mathcal L_{hier}(q).$$
*Proof.* If every ancestor $a_\ell(v)$ is in the global top $b_\ell$ of $V_\ell$, then by induction from the root each is a candidate at its level (its parent is in the beam) and ranks within the top $b_\ell$ of that smaller candidate set, so $v$ is retrieved. Hence $\mathbb 1[v\text{ missed}]\le\sum_\ell\mathbb 1[\text{global rank of }a_\ell(v)>b_\ell]$; bound each indicator as in Proposition 1.1 and average over $v\in P_q$. $\square$ (C3 checks the first step on 3,000 random two-level instances.)
Two consequences. The weight of a parent is the number of evidence leaves it holds; that falls out of the bound rather than being chosen. And if $m^{(\ell)}_q>b_\ell$ no scorer can reach full recall, which is a structural ceiling, not a training problem: on LoCoMo 3.9% of all asks and 17.4% of multi-hop asks have evidence in more than 3 sessions, which caps any top-3 session router at 0.939 multi-hop coverage (share of evidence sessions found; 0.986 over all asks). The stop/depth bridge should therefore set $b_\ell$ per ask, and the read-again loop exists for the rest.

**(ii) Label-free soft-OR distillation** (needs no evidence labels, only a sample of states):
$$\mathcal L_{or}(\gamma)=\mathbb E_{s\sim\mathcal D_s}\sum_{u}\Big(\tau_p\log\sum_j e^{\langle s,k^{(j)}_u\rangle/\tau_p}-\mathrm{sg}\big[\mathrm{LSE}_\tau\big(\{\langle s,k_v\rangle\}_{v\in\mathrm{leaves}(u)}\big)\big]\Big)^2,$$
where $\mathrm{sg}$ is stop-gradient (children are not pulled toward their parent) and $\mathcal D_s$ is any distribution of past ask states. By Proposition 2.3 the target is the same quantity at every level. This term teaches $g$ to predict its subtree's best match where asks actually land; (i) then sharpens it with labels.

Gradient flow: $\partial\mathcal L_{hier}/\partial\gamma$ reaches $g$ through every parent key; with weights shared across levels, all levels train one $g$. Through $k_c$ the parent losses also reach $A$ (and any leaf residuals), so leaves are shaped to be aggregatable.

---

### 3. Stop, write, reshape and forget bridges

#### 3.1 Stop: calibrated binary

After hop $t$ the read has opened $O_{\le t}$. Features $\phi_t$: best unopened logit, gap between the best unopened and the worst opened logit, entropy of the frontier softmax, share of frontier mass already opened, hop index, and (with an open LLM) its answerability logit. $\pi_t=\sigma(w^\top\phi_t+\beta)$, label $y_t=\mathbb 1[P_q\subseteq O_{\le t}]$ (all evidence open) or, with a teacher, $\mathbb 1[\text{the reasoning plane answers correctly from }O_{\le t}]$.
$$\mathcal L_{stop}=-\frac1T\sum_t\big[y_t\log\pi_t+(1-y_t)\log(1-\pi_t)\big],\qquad \frac{\partial\mathcal L_{stop}}{\partial(w^\top\phi_t+\beta)}=\frac{\pi_t-y_t}{T}.$$
Log loss is a strictly proper scoring rule, so its population minimizer over all functions of $\phi$ is $\Pr(y=1\mid\phi)$; a finite model is only approximately calibrated, so fit a temperature on held-out asks and report ECE and Brier. **Decision:** stopping now costs $(1-\pi_t)C_{miss}$ in expectation; one more hop costs $C_{open}+\mathbb E[1-\pi_{t+1}\mid\phi_t]\,C_{miss}$. The one-stage look-ahead rule stops iff the first is not larger than the second; under the optimistic assumption that one more hop completes the evidence it reduces to: stop iff $\pi_t\ge1-C_{open}/C_{miss}$. (One-stage look-ahead is optimal when the stopping problem is monotone, Chow, Robbins and Siegmund 1971; in general it is a heuristic.) Calibration is what makes this threshold mean what it says.

#### 3.2 Write: choice among attach, new node, merge, drop

For a new leaf $x$ with $e_x=f(x)$, the action set is dynamic: $\mathcal A(x)=\{\mathrm{attach}(u):u\in H_x\}\cup\{\mathrm{new}(u):u\in H_x\}\cup\{\mathrm{merge}(v):v\in D_x\}\cup\{\mathrm{drop}\}$, where $H_x$ are the top-$K$ holders by the read bridge and $D_x$ near-duplicate leaves. Scores in the shared space:
$$\ell(a)=\alpha\langle\mathrm{unit}(S_We_x),\kappa_a\rangle+\beta_{\mathrm{type}(a)},\quad \kappa_{\mathrm{attach}(u)}=k_u,\ \kappa_{\mathrm{new}(u)}=\mathrm{unit}(k_u+\nu_{new}),\ \kappa_{\mathrm{merge}(v)}=k_v,\ \kappa_{\mathrm{drop}}=\nu_{drop},$$
$\nu_{new},\nu_{drop}\in\mathbb R^{d_z}$ learned, $\pi_W(a\mid x,G)=\mathrm{softmax}_{a\in\mathcal A(x)}\ell(a)$. With teacher labels $a^\star$ (Claude), the imitation loss is cost-sensitive because dropping is irreversible:
$$\mathcal L_{write}=\sum_{a\in\mathcal A(x)}\pi_W(a\mid x,G)\,C(a,a^\star)\quad\text{or simply}\quad-\log\pi_W(a^\star\mid x,G),$$
with $C(\mathrm{drop},a^\star)\gg C(\mathrm{attach}(u),a^\star)$ when $a^\star\ne\mathrm{drop}$. The softmax over a candidate set (rather than a fixed classifier) is what lets one head handle a graph that changes size.

#### 3.3 Reshape and forget as policies

State $G_t$ (graph, keys, usage counts); actions $a\in\mathcal A(G_t)=\{\mathrm{split}(u),\mathrm{merge}(u,u'),\mathrm{collapse}(u),\mathrm{regist}(u),\mathrm{forget}(u),\mathrm{noop}\}$; policy $\pi_\omega(a\mid G_t)=\mathrm{softmax}_a\,\ell_\omega(a,G_t)$. Reward over the asks $\mathcal Q^+_t$ that arrive before the next edit:
$$r_t=\frac1{\lvert\mathcal Q^+_t\rvert}\sum_{q\in\mathcal Q^+_t}\Big[\mathrm R@k(q;G_{t+1})-c_{open}\,\mathrm{opens}(q;G_{t+1})\Big]-c_{size}\,\mathrm{size}(G_{t+1}),\qquad J(\omega)=\mathbb E\Big[\sum_t\gamma^t r_t\Big].$$
Recall is dimensionless, so $c_{open}$ is recall per opened node and $c_{size}$ is recall per byte: exchange rates set by the product.

**REINFORCE with a baseline** (Williams 1992):
$$\nabla_\omega J=\mathbb E\Big[\sum_t\nabla_\omega\log\pi_\omega(a_t\mid G_t)\,\big(\hat R_t-b_t\big)\Big],\qquad \hat R_t=\sum_{t'\ge t}\gamma^{t'-t}r_{t'}.$$
It is unbiased for any $b_t$ that does not depend on $a_t$ given $G_t$, since $\mathbb E_{a\sim\pi}[\nabla\log\pi(a\mid G)]=0$. The variance-minimizing constant is $b^\star=\mathbb E[\lVert\nabla\log\pi\rVert^2\hat R]/\mathbb E[\lVert\nabla\log\pi\rVert^2]$.

**Replay baseline.** *Assumption (exogenous asks):* future asks do not depend on the edit. Then $b_t=\hat R_t(\mathrm{noop})$, computed by replaying the same future asks on the unedited graph, is a valid baseline, and the advantage $\hat R_t(a_t)-\hat R_t(\mathrm{noop})$ cancels ask difficulty, which is the largest source of variance (common random numbers). Because retrieval given $(G,\text{asks})$ is deterministic, the reward of **every** candidate action can be computed by replay, which gives the all-actions gradient $\sum_a\nabla_\omega\pi_\omega(a\mid G_t)\hat R_t(a)$ with no sampling variance for one-step edits.

**Comparison.**

| Estimator | Bias | Variance | Label cost | Fails when |
|---|---|---|---|---|
| REINFORCE + replay baseline | none | high for long horizons (forget now, asked months later) | none beyond logged asks | rewards are delayed and sparse |
| Imitation of a teacher (Claude labels) | bounded by the teacher | low | one LLM call per decision | covariate shift: errors compound as $O(T^2\epsilon)$ over horizon $T$, $O(T\epsilon)$ with DAgger (Ross and Bagnell 2010; Ross, Gordon and Bagnell 2011) |
| Off-policy IPS, $\hat J=\frac1n\sum_i\frac{\pi(a_i\mid G_i)}{\mu(a_i\mid G_i)}r_i$ | none if $\mu>0$ wherever $\pi>0$ | grows with $\mathbb E[(\pi/\mu)^2]$ | none | the logging policy is a deterministic rule ($\mu\in\{0,1\}$): undefined without exploration |
| Doubly robust, $\hat J=\frac1n\sum_i\big[\hat Q(G_i,\pi)+\frac{\pi}{\mu}(r_i-\hat Q(G_i,a_i))\big]$ | none if either $\hat Q$ or $\mu$ is right | lower than IPS | none | both are wrong |
| Exact replay (direct method with the real memory program) | none under exogenous asks and a fixed reasoning plane | none for one-step edits | none | read-again thoughts depend on what was read; gist rewrites need LLM calls; the user's later asks depend on earlier answers |

**Recommendation.** Start with imitation of Claude labels and DAgger (cheap, stable). Improve with exact replay on logged asks, accepting an edit only if its replayed reward beats noop (this is the structural step of Section 5.4). Use REINFORCE with the replay baseline only for what replay cannot evaluate exactly.

#### 3.4 Forgetting and privacy are different things

The **forget policy** proposes letting go of low-value nodes; it uses the reward above and an action mask that never touches nodes behind a keep or privacy wall. **Privacy deletion is not a learned action;** it is a hard constraint, and every trained quantity that saw the item must be recomputed: the node and its key; gists on its ancestor path (re-distilled); cite-log entries and training pairs that involve it; the heads (retrained without those pairs: exact unlearning by retraining is affordable because the heads train in minutes); and the keys of other nodes that learned from asks about it.

**Proposition 3.1 (exact decrement).** If node keys are stored as sufficient statistics $u_v=\mu k^0_v+\sum_{t\in\mathcal T_v}s_t$ with $k_v=\mathrm{unit}(u_v)$, deleting ask $t$ is exact: $u_v\leftarrow u_v-s_t$ gives the key that would exist had $t$ never happened. With the constant-step normalized update of Section 4.1, every later normalization rescales the earlier contributions, so one ask's effect can only be removed by replaying the log.

---

### 4. Use-driven key learning as online SGD

#### 4.1 The move rule is projected gradient descent

**Proposition 4.1.** Let $\Pi(x)=x/\lVert x\rVert$, the Euclidean projection onto the unit sphere ($x\ne0$). For $0<\eta<1$,
$$k^+=\Pi\big(k+\eta(s-k)\big)=\Pi\big(k-\eta\nabla_k\tfrac12\lVert k-s\rVert^2\big)=\Pi\big(k-\eta'\nabla_k(-\langle k,s\rangle)\big),\qquad \eta'=\frac{\eta}{1-\eta}.$$
*Proof.* $\nabla_k\frac12\lVert k-s\rVert^2=k-s$ gives the first equality. $k+\eta(s-k)=(1-\eta)\big(k+\eta' s\big)$ and $\Pi$ ignores positive scale. $\square$ (C4.)
On the sphere $\frac12\lVert k-s\rVert^2=1-\langle k,s\rangle$, so the move rule is projected SGD on the **cosine loss** $\ell_{cite}(k_v;s)=1-\langle k_v,s\rangle$, one step per cite. It is undefined only if $s=-k$ and $\eta=\frac12$.

#### 4.2 What it converges to, and the anchor

**Proposition 4.2.** Over unit vectors,
$$\arg\min_{\lVert k\rVert=1}\ \sum_{t\in\mathcal T_v}\tfrac12\lVert k-s_t\rVert^2+\tfrac\mu2\lVert k-k^0_v\rVert^2=\mathrm{unit}\Big(\sum_{t\in\mathcal T_v}s_t+\mu k^0_v\Big),$$
which is also the posterior mode when $s_t\sim\mathrm{vMF}(k,\kappa)$ and the prior is $k\sim\mathrm{vMF}(k^0_v,\kappa_0)$, with $\mu=\kappa_0/\kappa$ (the number of cites the node's own content is worth). *Proof.* On the sphere the objective is a constant minus $\langle k,\sum_ts_t+\mu k^0_v\rangle$; the vMF log-posterior is the same linear function times $\kappa$. $\square$ (C5: projected SGD with $1/t$ steps reaches it, cosine 1.00000.)
The move rule reaches this exactly if the step is $\eta_t=1/(1+\lVert u_t\rVert)$ with $u_t$ the running sum, since $\Pi(k_t+\eta(s-k_t))=\Pi(k_t+\eta' s)$ and $\Pi(u_t+s)=\Pi(k_t+s/\lVert u_t\rVert)$. With a constant $\eta$ it is a recency-weighted average: the weight of the original content $k^0_v$ decays roughly like $(1-\eta)^n$ after $n$ cites (0.35 after 10 cites at $\eta=0.1$), which is the "overwrite" failure. The anchored rule of `e6_fixes.py` (cap $\lVert k-k^0\rVert\le0.3$, then renormalize) is an approximate projection onto the intersection of the sphere and that ball; Proposition 4.2 gives the smooth version, $\mu>0$, whose fixed point always keeps $\mu k^0_v$ in the sum.

#### 4.3 The contrastive variant: pull cited, push opened-but-uncited, center

For one ask with state $s$, opened set $O$ (what the reasoning plane read), cited set $C\subseteq O$ and uncited $U=O\setminus C$:
$$\mathcal L_{key}(s)=\underbrace{\frac1{\lvert C\rvert}\sum_{v\in C}\log\Big(1+\sum_{u\in U}e^{\alpha\langle s,k_u\rangle-\alpha\langle s,k_v\rangle}\Big)}_{\text{ask}\to\text{node, within what was opened}}\;+\;\underbrace{\frac{1}{\lvert C\rvert}\sum_{v\in C}-\log\frac{e^{\alpha\langle s,k_v\rangle}}{\sum_{q'\in\mathcal B}e^{\alpha\langle s_{q'},k_v\rangle}}}_{\text{node}\to\text{ask, against a bank }\mathcal B\text{ of past asks}}\;+\;\frac\mu2\sum_{v\in C\cup U}\lVert k_v-k^0_v\rVert^2.$$
Euclidean gradients:
$$\nabla_{k_v}=-\frac{\alpha}{\lvert C\rvert}\Big[(1-\sigma_v)\,s+(s-\bar s_v)\Big]+\mu(k_v-k^0_v)\ \ (v\in C),\qquad \nabla_{k_u}=\alpha\,\omega_u\,s+\mu(k_u-k^0_u)\ \ (u\in U),$$
with $\sigma_v=\dfrac{e^{\alpha\langle s,k_v\rangle}}{e^{\alpha\langle s,k_v\rangle}+\sum_{u\in U}e^{\alpha\langle s,k_u\rangle}}$, $\omega_u=\dfrac1{\lvert C\rvert}\sum_{v\in C}\dfrac{e^{\alpha\langle s,k_u\rangle}}{e^{\alpha\langle s,k_v\rangle}+\sum_{u'\in U}e^{\alpha\langle s,k_{u'}\rangle}}$ and $\bar s_v=\sum_{q'\in\mathcal B}\mathrm{softmax}_{q'}\big(\alpha\langle s_{q'},k_v\rangle\big)s_{q'}$. The update is $k\leftarrow\Pi(k-\eta\nabla_k)$ per node.

What each term does:
- **Pull, self-limiting.** $(1-\sigma_v)\to0$ once the cited node beats the uncited ones, so a key stops moving when it already wins (the move rule keeps pulling forever).
- **Push, focused.** $\omega_u$ is large only for uncited nodes that outscored the cited ones (hard negatives) and vanishes for nodes already far away.
- **Centering.** The node-to-ask term pulls toward $s-\bar s_v$, the ask's specific part. **Proposition 4.3:** as $\alpha\to0$, $\bar s_v\to\frac1{\lvert\mathcal B\rvert}\sum_{q'}s_{q'}$, so the step direction becomes $s-\text{mean ask}$, which is the "centered" rule of `fix_cite_noise.py` with $c=1$ (that rule also normalizes the step direction, a per-ask step size). At $\alpha=20$ the softmax mean is local rather than global (check C6: the cosine between the two directions is 0.91 on synthetic data). It is the same gradient as the backward term of `e5` (Section 1.5).
- **Anchor.** Keeps a stationary point that remembers what the node says (Proposition 4.2).

Measured in `/tmp/claude-0/sm/fix-cite-noise/run.out` (rank-16 bridges, hyperparameters chosen on dev chats, 4,593 visits; each variant implements only part of $\mathcal L_{key}$): move 0.678 with clean cites and 0.654 with 30% wrong; pull plus fixed-step push of the opened-uncited ("contrastive") 0.683 and 0.671; centered pull 0.681 and 0.665; no learning 0.657. The full $\mathcal L_{key}$ (weighted push, centering and anchor together) has not been run.

#### 4.4 Why alias keys collapse (a derivation from the measured geometry)

The alias rule scores a node by $\max\big(\langle k_v,s'\rangle,\max_j\langle s_{q_j},s'\rangle\big)$, where the $s_{q_j}$ are states of asks that cited $v$. Node $v$ enters the top 10 of a later **unrelated** ask $s'$ through an alias iff $\max_j\langle s_{q_j},s'\rangle$ exceeds the 10th-best key cosine $\ell_{(10)}(s')/\alpha$ (margin 0, as in E6). In the rank-16 bridge space (`fix-alias-hub/run2.log`), unrelated asks in the same chat have mean cosine 0.308, ask-to-node cosines average 0.100, and the 10th-best key scores 0.350. The ask-to-ask distribution overlaps the entry threshold, and the measured entry rate for unrelated asks is 0.404. Every alias is a point inside the dense ask cloud, so the number of alias intruders in an unrelated ask's top 10 grows with the number of aliases, and recall collapses (0.463). The move rule at $\eta=0.1$ changes a key's score for an unrelated ask, to first order on the sphere, by $\eta\,\langle(I-kk^\top)s,s'\rangle=\eta\big(\langle s,s'\rangle-\langle k,s\rangle\langle k,s'\rangle\big)\approx0.1\,(0.308-0.379\cdot0.100)\approx0.03$ (0.379 is the mean ask-to-own-evidence cosine), far below the $0.25$ gap to the threshold. LoCoMo evidence turns are cited 1.65 times on average (59% once, at most 7), so keys never travel far, and the move rule does not intrude. The root cause is that asks are much closer to each other (0.31) than to nodes (0.10); centering (Section 4.3) and the uniformity side of the alignment loss (Section 6) both remove that common direction.

#### 4.5 Noisy cites

With wrong-cite rate $\rho_v$ for node $v$ and $n_v$ cites, Proposition 4.2 gives the anchored batch key as $\mathrm{unit}\big(n_v[(1-\rho_v)\hat m^+_v+\rho_v\hat m^-_v]+\mu k^0_v\big)$, where $\hat m^+_v$ and $\hat m^-_v$ are the mean states of the asks that correctly and wrongly cite $v$. **Conjecture 4.4.** Wrong cites drawn from near misses (as in E6) have $\hat m^-_v$ close to the centre of the ask cloud, so they pull keys toward the hub direction, and the gain from learning disappears when that pull cancels the specific pull of $\hat m^+_v$. Measured break-even for the move rule is near $\rho=0.3$ (0.654 vs 0.657); centering and the push term move it higher (contrastive at $\rho=0.3$: 0.671). The precise break-even as a function of the ask-cloud geometry is not derived.

#### 4.6 Keys as functions of the log, not free parameters

Nightly retraining changes $S$ and $A$, which makes per-node residuals learned against the old heads stale (the REALM stale-index problem at small scale). Store the cite log, not the key:
$$k_v=\mathrm{unit}\Big(\mu\,\mathrm{unit}(Ae_v)+\sum_{t\in\mathcal T_v}\big(\mathrm{unit}(Se_{q_t})-\bar s\big)-\beta\sum_{t\in\mathcal U_v}\mathrm{unit}(Se_{q_t})\Big),$$
with $\mathcal T_v$ the asks that cited $v$, $\mathcal U_v$ the asks that opened but did not cite it, $\bar s$ the mean ask state and $\beta\ge0$ small. This is the minimizer over the sphere of the linearized $\mathcal L_{key}$ with constant weights (Proposition 4.2 applied to the signed sum). Every key is recomputed exactly after each retraining (cost: the size of the log times $d_z$), and deletion is exact (Proposition 3.1).

---

### 5. Joint objective with an open reasoning model

#### 5.1 Parameters

| Block | Parameters | Trained by |
|---|---|---|
| LLM (Qwen3-8B) | frozen base $\theta_0$, LoRA $\Delta\theta$ | $\mathcal L_{LM}$, and through its hidden states $\mathcal L_{read}$, $\mathcal L_{align}$ |
| state reader | $S_R:\mathbb R^{d_h}\to\mathbb R^{d_z}$ reading layer $j^\star$ | $\mathcal L_{read}$, $\mathcal L_{align}$, $\mathcal L_{dist}$ |
| bridges | $S,A$ (low rank), $\alpha$, stop/write/reshape heads | Sections 1 to 3 |
| internode encoder | $g_\gamma$ | $\mathcal L_{hier}$, $\mathcal L_{or}$, $\mathcal L_{LM}$ via soft tokens |
| memory-to-LLM projector | $P:\mathbb R^{d_z}\to\mathbb R^{n_m\times d_h}$ ($n_m$ soft tokens per node) | $\mathcal L_{LM}$, $\mathcal L_{cyc}$ |
| text encoder | $f$ | frozen (no gradient) |
| structure | $G$: nodes, edges, membership, gist texts | discrete step (Section 5.4) |

#### 5.2 The loss

One episode: ask $x$; the LLM's state $z_t=\mathrm{unit}\big(S_R\,\mathrm{pool}(H^{(j^\star)}_t)\big)$; the read bridge opens $O_t$; the context is the opened texts plus soft tokens $Pk_v$; the LLM emits a thought (next $z_{t+1}$) or the answer $y$ with cites.
$$\mathcal L=\mathcal L_{LM}+\lambda_1\mathcal L_{read}+\lambda_2\mathcal L_{align}+\lambda_3\mathcal L_{hier}+\lambda_4\mathcal L_{stop}+\lambda_5\mathcal L_{cyc}+\lambda_6\mathcal L_{dist}+\Omega,$$
- $\mathcal L_{LM}=-\sum_j\log p_{\theta_0+\Delta\theta}\big(y_j\mid y_{<j},x,\mathrm{ctx}(O)\big)$, the answer's token log-likelihood;
- $\mathcal L_{read}=\mathcal L_{hop}$ (Section 1.6) with positives = gold evidence or verified cites, scored with $z_t$;
- $\mathcal L_{dist}=\mathrm{KL}\big(\mathrm{sg}[Q(\cdot\mid x,y)]\ \Vert\ p_\phi(\cdot\mid z_0)\big)$ over the retrieved candidates: the LLM's own judgement of which node helps, used when there is no gold evidence. The exact E-step is $Q(v\mid x,y)\propto p_\phi(v\mid z_0)\,p_\theta(y\mid x,v)$; REPLUG and Atlas drop the prior and add a temperature, $Q\propto\exp\big(\tfrac1\beta\log p_\theta(y\mid x,v)\big)$, which is the posterior under a uniform prior over the retrieved set at $\beta=1$;
- $\mathcal L_{align}$, $\mathcal L_{cyc}$ in Section 6; $\mathcal L_{hier}$, $\mathcal L_{stop}$ as above;
- $\Omega=0.01\sum_{W}\lVert W-I\rVert_F^2+\text{weight decay on }\Delta\theta,P,\gamma$.

**Why $\mathcal L_{dist}$ is the EM step.** With the latent "which node supports the answer" $v$, $\log p(y\mid x)=\log\sum_v p_\phi(v\mid x)p_\theta(y\mid x,v)\ge\sum_vQ(v)\big[\log p_\phi(v\mid x)+\log p_\theta(y\mid x,v)\big]+H(Q)$ (Jensen), with equality iff $Q$ is the exact posterior above. The E-step sets $Q$; the M-step trains the reader on $Q$-weighted likelihood and the read bridge by minimizing $\mathrm{KL}(Q\Vert p_\phi)$. Restricting the sum to the retrieved top $K$ biases the bound, as in REALM and Atlas.

#### 5.3 Which gradients flow where

| Loss | $\Delta\theta$ | $S_R$ | $S,A$ | $g$ | $P$ | $f$ | $G$ |
|---|---|---|---|---|---|---|---|
| $\mathcal L_{LM}$ | yes | no (top-$K$ is discrete) | $A$ only, through soft tokens $Pk_v$ | only through soft tokens of parents | yes | no | no |
| $\mathcal L_{read}$ | **yes, through $H_t$** | yes | yes | yes, if parents are candidates | no | no | no |
| $\mathcal L_{dist}$ | yes, through $z_0$ | yes | yes | yes | no | no | no (target detached) |
| $\mathcal L_{align}$ | yes | yes | text-side head | no | no | no | no |
| $\mathcal L_{hier}$, $\mathcal L_{or}$ | through $z$ if states come from the LLM | yes | yes | yes | no | no | no |
| $\mathcal L_{stop}$ | no (state detached, so the LLM cannot game the stop head) | no | no | no | no | no | no |
| $\mathcal L_{cyc}$ | no (teacher side detached) | no | yes | yes | yes | no | no |

Three deliberate stop-gradients: $f$ is frozen so the index never goes stale (re-projecting every key after a head update is one matrix product); the targets of $\mathcal L_{dist}$ and $\mathcal L_{or}$ are detached (EM targets); the stop head reads a detached state. The one coupling that makes the planes "one model" is the $\mathcal L_{read}\to H_t\to\Delta\theta$ path: the LLM is trained to put a good query into its own hidden state.

#### 5.4 Alternating schedule for discrete structure and continuous parameters

Let $\Theta$ be all continuous parameters and $\mathcal J(G,\Theta)=\mathbb E_{q\sim\mathcal D}\big[\mathcal L(q;G,\Theta)\big]+c_{size}\,\mathrm{size}(G)$ on a fixed replay set $\mathcal D$.
- **C-step (nightly):** $\Theta\leftarrow$ a descent step (or several) on $\mathcal J(G,\cdot)$ with $G$ fixed.
- **S-step (structural):** propose edits from the reshape policy; accept $G\leftarrow G\oplus a$ only if $\mathcal J(G\oplus a,\Theta)<\mathcal J(G,\Theta)$ by replay; re-distill gists on changed paths and recompute keys from the log (Section 4.6).
- **Fast path (per ask):** key updates from cites (Section 4), between C-steps.

**Proposition 5.1 (monotone descent).** If each C-step does not increase $\mathcal J$ on $\mathcal D$ and each S-step accepts only edits that decrease it on the same $\mathcal D$, then $\mathcal J(G_i,\Theta_i)$ is non-increasing; since $\mathcal J\ge0$, it converges. This is the argument for Lloyd's k-means and hard EM. It gives no global optimum, and it holds only approximately with stochastic C-steps or a subsampled replay set. Because new asks keep arriving and privacy deletions are exogenous edits that may increase $\mathcal J$, the real system tracks a moving target rather than converging. Keeping fast keys as functions of the log (Section 4.6) means a C-step never leaves stale keys behind, which avoids the two-timescale stability conditions (Borkar 1997) that free per-node parameters would need.

---

### 6. The shared space $Z$ and the alignment loss

#### 6.1 Definition

$Z=\mathbb S^{d_z-1}$ is the common language. Every plane has an encoder **into** $Z$ and the LLM has one decoder **out of** it:
- text view $\psi_T(x)=\mathrm{unit}(T\,f(x))$, $T\in\mathbb R^{d_z\times d_f}$ (the action head $A$ for nodes, the state head $S$ for asks);
- reasoning view $\psi_R(H_t)=\mathrm{unit}\big(S_R\,\mathrm{pool}(H^{(j^\star)}_t)\big)$, $S_R\in\mathbb R^{d_z\times d_h}$ (384 by 4,096 is 1.6M parameters; low rank is an option);
- memory view $\psi_M(u)=k_u$ from $g$;
- decoder $P:Z\to\mathbb R^{n_m\times d_h}$, soft tokens the LLM reads.

#### 6.2 Read-out alignment: LLM state and text encoder agree on the same thought

For a batch of $B$ thoughts with hidden states $H_i$ and decoded text $x_i$:
$$\mathcal L_{align}=\frac1{2B}\sum_{i=1}^B\Big[-\log\frac{e^{\alpha\langle\psi_R(H_i),\psi_T(x_i)\rangle}}{\sum_je^{\alpha\langle\psi_R(H_i),\psi_T(x_j)\rangle}}-\log\frac{e^{\alpha\langle\psi_R(H_i),\psi_T(x_i)\rangle}}{\sum_je^{\alpha\langle\psi_R(H_j),\psi_T(x_i)\rangle}}\Big].$$
Hard negatives are other thoughts of the same episode. After training, the LLM's hidden state can be used as a query against keys built from text, without generating text first, and heads trained on the text view (the current bridges) carry over to the hidden-state view.

Properties:
1. Each direction bounds mutual information from below: $I\big(\psi_R(H);\psi_T(X)\big)\ge\log B-\mathcal L_{NCE}$ (van den Oord et al. 2018; Poole et al. 2019). The bound cannot exceed $\log B$, so small batches cap what it can certify.
2. As $B\to\infty$, $\mathcal L_{NCE}-\log B\to-\alpha\,\mathbb E\langle\psi_R,\psi_T\rangle+\mathbb E_H\log\mathbb E_{x'}e^{\alpha\langle\psi_R(H),\psi_T(x')\rangle}$: an **alignment** term and a **uniformity** term (Wang and Isola 2020). Uniformity spreads states over $Z$, which counters the dense ask cloud behind the alias collapse (Section 4.4).
3. Why not regression $\lVert\psi_R(H)-\psi_T(x)\rVert^2$: with both sides trainable it is minimized by collapsing to a constant, and with $\psi_T$ frozen it spends capacity matching directions shared by all texts. Retrieval only uses cosine ranking, which is what the contrastive loss constrains.

Layer choice: pick $j^\star$ by training a linear $S_R$ per layer and keeping the layer with the best held-out retrieval. (Assumption, not measured here: middle layers usually carry the most retrievable semantics.)

#### 6.3 Write-in alignment: a node's vector should read like its text

$$\mathcal L_{cyc}=\mathbb E_u\ \mathrm{KL}\Big(p_{\theta}\big(\cdot\mid x_u,\text{probe}\big)\ \Big\Vert\ p_{\theta}\big(\cdot\mid P\,\psi_M(u),\text{probe}\big)\Big),$$
the LLM's next-token distribution on a probe prompt with the node's text in context (teacher, detached) versus with its soft tokens (student). It trains $P$, and through $\psi_M$ also $g$ and $A$, so that $Z$ is readable by the LLM, not only writable by it (as in xRAG and ICAE). One 384-dimensional vector carries far less than a 50-token gist, so soft tokens add to text in the context; they do not replace it.

---

### 7. What can be trained from scratch

| Part | From scratch? | Objective | Why |
|---|---|---|---|
| bridges $S,A$, stop, write, reshape heads | yes | Sections 1 to 3 | $10^4$ to $10^6$ parameters; the identity init is a prior, not a requirement |
| internode encoder $g$ | yes | $\mathcal L_{or}$ (label-free) then $\mathcal L_{hier}$ | no pretrained model does this job |
| $S_R$, $P$ | yes | $\mathcal L_{align}$, $\mathcal L_{cyc}$ | small linear maps between fixed spaces |
| text encoder $f$ | not practical | contrastive pretraining | needs on the order of $10^8$ pairs; fine-tuning it forces re-encoding every node |
| reasoning LLM | no (LoRA only) | $\mathcal L_{LM}$ plus couplings | 8B parameters |

Capacity matters at our data size (about 1,200 training asks per fold): a full head has $d^2=147{,}456$ parameters, a rank-16 head $2dr=12{,}288$. The measured overfit of full-rank heads (0.610 vs 0.657 on LoCoMo; 0.822 vs 0.864 on LongMemEval-S, below the frozen encoder's 0.860) fits that count.

### 8. Predictions that follow from the math (each testable)

1. Changing the read loss only changes asks with $m_q\ge2$ in the forward direction (identical functions at $m_q=1$); the effect concentrates on multi-hop asks. Measured: $+0.017$ on the 409 multi-evidence asks, $-0.004$ (not significant) on single-evidence asks. A follow-up test: whether the backward term helps transfer to LongMemEval-S despite costing LoCoMo multi-evidence asks.
2. Under $\mathcal L_{mask}$ with an unclamped $\alpha$, longer training drives $\alpha$ up on separable training chats; under $\mathcal L_{out}$ it stays bounded.
3. Parent routing by a single mean vector degrades as sessions grow (margin $\propto1/n_u$); routing by soft-OR-trained prototypes degrades slowly with $n_u$ and approaches max-pooling as $m$ grows.
4. A top-$b$ router cannot exceed the coverage ceiling $\mathbb E\big[\min(m^{(\ell)}_q,b)/m^{(\ell)}_q\big]$ (0.939 for LoCoMo multi-hop at $b=3$, sessions as parents); adaptive $b$ is required to pass it.
5. Any key rule that places vectors in the ask cloud (aliases, large $\eta$) intrudes into unrelated asks at a rate set by the overlap between ask-ask similarity and the 10th-best key score; centered or contrastive rules reduce the intrusion.
6. A rank sweep $r\in\{2,4,8,16,32,64,\text{full}\}$ should show the LoCoMo-to-LongMemEval transfer gap growing with $r$ (conjecture).
7. Pretraining $S_R$ with $\mathcal L_{align}$ should let the LoCoMo-trained bridges work on LLM hidden states with no retrieval labels, with recall close to the text-view recall (conjecture).
