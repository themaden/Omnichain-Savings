// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {
    CCIPReceiver
} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCCIPRouter {
    // Calculate fake fee when transferring funds
    function getFee(
        uint64,
        Client.EVM2AnyMessage memory
    ) external pure returns (uint256) {
        return 0; // Free for testing
    }

    // Message sending simulation
    function ccipSend(
        uint64, // destinationChainSelector (Irrelevant in test)
        Client.EVM2AnyMessage memory message
    ) external payable returns (bytes32) {
        // 1. Decode destination address from message
        address receiver = abi.decode(message.receiver, (address));

        // 2. Simulate token transfer (Sender -> Receiver)
        address token = message.tokenAmounts[0].token;
        uint256 amount = message.tokenAmounts[0].amount;

        // Router takes money from Sender (SourceVault), gives to Receiver (DestAdapter)
        IERC20(token).transferFrom(msg.sender, receiver, amount);

        // 3. TRIGGER the _ccipReceive function at the destination
        // MockRouter acts as a real CCIP network and pokes the destination.

        // Convert message format to Any2EVM (CCIPReceiver format)
        Client.Any2EVMMessage memory incomingMsg = Client.Any2EVMMessage({
            messageId: bytes32(uint256(1)), // Random ID
            sourceChainSelector: 1,
            sender: abi.encode(msg.sender),
            data: message.data,
            destTokenAmounts: message.tokenAmounts // Simplification
        });

        CCIPReceiver(receiver).ccipReceive(incomingMsg);

        return incomingMsg.messageId;
    }
}
