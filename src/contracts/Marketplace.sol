pragma solidity ^0.5.0;

contract Marketplace {

	bytes32 public name;
	uint64 public productCount;
	uint8 public maxProductsPerBuyerPerIssuer = 2; 
	uint8 public percentFee = 3; // MUST NEVER BE ZERO!!!

	address payable owner; 

	mapping(uint64 => Product) public products;
	mapping(address => mapping(address => uint32)) public productsPerBuyerPerIssuer; 

	// Note on uint: uint256 by default, aiiowing 2**256-1 ~ 1.16e77 unique tickets
	struct Product {
		address payable issuer; // Issuer of ticket (e.g., event host, trusted third party)
		address payable holder; // Holder of ticket
		bytes32 name; // Location of ticket in venue
		uint64 id; // Unique ticket ID
		uint128 price; // Price in Wei
		uint8 percentRefund; // Non-refundable products (percentRefund == 0) can be purchased but not returned
		bool purchased; // Purchased products cannot be bought again
		bool returnRequested; // Buyer can request refunds, but seller must unilaterally approve requests
		bool withdrawn; // Withdrawn products can be returned but not purchased
	}

	event ProductCreated(
		address payable issuer,
		address payable holder,
		bytes32 name,
		uint64 id,
		uint128 price,
		uint8 percentRefund, 
		bool purchased, 
		bool returnRequested, 
		bool withdrawn
	);

	event ProductWithdrawn(uint64 id);

	event ReturnRequested(uint64 id);

	event ProductPurchased(uint64 id);

	event ProductReturned(uint64 id);

	constructor() public {
		name = "Ticketly";
		owner = msg.sender; 
	}

	modifier onlyOwner {
		// Require that issuer is valid
		require(owner == msg.sender, "Only the contract owner can call this function.");
		_; 
	}

	modifier validProductID(uint64 _id) {
		// Check if product has valid ID
		require(_id > 0 && _id <= productCount, "Invalid product ID passed to this function.");
		_; 
	}

	// Fallback function: only for paying Ethereum to contract
	function () external payable {
		require(msg.data.length == 0); 
	}

	// msg.sender is the issuer
	// Transaction fee for owner: 0 Wei
	function createProduct(string calldata _name, uint64 _price, uint8 _percentRefund) external {
		uint len = bytes(_name).length; 
		// Require a valid name
		require(len > 0, "Invalid name passed to product creation function."); 
		// Require a short name
		require(len <= 32, "Name passed to product creation function is too long."); 
		// Require a valid price (so that 1% of the minimum price = 1 wei)
		require(_price >= 100, "Insufficiently low price passed to product creation function."); 
		// Require a valid percent
		require(_percentRefund >= 0 && _percentRefund <= 100); 
		// Increment product count
		productCount++;
		// Create product
		bytes32 _name32 = stringToBytes32(_name);
		// products[productCount] = Product(msg.sender, msg.sender, _name32, productCount, _price, _percentRefund, false, false, false);
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

	// Convert string to bytes32
	// Source: https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
	function stringToBytes32(string memory source) private pure returns (bytes32 result) {
	    bytes memory tempEmptyStringTest = bytes(source);
	    if (tempEmptyStringTest.length == 0) {
	        return 0x0;
	    }
	    assembly {
	        result := mload(add(source, 32))
	    }
	}

	// msg.sender is the issuer
	// Irreversibly withdraws products[_id] from the market
	function withdrawProduct(uint64 _id) validProductID(_id) external {
		// Fetch the product
		Product memory _product = products[_id];
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the product issuer can withdraw a product."); 
		// Make withdrawn
		_product.withdrawn = true; 
		// Update the product
		products[_id] = _product; 
		// Trigger an event
		emit ProductWithdrawn(_product.id);
	}

	// msg.sender is the buyer
	// Requests for issuer to refund item
	function requestReturn(uint64 _id) validProductID(_id) external {
		// Fetch the product
		Product memory _product = products[_id];
		// Require that product is refundable
		require(_product.percentRefund > 0, "Product is non-refundable."); 
		// Require that product has been purchased
		require(_product.purchased); 
		// Require that buyer is valid
		require(_product.holder == msg.sender, "Only the product holder can request a return."); 
		// Request return
		_product.returnRequested = true; 
		// Update the product
		products[_id] = _product; 
		// Trigger an event
		emit ReturnRequested(_product.id);
	}

	// msg.sender is the buyer
	// Transaction fee for owner: percentFee pct of ticket price
	function purchaseProduct(uint64 _id) validProductID(_id) external payable {
		// Fetch the product
		Product memory _product = products[_id];
		// Fetch the issuer
		address payable _issuer = _product.issuer;
		// Check if buyer has bought too many tickets
		require(productsPerBuyerPerIssuer[msg.sender][_issuer] < maxProductsPerBuyerPerIssuer, "Buyer has attempted to buy too many products from issuer."); 
		// Check if value has enough ether attached
		require(msg.value >= _product.price, "Insufficient ether attached to product purchase attempt.");
		// Require that product has not been purchased
		require(!_product.purchased, "Product has already been purchased.");
		// Require that buyer is not issuer
		require(_issuer != msg.sender, "Issuer cannot buy product from themselves."); 
		// Require that the product is not withdrawn
		require(!_product.withdrawn, "Product has been withdrawn."); 
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

	// msg.sender is the issuer
	// Transaction fee for owner: percentFee pct of ticket price
	function returnProduct(uint64 _id) validProductID(_id) external payable {
		// Fetch the product
		Product memory _product = products[_id];
		// Fetch the holder
		address payable _buyer = _product.holder;
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the ticket issuer can call this function."); 
		// Check if buyer currently holds ticket
		require(productsPerBuyerPerIssuer[_buyer][msg.sender] > 0, "Buyer has no tickets to return to this issuer."); 
		// Check if value has enough ether attached
		require(msg.value >= _product.price * _product.percentRefund / 100, "Insufficient ether attached to product return attempt.");
		// Require that product has been purchased
		require(_product.purchased, "Unpurchased products cannot be returned.");
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the product issuer can initiate a return."); 
		// Require that buyer is not issuer
		require(_buyer != msg.sender, "Issuer cannot return product to themselves."); 
		// Require that product is refundable
		require(_product.percentRefund > 0, "Product is non-refundable."); 
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
