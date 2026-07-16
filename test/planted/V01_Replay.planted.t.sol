// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V01_Replay, IERC20Minimal} from "src/V01_Replay.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V01_Replay. Deploys the facilitator with
/// defenseOn=false (payment-replay hunk enabled) and asserts that
/// the same signed authorization can be settled N times, draining
/// the payer's balance. The invariant "recipient received exactly
/// the amount the payer authorized once" is violated on the second
/// settle; the assertion surfaces the marker `INVARIANT VIOLATED
/// V01_Replay` and exits non-zero, which the run.sh matrix greps
/// for.
contract V01_ReplayPlantedTest is Test {
    MockERC20 internal token;
    V01_Replay internal facilitator;
    uint256 internal payerPk = 0xA11CE;
    address internal payer;
    address internal recipient = address(0xBEEF);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V01_Replay(IERC20Minimal(address(token)), false);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_replaySurfacesInvariantViolated() public {
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
        facilitator.settle(a, v, r, s);
        facilitator.settle(a, v, r, s);

        // Payer authorized 100e6; if the facilitator honored the authorization
        // exactly once, recipient balance would be 100e6. The planted hunk
        // lets the same auth settle repeatedly.
        assertEq(
            token.balanceOf(recipient),
            100e6,
            "INVARIANT VIOLATED V01_Replay: same signed auth settled >1 time"
        );
    }
}
