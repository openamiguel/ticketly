## Brief description
An event ticketing app with low-ish transaction fees and blockchain-driven anti-scalping protections

## Slightly longer description
Ticketly is a Solidity-based decentralized app ("dapp") for event ticketing. Tickets have various properties, including name, unique ID, price, percent refundable, time of creation (Unix), and duration to expiry. 

Any address ("ticket issuer") can issue tickets, and any address ("ticket holder") can purchase tickets. Ticket issuers can withdraw their tickets from the marketplace and approve ticket returns. Ticket holders can request to return their tickets. By design of the underlying smart contract, tickets cannot be resold to another ticket holder; they can _only_ be purchased from the issuer or returned to the issuer\*. 

The only transaction fees are gas costs for running any of the aforementioned functions; the platform itself collects no transaction fees. I applied a reasonable number of gas optimizations, e.g., variable packing in `struct` declarations, variable initialization, minimized on-chain data, and the use of static-length types (like `bytes15`) instead of dynamic-length types (like `string`). 

I integrated various dapp/Solidity security best practices [from a credible source](https://consensys.github.io/smart-contract-best-practices/). One notable addition is the use of a mapping to maintain issuer/holder balances. No actual ether is transferred upon ticket purchase and returns; the values in the mapping change. Issuers/holders can deposit/withdraw ether to/from the smart contract, which updates the values in the mapping accordingly. 

As of the last update, this dapp has only been deployed to a testnet on Ganache. This is because gas costs for deployment to the blockchain are ~0.074 eth (according to the Ganache testnet), which is rather expensive in USD. 

\*In theory, one can still scalp tickets by purchasing an issued ticket with address _X_ and selling the address private key on a different platform. But this requires one different wallet for each scalped ticket. Hopefully, this is less scalable than current scalping practices. 

## Dependencies
- Ganache `2.5.4`
- Truffle `5.1.60` with Solidity `0.8.0` (the pragma is locked in my code), Node `v14.15.4`, and Web3.js `v1.2.9`
- `npm 6.14.10` with `web3@1.0.0-beta.55`
- Metamask `9.0.3` (Google Chrome browser extension) connected to my Ganache testnet

## How to run the dapp (test.js file)
1. Open the Ganache app (dock)

	a. Open the hard-to-find-sponge workspace
	
2. Open the Metamask browser extension (Google Chrome)

	a. Log in if needed
	
	b. Switch to the Ganache TEST network
	
3. In Terminal, `cd` into the project directory
4. In Terminal, run `truffle compile`
5. In Terminal, run `truffle migrate --reset` (pushes new code to the blockchain!)
6. In Terminal, run `truffle console` (optional)

	a. If so desired, run the following test commands: 
	
		`marketplace = await Marketplace.deployed()`
		
		`marketplace.address`
		
		`name = await marketplace.name()`
		
		`name`
		
		`sup = await marketplace.supervisor()`
		
		`sup`
		
7. In Terminal, run `truffle test`

## How to run the dapp (Remix IDE)
1. Open [remix.ethereum.org](remix.ethereum.org)
2. Upload any relevant `.sol` files to the File Explorer
3. In the `Solidity Compiler` tab, do the following:

	a. Choose the correct compiler given the `.sol` files
	
	b. Compile the selected code
	
4. In the `Deploy and Run Transactions` tab, do the following: 

	a. In the `Environment` dropdown menu, choose the JavaScript VM
	
	b. In the `Account` dropdown menu, choose the first address to deploy the contract
	
	c. Press the `Deploy` button
	
	d. Click on the dropdown menu that says `Marketplace at (some address)`
	
	e. Test the various functions, e.g., `createProduct`, `purchaseProduct`, and others
	
		i. Recommendation: use the second address as ticket issuer, and use the third address as ticket holder
		
5. If errors arise in the console, press the `Debug` button to view line-by-line code execution

## How to run the dapp (npm frontend)
1. Open the Ganache app (dock)

	a. Open the hard-to-find-sponge workspace

2. Open the Metamask browser extension (Google Chrome)

	a. Log in if needed
	
	b. Switch to the Ganache TEST network

3. In Terminal, `cd` into the project directory
4. In Terminal, run `npm run start`

## Acknowledgements
Credits to Dapp University for the starter code for this app: [Github repo](https://github.com/dappuniversity/marketplace)
- See the [website tutorial](https://www.dappuniversity.com/articles/how-to-build-a-blockchain-app#dependencies) for more details on dependencies, Metamask/Ganache setup, etc. 
