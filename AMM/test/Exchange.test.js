const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { parseEther, formatEther } = require("ethers/lib/utils");
const provider = waffle.provider;
const { ethers } = require("hardhat");

describe("Exchange", function () {

  let TheCoin, theCoin, Exchange, exchange, owner, addr1, addr2;

  this.beforeEach(async () => {
    TheCoin = await ethers.getContractFactory("TheCoin");
    theCoin = await TheCoin.deploy("TheCoin", "THEC", parseEther("100000"));
    Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(theCoin.address);

    [owner, addr1, addr2, _] = await ethers.getSigners();
  });

  it("Should add liquidity", async () => {
    const tokenAmount = 100000;
    const etherAmount = parseEther("1.0");

    await theCoin.approve(exchange.address, tokenAmount);
    await exchange.addLiquidity(tokenAmount, { value: etherAmount});
    
    expect(await provider.getBalance(exchange.address)).to.equal(etherAmount); 
    expect(await exchange.getReserve()).to.equal(tokenAmount);
  });

  it("Returns correct token amount", async () => {
    const tokenAmount = parseEther("2000");
    const etherAmount = parseEther("1000");

    await theCoin.approve(exchange.address, tokenAmount);
    await exchange.addLiquidity(tokenAmount, { value: etherAmount});

    let tokenOutput = await exchange.getTokenAmount(parseEther("1.0"));

    expect(formatEther(tokenOutput)).to.equal("1.998001998001998001");
  });

  it("Returns correct ether amount", async () => {
    const tokenAmount = parseEther("2000");
    const etherAmount = parseEther("1000");

    await theCoin.approve(exchange.address, tokenAmount);
    await exchange.addLiquidity(tokenAmount, { value: etherAmount});

    let etherOutput = await exchange.getEtherAmount(parseEther("2.0"));
    
    expect(formatEther(etherOutput)).to.equal("0.999000999000999");
  });
});
