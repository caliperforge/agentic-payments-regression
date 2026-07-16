// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title V01_Replay  -  x402 facilitator with payment-replay planted twin
/// @notice Reproduces the payment-replay class from arXiv:2605.11781 ("Five
/// Attacks on x402"). The paper describes a signed payment
/// authorization that a facilitator (or observer) can resubmit N times
/// against a payer whose token allowance to the facilitator has not
/// been reset, because the facilitator does not persist the
/// signed-auth digest as a used nonce.
///
/// Citation: arXiv:2605.11781  -  "Five Attacks on x402".
/// [UNVERIFIED-AT-FETCH: exact section anchor pending live re-fetch;
/// see coverage_map.md §1 for the retrieval-date note. The attack
/// shape reproduced here is the payment-replay shape described in
/// the Director brief 2026-07-14 quoting that paper.]
///
/// Feature flag: `defenseOn`. When true, the facilitator persists
/// `usedAuth[digest] = true` on first settle and reverts subsequent
/// settles of the same digest. When false, the check is skipped and
/// the attack succeeds  -  the planted-leg test surfaces
/// `INVARIANT VIOLATED V01_Replay`.
///
/// Signature scheme: minimal EIP-191-style prefixed-hash-of-struct
/// (`keccak256(abi.encode(payer, recipient, amount, deadline, nonce))`,
/// then `\x19Ethereum Signed Message:\n32` prefix). This is not full
/// EIP-712 typed-data; the shape is faithful enough to the paper's
/// attack to reproduce the class deterministically without vendoring
/// the reference SDK's exact domain separator. Full EIP-712 is M2 if a
/// downstream integrator asks for it.
contract V01_Replay {
    struct Auth {
        address payer;
        address recipient;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
    }

    IERC20Minimal public immutable token;
    bool public immutable defenseOn;
    mapping(bytes32 => bool) public usedAuth;

    event Settled(bytes32 indexed digest, address indexed payer, uint256 amount);

    constructor(IERC20Minimal _token, bool _defenseOn) {
        token = _token;
        defenseOn = _defenseOn;
    }

    function digest(Auth memory a) public pure returns (bytes32) {
        bytes32 h = keccak256(abi.encode(a.payer, a.recipient, a.amount, a.deadline, a.nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function settle(Auth calldata a, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= a.deadline, "V01: deadline");
        bytes32 d = digest(a);

        // Planted-twin split: only the defense-on path persists the digest.
        // The paper's replay attack is the delta between these two branches.
        if (defenseOn) {
            require(!usedAuth[d], "V01: replayed");
            usedAuth[d] = true;
        }

        address signer = ecrecover(d, v, r, s);
        require(signer == a.payer && signer != address(0), "V01: bad sig");

        require(token.transferFrom(a.payer, a.recipient, a.amount), "V01: transfer");
        emit Settled(d, a.payer, a.amount);
    }
}
