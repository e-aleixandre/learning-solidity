const Dex = artifacts.require("Dex");
const Token = artifacts.require("Token");
const truffleAssert = require("truffle-assertions");

contract("Dex", accounts => {
    it("should ensure enough ETH on buy orders", async () => {
        let dex = await Dex.deployed();

        await truffleAssert.reverts(
            dex.createLimitOrder(
                0,
                web3.utils.fromUtf8("VISAN"),
                100,
                100
            )
        );

        await dex.depositEth({ value: 100000000 });

        await truffleAssert.passes(
            dex.createLimitOrder(
                0,
                web3.utils.fromUtf8("VISAN"),
                100,
                100
            )
        );
    });

    it("should ensure enough token balance on sell orders", async () => {
        let dex = await Dex.deployed();
        let token = await Token.deployed();
        
        await dex.addToken(web3.utils.fromUtf8("VISAN"), token.address);
        await token.approve(dex.address, 10000);
        await dex.deposit(10000, web3.utils.fromUtf8("VISAN"));

        await truffleAssert.reverts(
            dex.createLimitOrder(
                1,
                web3.utils.fromUtf8("VISAN"),
                100,
                100,
                { from: accounts[1] }
            )
        );

        await truffleAssert.passes(
            dex.createLimitOrder(
                1,
                web3.utils.fromUtf8("VISAN"),
                100,
                100
            )
        );
    });

    it("should ensure the orders are stored in the book", async () => {
        let dex = await Dex.deployed ();
        let ticker = web3.utils.fromUtf8("VISAN");
        let orderBook = await dex.getOrderBook(ticker, 0);
        let orderBookLength = orderBook.length;

        await dex.createLimitOrder(
            0,
            ticker,
            100,
            100
        );

        orderBook = await dex.getOrderBook(ticker, 0);
        
        assert(orderBook.length === orderBookLength + 1, "The buying orderBook is not storing new orders");
        
        orderBook = await dex.getOrderBook(ticker, 1);
        orderBookLength = orderBook.length;

        await dex.createLimitOrder(
            1,
            ticker,
            100,
            100
        );

        orderBook = await dex.getOrderBook(ticker, 1);

        assert(orderBook.length === orderBookLength + 1, "The selling orderBook is not storing new orders");
    });

    it("should ensure the buy order book is in descending order", async () => {
        let dex = await Dex.deployed();
        
        const createBuyOrder = async (amount, price) => {
            await dex.createLimitOrder(
                0,
                web3.utils.fromUtf8("VISAN"),
                amount,
                price
            );
        }
        
        await createBuyOrder(100, 100);
        await createBuyOrder(100, 200);
        await createBuyOrder(100, 150);
        await createBuyOrder(100, 300);

        let orderBook = await dex.getOrderBook(web3.utils.fromUtf8("VISAN"), 0);
        
        for (let i = 0; i < orderBook.length - 1; ++i)
            assert(parseInt(orderBook[i].price) >= parseInt(orderBook[i + 1].price));
    });

    it("should ensure the sell order book is in ascending order", async () => {
        let dex = await Dex.deployed();

        const createSellOrder = async (amount, price) => {
            await dex.createLimitOrder(
                1,
                web3.utils.fromUtf8("VISAN"),
                amount,
                price
            );
        }

        await createSellOrder(100, 100);
        await createSellOrder(100, 200);
        await createSellOrder(100, 110);
        await createSellOrder(100, 80);

        let orderBook = await dex.getOrderBook(web3.utils.fromUtf8("VISAN"), 1);

        for (let i = 0; i < orderBook.length - 1; ++i)
            assert(parseInt(orderBook[i].price) <= parseInt(orderBook[i + 1].price));
    });
});