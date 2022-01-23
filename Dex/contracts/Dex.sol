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
    else if (action == Action.SELL)
    {
      require(balances[msg.sender][ticker] >= amount, "Insufficient token balance");
      orders = orderBook[ticker][Action.BUY];
    }
    else
    {
      revert("The specified action does not exist");
    }

    uint256 totalFilled = 0;

    for (uint256 i = 0; i < orders.length && totalFilled != amount; ++i)
    {
      Order storage order = orders[i];
      uint256 leftToFill = amount.sub(totalFilled);
      uint256 orderAmount = order.amount.sub(order.filled);
      uint256 filled = 0;

      if (leftToFill > orderAmount) {
        totalFilled = totalFilled.add(orderAmount);
        filled = orderAmount;
        order.filled = order.amount;
      } else {
        order.filled = order.filled.add(leftToFill);
        totalFilled = amount;
        filled = leftToFill;
      }

      uint256 cost = filled.mul(order.price);

      if (action == Action.BUY)
      {
        require(balances[msg.sender]["ETH"] >= cost, "Insuficient ETH to cover the transaction");
        
        balances[order.trader][ticker] = balances[order.trader][ticker].sub(filled);
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);

        balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
        balances[order.trader]["ETH"] = balances[order.trader]["ETH"].add(cost);
      }
      else
      {
        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
        balances[order.trader][ticker] = balances[order.trader][ticker].add(filled);

        balances[order.trader]["ETH"] = balances[order.trader]["ETH"].sub(cost);
        balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
      }
    }

    uint256 index = 0;

    while (orders[index].amount == orders[index].filled && index < orders.length)
    {
      ++index;
    }

    uint256 pops = index;

    for (uint256 i = 0; index != 0 && index < orders.length; ++i)
    {
      orders[i] = orders[index];
      ++index;
    }

    for (uint256 i = 0; i < pops; ++i)
    {
      orders.pop();
    }
  }
}
