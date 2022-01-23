// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress;

    constructor(address _token) {
        require(_token != address(0), "Invalid address");
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        require(_tokenAmount > 0, "Token amount should be greater than 0");
        require(msg.value > 0, "Transaction value should be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function calculateTradeOutput(
        uint256 tradeInput,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0, "Input reserve should be greater than 0");
        require(outputReserve > 0, "Output reserve should be greater than 0");

        return (tradeInput * outputReserve) / (inputReserve + tradeInput);
    }

    function getTokenAmount(uint256 _etherSold) public view returns (uint256) {
        require(_etherSold > 0, "Ether quantity should be greater than 0");

        return
            calculateTradeOutput(
                _etherSold,
                address(this).balance,
                getReserve()
            );
    }

    function getEtherAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "Token quantity should be greater than 0");

        return
            calculateTradeOutput(
                _tokenSold,
                getReserve(),
                address(this).balance
            );
    }

    function swapEtherToToken(uint256 minTokenAmount) public payable {
        uint256 tokenAmount = calculateTradeOutput(
            msg.value,
            address(this).balance - msg.value,
            getReserve()
        );

        require(tokenAmount >= minTokenAmount, "Token amount was less than requested minimum");

        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    function swapTokenToEther(uint256 tokenAmount, uint256 minEtherAmount) public {
        uint256 etherAmount = calculateTradeOutput(
            tokenAmount,
            getReserve() - tokenAmount,
            address(this).balance
        );

        require(etherAmount >= minEtherAmount, "Ether amount was less than requested minimum");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        (bool success, ) = payable(msg.sender).call{value: etherAmount}("");

        require(success, "The transaction did not succeed");
    }
}
