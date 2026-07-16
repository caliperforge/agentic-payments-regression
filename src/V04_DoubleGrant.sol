// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IResource {
    function deliver(address to, bytes32 resourceId) external;
}

/// @title V04_DoubleGrant  -  x402 facilitator with concurrency-race /
/// duplicate-service-grant planted twin
/// @notice Reproduces the concurrency-race class from arXiv:2605.30998
/// ("Free-Riding the Agentic Web: A Systematic Security Analysis of
/// x402 Payments"). The paper describes a
/// facilitator whose service-grant emission happens before the
/// settlement is marked final, letting a colluding or malicious
/// resource contract reenter settle() and receive multiple grants
/// for a single on-chain payment.
///
/// The paper's original oracle is the HTTP-facilitator race
/// ("probabilistic service duplication"); this contract encodes the
/// on-chain analog as a checks-effects-interactions violation. The
/// numeric oracle from that paper (headline "248 grants for one
/// settlement" attributed downstream) is flagged UNVERIFIED per
/// `agents/solidity_specialist/inbox/T-ef-anchor-harness-m1-scaffold
/// -2026-07-14_arxiv-urls-reply.md` §2. This planted twin
/// reproduces the *class* (>1 grant per settle), not the specific
/// numeric oracle.
///
/// Citation: arXiv:2605.30998  -  "Free-Riding the Agentic Web:
/// A Systematic Security Analysis of x402 Payments".
/// [UNVERIFIED-AT-FETCH: exact section anchor pending live re-fetch;
/// see coverage_map.md §1.]
///
/// Feature flag: `defenseOn`. When true, settle() flips the
/// `settled[nonce]` state BEFORE calling into the external resource
/// contract (effects before interactions). When false, the external
/// call happens first, and a malicious resource can reenter settle()
/// to receive additional grants against the same (still unsettled)
/// auth.
contract V04_DoubleGrant {
    struct Auth {
        address payer;
        bytes32 resourceId;
        address resource;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
    }

    IERC20Minimal public immutable token;
    bool public immutable defenseOn;
    mapping(bytes32 => bool) public settled;

    event GrantEmitted(bytes32 indexed digest, address indexed payer, bytes32 indexed resourceId);
    event Settled(bytes32 indexed digest, uint256 amount);

    constructor(IERC20Minimal _token, bool _defenseOn) {
        token = _token;
        defenseOn = _defenseOn;
    }

    function digest(Auth memory a) public pure returns (bytes32) {
        bytes32 h =
            keccak256(abi.encode(a.payer, a.resourceId, a.resource, a.amount, a.deadline, a.nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function settle(Auth calldata a, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= a.deadline, "V04: deadline");
        bytes32 d = digest(a);
        require(!settled[d], "V04: already settled");

        address signer = ecrecover(d, v, r, s);
        require(signer == a.payer && signer != address(0), "V04: bad sig");

        if (defenseOn) {
            // Effects first: mark settled, then interact.
            settled[d] = true;
            emit GrantEmitted(d, a.payer, a.resourceId);
            IResource(a.resource).deliver(a.payer, a.resourceId);
            require(token.transferFrom(a.payer, msg.sender, a.amount), "V04: transfer");
            emit Settled(d, a.amount);
        } else {
            // Planted: interact before flipping settled  -  reentrant resource
            // can call settle() again with the same auth and receive a second
            // grant before the state update lands.
            emit GrantEmitted(d, a.payer, a.resourceId);
            IResource(a.resource).deliver(a.payer, a.resourceId);
            settled[d] = true;
            require(token.transferFrom(a.payer, msg.sender, a.amount), "V04: transfer");
            emit Settled(d, a.amount);
        }
    }
}
