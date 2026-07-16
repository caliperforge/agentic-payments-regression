// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V06_DelegationCap} from "src/V06_DelegationCap.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Clean-leg twin for V06_DelegationCap. Deploys the manager with
/// defenseOn=true (cumulative-cap enforced and persisted). The
/// payer (account) signs a permission granting the spender an
/// allowance of 100e6 per 1-day period; the spender calls spend()
/// once at the full allowance, then attempts a second spend() in
/// the same period. The second call reverts on "V06: cap".
contract V06_DelegationCapCleanTest is Test {
    MockERC20 internal token;
    V06_DelegationCap internal manager;
    uint256 internal accountPk = 0xACC0;
    address internal account;
    address internal spender = address(0x5EED);

    function setUp() public {
        token = new MockERC20();
        manager = new V06_DelegationCap(true);
        account = vm.addr(accountPk);
        token.mint(account, 1_000_000e6);
        vm.prank(account);
        token.approve(address(manager), type(uint256).max);
    }

    function test_secondSpendInSamePeriodReverts() public {
        V06_DelegationCap.SpendPermission memory p = V06_DelegationCap.SpendPermission({
            account: account,
            spender: spender,
            token: address(token),
            allowance: 100e6,
            period: 1 days,
            start: block.timestamp,
            end: block.timestamp + 7 days,
            salt: 1
        });
        bytes32 d = manager.digest(p);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(accountPk, d);

        vm.prank(spender);
        manager.spend(p, v, r, s, 100e6);
        assertEq(token.balanceOf(spender), 100e6);

        // Same period: cumulative cap already at allowance.
        vm.prank(spender);
        vm.expectRevert(bytes("V06: cap"));
        manager.spend(p, v, r, s, 1);

        // Invariant: spender has drawn no more than one allowance in the
        // period.
        assertEq(token.balanceOf(spender), 100e6);
    }

    function test_nextPeriodResetsCap() public {
        V06_DelegationCap.SpendPermission memory p = V06_DelegationCap.SpendPermission({
            account: account,
            spender: spender,
            token: address(token),
            allowance: 100e6,
            period: 1 days,
            start: block.timestamp,
            end: block.timestamp + 7 days,
            salt: 2
        });
        bytes32 d = manager.digest(p);
        (uint8 v, bytes32 r, bytes32 s) = AuthSigner.sign(accountPk, d);

        vm.prank(spender);
        manager.spend(p, v, r, s, 100e6);

        // Advance to the next period; the (digest, periodIndex) key changes,
        // so the cumulative counter resets by design.
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(spender);
        manager.spend(p, v, r, s, 100e6);

        assertEq(token.balanceOf(spender), 200e6);
    }
}
