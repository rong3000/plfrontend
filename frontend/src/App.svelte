<script>
  import { ethers } from "ethers";
  import { onMount } from "svelte";
  import Contract from "./PL1155.json";
  import { getOwned, sayHi, sayBye } from "./getOwned";

  // const CONTRACT_ID = "0x26c1a3Bca442fe4517437d139779bf1cc153EecB";
  // const CONTRACT_ID = "0xF8bB3f6e2502325B21E7abD98f3132a022C9B260";
  // const CONTRACT_ID = "0xc4a805Feb788010EDdD940D9B88F7C08723AD101";
  // const CONTRACT_ID = "0x30fD288439231Bf31C6f73562496112773CEcDC0";
  const CONTRACT_ID = "0x29F5eb891F5229346F4995D9De74590cDf565fAD";

  const ethereum = window.ethereum;

  let chain, provider, signer, contract, contractWithSigner;

  let maxMints = -1;
  let currentMinted = -1;
  let account = null;
  let minted = false;
  let loading = false;
  let quantity = 1;
  let ownedTokens = [];
  let recentlyMintedTokens = [];
  let openseaContractLink =
    "https://testnets.opensea.io/assets/0x290422ec6eadc2cc12acd98c50333720382ca86b/";
  let tokenSymbol = "PL";
  let selected = false;
  let childNFTs = {};
  // let accounts = [];
  function toggle(event) {
    // selected =!selected;
    // childNFTs[event.currentTarget.id] = selected;
    childNFTs[event.currentTarget.id] = !childNFTs[event.currentTarget.id];
    // console.log(
    //   "selected",
    //   selected,
    //   "event target",
    //   event.target,
    //   "event",
    //   event,
    //   "event current target",
    //   event.currentTarget,
    //   "event current target id",
    //   event.currentTarget.id
    // );
    console.log("childNFTs", childNFTs);
  }

  onMount(() => {
    chain = window.ethereum.networkVersion;
    console.log("--------------minted", minted);
  });

  // If Metamask is installed
  if (ethereum) {
    provider = new ethers.providers.Web3Provider(ethereum);
    signer = provider.getSigner();

    contract = new ethers.Contract(CONTRACT_ID, Contract.abi, provider);
    contractWithSigner = contract.connect(signer);

    ethereum.on("accountsChanged", function (accounts) {
      account = accounts[0];
      window.location.reload();
    });

    ethereum.on("chainChanged", function () {
      window.location.reload();
    });

    init();
  }

  async function init() {
    if (!account && ethereum.selectedAddress) {
      account = ethereum.selectedAddress;
    }

    if (account) {
      findCurrentOwned();
      findCurrentMinted();
    } else {
      fetchRecentlyMinted();
    }
  }

  async function login() {
    const accounts = await ethereum.request({
      method: "eth_requestAccounts",
    });
    account = accounts[0];
    init();
  }

  // async function disconnect() {
  //   accounts[0] = null;
  //   alert('ha');
  //   account = null;
  //   alert('ha');
  //   init();
  // }

  async function mint() {
    await contractWithSigner.mint(account, 1, quantity, "0x00");
    loading = true;
    contractWithSigner.on("Minted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      console.log("amount", amount.toNumber());
      currentMinted += amount.toNumber();
    });
  }

  async function forge() {
    await contractWithSigner.mint(account, 1, quantity, "0x00");
    loading = true;
    contractWithSigner.on("Minted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      console.log("amount", amount.toNumber());
      currentMinted += amount.toNumber();
    });
  }

  async function findCurrentOwned() {
    const numberOfTokensOwned = await contract.balanceOf(account, 1);
    console.log("numberOfTokensMinted", numberOfTokensOwned.toNumber());
    // for (let i = 0; i < Number(numberOfTokensOwned); i++) {

    const ownedToken = await getOwned(contract, account);
    console.log("ownedToken is: ", ownedToken);

    // const token = await contract.mintedTokenOfOwnerByIndex(account, i);
    const URI = await contract.uri(ownedToken[0].id);
    const mergedURI = URI.slice(0, -4) + ownedToken[0].id;
    console.log("URI is ", mergedURI);
    let response;
    try {
      response = await fetch(
        "https://sheltered-beach-35853.herokuapp.com/" + mergedURI
      );
      // response = await fetch(URI);
    } catch (error) {
      console.log(error);
    }

    const result = await response.json();
    result.id = ownedToken[0].id;

    ownedTokens.push(result);
    // }
    ownedTokens = ownedTokens;
  }

  async function findCurrentMinted() {
    const total = await contract.MAX_MINTS();
    sayHi("uri");
    const ownedToken = await getOwned(contract, account);
    console.log("ownedToken is: ", ownedToken);
    const supply = await contract.totalSupply(1);

    maxMints = Number(total);
    currentMinted = Number(supply);
  }

  async function fetchRecentlyMinted() {
    let recentMintEvents = await contract.queryFilter({
      topics: [
        "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62",
      ],
    });

    recentMintEvents = recentMintEvents.slice(-3);

    await recentMintEvents.map(async (MintEvent) => {
      const token = MintEvent.args.id;
      console.log("token id is ", token);
      const URI = await contract.uri(token);
      const mergedURI = URI.slice(0, -4) + token.toNumber();
      console.log("URI is ", mergedURI);

      let response;
      try {
        response = await fetch(
          "https://sheltered-beach-35853.herokuapp.com/" + mergedURI
        );
        // response = await fetch(URI);
      } catch (error) {
        console.log(error);
      }

      const result = await response.json();
      result.id = token;

      recentlyMintedTokens.push(result);
      recentlyMintedTokens = recentlyMintedTokens;
    });
  }
