# test/

Foundry property tests for the planted-twin matrix.

**M1 shipping set (2026-07-14).** Four clean/planted pairs plus shared harness.
**M1+ / novel additions (2026-07-15).** V05_CrossDomain + V06_DelegationCap  -  two additional clean/planted pairs under the same discipline.

- `V0{1..6}_*.t.sol`  -  clean-leg property tests. Each asserts the invariant the planted leg violates.
- `planted/V0{1..6}_*.planted.t.sol`  -  planted-leg tests. Each surfaces `INVARIANT VIOLATED <name>` and exits non-zero from the property assertion.
- `harness/AuthSigner.sol`  -  shared EIP-191-prefixed digest signing helper. Reused unchanged by V05 (whose contract-side digest is full EIP-712 but the signer helper still just signs any bytes32) and V06.
- `harness/Resources.sol`  -  `BenignResource` + `MaliciousResource` for V04's reentrancy leg.

**Convention.**

- `test/<Name>.t.sol`  -  clean leg. Must pass silently under the pinned toolchain (no `INVARIANT VIOLATED` in output).
- `test/planted/<Name>.planted.t.sol`  -  planted leg. Must surface at least one `INVARIANT VIOLATED <name>` marker via `assertEq/assertTrue(cond, "INVARIANT VIOLATED <name>")` or equivalent, and must exit non-zero from the property revert.

The `run.sh` runner and the `.github/workflows/ci.yml` matrix both discover twins by scanning this convention; no runner or workflow edit is required per-twin. The naming is load-bearing.
