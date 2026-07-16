// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title V06_DelegationCap  -  minimal SpendPermissionManager-shape session-key
/// manager with cumulative-cap-violation planted twin
/// @notice Reproduces the novel candidate class C2 from
/// `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md`
/// §3: for any active delegation with cumulative-spend cap `allowance`
/// over a rolling `period` window, the sum of amounts settled under
/// that delegation across all invocations within one period must not
/// exceed `allowance`. Formally:
///     spent[(digest, periodIndex)] + amount <= allowance
/// checked-and-updated atomically inside every `spend()` path, with
/// `(digest, periodIndex)` as the reset key.
///
/// Class is not covered by V01/V02/V03/V04 or by any named attack in
/// the arXiv corpus. V02 caps a single settle to an owner-posted
/// price; V06 caps cumulative settlement across N invocations under
/// a delegation, a different accounting invariant with a different
/// bug surface (delegation-state vs single-call-state).
///
/// Reference pattern: Coinbase's `SpendPermissionManager` shape
/// (Apache-2.0), a live-deployed session-key permission model on
/// Base. Reference: coinbase/spend-permissions
/// `src/SpendPermissionManager.sol`. This contract mirrors the
/// permission struct fields (account, spender, token, allowance,
/// period, start, end, salt) and the per-period cumulative-cap
/// enforcement rule; it does NOT vendor the full manager (approval
/// mechanics, ERC-1271 delegation, revocation) which are out of
/// scope for the class-level twin. The `NOTICE` scaffolding in
/// `coverage_map.md` §2 covers the pattern-provenance discipline if
/// the full manager is vendored in a future milestone.
///
/// Signature scheme: same minimal EIP-191-prefixed-hash-of-struct as
/// V01-V04 (deliberately not full EIP-712; the class here is
/// cumulative-cap arithmetic, not domain-separator construction).
///
/// Feature flag: `defenseOn`. When true, `spend()` computes
/// `(digest, periodIndex)` and enforces `spent + amount <= allowance`
/// BEFORE the `transferFrom`, persisting the updated `spent` first.
/// When false, the cumulative counter is never updated: each call
/// checks only the single-call `amount <= allowance`, so the spender
/// can drain the payer's approval up to the token allowance across
/// unbounded calls within a single period.
///
/// HARD-rail: this is a class-level twin against a synthesized
/// minimal manager. No live SpendPermissionManager deployment was
/// tested against; no specific-instance CVE claim is made. If a
/// live SDK carrying this class surfaces during downstream
/// vendoring, the standard STOP-and-flag rail applies
/// (`disclosures/TEMPLATE.md`).
contract V06_DelegationCap {
    struct SpendPermission {
        address account;
        address spender;
        address token;
        uint256 allowance;
        uint256 period;
        uint256 start;
        uint256 end;
        uint256 salt;
    }

    bool public immutable defenseOn;

    // Per-(delegation, periodIndex) cumulative spent. Only populated in
    // the defense branch  -  the planted branch omits this update entirely,
    // and each invocation gates on the single-call amount alone.
    mapping(bytes32 => mapping(uint256 => uint256)) public spentInPeriod;

    event Spent(
        bytes32 indexed digestKey,
        address indexed spender,
        uint256 indexed periodIndex,
        uint256 amount
    );

    constructor(bool _defenseOn) {
        defenseOn = _defenseOn;
    }

    function digest(SpendPermission memory p) public pure returns (bytes32) {
        bytes32 h = keccak256(
            abi.encode(
                p.account, p.spender, p.token, p.allowance, p.period, p.start, p.end, p.salt
            )
        );
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function currentPeriodIndex(SpendPermission memory p) public view returns (uint256) {
        // Monotone rolling-window index computed off (start, period). Not
        // manipulable by the spender because start is a signed field.
        return (block.timestamp - p.start) / p.period;
    }

    function spend(SpendPermission calldata p, uint8 v, bytes32 r, bytes32 s, uint256 amount)
        external
    {
        require(msg.sender == p.spender, "V06: not spender");
        require(block.timestamp >= p.start && block.timestamp <= p.end, "V06: window");
        require(amount > 0 && amount <= p.allowance, "V06: amount");

        bytes32 d = digest(p);
        address signer = ecrecover(d, v, r, s);
        require(signer == p.account && signer != address(0), "V06: bad sig");

        uint256 periodIndex = currentPeriodIndex(p);

        if (defenseOn) {
            // Effects-first: cumulative counter enforced and persisted
            // before the external token call.
            uint256 already = spentInPeriod[d][periodIndex];
            require(already + amount <= p.allowance, "V06: cap");
            spentInPeriod[d][periodIndex] = already + amount;
        }
        // Planted: no cumulative counter update. Per-call gate only.

        require(
            IERC20Minimal(p.token).transferFrom(p.account, p.spender, amount),
            "V06: transfer"
        );
        emit Spent(d, p.spender, periodIndex, amount);
    }
}
