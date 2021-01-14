pragma solidity ^0.5.0;

contract Marketplace {

	string public name;
	uint public productCount = 0;
	uint public maxProductsPerBuyerPerIssuer = 2; 
	uint public percentFee = 3; // MUST NEVER BE ZERO!!!

	address payable public supervisor = 0x3ceB4eEADfb650F2973c2F943E9fBdFdDA15385B;

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
		bool obsolete; // Obsolete products can be returned but not purchased
	}

	event ProductCreated(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool obsolete
	);

	event ProductMadeObsolete(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool obsolete
	);

	event ProductPurchased(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool obsolete
	);

	event ProductReturned(
		uint id,
		string name,
		uint price,
		address payable issuer,
		address payable holder,
		bool purchased, 
		bool refundable, 
		bool obsolete
	);

	constructor() public {
		name = "Ticketly";
	}

	// msg.sender is the issuer
	// Transaction fee for supervisor: 0 Wei
	function createProduct(string calldata _name, uint _price, bool refundable) external {
		// Require a valid name
		require(bytes(_name).length > 0); 
		// Require a valid price
		require(_price >= 1 * 100 / percentFee); 
		// Increment product count
		productCount++;
		// Create product
		products[productCount] = Product(productCount, _name, _price, msg.sender, msg.sender, false, refundable, false);
		// Trigger an event
		emit ProductCreated(productCount, _name, _price, msg.sender, msg.sender, false, refundable, false);
	}

	// msg.sender is the issuer
	// Irreversibly toggles products[_id] to be obsolete
	function makeProductObsolete(uint _id) external {
		// Fetch the product
		Product memory _product = products[_id];
		// Check if product has valid ID
		require(_product.id > 0 && _product.id <= productCount);
		// Require that issuer is valid
		require(_product.issuer == msg.sender); 
		// Make obsolete
		_product.obsolete = true; 
		// Update the product
		products[_id] = _product; 
		// Trigger an event
		emit ProductCreated(_product.id, _product.name, _product.price, msg.sender, _product.holder, _product.purchased, _product.refundable, true);
	}

	// msg.sender is the buyer
	// Transaction fee for supervisor: percentFee pct of ticket price
	function purchaseProduct(uint _id) external payable {
		// Fetch the product
		Product memory _product = products[_id];
		// Fetch the issuer
		address payable _issuer = _product.issuer;
		// Check if buyer has bought too many tickets
		require(productsPerBuyerPerIssuer[msg.sender][_issuer] < maxProductsPerBuyerPerIssuer); 
		// Check if product has valid ID
		require(_product.id > 0 && _product.id <= productCount);
		// Check if value has enough ether attached
		require(msg.value >= _product.price);
		// Require that product has not been purchased
		require(!_product.purchased);
		// Require that buyer is not issuer
		require(_issuer != msg.sender); 
		// Require that the product is not obsolete
		require(!_product.obsolete); 
		// Transfer holder status to buyer
		_product.holder = msg.sender; 
		// Mark as purchased
		_product.purchased = true;
		// Update the product
		products[_id] = _product; 
		// Pay the issuer with Ether
		address(_issuer).transfer(msg.value);
		// Pay the supervisor with Ether
		// address(supervisor).transfer(percentFee * msg.value / 100); 
		// Update mapping
		productsPerBuyerPerIssuer[msg.sender][_issuer]++; 
		// Trigger event
		emit ProductPurchased(_product.id, _product.name, _product.price, _product.issuer, msg.sender, true, _product.refundable, false);
	}

	// msg.sender is the issuer
	// Problem: avoid the case where issuer unilaterally pulls tickets? (unless we WANT that to be allowed)
	// Problem: avoid the case where issuer refuses to refund, despite previously attested-to terms
	// Transaction fee for supervisor: percentFee pct of ticket price
	function returnProduct(uint _id) external payable {
		// Fetch the product
		Product memory _product = products[_id];
		// Fetch the holder
		address payable _buyer = _product.holder;
		// Check if product has valid ID
		require(_product.id > 0 && _product.id <= productCount);
		// Check if buyer currently holds ticket
		require(productsPerBuyerPerIssuer[_buyer][msg.sender] > 0); 
		// Check if value has enough ether attached
		require(msg.value >= _product.price);
		// Require that product has been purchased
		require(_product.purchased);
		// Require that issuer is valid
		require(_product.issuer == msg.sender); 
		// Require that buyer is not issuer
		require(_buyer != msg.sender); 
		// Require that product is refundable
		require(_product.refundable); 
		// Transfer holdership back to issuer
		_product.holder = msg.sender; 
		// Revert purchased status
		_product.purchased = false;
		// Update the product
		products[_id] = _product; 
		// Pay the buyer with Ether
		address(_buyer).transfer(msg.value);
		// Pay the supervisor with Ether
		// address(supervisor).transfer(msg.value * percentFee / 100); 
		// Update mapping
		productsPerBuyerPerIssuer[_buyer][msg.sender]--; 
		// Trigger event
		emit ProductReturned(_product.id, _product.name, _product.price, msg.sender, _product.holder, false, true, _product.obsolete);
	}

}
