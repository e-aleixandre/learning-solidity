const Dex = artifacts.require("Dex");
const Token = artifacts.require("Token");
const truffleAssert = require("truffle-assertions");

contract("Dex", accounts => {
    it("should fill market orders until order book is empty", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        let symbol = await token.symbol();
        let ticker = web3.utils.fromUtf8(symbol);

        await dex.addToken(ticker, token.address);

        await token.transfer(accounts[1], 100000);
        await token.transfer(accounts[2], 100000);
        await token.transfer(accounts[3], 100000);

        await token.approve(dex.address, 100000, { from: accounts[1] });
        await token.approve(dex.address, 100000, { from: accounts[2] });
        await token.approve(dex.address, 100000, { from: accounts[3] });

        await dex.depositEth({ value: 10000000 });

        await dex.deposit(100000, ticker, { from: accounts[1] });
        await dex.deposit(100000, ticker, { from: accounts[2] });
        await dex.deposit(100000, ticker, { from: accounts[3] });

        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[1] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[2] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[3] });

        await dex.createMarketOrder(0, ticker, 5000);

        let orderBook = await dex.getOrderBook(ticker, 1);
        
        assert(orderBook.length === 0, "Order book is not empty");

        let balance = await dex.balances(accounts[0], ticker);

        assert(balance === 3000, "The market order was not even partially filled");
        
    });

    it("should fill market orders until order is completely filled", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        let symbol = await token.symbol();
        let ticker = web3.utils.fromUtf8(symbol);

        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[1] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[2] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[3] });

        await dex.createMarketOrder(0, ticker, 1500);

        let orderBook = await dex.getOrderBook(ticker, 1);
        
        assert(orderBook.length === 2, "Order book should have 2 orders");

        let balance = await dex.balances(accounts[0], ticker);

        assert(balance === 1500, "The market order was not filled");
    });
    
    it("should decrease the ETH balance of the buyer", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        let eth = web3.utils.fromUtf8("ETH");
        let symbol = await token.symbol();
        let ticker = web3.utils.fromUtf8(symbol);

        let oldBalance = await dex.balances(accounts[0], eth);

        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[1] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[2] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[3] });

        await dex.createMarketOrder(0, ticker, 3000);

        let balance = await dex.balances(accounts[0], eth);

        assert(oldBalance === balance - 150000, "The ETH balance didn't decrease after buying");
    });

    it("should decrease the token balance of the sellers", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        let symbol = await token.symbol();
        let ticker = web3.utils.fromUtf8(symbol);

        let oldBalance = await dex.balances(accounts[1], ticker);

        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[1] });

        await dex.createMarketOrder(0, ticker, 3000);

        let balance = await dex.balances(accounts[1], ticker);

        assert(oldBalance === balance - 1000, "The token balance didn't decrease after selling");
    });

    it("should delete filled orders from the order book", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        let symbol = await token.symbol();
        let ticker = web3.utils.fromUtf8(symbol);

        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[1] });
        await dex.createLimitOrder(1, ticker, 1000, 50, { from: accounts[2] });

        let orderBook = await dex.getOrderBook(ticker, 1);
        let oldOrderAmount = orderBook.length;

        await dex.createMarketOrder(0, ticker, 1000);

        orderBook = await dex.getOrderBook(ticker, 1);

        assert(oldOrderAmount === orderBook.length - 1, "The filled order wasn't removed from the book");
    });
});
