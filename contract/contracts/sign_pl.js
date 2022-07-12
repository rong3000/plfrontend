const hre = require("hardhat");

const fs = require('fs');
const addresses = require('./addresses.json');

const pk = process.env.ACCOUNT_PRIVATE_KEY
// console.log('pk is', pk);

const SIGNING_DOMAIN_NAME = "PL"
const SIGNING_DOMAIN_VERSION = "1"

class SignHelper {
    constructor(contractAddress, chainId, signer) {
        this.contractAddress = contractAddress
        this.chainId = chainId
        this.signer = signer
    }

    async createSignature(id, number, address) {
        const obj = { id, number, address }
        const domain = await this._signingDomain()
        const types = {
            Web3Struct: [
                // { name: "id", type: "uint256" },
                { name: "id", type: "string" },
                { name: "number", type: "uint256" },
                { name: "address", type: "address" }
            ]
        }
        const signature = await this.signer._signTypedData(domain, types, obj)
        return { ...obj, signature }
    }

    async _signingDomain() {
        if (this._domain != null) {
            return this._domain
        }
        const chainId = await this.chainId
        this._domain = {
            name: SIGNING_DOMAIN_NAME,
            version: SIGNING_DOMAIN_VERSION,
            verifyingContract: this.contractAddress,
            chainId,
        }
        return this._domain
    }

    static async getSign(contractAddress, chainId, voucherId, maxNumber, minterAddress) {
        // var provider = new ethers.providers.Web3Provider(window.ethereum)

        // await provider.send("eth_requestAccounts", []);
        // var signer = provider.getSigner()
        // await signer.getAddress()

        const [owner] = await hre.ethers.getSigners()
        const signer = pk ? new hre.ethers.Wallet(pk, hre.ethers.provider) : owner

        var lm = new SignHelper(contractAddress, chainId, signer)
        var voucher = await lm.createSignature(voucherId, maxNumber, minterAddress)

        return voucher
    }
}

async function main() {
    let signedMessages = [];
    for (let address of addresses) {

        // let { signature } = await SignHelper.getSign('0xd9145CCE52D386f254917e481eB44e9943F39138', 1, 4, 5, address)
        // let { signature } = await SignHelper.getSign('0x00f6793D6e227A7eeE9625eDfF762005fd4816aE', 1, 4, 5, address) //rinkeby signed with chain id 1
        // let { signature } = await SignHelper.getSign('0x00f6793D6e227A7eeE9625eDfF762005fd4816aE', 4, 4, 5, address) //success rinkeby signed with chain id 4
        // let { signature } = await SignHelper.getSign('0x5AA693BdB0c2e92B5c62FEEf451A41E1e8c1b7AF', 4, 4, 5, address) //success rinkeby signed with chain id 4
        // let { signature } = await SignHelper.getSign('0xd9145CCE52D386f254917e481eB44e9943F39138', 1, 4, 5, address) //java signed with chain id 1 deployed 0x3A92e4F5D0eF0642A85c0772915C78380C7A1548
        // let { signature } = await SignHelper.getSign('0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8', 1, 4, 5, address) //java signed with chain id 1 deployed 0x74e2Be10DFf4e189c5CA9e605ee46547382e38E0
        // let coupon = await SignHelper.getSign('0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c', 1, 4, 5, address) //int
        let coupon = await SignHelper.getSign('0xcD6a42782d230D7c13A74ddec5dD140e55499Df9', 1, "x", 5, address) //string
        signedMessages.push(coupon);

    }
    fs.writeFileSync('./signatures.json', JSON.stringify(signedMessages, null, 2), 'utf8');
    console.log("Signatures Written > `./signatures.json`");

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("something went wrong")
        console.error(error);
        process.exit(1);
    });
