# Mento Demo

This repository contains a demo implementation of a contract that interacts with the Mento protocol on Celo to perform token swaps.

## Setup

1. Clone the repository:

```bash
git clone https://github.com/mento-protocol/hackathon-demo.git
cd hackathon-demo
```

2. Install dependencies:

```bash
forge install
```

3. Set up environment variables:

```bash
cp .env.example .env
```

4. Add your private key to the .env file:

```bash
# For Celo mainnet RPC URL
CELO_MAINNET_RPC_URL="https://forno.celo.org"

# For testnet RPC URL
CELO_TESTNET_RPC_URL="https://alfajores-forno.celo-testnet.org"

# Your private key
PRIVATE_KEY=

# Celoscan API Key for verifying contracts
CELOSCAN_API_KEY=
```

## Running Tests

The repository includes fork tests that interact with the actual Celo mainnet contracts.

1. Run all tests:

```bash
forge test
```

## Deploying the Contract

To deploy the BrokerDemo contract to Celo mainnet:

1. Set your private key in the .env file:

```bash
PRIVATE_KEY=your_private_key_here
```

2. Deploy the contract:

```bash
forge script deploy/DeployBrokerDemo.s.sol --rpc-url https://forno.celo.org --broadcast
```

3. Verify the contract:

```bash
forge verify-contract $CONTRACT_ADDRESS  --chain celo --rpc-url https://forno.celo.org
```

## Running the Demo Script

The repository includes a script that demonstrates the swap functionality by interacting with a deployed BrokerDemo contract.

1. Update the script with your deployed contract address:

   - Open `script/BrokerDemo.s.sol`
   - Replace `BROKER_DEMO` constant with your deployed contract address
  
2. Run the script:

```bash
forge script script/BrokerDemo.s.sol --rpc-url https://forno.celo.org --broadcast
```

## Contract Overview

The `BrokerDemo` contract provides a simple interface to swap cUSD for cEUR through the Mento protocol Router. It:

1. Takes cUSD as input
2. Swaps cUSD for USDC
3. Swaps USDC for cEUR
4. Returns cEUR to the user

## Important Addresses

- MentoRouter: `0xBE729350F8CdFC19DB6866e8579841188eE57f67`
- BiPoolManager: `0x22d9db95E6Ae61c104A7B6F6C78D7993B94ec901`
- cUSD: `0x765DE816845861e75A25fCA122bb6898B8B1282a`
- USDC: `0xcebA9300f2b948710d2653dD7B07f33A8B32118C`
- cEUR: `0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73`

## Requirements

- Foundry (forge, anvil, cast)
- A Celo wallet with Celo,cUSD for testing

## License

GPL-3.0-or-later
