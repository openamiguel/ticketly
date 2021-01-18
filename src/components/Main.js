import React, { Component } from 'react';

class Main extends Component {

  render() {
    return (
      <div id="content">
        <h2>Add Product</h2>
        <form onSubmit={(event) => {
          event.preventDefault()
          const name = this.productName.value
          const price = window.web3.utils.toWei(this.productPrice.value.toString(), 'Ether')
          const refund = this.productPercentRefundable.value
          this.props.createProduct(name, price, refund)
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
            <input
              id="productPercentRefundable"
              type="number"
              ref={(input) => { this.productPercentRefundable = input }}
              className="form-control"
              placeholder="Percent Refundable"
              required />
          </div>
          <button type="submit" className="btn btn-primary">Add Product</button>
        </form>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <h2>Product Catalog</h2>
        <table className="table">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Name</th>
              <th scope="col">Price</th>
              <th scope="col">Issuer</th>
              <th scope="col">Holder</th>
              <th scope="col">Percent Refundable</th>
              <th scope="col">Return Requested</th>
              <th scope="col">Withdrawn</th>
              <th scope="col"></th>
            </tr>
          </thead>
          <tbody id="productList">
            { this.props.products.map((product, key) => {
              return(
                <tr key={key}>
                  <th scope="row">{product.id.toString()}</th>
                  <td>{window.web3.utils.toAscii(product.name)}</td>
                  <td>{window.web3.utils.fromWei(product.price.toString(), 'Ether')} Eth</td>
                  <td>{product.issuer}</td>
                  <td>{product.holder}</td>
                  <td>{product.percentRefund.toString()}</td>
                  <td>{product.returnRequested.toString()}</td>
                  <td>{product.withdrawn.toString()}</td>
                  <td>
                    { !product.purchased && !product.withdrawn && this.props.account !== product.issuer
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.purchaseProduct(event.target.name, event.target.value)
                          }}
                        >
                          Buy Product
                        </button>
                      : null
                    }
                    </td>
                  <td>
                    { product.purchased && product.percentRefund > 0 && this.props.account === product.issuer
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.returnProduct(event.target.name, event.target.value * product.percentRefund / 100)
                          }}
                        >
                          Return Funds
                        </button>
                      : null
                    }
                    </td>
                  <td>
                    { product.purchased && product.percentRefund > 0 && !product.returnRequested && this.props.account === product.holder
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.requestReturn(event.target.name, event.target.value)
                          }}
                        >
                          Request Return
                        </button>
                      : null
                    }
                    </td>
                  <td>
                    { !product.withdrawn && this.props.account === product.issuer
                      ? <button
                          name={product.id}
                          value={product.price}
                          onClick={(event) => {
                            this.props.withdrawProduct(event.target.name)
                          }}
                        >
                          Withdraw Product
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
