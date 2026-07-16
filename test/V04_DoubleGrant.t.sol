// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V04_DoubleGrant, IERC20Minimal} from "src/V04_DoubleGrant.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {BenignResource, MaliciousResource} from "test/harness/Resources.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V04_DoubleGrant. Deploys the facilitator with
/// defenseOn=true (state flipped before external call). Asserts that
/// a malicious resource cannot receive a second grant via reentrant
/// settle()  -  the reentry reverts on the "already settled" check.
contract V04_DoubleGrantCleanTest is Test {
    MockERC20 internal token;
    V04_DoubleGrant internal facilitator;
    MaliciousResource internal resource;
    uint256 internal payerPk = 0xD00D;
    address internal payer;
    address internal collector = address(0xC0FFEE);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V04_DoubleGrant(IERC20Minimal(address(token)), true);
        resource = new MaliciousResource(facilitator);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_reentrantResourceRevertsOnSecondSettle() public {
        V04_DoubleGrant.Auth memory a = V04_DoubleGrant.Auth({
            payer: payer,
            resourceId: keccak256("resource/A"),
            resource: address(resource),
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);
        resource.armReentry(a, v, r, s);

        vm.prank(collector);
        vm.expectRevert(bytes("V04: already settled"));
        facilitator.settle(a, v, r, s);

        // No deliveries land because the outer settle reverts entirely.
        assertEq(resource.deliveries(), 0);
    }
}
