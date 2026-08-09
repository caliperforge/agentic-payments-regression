# Security Policy

`agentic-payments-regression` is a library of pre-deploy CI planted twins for the x402 agentic-payments threat model. We take security reports against the library itself seriously and aim to acknowledge every credible report within seven days.

## This library is NOT an audit

Before filing a report, please read:

- A passing CI run of `agentic-payments-regression` against a protocol's x402 integration does NOT certify the integration is safe. The library catches the bug classes the planted twins encode (see `coverage_map.md`); the residual surface is the integrator's.
- An `INVARIANT VIOLATED <name>` marker firing in a `test/planted/` twin (or in any documented planted-hunk reference) is the library **working as intended**. That output is not a vulnerability in `agentic-payments-regression`.
- This library is not a runtime monitor and does not encode every failure mode contemplated by the x402 spec. Read the x402 spec directly.

## What to report through this policy

Report to the responsible-disclosure contact below if you find any of the following in the library **itself** (not in a fork or in a downstream integrator):

- A planted twin whose clean leg fires `INVARIANT VIOLATED` on the pinned toolchain (a false-positive clean leg is a correctness bug in the library).
- A planted twin whose planted leg passes silently on the pinned toolchain (a missed catch is a coverage bug in the library).
- A code path in `src/` that would compile into a downstream integrator fork and introduce a new failure mode not present in the reference implementation being reproduced.
- Any information leakage in the repo itself (accidental key commit, private-endpoint URL, etc.).

## What to report elsewhere

- **Bugs you find in a downstream x402 integrator by running a fork of this harness against it.** Report those to that integrator's security contact directly. If the integrator has no security contact and you want help routing the disclosure, we can help; see the M2 disclosure workflow in `disclosures/TEMPLATE.md`. But the primary responsible-disclosure surface is the integrator, not us.
- **Bugs in the x402 spec itself.** Report to the Linux Foundation x402 Foundation working group per the spec's own disclosure channel.
- **Bugs in Foundry, `forge`, or any upstream dependency this library pins.** Report to that upstream project.

## How to report

- **Email:** `michael@caliperforge.com` (single-operator address; the operator-of-record monitors directly per §"What we do NOT commit to" below).
- **GitHub security advisory:** enable "Report a vulnerability" once the repo is public; that surface routes to the same role contact.
- **PGP:** optional. A key will be published under `docs/pgp.asc` if a reporter requests encrypted communication. Reporters who need PGP can request the key at the email address above.

Please include:

- A clear statement of what you observed and what you expected.
- The toolchain versions you ran (`forge --version` output; OS + arch).
- A minimal reproducer (branch, commit, command sequence). The closer to a one-command reproduction, the faster the turn.

## Disclosure window

- **Default:** 90 days from acknowledgement to public disclosure. That is deliberately longer than CERT/CC's own 45-day default, because a fix here may need coordination with a downstream integrator.
- **Extension:** we may request an extension if the fix requires coordination with a downstream integrator; the extension will be justified in writing and capped.
- **Short window:** if the bug is actively exploited or exposes end-user funds, we will move to a shorter window and coordinate with the affected integrator.

## What we commit to

- Acknowledge every credible report within seven calendar days.
- Confirm reproduction or ask specific clarifying questions within fourteen calendar days.
- Publish a fix (or a documented won't-fix rationale) before the disclosure window closes.
- Credit the reporter in the release notes and in `disclosures/` unless the reporter requests anonymity.

## What we do NOT commit to

- A bug-bounty payout. This library is Apache-2.0 open source with no funding line. Credible reports receive credit, not cash.
- Formal SLA commitments beyond the above. The operator-of-record is a single human; response times outside those windows depend on availability.

## Scope of this policy

- `agentic-payments-regression` at any commit under the `caliperforge/` org (or any successor org if this project is donated to OWASP incubation).
- Forks are out of scope; report fork issues to the fork maintainer.
