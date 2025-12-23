// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SourceVault.sol";
import "../src/DestAdapter.sol";
import "../src/mocks/MockUSDC.sol";
import "../src/mocks/MockAavePool.sol";
import "../src/mocks/MockCCIPRouter.sol";

contract OmnichainTest is Test {
    SourceVault sourceVault;
    DestAdapter destAdapter;
    MockUSDC usdc;
    MockAavePool aavePool;
    MockCCIPRouter router;

    address user = address(0x1);
    address owner = address(this); // We are the one running the test

    function setUp() public {
        // 1. Setup Infrastructure
        usdc = new MockUSDC();
        aavePool = new MockAavePool();
        router = new MockCCIPRouter();

        // 2. Deploy Contracts
        sourceVault = new SourceVault(IERC20(address(usdc)), address(router));
        destAdapter = new DestAdapter(address(router), address(aavePool));

        // 3. Give Money to User
        usdc.mint(user, 1000 ether); // 1000 USDC
    }

    function testFullFlow() public {
        vm.startPrank(user);

        // --- STEP 1: USER INVESTS ---
        // User deposits money into Vault
        usdc.approve(address(sourceVault), 100 ether);
        sourceVault.deposit(100 ether, user);

        assertEq(sourceVault.totalAssets(), 100 ether);
        console.log("1. User deposited 100 USDC. Vault Balance: 100");
        vm.stopPrank();

        // --- STEP 2: BRIDGE OPERATION (TRIGGERED BY BOT) ---
        // As owner (bot), we operate the bridge

        console.log("2. Bot saw high interest on Arbitrum and started bridging...");

        // Destination chain ID (Mocked as 999)
        uint64 destChainId = 999;

        sourceVault.bridgeToStrategy(destChainId, address(destAdapter), 100 ether);

        // --- STEP 3: RESULT CHECK ---

        // A. There should be no money left in SourceVault (all sent)
        assertEq(usdc.balanceOf(address(sourceVault)), 0);
        console.log("3. Source Vault emptied (Money is on the way).");

        // B. DestAdapter should have received the money and deposited it to Aave
        // How much money is in MockAavePool on behalf of DestAdapter?
        uint256 investedAmount = aavePool.balances(address(destAdapter));

        assertEq(investedAmount, 100 ether);
        console.log("4. SUCCESS! Aave Pool balance on destination chain: ", investedAmount / 1e18, "USDC");
    }
}
