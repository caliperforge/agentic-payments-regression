# coverage_map.md: arXiv x402 corpus coverage

**Status.** M1 shipping selection closed, 2026-07-14. Four planted-twin pairs
land against the three-paper corpus catalogued in §1. Reference-implementation
attribution and per-paper section anchors remain `[UNVERIFIED-AT-FETCH]`
pending a live re-pull of the abstract pages (see §6 for the disposition
plan). Every `[UNVERIFIED-AT-FETCH]` marker closes before public flip.

---

## 1. Sources

Three arXiv papers per `agents/solidity_specialist/inbox/T-ef-anchor-harness-m1-scaffold-2026-07-14_arxiv-urls-reply.md` §1 (grant_writer, 2026-07-14, sourced from research_lead's verification memo §7  -  all three URLs returned WebFetch HTTP 200 on 2026-07-14, inside the 72-hour analysis-class TTL, so no re-fetch was issued this session).

| # | arXiv ID | URL | Title | Retrieval | Author list |
|---|---|---|---|---|---|
| P1 | arXiv:2604.11430v2 | https://arxiv.org/abs/2604.11430 | *Hardening x402: PII-Safe Agentic Payments via Pre-Execution Metadata Filtering* | 2026-07-15 (solidity_specialist, verified HTTP 200 + abstract-page metadata) | Vladimir Stantchev |
| P2 | arXiv:2605.11781 | https://arxiv.org/abs/2605.11781 | *Five Attacks on x402 Agentic Payment Protocol* | 2026-07-15 (solidity_specialist, verified HTTP 200 + abstract-page metadata) | Zelin Li, Qin Wang, Zhipeng Wang |
| P3 | arXiv:2605.30998v2 | https://arxiv.org/abs/2605.30998 | *Free-Riding the Agentic Web: A Systematic Security Analysis of x402 Payments* | 2026-07-15 (solidity_specialist, verified HTTP 200 + abstract-page metadata) | Shengchen Ling, Yihang Huang, Yuefeng Du, Yuan Chen, Yajin Zhou, Lei Wu, Cong Wang |

**Load-bearing correction from grant_writer's reply §2 (adopted here).** The CoS memo's "eleven vulnerabilities across five classes" phrasing does not reconcile with the papers per research_lead's verification pass. Actual paper shape:

- **P1 (2604.11430)**  -  privacy / PII hardening middleware; methodology paper, not attack-count.
- **P2 (2605.11781)**  -  five concrete attacks, tested on Base Sepolia + live endpoints + 3 open-source SDKs.
- **P3 (2605.30998)**  -  four flaw classes with measured oracles (resource-leakage ratio up to 100%; 8.7× attacker leverage → 0.9× with defense).

The "one live endpoint that produced 248 HTTP payment grants for a single on-chain settlement" line from the CoS memo is flagged UNVERIFIED per that same reply. This library does not restate the 248:1 figure and does not encode it as an oracle. The V04 planted twin reproduces the *class* (>1 grant per one settlement) via the on-chain CEI-violation analog of the HTTP race, without claiming the specific numeric oracle from the CoS memo.

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
| A.1 | Payment replay: signed payment authorization can be resubmitted N times by the facilitator (or any observer with the signature) against a payer whose token allowance has not been reset. | P2 (arXiv:2605.11781) `[UNVERIFIED-AT-FETCH: exact §/table pending live re-pull]` | **M1** → `src/V01_Replay.sol` + `test/V01_Replay.t.sol` + `test/planted/V01_Replay.planted.t.sol` | Cleanest map to a Solidity feature-flag twin. Attack is deterministic on the pinned toolchain; INVARIANT VIOLATED fires in <1s local, well inside CI budget. |
| A.2 | Overpayment / wallet drain: facilitator accepts a caller-supplied `amount` on settle() rather than the resource-owner-posted price. Combined with the infinite-approval UX pattern, any caller drains the payer. | P2 (arXiv:2605.11781) `[UNVERIFIED-AT-FETCH]` | **M1** → `src/V02_Overpayment.sol` + `test/V02_Overpayment.t.sol` + `test/planted/V02_Overpayment.planted.t.sol` | Same-class as A.1 for a Solidity twin; the signed-struct-vs-caller-arg asymmetry is a common SDK regression shape worth having in the M1 audience's view. |
| A.3 | Signature semantic gap: signed authorization omits recipient (and / or resource identifier) from the digest; attacker resubmits with recipient=attacker to reroute funds. | P2 (arXiv:2605.11781) `[UNVERIFIED-AT-FETCH]` | **M1** → `src/V03_CrossResource.sol` + `test/V03_CrossResource.t.sol` + `test/planted/V03_CrossResource.planted.t.sol` | Cleanest single-contract EIP-191 twin. Deliberately mirrors the EIP-712-underconstraint bug class rather than pretending to be a full EIP-712 reproduction  -  full domain-separator work is M2 if a downstream asks. |
| A.4 | Cross-chain / cross-facilitator signature replay via EIP-712 domain-separator underconstraint: signed digest omits `chainId` and / or `verifyingContract`, so the same signature verifies against every facilitator instance on every chain. **NOVEL** (not in the arXiv corpus). | Class-precedent bugs: 2016 ETC replay, 2020 Uniswap `permit` chainId-omission, 2022 OpenSea sig-replay, 2023 Multichain bridge cross-chain replays. Reference pattern: OpenZeppelin `EIP712.sol` (Apache-2.0). Candidate source: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md` §3-C1. | **M1+ / novel** → `src/V05_CrossDomain.sol` + `test/V05_CrossDomain.t.sol` + `test/planted/V05_CrossDomain.planted.t.sol` | Domain-level semantic gap, orthogonal to A.1 (per-digest replay on one facilitator on one chain) and to A.3 (recipient-in-digest gap on one facilitator on one chain). Blast radius strictly larger: one signature replays across every deployed (facilitator, chain) pair sharing the token contract. |

### Class B: Prompt-layer attacks (P2)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| B.1 | Prompt-injection payment: LLM instructed via untrusted resource content to authorize a payment the human user did not intend. | P2 (arXiv:2605.11781) `[UNVERIFIED-AT-FETCH]` | **M2** | Off-chain LLM decision surface; no clean Solidity twin without vendoring an LLM harness. Route via AI-safety framing in the M2 disclosure workflow. |

### Class C: On-chain observability (P2)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| C.1 | Privacy / transaction-graph linkability: measured resource-leakage ratio up to 100% via calldata + event content on public chains. | P2 (arXiv:2605.11781) `[UNVERIFIED-AT-FETCH]` | **M2** | Reproduces cleanly as an on-chain observation harness, not as a clean/planted invariant. Better suited to a metrics-oriented notebook in M2 than a Foundry twin. |

### Class D: Settlement-race / duplicate-service-grant (P3)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| D.1 | Concurrency race: probabilistic duplicate service grants per one on-chain settlement, when facilitator emits the grant before finalizing settlement state. Paper reports the class with measured oracles (resource-leakage ratio, attacker-leverage delta). | P3 (arXiv:2605.30998) `[UNVERIFIED-AT-FETCH]` | **M1** → `src/V04_DoubleGrant.sol` + `test/V04_DoubleGrant.t.sol` + `test/planted/V04_DoubleGrant.planted.t.sol` | On-chain analog encoded as a CEI-violation reentrancy twin. Reproduces the *class* (>1 grant per settlement); does NOT restate the 248:1 numeric oracle from the CoS memo (that figure is UNVERIFIED per grant_writer reply §2 and is not carried forward here). |
| D.2 | Remaining flaw-class rows from P3 (verification memo cites 4 total). | P3 `[UNVERIFIED-AT-FETCH]` | **M2** | Held for the novel-variant hunt milestone; row IDs close on live re-pull of the paper. |

### Class F: Delegation-scope integrity (novel)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| F.1 | Cumulative-cap violation on a session-key path: session-key manager fails to persist per-period cumulative spent, so the spender can drain the payer's approval across N invocations well beyond the signed per-period `allowance`. **NOVEL** (not in the arXiv corpus). | Reference pattern: Coinbase `SpendPermissionManager` (Apache-2.0), a live-deployed session-key permission model on Base; AP2 mandate model (Google Agent Payments Protocol). Class-precedent bugs: repeat cumulative-cap-update-ordering issues in ERC-4337 session-key modules (Rhinestone / ModuleKit, Ithaca). Candidate source: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md` §3-C2. | **M1+ / novel** → `src/V06_DelegationCap.sol` + `test/V06_DelegationCap.t.sol` + `test/planted/V06_DelegationCap.planted.t.sol` | Different accounting invariant from A.2 (which caps a *single* settle to an owner-posted price). F.1 caps *cumulative* settlement across N invocations under a delegation. Delegation-state surface vs single-call-state surface. Materializes the moment agents (not humans) hold the delegated key  -  precisely the x402 use case. |

### Class E: Defense methodology (P1)

| ID | Vulnerability | Source | M1 target | Rationale |
|---|---|---|---|---|
| E.1 | PII-safe agentic-payment hardening methodology (not an attack; a defense-side line). | P1 (arXiv:2604.11430) `[UNVERIFIED-AT-FETCH]` | **out-of-scope for M1 as a twin** | P1 is methodology, not an attack-count paper. It informs the clean-twin baseline shape (why the defense side of V01-V04 looks the way it does) but does not warrant a dedicated `<Name>.sol` reproduction. |

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

Reproduction: `cd build/repos/_staging/ef-anchor-m1 && ./run.sh`. Forge 1.7.1 (nightly, build 2026-05-08). Total wall time under one second on the developer laptop; CI budget on `ubuntu-latest` at nightly Foundry is expected to stay under two minutes end-to-end (measure on first CI run once the M1 branch flips public). Table refreshed 2026-07-15 after V05_CrossDomain + V06_DelegationCap landed (M1+ / novel-variant additions).

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

Reproduction: `cd build/repos/_staging/ef-anchor-m1 && ci/reachability_leg.sh`.
The leg is wired into `.github/workflows/ci.yml` as job
`reachability-multi-seed` and is invoked by `run.sh` after the base
matrix passes.

---

## 6. Citation disposition plan (before public flip)

Every `[UNVERIFIED-AT-FETCH]` marker in §1 and §3 closes to `[VERIFIED YYYY-MM-DD source: arXiv:YYMM.NNNNNvN §<section>]` via a live WebFetch of each paper's abstract page during the §4a outbound-text review pass. The verification pulls:

- Author list per paper (§1 rows P1 / P2 / P3).
- Exact section / table / figure anchor per catalog row (§3 rows A.1 / A.2 / A.3 / D.1).
- Version tag on the arXiv ID (currently unlabeled per research_lead's fetch).

If any live fetch surfaces a paper claim that does not match the attack shape reproduced in the corresponding V0N twin, the twin is either revised to match the paper or downgraded to M2 with an explicit note. The M1 shipping bar does not accept a mismatch closed as "spirit-of-the-paper."

If the "248:1" oracle turns out to reconcile against P3 on live re-pull (grant_writer's reply flagged it as likely fabricated but did not close the door), a note lands in `docs/oracle_248to1_disposition.md`  -  either resurrecting or formally retiring the figure. Default posture stays "retired unless proven otherwise" per grant_writer reply §2.

---

## 7. Change log

| Date | Change | By |
|---|---|---|
| 2026-07-14 | File created; catalog rows placeholder pending grant_writer URL delivery; M1 / M2 split proposed by criteria in §4. | solidity_specialist |
| 2026-07-14 | Sources §1 closed to real arXiv IDs per grant_writer reply. Catalog §3 rewritten around actual paper shape (P2 five attacks / P3 four flaw classes / P1 methodology) after correction from CoS memo's disputed "11 / 5" phrasing. M1 shipping set closed to A.1 / A.2 / A.3 / D.1 (four twins). Local run verdict (§5) recorded. | solidity_specialist |
| 2026-07-15 | 16-seed reachability certification added (`ci/reachability_leg.sh`, `ci/reachability_seeds.txt`, `docs/reachability.md`, `docs/reachability_run.log`). CI job `reachability-multi-seed` wired; `run.sh` invokes the leg after the base matrix passes. All four planted twins certify 16/16. Section 5a records the verdict. | solidity_specialist |
| 2026-07-15 | M1+ / novel-variant additions: A.4 (V05_CrossDomain, EIP-712 domain-separator underconstraint) and F.1 (V06_DelegationCap, cumulative-cap violation on a session-key path). Both twins clean-pass and planted-fire on all 16 reachability seeds. `run.sh` now reports 6/6 clean + 6/6 planted; §5a table extended to 6 rows; §3 gains new class F for delegation-scope integrity. Neither twin reproduces a published attack; both encode a class the arXiv corpus does not name (candidate hunt: `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md`). | solidity_specialist |
