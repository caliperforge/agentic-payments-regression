// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V04_DoubleGrant, IERC20Minimal} from "src/V04_DoubleGrant.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {MaliciousResource} from "test/harness/Resources.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V04_DoubleGrant. Deploys with defenseOn=false
/// (interactions before effects). A malicious resource reenters
/// settle() during its first deliver() call, receiving a second
/// grant against the same signed auth before the settled state is
/// written. Assertion surfaces `INVARIANT VIOLATED V04_DoubleGrant`.
contract V04_DoubleGrantPlantedTest is Test {
    MockERC20 internal token;
    V04_DoubleGrant internal facilitator;
    MaliciousResource internal resource;
    uint256 internal payerPk = 0xD00D;
    address internal payer;
    address internal collector = address(0xC0FFEE);

    function setUp() public {
        token = new MockERC20();
        facilitator = new V04_DoubleGrant(IERC20Minimal(address(token)), false);
        resource = new MaliciousResource(facilitator);
        payer = vm.addr(payerPk);
        token.mint(payer, 1_000_000e6);
        vm.prank(payer);
        token.approve(address(facilitator), type(uint256).max);
    }

    function test_doubleGrantSurfacesInvariantViolated() public {
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
        facilitator.settle(a, v, r, s);

        // Invariant: exactly one grant delivered per authorized settlement.
        assertEq(
            resource.deliveries(),
            1,
            "INVARIANT VIOLATED V04_DoubleGrant: >1 service grant delivered for a single signed authorization"
        );
    }
}
