import React, { Component } from 'react';

class Main extends Component {

  constructor(props) {
    super(props);
    this.state = {
      checkboxValue: false
    }
    this.handleInputChange = this.handleInputChange.bind(this);
  }

  handleInputChange(event) {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;
    this.setState({
      [name]: value
    });
  }

  render() {
    return (
      <div id="content">
        <h2>Add Product</h2>
        <form onSubmit={(event) => {
          event.preventDefault()
          const name = this.productName.value
          const price = window.web3.utils.toWei(this.productPrice.value.toString(), 'Ether')
          const refundable = this.state.checkboxValue.value
          this.props.createProduct(name, price, refundable)
        }}>
          <div className="form-group mr-sm-2">
            <input
              id="productName"
              type="text"
              ref={(input) => { this.productName = input }}
              className="form-control"
              placeholder="Product Name"
              required />
          </div>
          <div className="form-group mr-sm-2">
            <input
              id="productPrice"
              type="text"
              ref={(input) => { this.productPrice = input }}
              className="form-control"
              placeholder="Product Price"
              required />
          </div>
          <div className="form-group mr-sm-2">
            Product is refundable:  
            <input
              id="productRefundable"
              type="checkbox"
              checked={this.state.checkboxValue}
              onChange={this.handleInputChange}
              />
          </div>
          <button type="submit" className="btn btn-primary">Add Product</button>
        </form>
        <p>&nbsp;</p>
        <h2>Withdraw Product from Marketplace</h2>
        <form onSubmit={(event) => {
          event.preventDefault()
          const id = this.productID.value
          this.props.withdrawProduct(id)
        }}>
          <div className="form-group mr-sm-2">
            <input
              id="productID"
              type="int"
              ref={(input) => { this.productID = input }}
              className="form-control"
              placeholder="Product ID"
              required />
          </div>
          <button type="submit" className="btn btn-primary">Withdraw Product</button>
        </form>
        <p>&nbsp;</p>
        <h2>Buy/Return Product</h2>
        <table className="table">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Name</th>
              <th scope="col">Price</th>
              <th scope="col">Issuer</th>
              <th scope="col">Holder</th>
              <th scope="col">Refundable</th>
              <th scope="col">Withdrawn</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody id="productList">
            { this.props.products.map((product, key) => {
              return(
                <tr key={key}>
                  <th scope="row">{product.id.toString()}</th>
                  <td>{product.name}</td>
                  <td>{window.web3.utils.fromWei(product.price.toString(), 'Ether')} Eth</td>
                  <td>{product.issuer}</td>
                  <td>{product.holder}</td>
                  <td>{product.refundable.toString()}</td>
                  <td>{product.withdrawn.toString()}</td>
                  <td>
                    { !product.purchased && !product.withdrawn
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.purchaseProduct(event.target.name, event.target.value)
                          }}
                        >
                          Buy
                        </button>
                      : null
                    }
                    </td>
                  <td>
                    { product.purchased && product.refundable
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.returnProduct(event.target.name, event.target.value)
                          }}
                        >
                          Return
                        </button>
                      : null
                    }
                    </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    );
  }
}

export default Main;