</script>

<header>
  <a href="/">Cloudflare Web3</a>
  <ul>
    <li>
      <a href="https://testnets.opensea.io/collection/cfnft">View on OpenSea</a>
    </li>
    <li><a href="https://github.com/signalnerve/cfweb3">GitHub</a></li>
  </ul>
</header>

{#if chain === "4"}
  <div class="warning">
    This marketplace is connected to the Rinkeby test network.
  </div>
{:else}
  <div class="error">
    This application requires you to be on the Rinkeby network. Use Metamask to
    switch networks.
  </div>
{/if}

<main>
  {#if ethereum}
    {#if account}
      <h1>👋 Welcome to the Cloudflare Web3 app</h1>
      <h2>You are currently logged in as {account.slice(0, 5)}</h2>
      {#if loading}
        <p>Transaction processing...</p>
      {/if}
      {#if minted}
        <p>
          You minted an NFT! If you haven't already, add a new asset to Metamask
          using the below info
        </p>
        <ul>
          <li>Contract address: {CONTRACT_ID}</li>
          <li>Token symbol: {tokenSymbol}</li>
          <li>Token decimal: 0</li>
        </ul>
      {/if}

      <form on:submit|preventDefault={mint}>
        <input
          type="number"
          min="1"
          max="3"
          placeholder="Quantity to mint"
          bind:value={quantity}
        />

        {#if currentMinted >= maxMints}
          <button disabled type="submit">Sold out</button>
        {:else}
          <button type="submit">Mint</button>
        {/if}
      </form>

      <section>
        <span>{currentMinted} / {maxMints} minted</span>
      </section>

      <h2>Your Tokens:</h2>
      {#if ownedTokens}
        <section>
          <button on:click={forge}>Forge Selected</button>
          <ul class="grid">
            <!-- <select id="childTokens" multiple="multiple"> -->
            {#each ownedTokens as token}
              <li id={token.id} on:click={toggle}>
                <label>
                  <input type="checkbox" checked={childNFTs[token.id]} />
                </label>
                <div class="grid-image">
                  <img src={token.image} alt={token.description} />
                </div>
                <div class="grid-footer">
                  <a target="_blank" href={`${openseaContractLink}${token.id}`}>
                    <h2>{token.name}</h2>
                    <span>{token.description}</span>
                  </a>
                </div>
              </li>
            {/each}
            <!-- </select> -->
          </ul>
        </section>
      {:else}
        <section>
          You don't have any tokens. Mint one with the button above to add it to
          your collection.
        </section>
      {/if}
    {:else}
      <h1>👋 Welcome to Cloudflare Web3.</h1>
      <h2>Login with Metamask to mint your NFT</h2>
      <button on:click={login}>Login</button>

      <h2>Recently Minted NFTs:</h2>
      {#if recentlyMintedTokens}
        <section>
          <ul class="grid">
            {#each recentlyMintedTokens as token}
              <li>
                <div class="grid-image">
                  <a
                    href={`https://testnets.opensea.io/assets/0x290422ec6eadc2cc12acd98c50333720382ca86b/${token.id}`}
                  >
                    <img src={token.image} alt={token.description} />
                  </a>
                </div>
                <div class="grid-footer">
                  <h2>{token.name}</h2>
                  <span>{token.description}</span>
                </div>
              </li>
            {/each}
          </ul>
        </section>
      {/if}
    {/if}
  {:else}
    <h1>This app requires a Metamask wallet.</h1>
    <p>
      You won't be asked to add any money. Install Metamask
      <a href="https://metamask.io/">here</a>.
    </p>
  {/if}
</main>

<footer>
  Built with <a href="https://pages.dev">Pages</a>
  and <a href="https://workers.dev">Workers</a>, and open-source
  <a href="https://github.com/cloudflare/cfweb3">on GitHub</a>.
  <a href="https://blog.cloudflare.com/get-started-web3"
    >Read the announcement blog post</a
  >.
</footer>
