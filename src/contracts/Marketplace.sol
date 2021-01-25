// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Marketplace {

	// Slot 1
	address private owner; 
	// Slot 2
	bytes16 public name;
	uint32 public productCount;
	uint8 public constant maxProductsPerBuyerPerIssuer = 2; 
	uint8 public constant percentFee = 3; // MUST NEVER BE ZERO!!!
	// Slot 3
	uint72 public constant maximumPrice = 500000000000000000 wei; // 0.5 eth
	uint8 public constant maxProductsPerIssuer = 5; 
	bool private stopped = false; 

	mapping(uint32 => Product) public products;
	mapping(address => mapping(address => uint24)) public productsPerBuyerPerIssuer; 
	mapping(address => uint24) public productsPerIssuer; 
	mapping(address => uint72) public balancePerIssuer; 

	// Note on uint: uint256 by default, aiiowing 2**256-1 ~ 1 possibilities
	struct Product {
		// Slot 1
		address issuer; // Issuer of ticket (e.g., event host, trusted third party)
		// Slot 2
		address holder; // Holder of ticket
		// Slot 3
		bytes15 name; // Location of ticket in venue (max: 15 characters)
		uint32 id; // Unique ticket ID (numerical max: 4.3 billion tickets)
		uint72 price; // Price in Wei (numerical max: 4722.4 Eth)
		uint8 percentRefund; // Non-refundable products (percentRefund == 0) can be purchased but not returned
		bool purchased; // Purchased products cannot be bought again
		bool returnRequested; // Buyer can request refunds, but seller must unilaterally approve requests
		bool withdrawn; // Withdrawn products can be returned but not purchased
		// Slot 4
		uint32 creationTime; // The code WILL break at 6:28:15 am UTC on February 7, 2106
		uint32 duration; // creationTime + duration is the ticket expiry time (seconds)
		uint32 refundWindow; // creationTime + duration - refundWindow is the last opportunity to return with a refund (seconds)
	}

	event ProductCreated(
		// Slot 1
		address issuer,
		// Slot 2
		address holder,
		// Slot 3
		bytes15 name,
		uint32 id,
		uint72 price,
		uint8 percentRefund, 
		bool purchased, 
		bool returnRequested, 
		bool withdrawn,
		uint32 creationTime,
		uint32 duration, 
		uint32 refundWindow
	);

	event ProductWithdrawn(uint32 id);

	event ReturnRequested(uint32 id);

	event ProductPurchased(uint32 id);

	event ProductReturned(uint32 id);

	constructor() {
		name = "Ticketly";
		owner = msg.sender; 
	}

	modifier isAdmin() {
		require(msg.sender == owner, "Owner only");
		_;
	}

	modifier stopInEmergency { if (!stopped) _; }

	// modifier onlyInEmergency { if (stopped) _; }

	// Receive function: only for paying Ethereum to contract
	receive() external payable {
		// Empty
	}

	// Fallback function: miscellaneous things
	fallback() external {
		require(msg.data.length == 0); 
	}

	function toggleContractActive() isAdmin public {
	    stopped = !stopped;
	}

	// msg.sender is the issuer
	// Transaction fee for owner: 0 Wei
	function createProduct(string memory _name, uint72 _price, uint8 _percentRefund, uint32 _duration, uint32 _refundWindow) stopInEmergency public {
		uint len = bytes(_name).length; 
		// Require a valid name
		require(len > 0, "Invalid name passed to create"); 
		// Require a short name
		require(len <= 15, "Very long name passed to create"); 
		// Require a valid price (so that 1% of the minimum price = 1 wei)
		require(_price >= 100, "Very low price passed to create"); 
		// Require a price less than maximumPrice
		require(_price <= maximumPrice, "High price passed to create"); 
		// Require cap on tickets issued
		require(productsPerIssuer[msg.sender] < maxProductsPerIssuer, "Maximum products reached");
		// Require a valid percent
		require(_percentRefund >= 0 && _percentRefund <= 100, "Invalid percentage passed to create"); 
		// Require valid duration
		require(_duration > _refundWindow, "Invalid duration passed to create"); 
		// Increment product count
		productCount++;
		// Convert string name to bytes15
		// Source: https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
		bytes15 _name15;
		assembly {
	        _name15 := mload(add(_name, 15))
	    }
	    // Create product
		Product memory _product;
		_product.issuer = msg.sender;
		_product.holder = msg.sender;
		_product.name = _name15;
		_product.id = productCount; 
		_product.price = _price; 
		_product.percentRefund = _percentRefund;
		_product.purchased = false;
		_product.returnRequested = false;
		_product.withdrawn = false;
		_product.creationTime = uint32(block.timestamp);
		_product.duration = _duration; 
		_product.refundWindow = _refundWindow; 
		products[productCount] = _product;
		// Add product to productsPerIssuer mapping
		productsPerIssuer[msg.sender]++; 
		// Trigger an event
		emit ProductCreated(msg.sender, msg.sender, _name15, productCount, _price, _percentRefund, false, false, false, _product.creationTime, _duration, _refundWindow);
	}

	// _code = 1: withdrawProduct
	// _code = 2: requestReturn
	// _code = 3: purchaseProduct
	// _code = 4: returnProduct
	function morphProduct(uint32 _id, uint8 _code) external payable {

		// Check if code is valid
		require(_code > 0 && _code < 5, "Invalid code passed to morph");
		// Check if product has valid ID
		require(_id > 0 && _id <= productCount, "Invalid ID passed to morph"); 

		// Fetch the product
		Product memory _product = products[_id];

		// Irreversibly withdraws products[_id] from the market
		if (_code == 1) {
			// Require that issuer is valid
			require(_product.issuer == msg.sender, "Unauthorized withdrawal attempt"); 
			// Require that the product is not expired
			require(block.timestamp < _product.creationTime + _product.duration, "Product expired"); 
			// Make withdrawn
			_product.withdrawn = true; 
			// Update the product
			products[_id] = _product; 
			// Trigger an event
			emit ProductWithdrawn(_product.id);
		}

		// Requests for issuer to refund item
		else if (_code == 2) {
			// Require that product is refundable
			require(_product.percentRefund > 0, "Product is non-refundable"); 
			// Require that product has been purchased
			require(_product.purchased); 
			// Require that buyer is valid
			require(_product.holder == msg.sender, "Unauthorized request attempt"); 
			// Require that the product is not expired
			require(block.timestamp < _product.creationTime + _product.duration, "Product expired"); 
			// Request return
			_product.returnRequested = true; 
			// Update the product
			products[_id] = _product; 
			// Trigger an event
			emit ReturnRequested(_product.id);
		}

		// Purchases ticket from issuer
		else if (_code == 3) {
			// Fetch the issuer
			address _issuer = _product.issuer;
			// Check if buyer has bought too many tickets
			require(productsPerBuyerPerIssuer[msg.sender][_issuer] < maxProductsPerBuyerPerIssuer, "Threshold for products reached"); 
			// Check if value has enough ether attached
			require(msg.value >= _product.price, "Insutticient funds for purchase");
			// Require that product has not been purchased
			require(!_product.purchased, "Product already purchased");
			// Require that buyer is not issuer
			require(_issuer != msg.sender, "Circular purchase attempt"); 
			// Require that the product is not withdrawn
			require(!_product.withdrawn, "Product withdrawn"); 
			// Require that the product is not expired
			require(block.timestamp < _product.creationTime + _product.duration, "Product expired"); 
			// Transfer holder status to buyer
			_product.holder = msg.sender; 
			// Mark as purchased
			_product.purchased = true;
			// Update the product
			products[_id] = _product; 
			// Pay the issuer with Ether
			(bool success, ) = payable(_issuer).call{value:msg.value}("");
        	require(success, "Transfer failed.");
			// _issuer.transfer(msg.value);
			// Pay the owner with Ether
			// address(owner).transfer(percentFee * msg.value / 100); 
			// Update mapping
			productsPerBuyerPerIssuer[msg.sender][_issuer]++; 
			// Trigger event
			emit ProductPurchased(_product.id);
		}

		// Returns ticket to issuer
		else if (_code == 4) {
			// Fetch the holder
			address _buyer = _product.holder;
			// Require that issuer is valid
			require(_product.issuer == msg.sender, "Unauthorized return attempt"); 
			// Check if buyer currently holds ticket
			require(productsPerBuyerPerIssuer[_buyer][msg.sender] > 0, "No tickets to return"); 
			// Require that product has been purchased
			require(_product.purchased, "Product not yet purchased");
			// Require that buyer is not issuer
			require(_buyer != msg.sender, "Circular return attempt"); 

			uint8 _percentRefund; 

			// If ticket expired, return without refund
			if (block.timestamp >= _product.creationTime + _product.duration) {
				_percentRefund = 0; 
			}

			// Otherwise, if product is withdrawn, give a full refund regardless of _product.percentRefund
			if (_product.withdrawn) {
				// Check if value has enough ether attached
				require(msg.value >= _product.price, "Insutticient funds for return");
				_percentRefund = 100; 
			}

			// Otherwise, trigger the vanilla logic for refunds
			else {
				// Require that product is refundable
				require(_product.percentRefund > 0, "Product is non-refundable"); 
				// Require that product has not reached non-refundable window
				require(block.timestamp < _product.creationTime + _product.duration - _product.refundWindow, "Product has passed refund window"); 
				// Check if value has enough ether attached
				require(msg.value >= _product.price * _product.percentRefund / 100, "Insutticient funds for return");
				_percentRefund = _product.percentRefund; 
			}

			// Transfer holdership back to issuer
			_product.holder = msg.sender; 
			// Revert purchased status
			_product.purchased = false;
			// Delete history of return request (if any)
			_product.returnRequested = false; 
			// Update the product
			products[_id] = _product; 
			// Pay the buyer with Ether
			// Potentially serious bug: msg.value is transferred but refund is not!!!
			// Currently, the code only works because the Javascript front end controls the amount of value to transfer!!!
			uint refund = msg.value * _percentRefund / 100; 
			(bool success, ) = payable(_buyer).call{value:refund}("");
        	require(success, "Transfer failed.");
			// _buyer.transfer(refund);
			// Pay the owner with Ether
			// address(owner).transfer(msg.value * percentFee / 100); 
			// Update mapping
			productsPerBuyerPerIssuer[_buyer][msg.sender]--; 
			// Trigger event
			emit ProductReturned(_product.id);
		}
	}
}