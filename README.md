# Web3

This is a Web3 application. It uses [Svelte](https://svelte.dev/) as web frontend. It uses [Hardhat](https://github.com/nomiclabs/hardhat) and [Solidity](https://soliditylang.org/) to create an [Ethereum](https://ethereum.org/) smart contract.

The contract offers tokens which can be minted via the frontend [Svelte](https://svelte.dev/) application. The entire app runs on Ethereum main network as well as the [Rinkeby](https://www.rinkeby.io/) test network.

## erc1155.online

Frontend app can be found at [erc1155.online](https://erc1155.online/).

## Building locally

1. Clone the repo
2. npm install in `contract` and `frontend` with:

```sh
cd contract
npm install
cd ../frontend
npm install
```

3. Install Metamask, switch to the testnet and add funds (instructions below)
4. Click on Metamask and then on the hamburger icon in the top right
5. Click on "Account details"
6. Click on "Export Private Key"
7. Enter Metamask password
8. Copy your private key
9. In one terminal window, move into the `contract` directory and run:

```sh
dapk="YOUR_PRIVATE_KEY" npx hardhat node
```

10. In a different terminal window, move into the `frontend` directory and run:

```sh
npm run dev
```

## Adding funds to your Metamask test account

1. Install [Metamask](https://metamask.io/)
2. Switch Metamask to the Rinkeby test network

![Metamask switch to testnet](/img/metamask-testnet.png)

3. Copy your Rinkeby account wallet address.

4. Go to the [Rinkeby faucet](https://faucet.rinkeby.io/)
5. Post a Tweet or a Facebook status with your Rinkeby wallet address.
6. Enter the URL of your Tweet or Facebook post on the faucet website.
7. Claim the amount you want.
8. Delete the social media post (optional).