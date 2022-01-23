// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
  using SafeMath for uint256;
  struct Token {
    bytes32 ticker;
    address tokenAddress; 
  }
  mapping(bytes32 => Token) public tokenMapping;
  bytes32[] public tokenList;
  mapping(address => mapping(bytes32 => uint256)) public balances;

  constructor() {
  }

  modifier TokenExists (bytes32 ticker) {
    require(tokenMapping[ticker].tokenAddress != address(0), "The token does not exist.");
    _;
  }

  function addToken(bytes32 ticker, address tokenAddress) external onlyOwner {
    tokenList.push(ticker);
    tokenMapping[ticker] = Token(ticker, tokenAddress);
  }

  function deposit(uint256 amount, bytes32 ticker) external TokenExists(ticker) {
    // Balance will be checked by the other contract

    balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
    IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
  }

  function depositEth() external payable {
    balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(msg.value);
  }

  function withdraw(uint256 amount, bytes32 ticker) external TokenExists(ticker) {
    require(balances[msg.sender][ticker] >= amount);

    balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
    IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
  }
}
