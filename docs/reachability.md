# Multi-seed reachability certification

## What this fixes

The base planted matrix (invoked by `run.sh` and by the CI
`runner-integration` job) runs each planted-twin suite once per commit at
the `foundry.toml` `[invariant]` budget. The six shipped triggers  -
four M1 (payment-replay, overpayment, cross-resource redirect,
CEI-violation duplicate grant) plus two M1+ / novel (EIP-712 domain
underconstraint, delegation-scope cumulative-cap violation)  -  fire
reliably at that budget, but "almost always" is not "always". A lucky
CI seed on a longer or rarer trigger would leave a false green where the
docs claim a hard red.

The multi-seed reachability leg (`ci/reachability_leg.sh`) closes that
gap for every planted suite: it runs each planted suite once per seed
across a fixed 16-seed set (`ci/reachability_seeds.txt`) and requires
every seed to fail with an `INVARIANT VIOLATED` marker. If any seed
passes on any suite, the leg fails and the docs' k/N number for that
suite goes down instead of quietly staying at 16/16.

## Verdict (per suite)

Recorded from the local run on 2026-07-15 against the six shipped
planted suites (four M1 + two M1+ / novel), at the standing
`foundry.toml [invariant]` budget:

| twin | planted contract | k / 16 | verdict |
| --- | --- | --- | --- |
| V01 payment-replay | `V01_ReplayPlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |
| V02 overpayment | `V02_OverpaymentPlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |
| V03 cross-resource | `V03_CrossResourcePlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |
| V04 double-grant | `V04_DoubleGrantPlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |
| V05 cross-domain (novel) | `V05_CrossDomainPlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |
| V06 delegation-cap (novel) | `V06_DelegationCapPlantedTest` | 16 / 16 | reachability certified: yes (16/16 failed as required) |

Overall:

```
reachability certified: yes (all suites, 16/16 failed as required)
```

Every seed in `ci/reachability_seeds.txt` produced a non-zero forge
exit and at least one `INVARIANT VIOLATED` marker on every planted
suite. The base budget is sufficient for every shipped twin; no bump
required. The full per-seed run log is at `docs/reachability_run.log`.

## Merge-gate rule

No new twin merges to `main` unless the reachability leg exits green
(fail-on-all-N) for the twin's planted suite. If a new planted twin
cannot certify at the default `(runs, depth)` budget, the twin owner:

1. Bumps `[invariant] runs` or `depth` in `foundry.toml` until the leg
   certifies, OR
2. Documents an honest caveat in `coverage_map.md` stating the k/N
   number the twin currently achieves at the standing budget.

The reachability leg is wired as a required check in
`.github/workflows/ci.yml` (job `reachability-multi-seed`) alongside
the base `library-build`, `runner-integration`, and
`runner-integration-macos` legs.

## Seed set

The seed list is a fixed, deterministic mix of small integers, common
test patterns, and pseudo-random-looking bytes. It is not regenerated
per run. See `ci/reachability_seeds.txt`. The file is identical to the
one shipped in `caliperforge/euler-earn-invariants` and
`caliperforge/uniswap-v4-invariants`.

## Reuse

The canonical script this leg mirrors lives at
`scripts/reachability/run_foundry_reachability.sh` in the
`caliperforge/crypto-contributor` repo. Future Foundry cases lift that
script + the seed set verbatim.
