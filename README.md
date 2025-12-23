# Omnichain Savings

An omnichain savings application that leverages **Chainlink CCIP** to transport funds from a source chain to a destination chain and automatically deposits them into an **Aave** strategy for yield generation.

## Overview

This project demonstrates how to build cross-chain DeFi applications using the "Lock-and-Mint" or "Burn-and-Mint" (or simply message passing with token transfer) patterns provided by Chainlink CCIP.

### Architecture

1.  **SourceVault (Source Chain)**:
    -   Users deposit funds (e.g., USDC) into this vault.
    -   The vault holds the funds (or burns/locks them depending on the token model).
    -   A bot (or owner) triggers the `bridgeToStrategy` function.
    -   Funds are sent via Chainlink CCIP to the destination chain.

2.  **DestAdapter (Destination Chain)**:
    -   Receives the CCIP message containing the tokens and the instruction ("DEPOSIT").
    -   Automatically approves the received tokens for the Aave Pool.
    -   Deposits the tokens into Aave to start earning interest.

## Repo Structure

-   `src/SourceVault.sol`: The contract on the source chain where users deposit funds.
-   `src/DestAdapter.sol`: The contract on the destination chain that receives funds and connects to Aave.
-   `src/mocks/`: Mock contracts for testing (Aave, CCIP Router, USDC).
-   `test/Omnichain.t.sol`: Foundry tests simulating the full cross-chain flow.

## Prerequisites

-   [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Setup & Testing

1.  **Install Dependencies**:
    ```bash
    forge install
    ```

2.  **Run Tests**:
    ```bash
    forge test -vv
    ```

    You should see the full flow described in the logs:
    1.  User deposits USDC.
    2.  Bot triggers the bridge.
    3.  Funds arrive at the destination.
    4.  Funds are deposited into Aave.

3.  **Build**:
    ```bash
    forge build
    ```

## Development

This project was built with Foundry.

-   **Build**: `forge build`
-   **Test**: `forge test`
-   **Format**: `forge fmt`
