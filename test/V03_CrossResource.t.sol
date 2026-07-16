// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V03_CrossResource, IERC20Minimal} from "src/V03_CrossResource.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V03_CrossResource. Deploys with defenseOn=true
/// so the recipient is bound into the signed digest. Asserts that a
/// signature authorizing a payment to `intendedRecipient` cannot be
/// resubmitted with the caller pointing recipient at their own
/// address.
contract V03_CrossResourceCleanTest is Test {
    MockERC20 internal token;
    V03_CrossResource internal facilitator;
    uint256 internal payerPk = 0xCAFE;
    address internal payer;
    address internal intendedRecipient = address(0xF00D);
    address internal attacker = address(0xBAD);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V03_CrossResource(IERC20Minimal(address(token)), true);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_reroutingReverts() public {
        V03_CrossResource.Auth memory a = V03_CrossResource.Auth({
            payer: payer,
            resourceId: keccak256("resource/A"),
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });
        bytes32 d = facilitator.digestDefended(a, intendedRecipient);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        // Legit path.
        facilitator.settle(a, intendedRecipient, v, r, s);
        assertEq(token.balanceOf(intendedRecipient), 100e6);

        // Attacker tries to reroute the same signed auth to their own address
        // with a fresh nonce; sig no longer verifies because recipient is
        // covered by the digest.
        V03_CrossResource.Auth memory b = a;
        b.nonce = 2;
        bytes32 dHonest = facilitator.digestDefended(b, intendedRecipient);
        (uint8 v2, bytes32 r2, bytes32 s2) = AuthSigner.sign(payerPk, dHonest);

        vm.prank(attacker);
        vm.expectRevert(bytes("V03: bad sig"));
        facilitator.settle(b, attacker, v2, r2, s2);
    }
}
