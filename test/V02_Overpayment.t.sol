// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V02_Overpayment, IERC20Minimal} from "src/V02_Overpayment.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V02_Overpayment. Deploys the facilitator with
/// defenseOn=true and asserts that a caller cannot settle for more
/// than the resource-owner-posted price.
contract V02_OverpaymentCleanTest is Test {
    MockERC20 internal token;
    V02_Overpayment internal facilitator;
    uint256 internal payerPk = 0xB0B;
    address internal payer;
    address internal attacker = address(0xBAD);
    bytes32 internal resourceId = keccak256("resource/A");

    function setUp() public {
        token = new MockERC20();
        facilitator = new V02_Overpayment(IERC20Minimal(address(token)), true);
        facilitator.setResourcePrice(resourceId, 50e6);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_settleAtPostedPriceSucceeds() public {
        V02_Overpayment.Auth memory a = V02_Overpayment.Auth({
            payer: payer, resourceId: resourceId, deadline: block.timestamp + 1 hours, nonce: 1
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        vm.prank(attacker);
        facilitator.settle(a, v, r, s, 50e6);
        assertEq(token.balanceOf(attacker), 50e6);
    }

    function test_overpaymentReverts() public {
        V02_Overpayment.Auth memory a = V02_Overpayment.Auth({
            payer: payer, resourceId: resourceId, deadline: block.timestamp + 1 hours, nonce: 2
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        vm.prank(attacker);
        vm.expectRevert(bytes("V02: overpayment"));
        facilitator.settle(a, v, r, s, 1_000_000e6);

        assertEq(token.balanceOf(payer), 1_000_000e6);
    }
}
