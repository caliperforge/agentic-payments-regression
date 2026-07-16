// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V05_CrossDomain, IERC20Minimal} from "src/V05_CrossDomain.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V05_CrossDomain. Deploys two facilitator
/// instances (F_A on chainId=1, F_B on chainId=8453) both with
/// defenseOn=true (full EIP-712 domain: name, version, chainId,
/// verifyingContract). Payer signs a payment auth against F_A on
/// chain 1; an attacker attempts to replay the same signature
/// against F_B on chain 8453. The clean-leg domain separator binds
/// chainId + verifyingContract, so F_B recovers a different signer
/// and reverts "V05: bad domain".
contract V05_CrossDomainCleanTest is Test {
    MockERC20 internal token;
    V05_CrossDomain internal facilitatorA;
    V05_CrossDomain internal facilitatorB;
    uint256 internal payerPk = 0xA11CE;
    address internal payer;
    address internal recipient = address(0xBEEF);

    function setUp() public {
        token = new MockERC20();
        // Deploy F_A on Ethereum mainnet chainId.
        vm.chainId(1);
        facilitatorA = new V05_CrossDomain(IERC20Minimal(address(token)), true);
        // Deploy F_B on Base chainId. Distinct address by construction
        // (different deployment nonce).
        vm.chainId(8453);
        facilitatorB = new V05_CrossDomain(IERC20Minimal(address(token)), true);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitatorA), type(uint256).max);
        vm.prank(payer);
        token.approve(address(facilitatorB), type(uint256).max);
    }

    function test_crossChainReplayReverts() public {
        V05_CrossDomain.Auth memory a = V05_CrossDomain.Auth({
            payer: payer,
            recipient: recipient,
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });

        // Sign against F_A / chainId=1.
        vm.chainId(1);
        bytes32 d = facilitatorA.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        // Legit path: settle on F_A / chain 1.
        facilitatorA.settle(a, v, r, s);
        assertEq(token.balanceOf(recipient), 100e6);

        // Attacker replays the same signature to F_B on chain 8453.
        // Under the defended domain, F_B computes a different digest
        // (its own chainId + verifyingContract), so ecrecover yields a
        // signer that does not match a.payer, tripping "V05: bad domain".
        vm.chainId(8453);
        vm.expectRevert(bytes("V05: bad domain"));
        facilitatorB.settle(a, v, r, s);

        // Invariant: recipient received exactly the amount the payer
        // authorized for the single (facilitator, chain) pair.
        assertEq(token.balanceOf(recipient), 100e6);
    }
}
