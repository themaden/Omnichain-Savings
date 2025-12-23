// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// CCIP Interfaces (Chainlink)
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

contract SourceVault is ERC4626, Ownable {
    // Chainlink CCIP Router Address (The courier carrying the message)
    address public immutable i_router;

    constructor(IERC20 _asset, address _router)
        ERC4626(_asset)
        ERC20("Omni Savings Share", "osUSD")
        Ownable(msg.sender) // The deployer becomes the owner

    {
        i_router = _router;
    }

    // --- CRITICAL FUNCTION ---
    // The bot will call this function to bridge funds to the destination chain
    function bridgeToStrategy(
        uint64 _destinationChainSelector, // Which chain is it going to? (Chainlink ID)
        address _receiver, // Who will receive it on the other side?
        uint256 _amount // How much are we sending?
    )
        external
        onlyOwner
    {
        // 1. Approve Router to spend funds
        IERC20(asset()).approve(i_router, _amount);

        // 2. Prepare the Message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode("DEPOSIT"), // Encrypted note to the other side: "DEPOSIT"
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000}) // Gas limit to be spent on the destination chain
            ),
            feeToken: address(0) // Pay fee with Native token (ETH/MATIC)
        });

        // Set token amount
        message.tokenAmounts[0] = Client.EVMTokenAmount({token: address(asset()), amount: _amount});

        // 3. Send!
        IRouterClient(i_router).ccipSend{value: 0}(// Note: In reality, you need to send value (ETH) for fees
            _destinationChainSelector, message
        );
    }

    // CCIP Fee calculation function for Demo (To show on Frontend)
    function getFee(uint64 _destinationChainSelector, address _receiver, uint256 _amount)
        external
        view
        returns (uint256)
    {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode("DEPOSIT"),
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0)
        });

        message.tokenAmounts[0] = Client.EVMTokenAmount({token: address(asset()), amount: _amount});

        return IRouterClient(i_router).getFee(_destinationChainSelector, message);
    }
}
