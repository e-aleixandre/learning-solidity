// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MinterPauserCapped is ERC20PresetMinterPauser {
  bytes32 public constant CAPPED_ROLE = keccak256("CAPPED_ROLE");
  uint private _cap;

  constructor(string memory name, string memory symbol, uint cap) ERC20PresetMinterPauser(name, symbol) {
    require(cap > 0);
    _cap = cap;
    _setupRole(CAPPED_ROLE, _msgSender());
  }

  /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }


    function changeCap(uint256 amount) external {
      require(hasRole(CAPPED_ROLE, msg.sender));
      _cap = amount;
    }
}
