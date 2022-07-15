<script>
  import { ethers } from "ethers";
  import { onMount } from "svelte";
  import Contract from "./PL1155.json";
  import { getOwned } from "./getOwned";
  import { signedInfo } from "./signatures.js";

  // const CONTRACT_ID = "0x8Ef0879e5bBcf5edf18B0C03D4DF858Ac07D3408"; //to be changed after contract deployed
  const CONTRACT_ID = "0x3506BA155414aC1404369d4357bf32A74C74cdC4"; //to be changed after contract deployed
  
  const ethereum = window.ethereum;

  let chain, provider, signer, contract, contractWithSigner;

  let maxMints = -1;
  let currentMinted = -1;
  let account = null;
  let minted = false;
  let loading = false;
  let errorCaught = false;
  let bElementId = 1;
  let ownedTokens = [];
  let recentlyMintedTokens = [];
  let openseaContractLink =
    "https://testnets.opensea.io/assets/" + CONTRACT_ID +"\/"; //to be changed after contract deployed
  let tokenSymbol = "PL";
  let childNFTs = {};
  let childNFTarray = new Set();
  let numberOfSelected;
  let containMerged = false;
  let loadedNFT = {
    loadedNFT: 0,
    total: -1,
  };
  let wl = false;
  let wlminted = -1;
  // let loadedNFTtotal = -1;

  function toggle(event) {
    childNFTs[event.currentTarget.id] = !childNFTs[event.currentTarget.id];
    if (childNFTs[event.currentTarget.id]) {
      childNFTarray.add(event.currentTarget.id);
    } else if (!childNFTs[event.currentTarget.id]) {
      childNFTarray.delete(event.currentTarget.id);
    }
    numberOfSelected = childNFTarray.size;
    containMerged = false;
    for (let i = 0; i < childNFTarray.size; i++) {
      if (Array.from(childNFTarray)[i] > 10000) {
        containMerged = true;
      }
    }
  }

  onMount(() => {
    chain = ethereum.chainId;
    account = ethereum.selectedAddress; //
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
      checkWhiteListed();
      childNFTs = {}; //Clear selection
      ownedTokens = [];
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

    await fetch("https://rannumber.herokuapp.com/api/ran/" + account)
      .then((response) => {
        return response.json();
      })
      .then((ran) => {
        // console.log("ran is ", ran);
        
        const options = {value: ethers.utils.parseEther("0.15")}
        contractWithSigner.mint(ran.id, ran.number, ran.signature, options).then(
          (result) => {},
          (error) => {
            alert(error.error.message);
            errorCaught = true;
          }
        );
      });

    if (errorCaught) {
      loading = false;
    } else {
      loading = true;
    }
    errorCaught = false;
    numberOfSelected = 0;
    
    contractWithSigner.on("Minted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      alert("Minted tokenId is " + tokenId); //amount? need to change
      childNFTs = {}; //Clear selection
      ownedTokens = [];
      findCurrentOwned();
      findWLminted();
      findCurrentMinted();
    });
  }


  async function wlMint() {
    minted = false;

    await fetch("https://rannumber.herokuapp.com/api/ran/" + account)
      .then((response) => {
        return response.json();
      })
      .then((ran) => {
        // console.log("ran is ", ran);
        const options = {value: ethers.utils.parseEther("0.05")}

        contractWithSigner.wlMint(wl.id, wl.number, wl.signature, ran.id, ran.number, ran.signature, options).then(
          (result) => {},
          (error) => {
            alert(error.error.message);
            errorCaught = true;
          }
        );
      });

    if (errorCaught) {
      loading = false;
    } else {
      loading = true;
    }
    errorCaught = false;
    numberOfSelected = 0;
    
    contractWithSigner.on("wlMinted", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      alert("WL Minted tokenId is " + tokenId); //amount? need to change
      childNFTs = {}; //Clear selection
      ownedTokens = [];
      findCurrentOwned();
      findWLminted();
      findCurrentMinted();
    });
  }

  async function merge() {
    minted = false;

    await contractWithSigner
      .merge(Array.from(childNFTarray), "0x00")
      .then(
        (result) => {},
        (error) => {
          alert(error.error.message);
          errorCaught = true;
        }
      );

    if (errorCaught) {
      loading = false;
    } else {
      loading = true;
    }
    errorCaught = false;
    numberOfSelected = 0;
    contractWithSigner.on("Merged", (to, tokenId, amount, event) => {
      minted = true;
      loading = false;
      alert("Merged tokenId is " + tokenId); //amount? need to change
      childNFTs = {}; //Clear selection
      ownedTokens = [];
      findCurrentOwned();
      findCurrentMinted();
    });
  }

  async function split() {
    minted = false;

    await contractWithSigner
      .split(Array.from(childNFTarray)[0], "0x00")
      .then(
        (result) => {},
        (error) => {
          alert(error.error.message);
          errorCaught = true;
        }
      );

    if (errorCaught) {
      loading = false;
    } else {
      loading = true;
    }
    errorCaught = false;
    numberOfSelected = 0;
    contractWithSigner.on("Split", (to, id, event) => {
      minted = true;
      loading = false;
      alert("Selected merged item id " + id + " is now split.");
      childNFTs = {}; //Clear selection
      ownedTokens = [];
      findCurrentOwned();
      findCurrentMinted();
    });
  }

  async function findWLminted() {
    
    const wlmintedPromise = await contract.wlConsumed(wl.id);

    wlminted = Number(wlmintedPromise);
  }

  async function findCurrentOwned() {
    numberOfSelected = 0;

    loadedNFT.total = -1;
    childNFTarray.clear();
    let ownedToken = await getOwned(contract, account);
    // loadedNFT.total = ownedToken.length;
    let intOwnedTokens = [];

    for (let i = 0; i < ownedToken.length; i++) {
      loadedNFT.loadedNFT = i + 1;
      loadedNFT.total = ownedToken.length;
      const URI = await contract.uri(ownedToken[i].id);
      // console.log("URI ", URI);
      const mergedURI = URI.slice(0, -4) + ownedToken[i].id; //rewrite
      let response;
      let fetchURI;
      try {
        // if (ownedToken[i].id < 10000) {
          fetchURI =
            mergedURI;
        // } else {
        //   fetchURI =
        //     "http://metapython.herokuapp.com/api/merged/" + ownedToken[i].id;
        // }
        response = await fetch(fetchURI);
      } catch (error) {
        console.log(error); //alert or console
      }

      const result = await response.json();
      result.id = ownedToken[i].id;

      if (ownedToken[i].quantity > 0) {
        intOwnedTokens.push(result);
      }
    }
    loadedNFT.loadedNFT = 0;
    ownedTokens = intOwnedTokens;

    if (ownedToken.length == 0) {
      loadedNFT.total = -2;
    } else {
      loadedNFT.total = -1;
    }
    // loadedNFTtotal = -1;
  }

  async function findCurrentMinted() {
    const total = await contract.getMaxMints();
    const supply = await contract.getTokensetMinted();

    maxMints = Number(total);
    console.log('maxmints is ', maxMints);
    currentMinted = Number(supply);
    console.log('currentMinted is ', currentMinted);
  } //rewrite or delete

  async function checkWhiteListed() {

    await fetch("https://rannumber.herokuapp.com/api/wl/" + account)
      // await fetch("http://localhost:3000/api/wl/" + account)
      .then((response) => {
        let resText = response.json();
        return resText;
      })
      .then((whitelist) => {
        wl = whitelist;
      });
    // wl = signedInfo.find(
    //   (item) => item.address.toLowerCase() === account.toLowerCase()
    // );
        
    findWLminted();
  } //rewrite or delete

  async function fetchRecentlyMinted() {
    let recentMintEvents = await contract.queryFilter({
      topics: [
        "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62",
      ],
    });

    // console.log("looking for selectedAddress 1 ", ethereum.selectedAddress); //
    if (ethereum.selectedAddress) {
      window.location.reload();
    } //if

    recentMintEvents = recentMintEvents.slice(-3);

    await recentMintEvents.map(async (MintEvent) => {
      const token = MintEvent.args.id;
      // console.log("token id is ", token); //

      const URI = await contract.uri(token);

      const mergedURI = URI.slice(0, -4) + token.toNumber();
      // console.log("URI is ", mergedURI); //

      let response;
      try {
        response = await fetch(
          mergedURI
        );
        // response = await fetch(URI);
      } catch (error) {
        console.log(error); //console or delete
      }

      const result = await response.json();
      result.id = token;

      recentlyMintedTokens.push(result);
      recentlyMintedTokens = recentlyMintedTokens;
    });

    chain = ethereum.chainId;
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
      <h2>
        You have logged in as {account.slice(0, 4) +
          ".." +
          account.slice(-4, account.length)}
      </h2>
      {#if wl && wl.number > 0}
        <p>
          Congrats! Your account is whitelisted. {wlminted} / {wl.number} minted
        </p>
      {:else}
        <p>Your account is not whitelisted.</p>
      {/if}
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

      <form on:submit|preventDefault={wlMint}>
        <!-- <input
          type="number"
          min="0"
          max="10000"
          placeholder="Basic element id to mint"
          bind:value={bElementId}
        /> -->
        {#if wl && wl.number > 0}
          <button type="submit">Whitelist Mint</button>
        {:else}
          <button disabled type="submit">Whitelist Mint</button>
        {/if}
      </form>

      <form on:submit|preventDefault={mint}>
        <!-- <input
          type="number"
          min="0"
          max="10000"
          placeholder="Basic element id to mint"
          bind:value={bElementId}
        /> -->

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
      {#if loadedNFT.total > 0}
        <!-- {#if loadedNFTtotal > 0} -->
        You own {loadedNFT.total} different token ids, loading {loadedNFT.loadedNFT}...
      {/if}
      {#if ownedTokens.length > 0}
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
        <!-- {:else if loadedNFT.total = 0} -->
      {:else if ownedTokens.length == 0 && loadedNFT.total == -2}
        <section>
          You don't have any tokens. Mint one with the button above to add it to
          your collection.
        </section>
        <!-- {:else if loadedNFT.total = -1} -->
      {:else if loadedNFT.total == -1}
        <section>Checking how many token you own...</section>
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
