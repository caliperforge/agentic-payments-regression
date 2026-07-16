// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title V02_Overpayment  -  x402 facilitator with overpayment / wallet-drain planted twin
/// @notice Reproduces the overpayment / wallet-drain class from
/// arXiv:2605.11781 ("Five Attacks on x402"). The paper describes a
/// facilitator that accepts a caller-supplied `amount` on settle()
/// and transfers that amount from the payer, rather than looking up
/// the resource-owner-posted price for the resource. Combined with
/// the standard "infinite approval" UX pattern (payer approves
/// `type(uint256).max` to the facilitator once), this lets any
/// caller drain the payer's balance up to the token allowance.
///
/// Citation: arXiv:2605.11781  -  "Five Attacks on x402".
/// [UNVERIFIED-AT-FETCH: exact section anchor pending live re-fetch;
/// see coverage_map.md §1. The overpayment shape reproduced here is
/// the amount-not-bound-to-posted-price shape described in the
/// Director brief 2026-07-14.]
///
/// Feature flag: `defenseOn`. When true, settle() transfers
/// `resourcePrice[resourceId]` (owner-posted) instead of the
/// caller-supplied amount, and rejects the settle if the auth's
/// amount exceeds the posted price. When false, the caller-supplied
/// amount is used directly.
///
/// Signature scheme: same minimal EIP-191-prefixed-hash-of-struct as
/// V01. The signature covers (payer, resourceId, deadline, nonce)
/// only  -  deliberately NOT the amount, to model the SDK bug where the
/// payer's signed authorization is over "any settlement for this
/// resource" and the facilitator is trusted to enforce the price.
contract V02_Overpayment {
    struct Auth {
        address payer;
        bytes32 resourceId;
        uint256 deadline;
        uint256 nonce;
    }

    IERC20Minimal public immutable token;
    bool public immutable defenseOn;
    mapping(bytes32 => uint256) public resourcePrice;
    mapping(bytes32 => bool) public usedAuth;

    event Settled(
        bytes32 indexed digest, address indexed payer, bytes32 indexed resourceId, uint256 amount
    );

    constructor(IERC20Minimal _token, bool _defenseOn) {
        token = _token;
        defenseOn = _defenseOn;
    }

    function setResourcePrice(bytes32 resourceId, uint256 price) external {
        // Real facilitator would gate by resource-owner; open here for test brevity.
        resourcePrice[resourceId] = price;
    }

    function digest(Auth memory a) public pure returns (bytes32) {
        bytes32 h = keccak256(abi.encode(a.payer, a.resourceId, a.deadline, a.nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    /// @param callerAmount caller-supplied settlement amount. In the planted
    /// branch this is transferred as-is. In the defense branch it is
    /// capped by `resourcePrice[a.resourceId]`.
    function settle(Auth calldata a, uint8 v, bytes32 r, bytes32 s, uint256 callerAmount) external {
        require(block.timestamp <= a.deadline, "V02: deadline");
        bytes32 d = digest(a);
        require(!usedAuth[d], "V02: replayed");
        usedAuth[d] = true;

        address signer = ecrecover(d, v, r, s);
        require(signer == a.payer && signer != address(0), "V02: bad sig");

        uint256 amount;
        if (defenseOn) {
            uint256 posted = resourcePrice[a.resourceId];
            require(posted > 0, "V02: unpriced");
            require(callerAmount <= posted, "V02: overpayment");
            amount = posted;
        } else {
            // Planted: trust the caller-supplied amount. Drains the payer.
            amount = callerAmount;
        }

        require(token.transferFrom(a.payer, msg.sender, amount), "V02: transfer");
        emit Settled(d, a.payer, a.resourceId, amount);
    }
}
