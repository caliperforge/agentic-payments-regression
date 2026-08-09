# coverage_map.md: arXiv x402 corpus coverage

**Status.** M1 shipping selection closed, 2026-07-14, at four planted-twin
pairs; two M1+ novel-variant pairs landed 2026-07-15, so six pairs ship (§3
row totals). Sources are catalogued in §1. Author lists, version
tags, and per-paper section anchors were re-pulled live on 2026-08-08. §1 and
§3 now carry a `[VERIFIED 2026-08-08 source: ...]` anchor on every row the
fetched paper supports, and a plain sentence on every row it does not. §6
records what the pull returned.

An earlier version of this paragraph said every `[UNVERIFIED-AT-FETCH]` marker
would close before public flip. That did not happen. The file went public on
2026-07-16 with eleven markers still in it; they closed on 2026-08-08, twenty-
three days after the flip. Of the eight markers on catalog rows, five closed to
a section anchor read on the fetched page. Three could not be closed, because
the paper cited does not contain the claim the row makes; those three now carry
a plain sentence saying so. No row was deleted. The remaining three markers were
prose (this section twice, and §6) and are rewritten above and below.

---

## 1. Sources

Three arXiv papers per `agents/solidity_specialist/inbox/T-ef-anchor-harness-m1-scaffold-2026-07-14_arxiv-urls-reply.md` §1 (grant_writer, 2026-07-14, sourced from research_lead's verification memo §7  -  all three URLs returned WebFetch HTTP 200 on 2026-07-14, inside the 72-hour analysis-class TTL, so no re-fetch was issued this session).

**Live re-pull 2026-08-08 (audit_engineer).** All three abstract pages returned HTTP 200. Every author list below matches the fetched page exactly, character for character. Version tags are closed in the ID column: P1 lists v1 (2026-04-13) and v2 (2026-06-30), P3 lists v1 (2026-05-29) and v2 (2026-06-22), and P2 has only v1 (2026-05-12), so P2's previously unlabeled ID closes to `v1` rather than to a higher version. Full text was read from `arxiv.org/html/` for section anchors: P1 v2 and P2 v1 served HTML; P3 v2 returned HTTP 404 and P3 v1 served HTML, so every P3 anchor below is a **v1** anchor and is written as such. The P3 v2 abstract lists the same four flaw classes in the same order as v1.

| # | arXiv ID | URL | Title | Retrieval | Author list |
|---|---|---|---|---|---|
| P1 | arXiv:2604.11430v2 | https://arxiv.org/abs/2604.11430 | *Hardening x402: PII-Safe Agentic Payments via Pre-Execution Metadata Filtering* | 2026-07-15 (solidity_specialist); re-pulled 2026-08-08 (audit_engineer, HTTP 200, author list exact match, v2 latest) | Vladimir Stantchev |
| P2 | arXiv:2605.11781v1 | https://arxiv.org/abs/2605.11781 | *Five Attacks on x402 Agentic Payment Protocol* | 2026-07-15 (solidity_specialist); re-pulled 2026-08-08 (audit_engineer, HTTP 200, author list exact match, only version is v1) | Zelin Li, Qin Wang, Zhipeng Wang |
| P3 | arXiv:2605.30998v2 | https://arxiv.org/abs/2605.30998 | *Free-Riding the Agentic Web: A Systematic Security Analysis of x402 Payments* | 2026-07-15 (solidity_specialist); re-pulled 2026-08-08 (audit_engineer, HTTP 200, author list exact match, v2 latest; v2 full text 404, anchors read from v1) | Shengchen Ling, Yihang Huang, Yuefeng Du, Yuan Chen, Yajin Zhou, Lei Wu, Cong Wang |

**Load-bearing correction from grant_writer's reply §2 (adopted here).** The CoS memo's "eleven vulnerabilities across five classes" phrasing does not reconcile with the papers per research_lead's verification pass. Actual paper shape:

- **P1 (2604.11430)**  -  privacy / PII hardening middleware; methodology paper, not attack-count.
- **P2 (2605.11781)**  -  five concrete attacks, tested on Base Sepolia + live endpoints + 3 open-source SDKs.
- **P3 (2605.30998)**  -  four flaw classes with measured oracles (resource-leakage ratio up to 100%; 8.7× attacker leverage → 0.9× with defense).

The "one live endpoint that produced 248 HTTP payment grants for a single on-chain settlement" line from the CoS memo was flagged UNVERIFIED per that same reply. **The 2026-08-08 re-pull found it.** P2 §4.3 (Evaluating Attack II) reads: *"In the strongest positive round, we observe 248 HTTP-layer grants and 1 on-chain settlement."* The figure is real and it belongs to P2, not to P3. §6 predicted it would reconcile against P3 if it reconciled at all; the string "248" does not occur anywhere in P3 v1. Attribution and the retired-vs-resurrected call are recorded in `docs/oracle_248to1_disposition.md`.

This library still does not encode 248:1 as an oracle, and the reason is now a measured one rather than a doubt about the figure. 248:1 is a per-round count from 1,000 concurrent HTTP requests against a live testnet endpoint; a Solidity twin has no HTTP layer and no concurrency, so it cannot assert that number. The V04 planted twin reproduces the *class* (>1 grant per one settlement) via the on-chain CEI-violation analog of the HTTP race.

---

## 2. Reference implementations targeted

M1 ships in-source planted-twin facilitator contracts under `src/V0{1,2,3,4}_*.sol`. No third-party reference implementation is vendored in M1  -  the facilitators are minimal reproductions of the attack surface described by the papers, small enough to read end-to-end during §4b review, and free of adjacent-substrate dependencies (no HTTP facilitator middleware, no off-chain signing side-channels, no wallet UI).

If a downstream integrator (or an M2 disclosure record) needs a reproduction wired against a specific published SDK, the `NOTICE` scaffolding is in place for the vendoring policy (proof_register row 6 shape: vendored source + upstream license + modification statement). M1 does not need it.

---

## 3. Vulnerability catalog + M1 / M2 / out-of-scope split

Catalog rows below are named against the paper each row cites. Class taxonomy mirrors the papers themselves (per grant_writer's correction adopted in §1) rather than the CoS memo's "5 classes" phrasing.

### Class A: Payment-authorization integrity (P2)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| A.1 | Payment replay: signed payment authorization can be resubmitted N times by the facilitator (or any observer with the signature) against a payer whose token allowance has not been reset. | P2 `[VERIFIED 2026-08-08 source: arXiv:2605.11781v1 §3.2]` — Attack II, "Replay / Idempotency across the HTTP–Chain Boundary": *"Single payment capability reused across multiple HTTP requests produces many grants despite one on-chain settlement."* Evaluated at §4.3; enumerated in Table 1 (§1). Row shape matches the paper. | **M1** → `src/V01_Replay.sol` + `test/V01_Replay.t.sol` + `test/planted/V01_Replay.planted.t.sol` | Cleanest map to a Solidity feature-flag twin. Attack is deterministic on the pinned toolchain; INVARIANT VIOLATED fires in <1s local, well inside CI budget. |
| A.2 | Overpayment / wallet drain: facilitator accepts a caller-supplied `amount` on settle() rather than the resource-owner-posted price. Combined with the infinite-approval UX pattern, any caller drains the payer. | P2 (arXiv:2605.11781v1) — **no anchor; this citation does not hold.** The 2026-08-08 re-pull read all five of P2's attacks (§3.1.1 revert-grant, §3.1.2 settlement preemption, §3.2 replay, §3.3 HTTP/proxy confusion, §3.4 server selection) and the cross-implementation audit at §4.6. None of them is a caller-supplied-`amount` overpayment. The nearest published relative is P3 v1 §5.2 (allowance overdraft), and its mechanism is different: an `upto` snapshot check passing at verify time against a larger transfer at settle time, driven by concurrent request volume rather than by a caller-controlled price field. P3 does not describe a charge exceeding the resource owner's posted price. **The attack shape V02 reproduces is not in the three-paper corpus.** The row and the twin stay; the "published attack" claim on this row does not. See §6a. | **M1** → `src/V02_Overpayment.sol` + `test/V02_Overpayment.t.sol` + `test/planted/V02_Overpayment.planted.t.sol` | Same-class as A.1 for a Solidity twin; the signed-struct-vs-caller-arg asymmetry is a common SDK regression shape worth having in the M1 audience's view. |
| A.3 | Signature semantic gap: signed authorization omits recipient (and / or resource identifier) from the digest; attacker resubmits with recipient=attacker to reroute funds. | P2 `[VERIFIED 2026-08-08 source: arXiv:2605.11781v1 §4.6]` — Cross-Implementation Audit: *"First, no audited SDK binds a payment to the intended resource: a payment signed for resource AA on Endpoint-1 can be replayed for resources BB, CC, and DD on the same server."* The recipient-binding half of this row is at §3.1.2 (Attack I-B): *"Settlement paths do not bind the facilitator identity to authorization. In EIP-3009, any observer can submit the signed authorization first."* Independently corroborated by P3 v1 §4.2 (cross-resource substitution). Row shape matches. Note the row was previously anchored to a §3 attack heading; the resource-binding finding is an audit result at §4.6, not one of the five numbered attacks. | **M1** → `src/V03_CrossResource.sol` + `test/V03_CrossResource.t.sol` + `test/planted/V03_CrossResource.planted.t.sol` | Cleanest single-contract EIP-191 twin. Deliberately mirrors the EIP-712-underconstraint bug class rather than pretending to be a full EIP-712 reproduction  -  full domain-separator work is M2 if a downstream asks. |
| A.4 | Cross-chain / cross-facilitator signature replay via EIP-712 domain-separator underconstraint: signed digest omits `chainId` and / or `verifyingContract`, so the same signature verifies against every facilitator instance on every chain. **NOVEL** (not in the arXiv corpus). | Class-precedent bugs: 2016 ETC replay, 2020 Uniswap `permit` chainId-omission, 2022 OpenSea sig-replay, 2023 Multichain bridge cross-chain replays. Reference pattern: OpenZeppelin `EIP712.sol` (Apache-2.0). Candidate source: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md` §3-C1. | **M1+ / novel** → `src/V05_CrossDomain.sol` + `test/V05_CrossDomain.t.sol` + `test/planted/V05_CrossDomain.planted.t.sol` | Domain-level semantic gap, orthogonal to A.1 (per-digest replay on one facilitator on one chain) and to A.3 (recipient-in-digest gap on one facilitator on one chain). Blast radius strictly larger: one signature replays across every deployed (facilitator, chain) pair sharing the token contract. |

### Class B: Prompt-layer attacks (no source in the corpus; see B.1)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| B.1 | Prompt-injection payment: LLM instructed via untrusted resource content to authorize a payment the human user did not intend. | P2 (arXiv:2605.11781v1) — **no anchor; this citation does not hold.** Prompt injection appears in none of the three papers on the 2026-08-08 re-pull. P2's five attacks are settlement-path, replay, HTTP/proxy, and server-selection; it contains no LLM-instruction attack. P3 v1 contains none. P1 v2 §3.1 is a PII threat model, not an instruction-manipulation one. **This row has no source in the corpus catalogued in §1.** It stays because the class is real and the row is M2-scoped, not M1-shipped; M2 must supply a citation before anything reproduces it. See §6a. | **M2** | Off-chain LLM decision surface; no clean Solidity twin without vendoring an LLM harness. Route via AI-safety framing in the M2 disclosure workflow. |

### Class C: On-chain observability (cited to P2 in error; see C.1)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| C.1 | Privacy / transaction-graph linkability: measured resource-leakage ratio up to 100% via calldata + event content on public chains. | P2 (arXiv:2605.11781v1) — **no anchor; this row carries two separate mis-citations.** First, P2 contains no privacy, linkability, or leakage-ratio content at all (re-pulled 2026-08-08). Second, "resource-leakage ratio up to 100%" is P3's figure, and P3 v1 §5.4.1 defines it as ρ = 1 − (total settled value ÷ total delivered value): compute that was delivered and never paid for, which is free-riding rather than privacy leakage. The privacy surface this row actually describes is P1's subject (arXiv:2604.11430v2 §1, §3.2 — payment metadata reaching the facilitator before settlement). Both errors are stated here rather than removed. See §6a. | **M2** | Reproduces cleanly as an on-chain observation harness, not as a clean/planted invariant. Better suited to a metrics-oriented notebook in M2 than a Foundry twin. |

### Class D: Settlement-race / duplicate-service-grant (P3)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| D.1 | Concurrency race: probabilistic duplicate service grants per one on-chain settlement, when facilitator emits the grant before finalizing settlement state. Paper reports the class with measured oracles (resource-leakage ratio, attacker-leverage delta). | P3 `[VERIFIED 2026-08-08 source: arXiv:2605.30998v1 §4.3]` — "Probabilistic Service Duplication: Violating Authorization Uniqueness (I4)". Measurement at §4.3.4: *"In 3 out of 50 rounds (6%), we successfully triggered service duplication...we received two distinct HTTP 200 responses...only one transaction was included on-chain."* Enumerated in Table 1 (§1). Row shape matches. Anchor is a **v1** anchor: the v2 full text returned HTTP 404 on 2026-08-08 and the v2 abstract lists the same four classes in the same order. | **M1** → `src/V04_DoubleGrant.sol` + `test/V04_DoubleGrant.t.sol` + `test/planted/V04_DoubleGrant.planted.t.sol` | On-chain analog encoded as a CEI-violation reentrancy twin. Reproduces the *class* (>1 grant per settlement); does NOT restate the 248:1 numeric oracle. That figure is real and published — the 2026-08-08 re-pull found it at P2 §4.3 — but it is a per-round HTTP-layer count and a Solidity twin has neither an HTTP layer nor concurrency, so it cannot assert it. See §1 and §6b. |
| D.2 | Remaining flaw-class rows from P3 (verification memo cites 4 total). | P3 `[VERIFIED 2026-08-08 source: arXiv:2605.30998v1 §4.2, §5.2, §5.3]` — the three classes other than D.1 are cross-resource substitution (§4.2), allowance overdraft (§5.2), and denial of settlement (§5.3). Table 1 (§1) enumerates all four plus an on-chain front-running row. The "4 total" count in the verification memo is correct. **v1** anchors, per the note on D.1. | **M2** | Held for the novel-variant hunt milestone. Row IDs closed on the 2026-08-08 re-pull; note that §4.2 (cross-resource substitution) already ships in M1 as A.3 / `V03_CrossResource`, so the M2 remainder from P3 is two classes, not three. |

### Class F: Delegation-scope integrity (novel)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| F.1 | Cumulative-cap violation on a session-key path: session-key manager fails to persist per-period cumulative spent, so the spender can drain the payer's approval across N invocations well beyond the signed per-period `allowance`. **NOVEL** (not in the arXiv corpus). | Reference pattern: Coinbase `SpendPermissionManager` (Apache-2.0), a live-deployed session-key permission model on Base; AP2 mandate model (Google Agent Payments Protocol). Class-precedent bugs: repeat cumulative-cap-update-ordering issues in ERC-4337 session-key modules (Rhinestone / ModuleKit, Ithaca). Candidate source: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md` §3-C2. | **M1+ / novel** → `src/V06_DelegationCap.sol` + `test/V06_DelegationCap.t.sol` + `test/planted/V06_DelegationCap.planted.t.sol` | Different accounting invariant from A.2 (which caps a *single* settle to an owner-posted price). F.1 caps *cumulative* settlement across N invocations under a delegation. Delegation-state surface vs single-call-state surface. Materializes the moment agents (not humans) hold the delegated key  -  precisely the x402 use case. |

### Class E: Defense methodology (P1)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| E.1 | PII-safe agentic-payment hardening methodology (not an attack; a defense-side line). | P1 `[VERIFIED 2026-08-08 source: arXiv:2604.11430v2 §3.2]` — Architecture; the middleware's PIIFilter control scans `resource_url`, `description`, and `reason` for PII entities before transmission. Evaluated across §5 (42-configuration precision/recall sweep; recommended config micro-F1 0.894 at p99 5.73 ms per the v2 abstract). Row shape matches: P1 is methodology, not an attack-count paper. | **out-of-scope for M1 as a twin** | P1 is methodology, not an attack-count paper. It informs the clean-twin baseline shape (why the defense side of V01-V04 looks the way it does) but does not warrant a dedicated `<Name>.sol` reproduction. |

**Row totals.** 4 M1 twins (A.1, A.2, A.3, D.1) + 2 M1+ / novel twins (A.4, F.1) + 3 M2 (B.1, C.1, D.2) + 1 out-of-scope (E.1). Class coverage per M1: A × 3, D × 1; per M1+ / novel: A × 1 (domain-level, orthogonal to A.1-A.3), F × 1 (new class). Six shipped twins total. Three classes still deliberately absent from M1 / M1+ (B off-chain LLM, C observability, E defense-only). The M1+ / novel additions expand the taxonomy in two orthogonal directions: A.4 upgrades the payment-auth-integrity class from single-facilitator-single-chain to cross-facilitator / cross-chain, and F.1 opens a delegation-state class that was not present at all in M1.

---

## 4. M1 selection rationale (closed)

Selection criteria from the initial draft (unchanged):

1. **Cleanest Solidity planted-twin map**  -  bug reproduces deterministically in a small facilitator with a `defenseOn` constructor flag.
2. **Class coverage over class depth**  -  modified (see §3 row-totals note): depth-in-A wins over breadth after weighing the reviewer signal.
3. **Non-controversial published source**  -  every selected row cites the paper directly; no novel-attack framing carried forward.
4. **Reproducible in CI-timeout budget**  -  every planted leg fires INVARIANT VIOLATED in <2s local (all four inside 90ms of forge test wall time; well under the 5-minute CI ceiling).

**Selection outcome.** A.1 (V01_Replay), A.2 (V02_Overpayment), A.3 (V03_CrossResource), D.1 (V04_DoubleGrant). Four twins land in the base M1 set; all four planted legs fire the marker; all four clean legs pass silently.

**M1+ / novel-variant addition (2026-07-15).** A.4 (V05_CrossDomain) and F.1 (V06_DelegationCap) land under the same clean/planted twin discipline. The candidate hunt that surfaced them is at `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md`; the engineering encode step is at `agents/solidity_specialist/outbox/T-ef-anchor-encode-v05-v06-2026-07-15_result.md`. Neither reproduces a published attack; both encode a class the arXiv corpus does not name, per §3 rows A.4 and F.1.

**Explicit non-carries.** No "would-have-caught" claim for any twin. Every twin frames as "reproduces the published attack class; confirms the CI-runnable planted-twin shape is on-target for x402 substrate." Any language stronger than that is out of scope for M1 per the ticket brief and the CoS memo §"What has to be true".

---

## 5. Local run verdict (2026-07-14)

```
================================================================
 agentic-payments-regression M1  -  clean/planted twin summary
================================================================
 CLEAN PASS V04_DoubleGrant
 CLEAN PASS V05_CrossDomain
 CLEAN PASS V02_Overpayment
 CLEAN PASS V01_Replay
 CLEAN PASS V06_DelegationCap
 CLEAN PASS V03_CrossResource
 PLANTED FIRED V03_CrossResource (INVARIANT VIOLATED)
 PLANTED FIRED V04_DoubleGrant (INVARIANT VIOLATED)
 PLANTED FIRED V05_CrossDomain (INVARIANT VIOLATED)
 PLANTED FIRED V06_DelegationCap (INVARIANT VIOLATED)
 PLANTED FIRED V01_Replay (INVARIANT VIOLATED)
 PLANTED FIRED V02_Overpayment (INVARIANT VIOLATED)
----------------------------------------------------------------
 clean total: 6 clean failed: 0
 planted total: 6 planted failed: 0
================================================================
```

Reproduction: `./run.sh` from the repository root. Forge 1.7.1 (nightly, build 2026-05-08). Total wall time under one second on the developer laptop; CI budget on `ubuntu-latest` at nightly Foundry is expected to stay under two minutes end-to-end (measure on first CI run once the M1 branch flips public). Table refreshed 2026-07-15 after V05_CrossDomain + V06_DelegationCap landed (M1+ / novel-variant additions).

### 5a. Multi-seed reachability verdict (2026-07-15)

Every planted twin is also certified across a fixed 16-seed set
(`ci/reachability_seeds.txt`); every seed must fail with an
`INVARIANT VIOLATED` marker on every planted suite. This upgrades the
base matrix's one-seed catch to a deterministic N-of-N certification,
so "the planted twin fires" is a property of the case, not the outcome
of a lucky CI seed. See `docs/reachability.md` for the rule and
`docs/reachability_run.log` for the full per-seed run.

| twin | planted contract | k / 16 | verdict |
|---|---|---|---|
| V01 payment-replay | `V01_ReplayPlantedTest` | 16 / 16 | reachability certified: yes |
| V02 overpayment | `V02_OverpaymentPlantedTest` | 16 / 16 | reachability certified: yes |
| V03 cross-resource | `V03_CrossResourcePlantedTest` | 16 / 16 | reachability certified: yes |
| V04 double-grant | `V04_DoubleGrantPlantedTest` | 16 / 16 | reachability certified: yes |
| V05 cross-domain (novel) | `V05_CrossDomainPlantedTest` | 16 / 16 | reachability certified: yes |
| V06 delegation-cap (novel) | `V06_DelegationCapPlantedTest` | 16 / 16 | reachability certified: yes |

```
reachability certified: yes (all suites, 16/16 failed as required)
```

Reproduction: `ci/reachability_leg.sh` from the repository root.
The leg is wired into `.github/workflows/ci.yml` as job
`reachability-multi-seed` and is invoked by `run.sh` after the base
matrix passes.

---

## 6. Citation disposition (executed 2026-08-08)

This section was a plan. It ran on 2026-08-08, twenty-three days after the public flip it was supposed to precede. What follows is what the pull returned.

The plan called for three things. All three were pulled:

- **Author list per paper (§1 rows P1 / P2 / P3).** All three match the fetched abstract page exactly. No correction needed.
- **Version tag on each arXiv ID.** P1 → v2, P3 → v2, P2 → v1 (P2 has no later version). §1's ID column is updated; P2's previously unlabeled ID now reads `v1`.
- **Exact section / table / figure anchor per catalog row.** Five of eight closed. Three did not, for the reason in §6a.

Anchors closed: A.1 → P2 v1 §3.2 (evaluated §4.3), A.3 → P2 v1 §4.6 (with §3.1.2), D.1 → P3 v1 §4.3 (measured §4.3.4), D.2 → P3 v1 §4.2 / §5.2 / §5.3, E.1 → P1 v2 §3.2 (evaluated §5). P3's full text is served only at v1 (v2 returned HTTP 404), so every P3 anchor is a v1 anchor and says so.

### 6a. What did not close, and what that costs

Three rows cite a paper that does not contain the claim the row makes. A.2 (overpayment), B.1 (prompt injection), and C.1 (privacy / linkability) are all attributed to P2, and P2 contains none of the three. Each row now carries a sentence saying so in place of its marker. No row was deleted, no twin was edited, and no `.sol` or test file was touched under this pass.

The consequence for M1's public claim is specific and it is A.2's alone. B.1 and C.1 are M2 rows: nothing ships against them, so a wrong citation there is a documentation defect. A.2 ships as `src/V02_Overpayment.sol`, and the claim attached to it — that it reproduces a published attack — is not supported. `V02_Overpayment` reproduces a real and well-known bug class. It is not a reproduction of anything in this corpus.

This section previously said that a mismatch between a paper and a twin means the twin is revised to match the paper or downgraded to M2, and that the M1 bar does not accept a mismatch closed as "spirit-of-the-paper." That rule now has a case to decide. **The call is not made here.** Revising `V02_Overpayment.sol` or moving it to M2 is an engineering change, and the pass that measured this mismatch was scoped to documentation. Until it is decided, the honest reading of M1 is: six twins ship, three reproduce a corpus attack, two are novel by design, and one reproduces a class the corpus does not carry. `README.md` states it that way.

### 6b. The 248:1 oracle

Resolved, and not where this section expected. The conditional above asked whether "248:1" reconciles against **P3**. It does not: the string "248" does not appear anywhere in P3 v1. It reconciles against **P2 §4.3**, which reads *"In the strongest positive round, we observe 248 HTTP-layer grants and 1 on-chain settlement."* The figure is real, it is published, and grant_writer's "likely fabricated" flag is withdrawn against the number itself while standing against the attribution the CoS memo gave it. `docs/oracle_248to1_disposition.md` carries the record.

The library's posture is unchanged and the reason for it is now better than it was. 248:1 is still not encoded as an oracle anywhere in `src/` or `test/`, because it is a per-round HTTP count from 1,000 concurrent requests against a live testnet endpoint and a Solidity twin has neither an HTTP layer nor concurrency.

---

## 7. Change log

| Date | Change | By |
|---|---|---|
| 2026-07-14 | File created; catalog rows placeholder pending grant_writer URL delivery; M1 / M2 split proposed by criteria in §4. | solidity_specialist |
| 2026-07-14 | Sources §1 closed to real arXiv IDs per grant_writer reply. Catalog §3 rewritten around actual paper shape (P2 five attacks / P3 four flaw classes / P1 methodology) after correction from CoS memo's disputed "11 / 5" phrasing. M1 shipping set closed to A.1 / A.2 / A.3 / D.1 (four twins). Local run verdict (§5) recorded. | solidity_specialist |
| 2026-07-15 | 16-seed reachability certification added (`ci/reachability_leg.sh`, `ci/reachability_seeds.txt`, `docs/reachability.md`, `docs/reachability_run.log`). CI job `reachability-multi-seed` wired; `run.sh` invokes the leg after the base matrix passes. All four planted twins certify 16/16. Section 5a records the verdict. | solidity_specialist |
| 2026-07-15 | M1+ / novel-variant additions: A.4 (V05_CrossDomain, EIP-712 domain-separator underconstraint) and F.1 (V06_DelegationCap, cumulative-cap violation on a session-key path). Both twins clean-pass and planted-fire on all 16 reachability seeds. `run.sh` now reports 6/6 clean + 6/6 planted; §5a table extended to 6 rows; §3 gains new class F for delegation-scope integrity. Neither twin reproduces a published attack; both encode a class the arXiv corpus does not name (candidate hunt: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md`). | solidity_specialist |
| 2026-08-08 | Citation disposition executed (§6). All three papers re-pulled live: HTTP 200 on every abstract page, author lists match exactly, version tags closed (P1 v2, P2 v1, P3 v2; P3 full text served only at v1). Five of eight catalog markers closed to a read section anchor (A.1, A.3, D.1, D.2, E.1). Three did not close: A.2, B.1, and C.1 cite P2 for claims P2 does not contain, and each now carries a plain sentence saying so instead of a marker (§6a). No row deleted, no `.sol` or test file touched. "248:1" resolved: it is in P2 §4.3, not P3; `docs/oracle_248to1_disposition.md` added. §Status rewritten to record that the file went public on 2026-07-16 with eleven markers still in it. | audit_engineer |
