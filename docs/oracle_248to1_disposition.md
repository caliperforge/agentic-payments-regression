# Disposition of the "248:1" oracle

**Date:** 2026-08-08. **Trigger:** `coverage_map.md` §6, which held this figure open pending a live re-pull of the arXiv corpus.

## Verdict

**Resurrected as a published figure. Still not encoded as an oracle in this library.**

## The figure

An internal memo claimed "one live endpoint that produced 248 HTTP payment grants for a single on-chain settlement." A 2026-07-14 verification pass flagged it as likely fabricated and set the default posture to retired-unless-proven. `coverage_map.md` §6 wrote the reopening condition as: does it reconcile against **P3** (arXiv:2605.30998, *Free-Riding the Agentic Web*).

## What the 2026-08-08 re-pull measured

| Paper | Fetched | Result |
|---|---|---|
| P3, arXiv:2605.30998 | abstract page HTTP 200; `arxiv.org/html/2605.30998v2` HTTP 404; `arxiv.org/html/2605.30998v1` HTTP 200 | The string "248" does not appear anywhere in the v1 full text. P3's duplicate-settlement measurement is at §4.3.4 and reads 3 of 50 rounds (6%), two HTTP 200 responses against one on-chain transaction. |
| P2, arXiv:2605.11781v1 | abstract page HTTP 200; `arxiv.org/html/2605.11781v1` HTTP 200 | **Found, at §4.3 (Evaluating Attack II):** *"In the strongest positive round, we observe 248 HTTP-layer grants and 1 on-chain settlement."* Context is a replay of a single payment capability across 1,000 concurrent requests against a live testnet endpoint. |

So the condition as §6 wrote it did not fire. The figure was found anyway, in the other paper.

## What that changes

The "likely fabricated" flag is withdrawn against the number. 248:1 is a real, published measurement. The flag stands against the attribution: the memo did not say where the number came from, and the corpus file went on to associate it with P3, which does not contain it.

## What that does not change

248:1 is not encoded as an oracle in `src/` or `test/`, and this re-pull is not a reason to add it. The measurement is a per-round count of HTTP-layer grants under 1,000 concurrent requests against a live endpoint. A Foundry twin has no HTTP layer and no concurrency, so it cannot assert that number without inventing a substrate the paper did not test on.

`src/V04_DoubleGrant.sol` continues to reproduce the class — more than one grant per one settlement — as an on-chain CEI-violation analog of the HTTP race. That framing was chosen before this pull and survives it unchanged.

## Citation, if the figure is ever quoted

> Zelin Li, Qin Wang, Zhipeng Wang. *Five Attacks on x402 Agentic Payment Protocol.* arXiv:2605.11781v1, §4.3. Retrieved 2026-08-08.
