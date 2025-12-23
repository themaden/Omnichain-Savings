// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SourceVault.sol";
import "../src/mocks/MockUSDC.sol";
import "../src/mocks/MockCCIPRouter.sol";

contract DeployScript is Script {
    function run() external {
        // Anvil'in default key'i ile işlem yap
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        // 1. Mockları Yarat
        MockUSDC usdc = new MockUSDC();
        MockCCIPRouter router = new MockCCIPRouter();

        // 2. Vault'u Yarat
        SourceVault vault = new SourceVault(IERC20(address(usdc)), address(router));

        // 3. Vault'a test için biraz para koy (Demo yaparken cüzdan boş görünmesin)
        usdc.mint(address(vault), 1000 ether); 

        console.log("-----------------------------------------");
        console.log("SourceVault Adresi:", address(vault));
        console.log("-----------------------------------------");

        vm.stopBroadcast();
    }
}