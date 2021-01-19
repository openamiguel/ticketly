pragma solidity ^0.5.0;

contract Marketplace {

	// Slot 1
	address payable immutable owner; 
	// Slot 2
	bytes16 public immutable name;
	uint64 public immutable productCount;
	uint8 public constant maxProductsPerBuyerPerIssuer = 2; 
	uint8 public constant percentFee = 3; // MUST NEVER BE ZERO!!!

	mapping(uint32 => Product) public products;
	mapping(address => mapping(address => uint24)) public productsPerBuyerPerIssuer; 

	// Note on uint: uint256 by default, aiiowing 2**256-1 ~ 1.16e77 unique tickets
	struct Product {
		// Slot 1
		address payable issuer; // Issuer of ticket (e.g., event host, trusted third party)
		// Slot 2
		address payable holder; // Holder of ticket
		// Slot 3
		bytes15 name; // Location of ticket in venue (max: 15 characters)
		uint32 id; // Unique ticket ID (max: 4.3 billion tickets)
		uint72 price; // Price in Wei (max: 4722.4 Eth)
		uint8 percentRefund; // Non-refundable products (percentRefund == 0) can be purchased but not returned
		bool purchased; // Purchased products cannot be bought again
		bool returnRequested; // Buyer can request refunds, but seller must unilaterally approve requests
		bool withdrawn; // Withdrawn products can be returned but not purchased
	}

	event ProductCreated(
		address payable issuer,
		address payable holder,
		bytes15 name,
		uint32 id,
		uint72 price,
		uint8 percentRefund, 
		bool purchased, 
		bool returnRequested, 
		bool withdrawn
	);

	event ProductWithdrawn(uint32 id);

	event ReturnRequested(uint32 id);

	event ProductPurchased(uint32 id);

	event ProductReturned(uint32 id);

	constructor() public {
		name = "Ticketly";
		owner = msg.sender; 
	}

	// Fallback function: only for paying Ethereum to contract
	function () external payable {
		require(msg.data.length == 0); 
	}

	// msg.sender is the issuer
	// Transaction fee for owner: 0 Wei
	function createProduct(string memory _name, uint72 _price, uint8 _percentRefund) public {
		uint len = bytes(_name).length; 
		// Require a valid name
		require(len > 0, "Invalid name passed to create"); 
		// Require a short name
		require(len <= 32, "Very long name passed to create"); 
		// Require a valid price (so that 1% of the minimum price = 1 wei)
		require(_price >= 100, "Very low price passed to create"); 
		// Require a valid percent
		require(_percentRefund >= 0 && _percentRefund <= 100); 
		// Increment product count
		productCount++;
		// Convert string name to bytes32
		// Source: https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
		bytes32 _name32;
		assembly {
	        _name32 := mload(add(_name, 32))
	    }
	    // Create product
		Product memory _product;
		_product.issuer = msg.sender;
		_product.holder = msg.sender;
		_product.name = _name32;
		_product.id = productCount; 
		_product.price = _price; 
		_product.percentRefund = _percentRefund;
		_product.purchased = false;
		_product.returnRequested = false;
		_product.withdrawn = false;
		products[productCount] = _product;
		// Trigger an event
		emit ProductCreated(msg.sender, msg.sender, _name32, productCount, _price, _percentRefund, false, false, false);
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
			// Request return
			_product.returnRequested = true; 
			// Update the product
			products[_id] = _product; 
			// Trigger an event
			emit ReturnRequested(_product.id);
		}

		// Transaction fee for owner: percentFee pct of ticket price
		else if (_code == 3) {
			// Fetch the issuer
			address payable _issuer = _product.issuer;
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
			// Transfer holder status to buyer
			_product.holder = msg.sender; 
			// Mark as purchased
			_product.purchased = true;
			// Update the product
			products[_id] = _product; 
			// Pay the issuer with Ether
			address(_issuer).transfer(msg.value);
			// Pay the owner with Ether
			// address(owner).transfer(percentFee * msg.value / 100); 
			// Update mapping
			productsPerBuyerPerIssuer[msg.sender][_issuer]++; 
			// Trigger event
			emit ProductPurchased(_product.id);
		}

		// Transaction fee for owner: percentFee pct of ticket price
		else if (_code == 4) {
			// Fetch the holder
			address payable _buyer = _product.holder;
			// Require that issuer is valid
			require(_product.issuer == msg.sender, "Unauthorized return attempt"); 
			// Check if buyer currently holds ticket
			require(productsPerBuyerPerIssuer[_buyer][msg.sender] > 0, "No tickets to return"); 
			// Check if value has enough ether attached
			require(msg.value >= _product.price * _product.percentRefund / 100, "Insutticient funds for return");
			// Require that product has been purchased
			require(_product.purchased, "Product not yet purchased");
			// Require that buyer is not issuer
			require(_buyer != msg.sender, "Circular return attempt"); 
			// Require that product is refundable
			require(_product.percentRefund > 0, "Product is non-refundable"); 
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
			uint refund = msg.value * _product.percentRefund / 100; 
			address(_buyer).transfer(refund);
			// Pay the owner with Ether
			// address(owner).transfer(msg.value * percentFee / 100); 
			// Update mapping
			productsPerBuyerPerIssuer[_buyer][msg.sender]--; 
			// Trigger event
			emit ProductReturned(_product.id);
		}
	}
}