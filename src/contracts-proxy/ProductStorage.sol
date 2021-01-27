pragma solidity ^0.5.0;

contract ProductStorage {

	// Slot 1
	uint32 public _productCount;

	mapping(uint32 => Product) public _products;
	mapping(address => mapping(address => uint24)) public _productsPerBuyerPerIssuer; 

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

	//--- Get methods ---//

	function getProduct(uint32 _id) public view returns (Product) {
		return _products[_id]; 
	}

	function getProductsPerBuyerPerIssuer(address _holder, address _issuer) public view returns (uint24) {
		return _productsPerBuyerPerIssuer[_holder][_issuer]; 
	}

	function getProductCount() public view returns (uint32) {
		return _productCount; 
	}

	//--- Set methods ---//

	function setProduct(uint32 _id, Product _product) public {
		_products[_id] = _product; 
	}

	function setProductsPerBuyerPerIssuer(address _holder, address _issuer, bool increment) public {
		if (increment) {
			_productsPerBuyerPerIssuer[_holder][_issuer]++;
		} else {
			_productsPerBuyerPerIssuer[_holder][_issuer]--; 
		}
	}

	function incrementProductCount() public {
		_productCount++; 
	}
}