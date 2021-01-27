pragma solidity ^0.5.0;

import "./Storage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceLogic is Storage {

	// Slot 1
	bytes16 public name;
	uint8 public constant maxProductsPerBuyerPerIssuer = 2; 
	uint8 public constant percentFee = 3; // MUST NEVER BE ZERO!!!

	event ProductCreated(
		// Slot 1
		address payable issuer,
		// Slot 2
		address payable holder,
		// Slot 3
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
	}

	modifier onlyOwner() {
		require(msg.sender == _storage.getAddress("owner"));
		_;
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
		_storage.incrementProductCount(); 
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
		_storage.setProduct(productCount, _product);
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
		Product memory _product = _storage.getProduct(_id);

		// Irreversibly withdraws product from the market
		if (_code == 1) {
			// Require that issuer is valid
			require(_product.issuer == msg.sender, "Unauthorized withdrawal attempt"); 
			// Make withdrawn
			_product.withdrawn = true; 
			// Update the product
			_storage.setProduct(_id, _product); 
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
			_storage.setProduct(_id, _product); 
			// Trigger an event
			emit ReturnRequested(_product.id);
		}

		// Purchase product from issuer
		else if (_code == 3) {
			// Fetch the issuer
			address payable _issuer = _product.issuer;
			// Check if buyer has bought too many tickets
			require(_storage.getProductsPerBuyerPerIssuer(msg.sender, _issuer) < maxProductsPerBuyerPerIssuer, "Threshold for products reached"); 
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
			_storage.setProduct(_id, _product); 
			// Pay the issuer with Ether
			address(_issuer).transfer(msg.value);
			// Pay the owner with Ether
			// address(owner).transfer(percentFee * msg.value / 100); 
			// Update mapping
			_storage.setProductsPerBuyerPerIssuer(msg.sender, _issuer, true); 
			// Trigger event
			emit ProductPurchased(_product.id);
		}

		// Have product returned to issuer
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
			_storage.setProduct(_id, _product); 
			// Pay the buyer with Ether
			// Potentially serious bug: msg.value is transferred but refund is not!!!
			// Currently, the code only works because the Javascript front end controls the amount of value to transfer!!!
			uint refund = msg.value * _product.percentRefund / 100; 
			address(_buyer).transfer(refund);
			// Pay the owner with Ether
			// address(owner).transfer(msg.value * percentFee / 100); 
			// Update mapping
			_storage.setProductsPerBuyerPerIssuer(msg.sender, _issuer, false); 
			// Trigger event
			emit ProductReturned(_product.id);
		}
	}
}