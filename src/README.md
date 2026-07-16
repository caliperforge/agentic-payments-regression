# src/

Solidity contracts for the reproduction targets and the planted-twin defense patterns.

**M1 shipping set (2026-07-14).** Four planted-twin facilitators covering payment-authorization integrity (V01, V02, V03) and settlement-race duplicate service grants (V04). **M1+ / novel additions (2026-07-15):** V05 (EIP-712 domain-separator underconstraint) and V06 (delegation-scope cumulative-cap violation). Corpus catalog + M1 / M1+ / M2 / out-of-scope split in `../coverage_map.md`.

- `V01_Replay.sol`  -  payment-replay class (arXiv:2605.11781).
- `V02_Overpayment.sol`  -  amount-not-bound-to-posted-price class (arXiv:2605.11781).
- `V03_CrossResource.sol`  -  signature semantic gap / missing-recipient-binding class (arXiv:2605.11781).
- `V04_DoubleGrant.sol`  -  CEI-violation duplicate-grant class (arXiv:2605.30998).
- `V05_CrossDomain.sol`  -  EIP-712 domain-separator underconstraint / cross-facilitator + cross-chain replay class (novel; see `../coverage_map.md` §3 row A.4).
- `V06_DelegationCap.sol`  -  session-key cumulative-cap violation class (novel; see `../coverage_map.md` §3 row F.1).
- `mocks/MockERC20.sol`  -  minimal test-only ERC-20 payment token; not production-safe.

**Naming convention (from hyperevm-safety shape, proof_register row 7).**

- `src/<Name>.sol`  -  minimal Solidity contract that exhibits the bug class when the planted flag is on; carries NatSpec citing the arXiv source and naming the planted-flag semantics.
- Companion `test/<Name>.t.sol`  -  clean-leg property test.
- Companion `test/planted/<Name>.planted.t.sol`  -  planted-leg property test that surfaces `INVARIANT VIOLATED <name>`.
