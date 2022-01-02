// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;

import "./Wallet.sol";

contract Dex is Wallet {

  using SafeMath for uint256;

  enum Action {
    BUY,
    SELL
  }

  struct Order {
    uint256 id;
    address trader;
    Action action;
    bytes32 ticker;
    uint256 amount;
    uint256 filled;
    uint256 price;
  }

  uint256 private nextId = 0;

  mapping(bytes32 => mapping(Action => Order[])) orderBook;

  function getOrderBook(bytes32 ticker, Action action) external view returns (Order[] memory)
  {
    return orderBook[ticker][action];
  }

  function createLimitOrder(Action action, bytes32 ticker, uint256 amount, uint256 price) external {
    if (action == Action.BUY)
      require(balances[msg.sender]["ETH"] >= amount.mul(price), "Not enough ETH for buying");
    else if (action == Action.SELL)
      require(balances[msg.sender][ticker] >= amount, "Insufficient token amount for selling");
    else
      revert("The provided action does not exist");

    Order[] storage orders = orderBook[ticker][action];

    orders.push(
      Order(nextId++, msg.sender, action, ticker, amount, 0, price)
    );

    uint256 i = orders.length > 0 ? orders.length - 1 : 0;

    if (action == Action.BUY)
    {
      while (i > 0)
      {
        if (orders[i].price <= orders[i - 1].price)
          break;

        Order memory order = orders[i];
        orders[i] = orders[i - 1];
        orders[i - 1] = order;
        --i;
      }
    } else if (action == Action.SELL) {
      while (i > 0)
      {
        if (orders[i].price >= orders[i - 1].price)
          break;

        Order memory order = orders[i];
        orders[i] = orders[i - 1];
        orders[i - 1] = order;
        --i;
      }
    }
  }

  function createMarketOrder(Action action, bytes32 ticker, uint256 amount) external {
    Order[] storage orders;

    if (action == Action.BUY)
    {
      orders = orderBook[ticker][Action.SELL];    
    }
    else
    {
      require(balances[msg.sender][ticker] >= amount, "Insufficient token balance");
      orders = orderBook[ticker][Action.BUY];
    }

    uint256 totalFilled = 0;

    for (uint256 index = 0; index < orders.length; ++index)
    {
      uint256 leftToFill = amount.sub(totalFilled);
      uint256 orderAmount = orders[index].amount.sub(orders[index].filled);

      if (leftToFill > orderAmount) {
        totalFilled = totalFilled.add(orderAmount);
        orders[index].filled = orders[index].amount;
      } else {
        orders[index].filled = orders[index].filled.add(leftToFill);
        break;
      }
    }
  }
}
