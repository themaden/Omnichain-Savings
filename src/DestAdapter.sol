// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Simple interface to talk to Aave Pool
interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

contract DestAdapter is CCIPReceiver, Ownable {
    // The target pool where we will deposit funds (e.g. Aave Arbitrum Pool)
    address public immutable i_aavePool;

    // Events (Very important for showing on Frontend)
    event FundsReceived(bytes32 indexed messageId, uint256 amount, string action);
    event FundsInvested(address asset, uint256 amount);

    constructor(address _router, address _aavePool) CCIPReceiver(_router) Ownable(msg.sender) {
        i_aavePool = _aavePool;
    }

    // --- MAGIC FUNCTION ---
    // Router triggers this function. We don't need to call it manually.
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // 1. Capture the incoming Token and Amount
        // CORRECTION HERE: WE USE .destTokenAmounts INSTEAD OF .tokenAmounts
        address token = message.destTokenAmounts[0].token;
        uint256 amount = message.destTokenAmounts[0].amount;

        // 2. Decode the incoming Message (Data)
        string memory action = abi.decode(message.data, (string));

        emit FundsReceived(message.messageId, amount, action);

        // 3. If the order is "DEPOSIT", deposit to Aave
        if (keccak256(bytes(action)) == keccak256(bytes("DEPOSIT"))) {
            _depositToAave(token, amount);
        }
    }

    function _depositToAave(address _token, uint256 _amount) internal {
        // Approve Aave to "take my money"
        IERC20(_token).approve(i_aavePool, _amount);

        // Deposit money (onBehalfOf: deposit on behalf of this contract)
        IAavePool(i_aavePool).supply(_token, _amount, address(this), 0);

        emit FundsInvested(_token, _amount);
    }

    // Emergency button: To withdraw funds if something goes wrong
    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }
}
