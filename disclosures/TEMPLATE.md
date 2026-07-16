# Disclosure record: <variant-name>

**Status.** Populated in M2 with the actual novel-variant disclosure. This template is the shape every disclosure record follows.

**File-naming convention.** `disclosures/YYYY-MM-DD-<variant-slug>.md` (chronological + kebab-case slug).

---

## Variant

- **Name:** `<variant-name>`. Short, descriptive; e.g. `x402-facilitator-double-settle-race`.
- **Class:** which class from `coverage_map.md` this variant belongs to (or "novel" if it opens a class the corpus does not contemplate).
- **Substrate:** Solidity / TypeScript facilitator / other.
- **Discovered by:** operator name(s) + AI specialists involved in the surfacing.
- **Discovery method:** planted-twin fuzz / manual review / hunt-log lead / other.

## Affected implementation

- **Project:** the affected downstream x402 integrator or reference implementation.
- **Repository / commit:** URL + commit SHA at the time of discovery.
- **Deployed instances (if any):** live contract addresses / facilitator endpoints affected.
- **Version range:** which versions of the integrator carry the vulnerable code path.

## Timeline

| Date | Event |
|---|---|
| YYYY-MM-DD | Vulnerability surfaced locally in `agentic-payments-regression` fork against the affected implementation. |
| YYYY-MM-DD | Responsible-disclosure report filed to maintainer via `<channel>` (email / GitHub security advisory / SECURITY.md contact). |
| YYYY-MM-DD | Maintainer acknowledgement received. |
| YYYY-MM-DD | Fix confirmed / patched version released. |
| YYYY-MM-DD | Public disclosure. |

## Report contents (redacted for public-disclosure staging)

- **Summary:** one-paragraph description of the failure mode.
- **Reproduction:** minimal repro steps or link to the `test/` twin that reproduces it in this harness.
- **Impact:** what an attacker can do; what user-visible effect this has; funds-at-risk estimate if applicable.
- **Suggested fix:** the defense pattern this harness recommends (typically the same defense pattern the corresponding `src/` file in this harness encodes).
- **Credits:** reporter(s), plus any co-discoverers or independent verifiers.

## CVE / advisory reference

- **CVE:** `CVE-YYYY-NNNNN` (assigned by MITRE / GitHub Security Advisories / integrator's numbering authority).
- **GHSA:** `GHSA-XXXX-XXXX-XXXX` (if issued via GitHub Security Advisories).
- **Integrator advisory URL:** direct link to the integrator's public advisory.

## Reproduction bundle in this repo

- **Planted twin location:** `test/<Name>.t.sol` + `test/planted/<Name>.planted.t.sol` at commit `<SHA>` of `agentic-payments-regression`.
- **How to run:** `./run.sh` from a fresh clone at that SHA. The planted leg surfaces `INVARIANT VIOLATED <name>`; the clean leg passes silently.
- **NOTICE update (if vendoring landed):** confirm the `NOTICE` file at repo root lists any vendored source used in the reproduction.

## Post-disclosure

- **Coverage_map.md row moved:** confirm the row for this class moved from `M2` to `shipped-in-M2` (or `shipped-post-M2`) with the correct source citation.
- **Public thanks / referral:** if the integrator posts a public advisory referencing this harness, link to it in the repo README's "citations" section.

---

*Template shape stable at v0.1. Do not delete unused sections; leave them empty with a `n/a (reason)` note if genuinely inapplicable. That keeps disclosure records comparable across variants.*
