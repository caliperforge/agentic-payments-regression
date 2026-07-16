// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title V05_CrossDomain  -  x402 facilitator with EIP-712 domain-separator
/// underconstraint (cross-chain / cross-facilitator replay) planted twin
/// @notice Reproduces the novel candidate class C1 from
/// `agents/research_lead/outbox/T-x402-candidate-hunt-2026-07-15_result.md`
/// §3: an x402 payment authorization signed against facilitator F on
/// chain C must NOT settle on any facilitator F' != F or any chain
/// C' != C, even when payer / recipient / amount / deadline / nonce
/// match. The failure mode is an EIP-712 domain separator that omits
/// `chainId` and `verifyingContract`  -  the same signature then
/// verifies against every facilitator instance on every chain.
///
/// Class is not covered by V01/V02/V03/V04 or by any named attack in
/// the arXiv corpus (P1 arXiv:2604.11430, P2 arXiv:2605.11781, P3
/// arXiv:2605.30998). V01 is per-digest replay on the same
/// facilitator on the same chain; V03 is a semantic gap on
/// `recipient` inside the digest; V05 is a semantic gap at the
/// domain level, orthogonal to both.
///
/// Reference pattern: EIP-712 domain-separator construction as
/// specified in EIP-712 and implemented by OpenZeppelin's
/// `EIP712.sol` (Apache-2.0). This contract does not vendor OZ; the
/// domain-separator math is inlined so the planted / clean delta
/// reads end-to-end without cross-file navigation, matching the M1
/// in-source-minimal-facilitator posture per `coverage_map.md` §2.
/// OZ pattern reference: OpenZeppelin/openzeppelin-contracts
/// contracts/utils/cryptography/EIP712.sol.
///
/// Feature flag: `defenseOn`. When true, the domain separator binds
/// `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`
/// with `block.chainid` and `address(this)`  -  standard EIP-712 shape.
/// When false, the domain separator uses a stripped typehash
/// `keccak256("EIP712Domain(string name,string version)")` and omits
/// both `chainId` and `verifyingContract`  -  the SDK-fork bug shape
/// where a downstream integrator "simplified" the domain construction.
///
/// HARD-rail: this is a class-level twin against a synthesized
/// minimal facilitator. No live x402 SDK was tested against; no
/// specific-instance CVE claim is made. If a live SDK carrying this
/// class surfaces during downstream vendoring, the standard
/// STOP-and-flag rail applies (`disclosures/TEMPLATE.md`).
contract V05_CrossDomain {
    struct Auth {
        address payer;
        address recipient;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
    }

    // EIP-712 typehashes. `PAYMENT_AUTH_TYPEHASH` is the same in both
    // branches; only the domain typehash differs, so the planted delta
    // is scoped to `_domainSeparator()`.
    bytes32 internal constant PAYMENT_AUTH_TYPEHASH = keccak256(
        "PaymentAuth(address payer,address recipient,uint256 amount,uint256 deadline,uint256 nonce)"
    );
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH_FULL = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH_STRIPPED = keccak256(
        "EIP712Domain(string name,string version)"
    );
    bytes32 internal constant NAME_HASH = keccak256(bytes("x402-facilitator"));
    bytes32 internal constant VERSION_HASH = keccak256(bytes("1"));

    IERC20Minimal public immutable token;
    bool public immutable defenseOn;
    mapping(bytes32 => bool) public usedAuth;

    event Settled(bytes32 indexed digest, address indexed payer, uint256 amount);

    constructor(IERC20Minimal _token, bool _defenseOn) {
        token = _token;
        defenseOn = _defenseOn;
    }

    function _domainSeparator() internal view returns (bytes32) {
        if (defenseOn) {
            // Standard EIP-712 domain: name, version, chainId, verifyingContract.
            return keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH_FULL, NAME_HASH, VERSION_HASH, block.chainid, address(this)
                )
            );
        }
        // Planted: omits chainId and verifyingContract. The same signature
        // now verifies against every facilitator instance on every chain.
        return keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH_STRIPPED, NAME_HASH, VERSION_HASH));
    }

    function digest(Auth memory a) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                PAYMENT_AUTH_TYPEHASH, a.payer, a.recipient, a.amount, a.deadline, a.nonce
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
    }

    function settle(Auth calldata a, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= a.deadline, "V05: deadline");
        bytes32 d = digest(a);
        require(!usedAuth[d], "V05: replayed");
        usedAuth[d] = true;

        address signer = ecrecover(d, v, r, s);
        require(signer == a.payer && signer != address(0), "V05: bad domain");

        require(token.transferFrom(a.payer, a.recipient, a.amount), "V05: transfer");
        emit Settled(d, a.payer, a.amount);
    }
}
