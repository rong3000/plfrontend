<script>
  import { ethers } from "ethers";
  import { onMount } from "svelte";
  import Contract from "./PL1155.json";
  import { getOwned } from "./getOwned";

  const CONTRACT_ID = "0x8Ef0879e5bBcf5edf18B0C03D4DF858Ac07D3408"; //to be changed after contract deployed

  const ethereum = window.ethereum;

  let chain, provider, signer, contract, contractWithSigner;

  let maxMints = -1;
  let currentMinted = -1;
  let account = null;
  let minted = false;
  let loading = false;
  let bElementId = 1;
  let ownedTokens = [];
  let recentlyMintedTokens = [];
  let openseaContractLink =
    "https://testnets.opensea.io/assets/0x92AB5aBa441674FD59aeb63Ee3282851567b63a1/"; //to be changed after contract deployed
  let tokenSymbol = "PL";
  let childNFTs = {};
  let childNFTarray = new Set();
  let numberOfSelected;
  let containMerged = false;

  // console.log("first childNFTs[token.id] is ", childNFTs[1]);

  function toggle(event) {
    childNFTs[event.currentTarget.id] = !childNFTs[event.currentTarget.id];
    console.log("childNFTs", childNFTs); //console.log
    if (childNFTs[event.currentTarget.id]) {
      childNFTarray.add(event.currentTarget.id);
    } else if (!childNFTs[event.currentTarget.id]) {
      childNFTarray.delete(event.currentTarget.id);
    }
    numberOfSelected = childNFTarray.size;
    console.log("childNFTarray", ...childNFTarray); //console.log
    console.log("childNFTarray.size is", numberOfSelected); //console.log
    containMerged = false;
    for (let i = 0; i < childNFTarray.size; i++) {
      if (Array.from(childNFTarray)[i] > 10000) {
        containMerged = true;
      }
    }
  }

  onMount(() => {
    chain = ethereum.chainId;
    account = ethereum.selectedAddress;//
    console.log("1 chain is ", chain);//
    console.log("1 account is ", account);//
    console.log("1 selectedAddress is ", ethereum.selectedAddress);//
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


    console.log("2 chain is ", chain);
    console.log("2 account is ", account);

    init();
  }

  async function init() {
    console.log('account ', account);
    console.log('ethereum.selectedAddress ', ethereum.selectedAddress);
    console.log('if ', (!account && ethereum.selectedAddress));
    if (!account && ethereum.selectedAddress) {
    // if (!(account && ethereum.selectedAddress)) {
      account = ethereum.selectedAddress;
    }

    console.log("3 chain is ", chain);
    console.log("3 account is ", account);
    console.log("3 selectedAddress is ", ethereum.selectedAddress);

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

  async function mint() {
    minted = false;
    await contractWithSigner.mint(account, bElementId, 1, "0x00");
    loading = true;
    numberOfSelected = 0;
    childNFTs = {}; //Clear selection
    contractWithSigner.on("Minted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      console.log("amount", amount.toNumber());
      findCurrentOwned();
    });
  }

  async function merge() {
    console.log("merge1?");//
    minted = false;

    await contractWithSigner.merge(account, Array.from(childNFTarray), "0x00");
    loading = true;
    numberOfSelected = 0;
    childNFTs = {}; //Clear selection
    contractWithSigner.on("Minted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      console.log("Merged id is ", tokenId.toNumber());
      findCurrentOwned();
    });
  }

  async function split() {
    console.log(
      "childNFTarray size and element ",
      childNFTarray.size,
      Array.from(childNFTarray)
    );

    if (childNFTarray.size == 1 && Array.from(childNFTarray)[0] > 10000) {
      console.log("can split");//
      minted = false;

      await contractWithSigner.split(
        account,
        Array.from(childNFTarray)[0],
        "0x00"
      );
      loading = true;
      numberOfSelected = 0;
      childNFTs = {}; //Clear selection
      contractWithSigner.on("Split", (to, id, event) => {
        minted = true;
        loading = false;
        console.log("Split ", id.toNumber());
      findCurrentOwned();
      });
    } else {
      console.log("Can only select one merged element to split");
    }
  }

  async function findCurrentOwned() {
    numberOfSelected = 0;
    childNFTs = {}; //Clear selection
    const numberOfTokensOwned = await contract.balanceOf(account, 1);
    console.log("numberOfTokensMinted", numberOfTokensOwned.toNumber());
    // for (let i = 0; i < Number(numberOfTokensOwned); i++) {

    childNFTarray.clear();
    let ownedToken = await getOwned(contract, account);
    console.log("ownedToken is: ", ownedToken);
    console.log("childNFTarray is cleared ", childNFTarray);

    ownedTokens = [];
    console.log("resetted ownedToken is ", ownedTokens);
    
    for (let i = 0; i < ownedToken.length; i++) {
      console.log("fetching ", i);
      // const token = await contract.mintedTokenOfOwnerByIndex(account, i);
      const URI = await contract.uri(ownedToken[i].id);
      const mergedURI = URI.slice(0, -4) + ownedToken[i].id;
      // const originalURI = URI
      // console.log("original URI is ", URI);
      // const mergedURI = URI.slice(0, -4);
      console.log("merged URI is ", mergedURI);
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
      result.id = ownedToken[i].id;
      if (ownedToken[i].quantity > 0) {
        ownedTokens.push(result);
      }
    }

    // }
    ownedTokens = ownedTokens; //Clear button status

    console.log("ownedTokens, numberOfSelected, childNFTs", ownedTokens, numberOfSelected, childNFTs);

  }

  async function findCurrentMinted() {
    const total = await contract.MAX_MINTS();
    // const ownedToken = await getOwned(contract, account);
    // console.log("ownedToken is: ", ownedToken);
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
    
    console.log("looking for selectedAddress 1 ", ethereum.selectedAddress);
    if (ethereum.selectedAddress) {
      window.location.reload();
    } //if

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

    chain = ethereum.chainId;
    console.log("4 chain is ", chain);
    console.log("4 account is ", account);
    console.log("4 selectedAddress is ", ethereum.selectedAddress);
  }
