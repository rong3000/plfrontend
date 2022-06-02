<script>
    import { onMount } from "svelte";
    let counter = 0;
    onMount(() => {
        console.log("1 chain is ");
        console.log("the component has mounted");
        // get dom element by id
        console.log(document.getElementById("tag"));
        //intervals functions
        const interval = setInterval(() => {
            counter = counter + 1;
        }, 1000);
        //If a function is returned from onMount, it will be called when the component is unmounted.
        return () => clearInterval(interval);
    });

    console.log("2 chain is ");
    init();

    // function temp() {
    //     console.log("2 chain is ");
    //     init();
    // }

    async function init() {
        // 		counter -= 1;
        // 		console.log("counter - 1");
        console.log("3 chain is ");
        fetchRecentlyMinted();
    }

    const DEF_DELAY = 1000;

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms || DEF_DELAY));
}


    async function fetchRecentlyMinted() {

      console.log("1.1 suspected onmount point");
        await sleep(100);

      console.log("1.2 suspected onmount point");

    console.log("4 chain is ");
    }

    // await sleep(100);
</script>

<h1 id="tag">
    {counter}
</h1>
