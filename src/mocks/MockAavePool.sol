// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockAavePool {
    // Keep track of who deposited how much
    mapping(address => uint256) public balances;

    // We are mocking Aave's supply function
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /* referralCode */
    ) external {
        // Pull funds into this contract
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Update balance
        balances[onBehalfOf] += amount;
    }
}
