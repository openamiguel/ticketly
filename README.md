Source for this starter dapp: https://www.dappuniversity.com/articles/how-to-build-a-blockchain-app#dependencies

How to run the dapp
1. Open the Ganache app (dock)
	a. Open the hard-to-find-sponge workspace
2. Open the Metamask browser extension (Google Chrome)
	a. Log in if needed**
	b. Switch to the Ganache TEST network
3. In Terminal, run `cd /Users/openamiguel/Documents/marketplace`
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

** All necessary credentials are in the mask.txt file in my Dropbox

Untested functionalities
* Is productsPerBuyerPerIssuer actually tracking number of purchases?

To debug, upload `Marketplace.sol` onto remix.ethereum.org and run the contract in the JavaScript VM. Deploy the contract with the first address as supervisor, second address as ticket issuer, and third address as ticket buyer. 