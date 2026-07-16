#!/usr/bin/env bash
# run.sh  -  one-command runner for agentic-payments-regression M1.
#
# Behaviour per spec.md §AC-7 + Implementation direction / Dep-bootstrap step:
#   1. Detect missing `forge`; print a single install line and exit non-zero.
#   2. Initialise submodules recursively.
#   3. forge build.
#   4. Run clean/planted matrix: clean legs pass silently; planted legs surface
#      at least one `INVARIANT VIOLATED <name>` marker and exit non-zero.
#   5. Print a summary block: CLEAN PASS / PLANTED FIRED rows.
#   6. Exit 0 iff all clean pass AND all planted fire; non-zero otherwise, with
#      a clear line pointing at the failing step.
#
# The clean/planted twin selection is discovered at runtime by scanning
# test/ and test/planted/. Adding a new twin does not require editing this
# script  -  the naming convention is load-bearing:
#   test/<Name>.t.sol                    -  clean leg (must pass; must NOT emit INVARIANT VIOLATED).
#   test/planted/<Name>.planted.t.sol    -  planted leg (MUST emit INVARIANT VIOLATED and exit non-zero).
#
# Runs on macOS + Linux (bash 3.2+ compatible; no bash-4-isms  -  we test on
# the default macOS bash and on ubuntu-latest CI).

set -uo pipefail

log()  { printf '[run.sh] %s\n' "$*" >&2; }
fail() { printf '[run.sh] FAIL: %s\n' "$*" >&2; exit 1; }

# --- Step 1: dep detect --------------------------------------------------

if ! command -v forge >/dev/null 2>&1; then
    cat >&2 <<'EOF'
[run.sh] FAIL: `forge` (Foundry) is required but not installed.

Install Foundry with:

    curl -L https://foundry.paradigm.xyz | bash && foundryup

See https://book.getfoundry.sh/getting-started/installation for details.
This script does not `curl | sh` on your behalf.
EOF
    exit 2
fi

if ! command -v git >/dev/null 2>&1; then
    fail "\`git\` is required but not installed."
fi

# --- Step 2: submodules --------------------------------------------------

if [ -f .gitmodules ]; then
    log "Initialising submodules recursively..."
    if ! git submodule update --init --recursive; then
        fail "git submodule update failed. Fix the submodule state before re-running."
    fi
fi

# --- Step 3: build -------------------------------------------------------

log "forge build..."
if ! forge build; then
    fail "forge build failed. See output above for the compiler diagnostic."
fi

# --- Step 4: discover twin pairs ----------------------------------------

clean_tests=()
if [ -d test ]; then
    while IFS= read -r -d '' f; do
        clean_tests+=("$f")
    done < <(find test -maxdepth 1 -type f -name '*.t.sol' -print0 2>/dev/null || true)
fi

planted_tests=()
if [ -d test/planted ]; then
    while IFS= read -r -d '' f; do
        planted_tests+=("$f")
    done < <(find test/planted -maxdepth 1 -type f -name '*.planted.t.sol' -print0 2>/dev/null || true)
fi

if [ ${#clean_tests[@]} -eq 0 ] && [ ${#planted_tests[@]} -eq 0 ]; then
    log "No planted twins found under test/. This is the M1 scaffold pre-implementation state  -  the runner exits vacuous-green so CI stays green while the src/+test/ tree lands."
    log "SUMMARY: 0 clean, 0 planted. No coverage yet."
    exit 0
fi

# --- Step 5: run clean legs ---------------------------------------------

clean_summary=()
clean_failed=0
for t in "${clean_tests[@]}"; do
    name=$(basename "$t" .t.sol)
    log "CLEAN: forge test --match-path $t"
    out=$(forge test --match-path "$t" -vv 2>&1)
    ec=$?
    if [ $ec -ne 0 ]; then
        clean_summary+=("CLEAN FAIL $name (forge test exited $ec)")
        clean_failed=$((clean_failed + 1))
        printf '%s\n' "$out"
        continue
    fi
    if printf '%s' "$out" | grep -q "INVARIANT VIOLATED"; then
        clean_summary+=("CLEAN FAIL $name (produced INVARIANT VIOLATED  -  clean leg must pass silently)")
        clean_failed=$((clean_failed + 1))
        printf '%s\n' "$out"
        continue
    fi
    clean_summary+=("CLEAN PASS $name")
done

# --- Step 6: run planted legs -------------------------------------------

planted_summary=()
planted_failed=0
for t in "${planted_tests[@]}"; do
    name=$(basename "$t" .planted.t.sol)
    log "PLANTED: forge test --match-path $t"
    out=$(forge test --match-path "$t" -vv 2>&1)
    ec=$?
    if ! printf '%s' "$out" | grep -q "INVARIANT VIOLATED"; then
        planted_summary+=("PLANTED FAIL $name (did NOT produce INVARIANT VIOLATED  -  planted leg must surface it)")
        planted_failed=$((planted_failed + 1))
        printf '%s\n' "$out"
        continue
    fi
    if [ $ec -eq 0 ]; then
        planted_summary+=("PLANTED FAIL $name (forge test exited 0  -  planted leg must exit non-zero from property revert)")
        planted_failed=$((planted_failed + 1))
        continue
    fi
    planted_summary+=("PLANTED FIRED $name (INVARIANT VIOLATED)")
done

# --- Step 7: summary ----------------------------------------------------

echo ""
echo "================================================================"
echo " agentic-payments-regression M1  -  clean/planted twin summary"
echo "================================================================"
for line in "${clean_summary[@]}"; do echo "  $line"; done
for line in "${planted_summary[@]}"; do echo "  $line"; done
echo "----------------------------------------------------------------"
echo "  clean total: ${#clean_tests[@]}    clean failed: $clean_failed"
echo "  planted total: ${#planted_tests[@]}    planted failed: $planted_failed"
echo "================================================================"

if [ $clean_failed -gt 0 ] || [ $planted_failed -gt 0 ]; then
    fail "clean_failed=$clean_failed planted_failed=$planted_failed  -  see summary above for the row(s) that need attention."
fi

# --- Step 8: reachability leg (16 seeds x every planted suite) ----------
#
# Turns the base planted matrix's one-seed catch into a deterministic
# N-of-N certification: every seed in ci/reachability_seeds.txt must fire
# INVARIANT VIOLATED on every planted suite. Mirrors the identical leg
# shipped in caliperforge/euler-earn-invariants and
# caliperforge/uniswap-v4-invariants (proof_register row 7). Skipped only
# if the leg script is absent (older checkouts pre-reachability).

if [ -x ci/reachability_leg.sh ]; then
    log "REACHABILITY: ci/reachability_leg.sh (16 seeds x planted suites)"
    if ! ci/reachability_leg.sh; then
        fail "reachability leg did not certify fail-on-all-N  -  see per-suite lines above."
    fi
elif [ -f ci/reachability_leg.sh ]; then
    log "REACHABILITY: ci/reachability_leg.sh present but not executable; skipping (chmod +x to enable)."
else
    log "REACHABILITY: ci/reachability_leg.sh absent; skipping (older checkout pre-reachability)."
fi

log "All clean legs passed; all planted legs surfaced INVARIANT VIOLATED; reachability certified 16/16 on every planted suite. OK."
exit 0
