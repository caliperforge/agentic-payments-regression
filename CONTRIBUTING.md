# Contributing to agentic-payments-regression

Thanks for your interest. `agentic-payments-regression` is an Apache-2.0 library of planted-twin regressions for the x402 agentic-payments threat model. Contributions that sharpen the harness against real reference implementations are welcome.

## How decisions get made

Single human operator-of-record (CaliperForge) reviews and merges. AI specialists draft and review under final human pass. There is no separate maintainer group at v0.1.

## What we accept

| Contribution shape | Default response | Notes |
|---|---|---|
| Bug reports with a reproducer | Welcome | Open a GitHub issue with `forge --version`, OS + arch, and a minimal reproducer |
| Documentation fixes | Welcome | Typos, broken links, README clarifications: PR directly |
| New planted twins (`src/<Name>.sol` + `test/<Name>.t.sol` + `test/planted/<Name>.planted.t.sol`) | Discuss first in an issue | Must ship as **clean + planted pair** with the `INVARIANT VIOLATED <name>` marker; must cite a public source (arXiv paper, post-mortem, spec section) for the bug class |
| Additional coverage against x402 reference implementations | Discuss first in an issue | Must map to a row in `coverage_map.md`; new rows require a public source citation |
| Refactors with no behavior change | Discuss first | Land if they meaningfully reduce surface; large rewrites without an issue first will likely be closed |
| Security reports | Do **not** open a public issue | See `SECURITY.md` |
| Novel-variant findings against downstream x402 integrators | Route through `disclosures/` workflow | The disclosure record ships in-repo after coordination with the affected integrator |

## PR checklist for a new planted twin

Every new planted twin ships with all of the following or the PR will be held:

1. **`src/<Name>.sol`**: the reproduction target (a minimal contract that exhibits the bug class when the planted flag is on).
2. **`test/<Name>.t.sol`**: the clean-leg test. Passes silently under the pinned toolchain.
3. **`test/planted/<Name>.planted.t.sol`**: the planted-leg test. Surfaces at least one `INVARIANT VIOLATED <name>` marker and exits non-zero under the pinned toolchain.
4. **CI wiring**: corresponding jobs added to `.github/workflows/ci.yml` (path-existence-gated so the CI stays green until the twin lands, then flips atomically).
5. **`coverage_map.md` row**: updates the catalog row for the reproduced bug class, moving it from `roadmap-M2` or `out-of-scope-with-reason` into `shipped-in-M1` (or a subsequent milestone) with a source citation.
6. **NatSpec on `src/<Name>.sol`**: explains the bug class, cites the public source, and names the planted-flag semantics.

## What we do NOT accept

- New planted twins without a public source citation. Every bug class in the harness must trace to arXiv, a spec section, a post-mortem, or an equivalent published artifact. No first-party invention of a bug class without a source; if you have a novel-variant finding, route it through `disclosures/` first, coordinate with the affected integrator, then land the reproduction after coordinated disclosure.
- Cross-substrate contributions. This library covers agentic-payments only. Contributions targeting Uniswap, Solana, Taiko, or BSC substrates should route to the appropriate `caliperforge/` sibling repo.
- Runtime-monitoring code. This is a pre-deploy CI library. Runtime monitoring is out of scope.
- Contributions that strip the `INVARIANT VIOLATED <name>` marker or the clean/planted twin convention. The marker + twin shape is load-bearing for both the local runner and the CI matrix.

## Toolchain

- Solidity 0.8.x pinned in `foundry.toml`.
- Foundry (`forge`, `cast`, `anvil`).
- No paid tool tiers. `slither` (free) and `forge inspect` are the static-analysis baseline.

## AI disclosure

This repository is authored by a human-supervised AI-augmented process. Every PR merged into `main` carries an AI-disclosure footer per the operator's public register. Contributors are asked to disclose AI assistance in their own PRs at the level of specificity they are comfortable with. A one-line note in the PR description is sufficient.
