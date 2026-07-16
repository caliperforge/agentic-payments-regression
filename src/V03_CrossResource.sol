// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title V03_CrossResource  -  x402 facilitator with signature semantic-gap /
/// cross-resource-substitution planted twin
/// @notice Reproduces the signature-semantic-gap class from
/// arXiv:2605.11781 ("Five Attacks on x402"). The paper describes a
/// payment authorization whose signed struct omits the recipient
/// and/or resource identifier, letting an attacker who observes the
/// signature resubmit it against a different resource or reroute the
/// proceeds to their own address.
///
/// Citation: arXiv:2605.11781  -  "Five Attacks on x402".
/// [UNVERIFIED-AT-FETCH: exact section anchor pending live re-fetch;
/// see coverage_map.md §1. The semantic-gap shape reproduced here is
/// the missing-recipient-binding shape described in the Director
/// brief 2026-07-14.]
///
/// Feature flag: `defenseOn`. When true, the signed struct includes
/// `recipient` and the facilitator refuses any settle where the
/// caller-supplied recipient differs from the signed one. When
/// false, `recipient` is caller-controlled and unsigned  -  the
/// attacker reroutes the payer's payment to their own address.
///
/// Signature scheme: same minimal EIP-191 prefix as V01/V02. The
/// planted-leg auth deliberately omits `recipient` from the digest.
contract V03_CrossResource {
    struct Auth {
        address payer;
        bytes32 resourceId;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
        // recipient intentionally not on the struct  -  caller-supplied.
    }

    IERC20Minimal public immutable token;
    bool public immutable defenseOn;
    mapping(bytes32 => bool) public usedAuth;

    event Settled(
        bytes32 indexed digest, address indexed payer, address indexed recipient, uint256 amount
    );

    constructor(IERC20Minimal _token, bool _defenseOn) {
        token = _token;
        defenseOn = _defenseOn;
    }

    function digestPlanted(Auth memory a) public pure returns (bytes32) {
        // Planted: recipient NOT covered by signature.
        bytes32 h = keccak256(abi.encode(a.payer, a.resourceId, a.amount, a.deadline, a.nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function digestDefended(Auth memory a, address recipient) public pure returns (bytes32) {
        // Defense: recipient bound into the signed digest.
        bytes32 h =
            keccak256(abi.encode(a.payer, a.resourceId, a.amount, a.deadline, a.nonce, recipient));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function settle(Auth calldata a, address recipient, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= a.deadline, "V03: deadline");

        bytes32 d = defenseOn ? digestDefended(a, recipient) : digestPlanted(a);
        require(!usedAuth[d], "V03: replayed");
        usedAuth[d] = true;

        address signer = ecrecover(d, v, r, s);
        require(signer == a.payer && signer != address(0), "V03: bad sig");

        require(token.transferFrom(a.payer, recipient, a.amount), "V03: transfer");
        emit Settled(d, a.payer, recipient, a.amount);
    }
}
