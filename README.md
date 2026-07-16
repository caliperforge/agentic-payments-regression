# agentic-payments-regression (v0.1, M1 scaffold)

**Status.** M1 scaffold in staging. Public flip pending §4a (outbound-text review) and §4b (code-quality review) gates on the M1 bundle.

**Intended home on public flip.** `caliperforge/agentic-payments-regression` (name ratified per `ops/decisions.md` D-ef-anchor-repo-naming-2026-07-14, 2026-07-14).

---

## What this is

`agentic-payments-regression` is an open-source library of CI-runnable planted-twin reproductions for the **x402 agentic-payments** threat model. Each planted twin ships as a `clean` + `planted` pair against a reference x402 implementation, with a CI matrix that asserts the clean leg passes silently and the planted leg surfaces an `INVARIANT VIOLATED <name>` marker.

The M1 shipping set reproduces four published x402 attack classes from the arXiv corpus catalogued in `coverage_map.md` (payment-authorization integrity ×3 + settlement-race duplicate service grants ×1, drawn from arXiv:2605.11781 and arXiv:2605.30998; PII-hardening methodology paper arXiv:2604.11430 informs the clean-twin baseline but is not itself a reproduced twin). The **M1+ / novel-variant additions (2026-07-15)** land two further twins covering classes the arXiv corpus does not name: V05 (EIP-712 domain-separator underconstraint / cross-facilitator + cross-chain replay) and V06 (session-key cumulative-cap violation on a Coinbase `SpendPermissionManager`-shape delegation). Both are class-level twins against synthesized minimal contracts, not disclosures of a specific live SDK. The library is a **candidate for OWASP incubation**; a project-proposal will be filed with the OWASP Projects Committee once M2 (further novel-variant hunt + responsible-disclosure record) lands. It is not an OWASP project today.

## Why this exists

The x402 spec (Coinbase / Linux Foundation x402 Foundation) opens an agentic-payments surface that regression-CI has not yet caught up with. Published research (arXiv corpus, `coverage_map.md`) documents the concrete attacks: five in arXiv:2605.11781 ("Five Attacks on x402 Agentic Payment Protocol") and four flaw classes in arXiv:2605.30998 ("Free-Riding the Agentic Web"), with arXiv:2604.11430 supplying PII-hardening methodology on the defense side. Reference implementations quietly re-introduce these classes as SDKs evolve. This library ports the planted-twin CI shape (feature-flag pairing, `INVARIANT VIOLATED` marker convention) from `caliperforge/hyperevm-safety` to the x402 substrate so that any downstream integrator can:

1. Clone this repo, run `./run.sh`, and see the clean/planted diff in under five minutes on a MacBook or a GitHub Actions runner.
2. Fork the harness, wire it against their own x402 integration, and get CI-gated regression coverage on the catalogued bug classes.

The thesis: the triage is the product. A planted-twin catch is a maintainer-actionable artifact. It is not a report, not a scan, not an audit summary.

## What this is NOT

- **Not an audit.** A passing CI run on a fork of this library against a protocol's x402 integration does not certify the integration is safe. The library catches the bug classes the invariants encode; the residual surface belongs to the integrator.
- **Not a "would-have-caught" story.** The M1 planted twins reproduce published attacks from the arXiv corpus. They confirm the CI-runnable planted-twin shape catches the published bug class; they do not claim the harness would have pre-empted the original discovery. The novel-variant hunt is M2 scope, filed separately after M1 acceptance.
- **Not an OWASP project.** OWASP does not have a project by this name today. We intend to file an incubation proposal to the OWASP Projects Committee after M2 lands. Any language you see referring to OWASP is forward-looking.
- **Not a runtime monitor.** The properties are pre-deploy CI gates. Runtime monitoring of live x402 facilitators is a separate concern owned by other actors and out of scope here.
- **Not a substitute for the x402 spec's own security review.** Read the x402 spec directly; this library encodes a subset of the failure modes the spec's threat model already contemplates.
- **Not cross-substrate.** This library covers agentic-payments only. It does not vendor or reference Uniswap, Solana, Taiko, or BSC artifacts. Substrate-mixing has its own regression harnesses in the `caliperforge/` portfolio.

## How to run

Prerequisites:

- Foundry (`forge`, `cast`, `anvil`). The bootstrap script detects a missing `forge` and prints a single actionable install line; it does not `curl | sh` foundryup silently.
- `git submodule` support (the bootstrap script initialises submodules on first run).
- macOS or Linux. Windows via WSL is expected to work but is not part of the CI matrix at v0.1.

Once cloned:

```
./run.sh
```

Behaviour:

1. Detects missing dependencies; prints an install line and exits non-zero if `forge` is absent.
2. Initialises submodules recursively.
3. Runs `forge build`.
4. Runs the clean/planted matrix: every clean leg must pass silently; every planted leg must surface at least one `INVARIANT VIOLATED <name>` marker and exit non-zero.
5. Prints a summary block: rows of `CLEAN PASS <name>` and `PLANTED FIRED <name> (INVARIANT VIOLATED)`.
6. Exits 0 if all clean legs pass and all planted legs fire; non-zero otherwise with a clear line pointing at the failing step.

CI (`.github/workflows/ci.yml`) runs the same matrix on `ubuntu-latest` and gates `main`. First-meaningful-commit CI run URL will land in the proof_register row on public flip.

