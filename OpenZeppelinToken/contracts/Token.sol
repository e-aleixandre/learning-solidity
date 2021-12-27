// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
  constructor() ERC20("MyToken", "MTK") {
    _mint(msg.sender, 1000000);
  }
}
