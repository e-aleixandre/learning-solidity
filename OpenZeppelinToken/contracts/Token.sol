// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20Capped, Ownable {
  constructor() ERC20("MyToken", "MTK") ERC20Capped(100000) {
    _mint(msg.sender, 10000);
  }
}
