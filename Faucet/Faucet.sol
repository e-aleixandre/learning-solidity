// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Faucet {
    function withdraw(uint amount) public {
        assert(amount <= 0.1 ether);
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