## Multi-seed reachability certification

Every planted twin is also certified across a fixed 16-seed set (see [`docs/reachability.md`](docs/reachability.md)): every seed fails with an `INVARIANT VIOLATED` marker on every planted suite, so "the planted twin fires" is a deterministic property of the case, not the outcome of a single random walk. The leg is wired as a required check in `.github/workflows/ci.yml` (job `reachability-multi-seed`) and is invoked by `./run.sh` after the base matrix passes.

Verdict from the local certification run on 2026-07-15, at the standing `foundry.toml [invariant]` budget:

```
reachability certified: yes (all suites, 16/16 failed as required)
```

Per-twin k / 16 numbers, the seed list, and the merge-gate rule are in [`docs/reachability.md`](docs/reachability.md); the full per-seed run log is at [`docs/reachability_run.log`](docs/reachability_run.log). The seed set (`ci/reachability_seeds.txt`) is identical to the one shipped in `caliperforge/euler-earn-invariants` and `caliperforge/uniswap-v4-invariants` (proof_register row 7).

## Disclosure policy

See `SECURITY.md`. Summary: 90-day default disclosure window on any bug found in this library itself (not in integrator forks); responsible-disclosure contact is a role email, not a personal credential. Novel-variant findings against downstream x402 implementations follow the M2 disclosure workflow (`disclosures/TEMPLATE.md`).

## Incubation status

Candidate for OWASP incubation. Project-proposal to the OWASP Projects Committee is planned once M2 lands (novel-variant hunt + first disclosure record). Until then, this library lives under `caliperforge/` and is Apache-2.0 licensed for anyone to fork, vendor, or contribute to. No endorsement by OWASP or by any other body is claimed at v0.1.

## Contributing

See `CONTRIBUTING.md`. The short version: bug reports with a reproducer are welcome; new planted twins are welcome via issue-first discussion; refactors without behavior change are welcome if they meaningfully reduce surface. Security reports go through `SECURITY.md`, not the public issue tracker.

## Citations

The x402 spec, reference implementations, and the arXiv corpus that grounds this library's coverage are catalogued in `coverage_map.md`. Every citation carries a retrieval date. Where a citation is still pending verification at draft, it is marked `[UNVERIFIED-AT-DRAFT]` and will close before public flip.

## Repository layout

```
README.md                                    # this file
LICENSE                                      # Apache-2.0
SECURITY.md                                  # responsible-disclosure policy
CONTRIBUTING.md                              # one-page contribution guide
coverage_map.md                              # arXiv corpus catalog + M1/M2/out-of-scope selection
run.sh                                       # one-command runner (bootstrap + matrix + reachability + summary)
foundry.toml                                 # Foundry project config
.github/workflows/ci.yml                     # CI matrix (clean + planted + reachability legs)
ci/
  reachability_leg.sh                        # 16-seed reachability leg (fail-on-all-N per planted suite)
  reachability_seeds.txt                     # canonical 16-seed set (identical across the caliperforge Foundry repos)
src/
  README.md                                  # src/ overview + naming convention
  V01_Replay.sol                             # payment-replay reproduction (arXiv:2605.11781)
  V02_Overpayment.sol                        # amount-not-bound-to-posted-price (arXiv:2605.11781)
  V03_CrossResource.sol                      # signature-semantic-gap (arXiv:2605.11781)
  V04_DoubleGrant.sol                        # CEI-violation duplicate-grant (arXiv:2605.30998)
  V05_CrossDomain.sol                        # EIP-712 domain-separator underconstraint (novel; M1+)
  V06_DelegationCap.sol                      # session-key cumulative-cap violation (novel; M1+)
  mocks/
    MockERC20.sol                            # minimal test-only ERC-20; not production-safe
test/
  README.md                                  # test/ overview + naming convention
  V01_Replay.t.sol                           # clean-leg property test
  V02_Overpayment.t.sol                      # clean-leg property test
  V03_CrossResource.t.sol                    # clean-leg property test
  V04_DoubleGrant.t.sol                      # clean-leg property test
  V05_CrossDomain.t.sol                      # clean-leg property test
  V06_DelegationCap.t.sol                    # clean-leg property test
  harness/
    AuthSigner.sol                           # shared EIP-191 signing helper
    Resources.sol                            # Benign/Malicious resource harness for V04
  planted/
    V01_Replay.planted.t.sol                 # planted-leg (INVARIANT VIOLATED)
    V02_Overpayment.planted.t.sol            # planted-leg (INVARIANT VIOLATED)
    V03_CrossResource.planted.t.sol          # planted-leg (INVARIANT VIOLATED)
    V04_DoubleGrant.planted.t.sol            # planted-leg (INVARIANT VIOLATED)
    V05_CrossDomain.planted.t.sol            # planted-leg (INVARIANT VIOLATED)
    V06_DelegationCap.planted.t.sol          # planted-leg (INVARIANT VIOLATED)
disclosures/
  TEMPLATE.md                                # disclosure-record template; populated in M2
docs/
  reachability.md                            # 16-seed reachability rule + per-twin k/N verdict
  reachability_run.log                       # full per-seed run log (2026-07-15 local certification)
```

The layout follows the `caliperforge/hyperevm-safety` planted-twin shape (proof_register row 7) adapted to the x402 substrate. It does not vendor hyperevm-safety code; the shape is the reference, not the source.
