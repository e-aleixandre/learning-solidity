// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 < 0.9.0;
pragma abicoder v2;

contract MultiSigWallet {
    Wallet[] wallets;
    mapping (uint => bool) createdWallets;

    struct Transfer {
        mapping(address => bool) approvals;
        address destinatary;
        uint quantity;
        bool done;
    }

    struct Wallet {
        address[] owners;
        Transfer[] transfers;
        uint funds;
    }

    modifier walletExists(uint walletIndex) {
        require(createdWallets[walletIndex]);
        _;
    }

    modifier transferNotDone(uint walletIndex, uint transferIndex) {
        require(wallets[walletIndex].transfers[transferIndex].done == false);
        _;
    }

    modifier hasEnoughFunds(uint walletIndex, uint transferIndex) {
        require(wallets[walletIndex].transfers[transferIndex].quantity <= wallets[walletIndex].funds);
        _;
    }

    function createWallet(address[] memory addresses) public returns (uint) {
        require(addresses.length == 2, "A wallet needs 2 extra addresses for transfer approval");
        
        Wallet storage wallet = wallets.push();
        wallet.owners = addresses;
        wallet.owners.push(msg.sender);
        createdWallets[wallets.length - 1] = true;

        return wallets.length - 1;
    } 

    function deposit(uint walletIndex) public payable walletExists(walletIndex){
        wallets[walletIndex].funds += msg.value;
    }

    function createTransfer(uint walletIndex, address destinatary, uint amount) public walletExists(walletIndex) returns (uint) {
        ensureIsWalletOwner(walletIndex);

        Transfer storage transfer = wallets[walletIndex].transfers.push();

        transfer.destinatary = destinatary;

        transfer.approvals[msg.sender] = true;

        transfer.quantity = amount;

        return wallets[walletIndex].transfers.length - 1;
    }

    function approveTransfer(uint walletIndex, uint transferIndex) public walletExists(walletIndex) {
        ensureIsWalletOwner(walletIndex);

        wallets[walletIndex].transfers[transferIndex].approvals[msg.sender] = true;
    }

    function commitTransfer(uint walletIndex, uint transferIndex) public walletExists(walletIndex) transferNotDone(walletIndex, transferIndex) hasEnoughFunds(walletIndex, transferIndex) {
        ensureIsWalletOwner(walletIndex);
        ensureTransferIsApproved(walletIndex, transferIndex);

        Transfer storage transfer = wallets[walletIndex].transfers[transferIndex];

        payable(transfer.destinatary).transfer(transfer.quantity);
    }

    function ensureIsWalletOwner(uint walletIndex) private view {
        for (uint i = 0; i < 3; ++i)
            if (wallets[walletIndex].owners[i] == msg.sender)
                return;

        require(false, "You don't have permissions on that wallet");
    }

    function ensureTransferIsApproved(uint walletIndex, uint transferIndex) private view {
        uint8 disapprovals = 0;
        Wallet storage wallet = wallets[walletIndex];
        Transfer storage transfer = wallet.transfers[transferIndex];

        for (uint i = 0; i < 3; ++i)
        {
            if (!transfer.approvals[wallet.owners[i]])
                ++disapprovals;
        }

        // Disapprovals are lower than 2, or equal to two and the sender is not the pending approver
        // If the pending approval was from the actual sender, it could be taken as an approval
        if (disapprovals < 2 || disapprovals == 2 && transfer.approvals[msg.sender])
            require(false, "Transfer is not approved by all wallet owners");
    }

    function getFunds(uint walletIndex) public view walletExists(walletIndex) returns (uint){
        return wallets[walletIndex].funds;
    }
}