// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V02_Overpayment, IERC20Minimal} from "src/V02_Overpayment.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V02_Overpayment. Deploys with defenseOn=false
/// (the caller-supplied amount is trusted). The attacker submits an
/// auth signed for the posted-price resource but settles for the
/// payer's full balance. Assertion surfaces `INVARIANT VIOLATED
/// V02_Overpayment`.
contract V02_OverpaymentPlantedTest is Test {
    MockERC20 internal token;
    V02_Overpayment internal facilitator;
    uint256 internal payerPk = 0xB0B;
    address internal payer;
    address internal attacker = address(0xBAD);
    bytes32 internal resourceId = keccak256("resource/A");
    uint256 internal constant POSTED_PRICE = 50e6;
    uint256 internal constant PAYER_BALANCE = 1_000_000e6;

    function setUp() public {
        token = new MockERC20();
        facilitator = new V02_Overpayment(IERC20Minimal(address(token)), false);
        facilitator.setResourcePrice(resourceId, POSTED_PRICE);
        payer = vm.addr(payerPk);
        token.mint(payer, PAYER_BALANCE);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_overpaymentSurfacesInvariantViolated() public {
        V02_Overpayment.Auth memory a = V02_Overpayment.Auth({
            payer: payer, resourceId: resourceId, deadline: block.timestamp + 1 hours, nonce: 1
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        vm.prank(attacker);
        facilitator.settle(a, v, r, s, PAYER_BALANCE);

        // Invariant: settlement amount for resource A must not exceed its
        // posted price.
        assertLe(
            token.balanceOf(attacker),
            POSTED_PRICE,
            "INVARIANT VIOLATED V02_Overpayment: transfer exceeded posted resource price"
        );
    }
}