</script>

<header>
  <a href="/">Poo</a>
  <ul>
    <li>
      <a href="https://testnets.opensea.io/collection/cfnft">View on OpenSea</a>
      <!-- to be updated after deployed -->
    </li>
  </ul>
</header>

{#if chain === "0x4"}
  <div class="warning">
    This application is connected to the Rinkeby test network.
  </div>
  <!-- to be updated after deployed -->
{:else if chain != "0x4"}
  <div class="error">
    This application requires you to be on the Rinkeby network. Use Metamask to
    switch networks.
  </div>
  <!-- to be updated after deployed -->
{/if}

<main>
  {#if ethereum}
    {#if account}
      <h1>Welcome to the Poo app</h1>
      <h2>You have logged in as {account.slice(0, 4) + ".." + account.slice(-4, account.length)}</h2>
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
          max="9999"
          placeholder="Basic element id to mint"
          bind:value={bElementId}
        />

        {#if currentMinted >= maxMints}
          <button disabled type="submit">Sold out</button>
        {:else}
          <button type="submit">Mint</button>
        {/if}
      </form>
      <!-- need redo for new contract. Need to limit max per id, not limiting total -->

      <section>
        <span>{currentMinted} / {maxMints} minted</span>
      </section>

      <h2>Your Tokens:</h2>
      {#if ownedTokens}
        <section>
          {#if numberOfSelected == 1}
            <button disabled on:click={merge}>Merge: Select More</button>
            {#if Array.from(childNFTarray)[0] > 10000}
              <button on:click={split}>Split</button>
            {:else}
              <button disabled on:click={split}>Split: Merged item only</button>
            {/if}
          {:else if numberOfSelected == 0}
            <button disabled on:click={merge}>Merge: Not Selected</button>
            <button disabled on:click={split}>Split: Not Selected</button>
          {:else}
            {#if containMerged == true}
              <button disabled on:click={merge}
                >Merge: Remove merged items</button
              >
            {:else if childNFTarray.size > 10}
              <button disabled on:click={merge}>Merge: Select 10 or less</button
              >
            {:else}
              <button on:click={merge}>Merge</button>
            {/if}
            <button disabled on:click={split}>Split: One at a time</button>
          {/if}
          <ul class="grid">
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
          </ul>
        </section>
      {:else}
        <section>
          You don't have any tokens. Mint one with the button above to add it to
          your collection.
        </section>
      {/if}
    {:else}
      <h1>Welcome to the Poo app</h1>
      <h2>Login with Metamask to mint, merge or split your NFT</h2>
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
                  <!-- to be updated after deployed -->
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
      Install Metamask
      <a href="https://metamask.io/">here</a>.
    </p>
  {/if}
</main>

<footer>      
  <a href="https://testnets.opensea.io/collection/cfnft">View on OpenSea</a>
  <!-- to be updated after deployed -->
  <!-- Built with <a href="https://pages.dev">Pages</a>
  and <a href="https://workers.dev">Workers</a>, and open-source
  <a href="https://github.com/cloudflare/cfweb3">on GitHub</a>.
  <a href="https://blog.cloudflare.com/get-started-web3"
    >Read the announcement blog post</a
  >. -->
</footer>
