// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V01_Replay, IERC20Minimal} from "src/V01_Replay.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V01_Replay. Deploys the facilitator with
/// defenseOn=true and asserts that a signed payment authorization
/// can be settled exactly once  -  the second settle of the same auth
/// reverts with "V01: replayed".
contract V01_ReplayCleanTest is Test {
    MockERC20 internal token;
    V01_Replay internal facilitator;
    uint256 internal payerPk = 0xA11CE;
    address internal payer;
    address internal recipient = address(0xBEEF);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V01_Replay(IERC20Minimal(address(token)), true);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_singleSettleSucceeds() public {
        V01_Replay.Auth memory a = V01_Replay.Auth({
            payer: payer,
            recipient: recipient,
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 1
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        facilitator.settle(a, v, r, s);
        assertEq(token.balanceOf(recipient), 100e6);
    }

    function test_replayReverts() public {
        V01_Replay.Auth memory a = V01_Replay.Auth({
            payer: payer,
            recipient: recipient,
            amount: 100e6,
            deadline: block.timestamp + 1 hours,
            nonce: 2
        });
        bytes32 d = facilitator.digest(a);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(payerPk, d);

        facilitator.settle(a, v, r, s);
        vm.expectRevert(bytes("V01: replayed"));
        facilitator.settle(a, v, r, s);

        // Invariant: recipient received exactly the single authorized amount.
        assertEq(token.balanceOf(recipient), 100e6);
    }
}
