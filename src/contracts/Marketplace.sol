pragma solidity ^0.5.0;

contract Marketplace {

	string public name;
	uint public productCount = 0;
	uint public maxProductsPerBuyerPerIssuer = 2; 
	uint public percentFee = 3; // MUST NEVER BE ZERO!!!

	address payable owner; 

	mapping(uint => Product) public products;
	mapping(address => mapping(address => uint)) public productsPerBuyerPerIssuer; 

	struct Product {
		uint id; // Unique ticket ID
		string name; // Location of ticket in venue
		uint price; // Price in Ether? Wei?
		address payable issuer; // Issuer of ticket (e.g., event host, trusted third party)
		address payable holder; // Holder of ticket
		bool purchased;
		bool refundable; // Non-refundable products can be purchased but not returned
		bool withdrawn; // withdrawn products can be returned but not purchased
	}

	event ProductCreated(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool withdrawn
	);

	event ProductWithdrawn(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool withdrawn
	);

	event ProductPurchased(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool withdrawn
	);

	event ProductReturned(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool withdrawn
	);

	constructor() public {
		name = "Ticketly";
		owner = msg.sender; 
	}

	modifier onlyOwner {
		// Require that issuer is valid
		require(owner == msg.sender, "Only the contract owner can call this function.");
		_; 
	}

	modifier validProductID(uint _id) {
		// Check if product has valid ID
		require(_product.id > 0 && _product.id <= productCount, "Invalid product ID passed to this function.");
		_; 
	}

	// msg.sender is the issuer
	// Transaction fee for owner: 0 Wei
	function createProduct(string calldata _name, uint _price, bool refundable) external {
		// Require a valid name
		require(bytes(_name).length > 0, "Invalid name passed to product creation function."); 
		// Require a valid price
		require(_price >= 1 * 100 / percentFee, "Insufficiently low price passed to product creation function."); 
		// Increment product count
		productCount++;
		// Create product
		products[productCount] = Product(productCount, _name, _price, msg.sender, msg.sender, false, refundable, false);
		// Trigger an event
		emit ProductCreated(productCount, _name, _price, msg.sender, msg.sender, false, refundable, false);
	}

	// msg.sender is the issuer
	// Irreversibly toggles products[_id] to be withdrawn
	function withdrawProduct(uint _id) validProductID(_id) external {
		// Fetch the product
		Product memory _product = products[_id];
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the product issuer can withdraw a product."); 
		// Make withdrawn
		_product.withdrawn = true; 
		// Update the product
		products[_id] = _product; 
		// Trigger an event
		emit ProductWithdrawn(_product.id, _product.name, _product.price, msg.sender, _product.holder, _product.purchased, _product.refundable, true);
	}

	// msg.sender is the buyer
	// Transaction fee for owner: percentFee pct of ticket price
	function purchaseProduct(uint _id) validProductID(_id) external payable {
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
		emit ProductPurchased(_product.id, _product.name, _product.price, _product.issuer, msg.sender, true, _product.refundable, false);
	}

	// msg.sender is the issuer
	// Problem: avoid the case where issuer unilaterally pulls tickets? (unless we WANT that to be allowed)
	// Problem: avoid the case where issuer refuses to refund, despite previously attested-to terms
	// Transaction fee for owner: percentFee pct of ticket price
	function returnProduct(uint _id) validProductID(_id) external payable {
		// Fetch the product
		Product memory _product = products[_id];
		// Fetch the holder
		address payable _buyer = _product.holder;
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the ticket issuer can call this function."); 
		// Check if buyer currently holds ticket
		require(productsPerBuyerPerIssuer[_buyer][msg.sender] > 0, "Buyer has no tickets to return to this issuer."); 
		// Check if value has enough ether attached
		require(msg.value >= _product.price, "Insufficient ether attached to product return attempt.");
		// Require that product has been purchased
		require(_product.purchased, "Unpurchased products cannot be returned.");
		// Require that issuer is valid
		require(_product.issuer == msg.sender, "Only the product issuer can initiate a return."); 
		// Require that buyer is not issuer
		require(_buyer != msg.sender, "Issuer cannot return product to themselves."); 
		// Require that product is refundable
		require(_product.refundable, "Product is non-refundable."); 
		// Transfer holdership back to issuer
		_product.holder = msg.sender; 
		// Revert purchased status
		_product.purchased = false;
		// Update the product
		products[_id] = _product; 
		// Pay the buyer with Ether
		address(_buyer).transfer(msg.value);
		// Pay the owner with Ether
		// address(owner).transfer(msg.value * percentFee / 100); 
		// Update mapping
		productsPerBuyerPerIssuer[_buyer][msg.sender]--; 
		// Trigger event
		emit ProductReturned(_product.id, _product.name, _product.price, msg.sender, _product.holder, false, true, _product.withdrawn);
	}

}
