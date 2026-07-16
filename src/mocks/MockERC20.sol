// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.28;

/// @title MockERC20
/// @notice Minimal ERC-20 payment token for the x402 facilitator planted-twin tests.
/// Not production-safe. Approvals default to `type(uint256).max` so the
/// "infinite approval" UX pattern common in x402 facilitator flows is
/// modelled without needing a per-test approve() step.
contract MockERC20 {
    string public constant name = "Mock USDC";
    string public constant symbol = "mUSDC";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amount, "ERC20: allowance");
        require(balanceOf[from] >= amount, "ERC20: balance");
        if (a != type(uint256).max) allowance[from][msg.sender] = a - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
