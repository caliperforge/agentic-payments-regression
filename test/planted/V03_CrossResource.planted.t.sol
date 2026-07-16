// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V03_CrossResource, IERC20Minimal} from "src/V03_CrossResource.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V03_CrossResource. Deploys with
/// defenseOn=false so the signed digest omits recipient. The payer
/// signs an authorization intending to pay `intendedRecipient`; an
/// attacker observing the signature resubmits it with recipient set
/// to their own address. Assertion surfaces `INVARIANT VIOLATED
/// V03_CrossResource`.
contract V03_CrossResourcePlantedTest is Test {
    MockERC20 internal token;
    V03_CrossResource internal facilitator;
    uint256 internal payerPk = 0xCAFE;
    address internal payer;
    address internal intendedRecipient = address(0xF00D);
    address internal attacker = address(0xBAD);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V03_CrossResource(IERC20Minimal(address(token)), false);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_reroutingSurfacesInvariantViolated() public {
        V03_CrossResource.Auth memory a = V03_CrossResource.Auth({
            payer: payer,
            resourceId: keccak256("resource/A"),
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });
        bytes32 d = facilitator.digestPlanted(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        vm.prank(attacker);
        facilitator.settle(a, attacker, v, r, s);

        // Invariant: funds went to the recipient the payer signed for.
        // Planted digest omits recipient, so the attacker successfully
        // pockets the payment.
        assertEq(
            token.balanceOf(intendedRecipient),
            100e6,
            "INVARIANT VIOLATED V03_CrossResource: payment rerouted from signed recipient"
        );
    }
}
