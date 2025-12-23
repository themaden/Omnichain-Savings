// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// CCIP Arayüzleri (Chainlink)
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

contract SourceVault is ERC4626, Ownable {
    // Chainlink CCIP Router Adresi (Mesajı taşıyan kargo şirketi)d
    address public immutable i_router;

    constructor(IERC20 _asset, address _router) 
        ERC4626(_asset) 
        ERC20("Omni Savings Share", "osUSD") 
        Ownable(msg.sender) // Deploy eden kişi owner olur
    {
        i_router = _router; 
        
    }

    // --- KRİTİK FONKSİYON ---
    // Bu fonksiyonu bot çağıracak ve parayı diğer zincire yollayacak
    function bridgeToStrategy(
        uint64 _destinationChainSelector, // Hangi zincire gidiyor? (Chainlink ID'si)
        address _receiver,                // Karşıda kim karşılayacak?
        uint256 _amount                   // Ne kadar yolluyoruz?
    ) external onlyOwner {
        // 1. Router'a parayı çekmesi için izin ver
        IERC20(asset()).approve(i_router, _amount);

        // 2. Mesajı Hazırla
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode("DEPOSIT"), // Karşı tarafa şifreli not: "Yatır"
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000}) // Karşı tarafta harcanacak gas limiti
            ),
            feeToken: address(0) // Ücreti Native token (ETH/MATIC) ile öde
        });

        // Token miktarını ayarla
        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(asset()),
            amount: _amount
        });

        // 3. Yolla!
        IRouterClient(i_router).ccipSend{value: 0}( // Not: Gerçekte value (ETH) göndermek gerekir fee için
            _destinationChainSelector,
            message
        );
    }

    // Demo için CCIP Fee hesaplama fonksiyonu (Frontend'de göstermek için)
    function getFee(
        uint64 _destinationChainSelector,
        address _receiver,
        uint256 _amount
    ) external view returns (uint256) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode("DEPOSIT"),
            tokenAmounts: new Client.EVMTokenAmount[](1),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0)
        });
        
        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(asset()),
            amount: _amount
        });

        return IRouterClient(i_router).getFee(_destinationChainSelector, message);
    }
}