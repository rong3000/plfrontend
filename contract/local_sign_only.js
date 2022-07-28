//express

const express = require('express')
const path = require('path')
const moment = require('moment')
const { HOST } = require('./src/constants')
const db = require('./src/database')

const PORT = process.env.PORT || 3000

const CONTRACT_ID = "0xf8e81D47203A594245E36C48e151709F0C19fBe8"; 

const app = express()
  .set('port', PORT)
  .set('views', path.join(__dirname, 'views'))
  .set('view engine', 'ejs')

app.all('*', function (req, res, next) {
  res.header('Access-Control-Allow-Origin', 'http://localhost:5000'); //当允许携带cookies此处的白名单不能写’*’
  res.header('Access-Control-Allow-Headers', 'content-type,Content-Length, Authorization,Origin,Accept,X-Requested-With'); //允许的请求头
  res.header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS, PUT'); //允许的请求方法
  res.header('Access-Control-Allow-Credentials', true);  //允许携带cookies
  next();
});

// Static public files
app.use(express.static(path.join(__dirname, 'public')))

app.get('/', function (req, res) {
  res.send('Local Signing Only');
})

var crypto = require('crypto');
const { Pool, Client } = require('pg')

const pool = new Pool({
  connectionString: "postgres://jnfjiorkiwpisn:6016ec366c4c94ffdc349592f11cddd8f0fe4c5aa97bce44d2b356fa86a22ee7@ec2-3-223-169-166.compute-1.amazonaws.com:5432/d32kveuo9b8bb4",
  ssl: {
    rejectUnauthorized: false
  }
});

app.get('/api/wl/:account', function (req, res) {

  const _acc = req.params.account.toString()
  console.log("valide address? ", ethers.utils.isAddress(_acc));

  var max = 11;
  var min = 1;

  //assync
  if (ethers.utils.isAddress(_acc)) {
    let queryText = "SELECT * FROM wl WHERE ADDRESS = " + "\'" + _acc.toString() + "\'";
    console.log("query text is ", queryText);
    pool.connect((err, client, done) => {
      if (err) throw err
      client.query(queryText, (err, dbRes) => {
        done()
        if (err) {
          console.log(err.stack)
        } else {
          if (dbRes.rowCount > 0) {
            console.log("in db");
            res.send(JSON.stringify(dbRes.rows[0]));
            console.log('sent ', JSON.stringify(dbRes.rows[0]));
          }
          else {
            console.log('not in db');
            generateSignature(_acc)
              .then((obj) => {
                res.send(obj);

                pool.connect((err, client, done) => {
                  if (err) throw err
                  client.query("INSERT INTO wl (id, number, address, signature, consumed) VALUES ($1::varchar, $2::int, $3::varchar, $4::varchar, $5::int)",
                    [obj.id,
                    obj.number,
                    obj.address,
                    obj.signature,
                    0
                    ], (err, res) => {
                      done()
                      if (err) {
                        console.log(err.stack)
                      } else {
                        console.log('inserted without error', res.command, ' ', res.rowCount);
                      }
                    })
                })

              })
              .catch((error) => {
                console.error("something went wrong")
                console.error(error);
              })
          }
        }
      })
    })
  }
  else {
    res.send("The address is not a valid ether address.");
  }
})


app.listen(app.get('port'), function () {
  console.log('Node app is running on port', app.get('port'));
})

//signing
const ethers = require("ethers");

const fs = require('fs');
const addresses = require('./addresses.json');

// const pk = process.env.ACCOUNT_PRIVATE_KEY
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

    // const [owner] = await hre.ethers.getSigners()
    // const signer = pk ? new hre.ethers.Wallet(pk, hre.ethers.provider) : owner

    // var signer = new ethers.Wallet('8055848cef3af87fd8f431924fd1c39195c1494c3098c632b57ac88579e0503d');
    //0x3A92e4F5D0eF0642A85c0772915C78380C7A1548
    var signer = new ethers.Wallet('3f954d38c9985e837510301bab7fe63dd25d2ef8b14beba24e65fa1ef5991aaf');
    //0xb3857ebb2BB273e72adaB45B3417D1c111f3b21b

    var lm = new SignHelper(contractAddress, chainId, signer)
    var voucher = await lm.createSignature(voucherId, maxNumber, minterAddress)

    return voucher
  }
}

async function generateSignature(account) {
  let id = crypto.randomUUID().toString();

  // let coupon = await SignHelper.getSign(CONTRACT_ID, 4, id, 3, account) //success rinkeby signed with chain id 4
  let coupon = await SignHelper.getSign(CONTRACT_ID, 1, id, 3, account) //mainnet or jvm

  return coupon;

}

//db
