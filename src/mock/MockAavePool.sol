// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockCCIPRouter {
    // Parayı transfer ederken yalandan fee hesapla
    function getFee(
        uint64,
        Client.EVM2AnyMessage memory
    ) external pure returns (uint256) {
        return 0; // Test için bedava olsun
    }

    // Mesaj gönderme simülasyonu
    function ccipSend(
        uint64, // destinationChainSelector (Testte önemsiz)
        Client.EVM2AnyMessage memory message
    ) external payable returns (bytes32) {
        // 1. Hedef adresi mesajdan çöz
        address receiver = abi.decode(message.receiver, (address));
        
        // 2. Token transferini simüle et (Gönderenden -> Alıcıya)
        address token = message.tokenAmounts[0].token;
        uint256 amount = message.tokenAmounts[0].amount;
        
        // Router parayı gönderenden (SourceVault) alır, Alıcıya (DestAdapter) verir
        IERC20(token).transferFrom(msg.sender, receiver, amount);

        // 3. Hedefteki _ccipReceive fonksiyonunu TETİKLE
        // MockRouter, sanki gerçek bir CCIP ağıymış gibi davranıp hedefi dürtüyor.
        
        // Mesaj formatını Any2EVM'e çevir (CCIPReceiver formatı)
        Client.Any2EVMMessage memory incomingMsg = Client.Any2EVMMessage({
            messageId: bytes32(uint256(1)), // Rastgele bir ID
            sourceChainSelector: 1,
            sender: abi.encode(msg.sender),
            data: message.data,
            destTokenAmounts: message.tokenAmounts // Basitleştirme
        });

        CCIPReceiver(receiver).ccipReceive(incomingMsg);

        return incomingMsg.messageId;
    }
}