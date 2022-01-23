// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Registry.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    address public registryAddress;

    constructor(address _token) ERC20("LPToken", "LPT") {
        require(_token != address(0), "Invalid address");
        tokenAddress = _token;

        // Each exchange is deployed by the Registry
        registryAddress = msg.sender;
    }

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "Invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);

        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");

        require(success, "The transaction did not succeed");

        return (ethAmount, tokenAmount);
    }

    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        require(_tokenAmount > 0, "Token amount should be greater than 0");
        require(msg.value > 0, "Transaction value should be greater than 0");

        uint256 mintedTokens;

        if (totalSupply() == 0) {
            mintedTokens = address(this).balance;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 correctTokenAmount = (msg.value * getReserve()) /
                ethReserve;

            require(
                _tokenAmount >= correctTokenAmount,
                "Not enough tokens sent"
            );

            mintedTokens = (totalSupply() * msg.value) / ethReserve;
        }

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);

        _mint(msg.sender, mintedTokens);

        return mintedTokens;
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

        //return (tradeInput * outputReserve) / (inputReserve + tradeInput);
        uint256 tradeInputWithFee = tradeInput * 99;
        uint256 numerator = tradeInputWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + tradeInputWithFee;

        return numerator / denominator;
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

    function etherToToken(uint256 minTokenAmount, address recipient) private {
        uint256 tokenAmount = calculateTradeOutput(
            msg.value,
            address(this).balance - msg.value,
            getReserve()
        );

        require(
            tokenAmount >= minTokenAmount,
            "Token amount was less than requested minimum"
        );

        IERC20(tokenAddress).transfer(recipient, tokenAmount);
    }

    function swapEtherToTokenTransfer(uint256 minTokenAmount, address recipient) public payable {
        etherToToken(minTokenAmount, recipient);
    }

    function swapEtherToToken(uint256 minTokenAmount) public payable {
        etherToToken(minTokenAmount, msg.sender);
    }


    function swapTokenToEther(uint256 tokenAmount, uint256 minEtherAmount)
        public
    {
        uint256 etherAmount = calculateTradeOutput(
            tokenAmount,
            getReserve() - tokenAmount,
            address(this).balance
        );

        require(
            etherAmount >= minEtherAmount,
            "Ether amount was less than requested minimum"
        );

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        (bool success, ) = payable(msg.sender).call{value: etherAmount}("");

        require(success, "The transaction did not succeed");
    }

    function swapTokenToToken(
        uint256 tokensSold,
        uint256 minTokenAmount,
        address outputToken
    ) public {
        address exchangeAddress = Registry(registryAddress).tokenToExchange(
            outputToken
        );

        require(tokensSold > 0, "Tokens sold must be greater than 0");
        require(address(this) != exchangeAddress, "Invalid exchange address");
        require(
            exchangeAddress != address(0),
            "There's no registry for that token"
        );

        uint256 tokenReserve = getReserve();
        uint256 ethBought = calculateTradeOutput(
            tokensSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokensSold
        );
        Exchange(exchangeAddress).swapEtherToTokenTransfer{value: ethBought}(
            minTokenAmount,
            msg.sender
        );
    }
}
