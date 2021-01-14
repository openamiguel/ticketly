const Marketplace = artifacts.require('./Marketplace.sol')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Marketplace', ([deployer, seller, buyer]) => {
  let marketplace

  before(async () => {
    marketplace = await Marketplace.deployed()
  })

  describe('deployment', async () => {
    it('deploys successfully', async () => {
      const address = await marketplace.address
      assert.notEqual(address, 0x0)
      assert.notEqual(address, '')
      assert.notEqual(address, null)
      assert.notEqual(address, undefined)
    })

    it('has a name', async () => {
      const name = await marketplace.name()
      assert.equal(name, 'Ticketly')
    })

    it('has a supervisor', async () => {
      const sup = await marketplace.supervisor()
      assert.equal(sup, 0x3ceB4eEADfb650F2973c2F943E9fBdFdDA15385B)
    })

  })

  describe('tickets', async () => {
    let result, productCount

    before(async () => {
      result = await marketplace.createProduct('Ticket: General Admission', web3.utils.toWei('1', 'Ether'), true, { from: seller })
      productCount = await marketplace.productCount()
    })

    it('creates tickets', async () => {
      // SUCCESS
      assert.equal(productCount, 1)
      const event = result.logs[0].args
      assert.equal(event.id.toNumber(), productCount.toNumber(), 'id is correct')
      assert.equal(event.name, 'Ticket: General Admission', 'name is correct')
      assert.equal(event.price, '1000000000000000000', 'price is correct')
      assert.equal(event.issuer, seller, 'issuer is correct')
      assert.equal(event.holder, seller, 'holder is correct')
      assert.equal(event.purchased, false, 'purchased is correct')

      // FAILURE: Product must have a name
      await await marketplace.createProduct('', web3.utils.toWei('1', 'Ether'), true, { from: seller }).should.be.rejected;
      // FAILURE: Product must have a price
      await await marketplace.createProduct('Ticket: General Admission', 0, true, { from: seller }).should.be.rejected;
    })

    it('purchases tickets', async () => {
  	  // Track the seller balance before purchase
  	  let oldSellerBalance
  	  oldSellerBalance = await web3.eth.getBalance(seller)
  	  oldSellerBalance = new web3.utils.BN(oldSellerBalance)

      // Track the supervisor balance before purchase
      // const sup = await marketplace.supervisor()
      // let oldSupervisorBalance
      // oldSupervisorBalance = await web3.eth.getBalance(sup)
      // oldSupervisorBalance = new web3.utils.BN(oldSupervisorBalance)

  	  // SUCCESS: Buyer makes purchase
  	  result = await marketplace.purchaseProduct(productCount, { from: buyer, value: web3.utils.toWei('1', 'Ether')})

  	  // Check logs
  	  const event = result.logs[0].args
  	  assert.equal(event.id.toNumber(), productCount.toNumber(), 'id is correct')
  	  assert.equal(event.name, 'Ticket: General Admission', 'name is correct')
  	  assert.equal(event.price, '1000000000000000000', 'price is correct')
  	  assert.equal(event.issuer, seller, 'issuer is correct')
      assert.equal(event.holder, buyer, 'holder is correct')
  	  assert.equal(event.purchased, true, 'purchased is correct')

  	  // Check that seller received funds
  	  let newSellerBalance
  	  newSellerBalance = await web3.eth.getBalance(seller)
  	  newSellerBalance = new web3.utils.BN(newSellerBalance)

  	  let price
  	  price = web3.utils.toWei('1', 'Ether')
  	  price = new web3.utils.BN(price)

  	  const expectedSellerBalance = oldSellerBalance.add(price)

  	  assert.equal(newSellerBalance.toString(), expectedSellerBalance.toString())

      // Check that supervisor received funds
      // let newSupervisorBalance
      // newSupervisorBalance = await web3.eth.getBalance(sup)
      // newSupervisorBalance = new web3.utils.BN(newSupervisorBalance)

      // const percentFee = await marketplace.percentFee()

      // const expectedSupervisorBalance = oldSupervisorBalance.add(price.mul(percentFee).div(100))

      // assert.equal(newSupervisorBalance.toString(), expectedSupervisorBalance.toString())

  	  // FAILURE: Tries to buy a product that does not exist, i.e., product must have valid id
  	  await marketplace.purchaseProduct(99, { from: buyer, value: web3.utils.toWei('1', 'Ether')}).should.be.rejected;      
  	  // FAILURE: Buyer tries to buy without enough ether
  	  await marketplace.purchaseProduct(productCount, { from: buyer, value: web3.utils.toWei('0.5', 'Ether') }).should.be.rejected;
  	  // FAILURE: Deployer tries to buy the product, i.e., product can't be purchased twice
  	  await marketplace.purchaseProduct(productCount, { from: deployer, value: web3.utils.toWei('1', 'Ether') }).should.be.rejected;
  	  // FAILURE: Buyer tries to buy again, i.e., buyer can't be the seller
  	  await marketplace.purchaseProduct(productCount, { from: buyer, value: web3.utils.toWei('1', 'Ether') }).should.be.rejected;
	  })

    it('returns tickets', async () => {
      // Track the buyer balance before return
      let oldBuyerBalance
      oldBuyerBalance = await web3.eth.getBalance(buyer)
      oldBuyerBalance = new web3.utils.BN(oldBuyerBalance)

      // Track the supervisor balance before purchase
      const sup = await marketplace.supervisor()
      let oldSupervisorBalance
      oldSupervisorBalance = await web3.eth.getBalance(sup)
      oldSupervisorBalance = new web3.utils.BN(oldSupervisorBalance)

      // SUCCESS: Seller approves return
      result = await marketplace.returnProduct(productCount, { from: seller, value: web3.utils.toWei('1', 'Ether')})

      // Check logs
      const event = result.logs[0].args
      assert.equal(event.id.toNumber(), productCount.toNumber(), 'id is correct')
      assert.equal(event.name, 'Ticket: General Admission', 'name is correct')
      assert.equal(event.price, '1000000000000000000', 'price is correct')
      assert.equal(event.issuer, seller, 'issuer is correct')
      assert.equal(event.holder, seller, 'holder is correct')
      assert.equal(event.purchased, false, 'purchased is correct')

      // Check that seller received funds
      let newBuyerBalance
      newBuyerBalance = await web3.eth.getBalance(buyer)
      newBuyerBalance = new web3.utils.BN(newBuyerBalance)

      let price
      price = web3.utils.toWei('1', 'Ether')
      price = new web3.utils.BN(price)

      const expectedBuyerBalance = oldBuyerBalance.add(price)

      assert.equal(newBuyerBalance.toString(), expectedBuyerBalance.toString())

      // Check that supervisor received funds
      // let newSupervisorBalance
      // newSupervisorBalance = await web3.eth.getBalance(sup)
      // newSupervisorBalance = new web3.utils.BN(newSupervisorBalance)

      // const percentFee = await marketplace.percentFee()

      // const expectedSupervisorBalance = oldSupervisorBalance.add(price.mul(percentFee).div(100))

      // assert.equal(newSupervisorBalance.toString(), expectedSupervisorBalance.toString())

      // FAILURE: Tries to return a product that does not exist, i.e., product must have valid id
      await marketplace.returnProduct(99, { from: seller, value: web3.utils.toWei('1', 'Ether')}).should.be.rejected;      
      // FAILURE: Seller tries to return without enough ether
      await marketplace.returnProduct(productCount, { from: seller, value: web3.utils.toWei('0.5', 'Ether') }).should.be.rejected;
      // FAILURE: Deployer tries to return the product, but they cannot do that!
      await marketplace.returnProduct(productCount, { from: deployer, value: web3.utils.toWei('1', 'Ether') }).should.be.rejected;
      // FAILURE: Seller tries to return again
      await marketplace.returnProduct(productCount, { from: seller, value: web3.utils.toWei('1', 'Ether') }).should.be.rejected;
    })
  })
})
