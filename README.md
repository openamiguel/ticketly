## Brief description
An event ticketing app with low transaction fees and blockchain-driven anti-scalping protections

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
1. Open remix.ethereum.org
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

## Untested functionalities
Should I be using modifiers to collapse duplicate code as much as possible? Or will I cause high gas/security problems?

## Acknowledgements
Credits to Dapp University for the starter code for this app: 
https://github.com/dappuniversity/marketplace
https://www.dappuniversity.com/articles/how-to-build-a-blockchain-app#dependencies

Good source on using Remix for debugging: https://medium.com/linum-labs/error-vm-exception-while-processing-transaction-revert-8cd856633793
