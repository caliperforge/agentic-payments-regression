// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {V06_DelegationCap} from "src/V06_DelegationCap.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {AuthSigner} from "test/harness/AuthSigner.sol";

/// @notice Planted-leg twin for V06_DelegationCap. Deploys the manager
/// with defenseOn=false (cumulative counter never updated; each
/// call gates only on the single-call `amount <= allowance`
/// check). The payer signs a delegation permitting the spender an
/// allowance of 100e6 per period; the spender calls spend() twice
/// in the same period, each time at the full allowance, and drains
/// the payer's approval well beyond the delegation's cumulative
/// cap. Assertion surfaces `INVARIANT VIOLATED V06_DelegationCap`.
contract V06_DelegationCapPlantedTest is Test {
    MockERC20 internal token;
    V06_DelegationCap internal manager;
    uint256 internal accountPk = 0xACC0;
    address internal account;
    address internal spender = address(0x5EED);

    function setUp() public {
        token = new MockERC20();
        manager = new V06_DelegationCap(false);
        account = vm.addr(accountPk);
        token.mint(account, 1_000_000e6);
        vm.prank(account);
        token.approve(address(manager), type(uint256).max);
    }

    function test_cumulativeOverspendSurfacesInvariantViolated() public {
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

        // Two consecutive spends in the same period, each at the full
        // allowance. Under the planted branch neither call updates the
        // cumulative counter; both succeed.
        vm.prank(spender);
        manager.spend(p, v, r, s, 100e6);
        vm.prank(spender);
        manager.spend(p, v, r, s, 100e6);

        // Invariant: cumulative amount drawn under this delegation in
        // one period cannot exceed the signed allowance.
        assertLe(
            token.balanceOf(spender),
            p.allowance,
            "INVARIANT VIOLATED V06_DelegationCap: cumulative spend exceeded per-period allowance"
        );
    }
}
