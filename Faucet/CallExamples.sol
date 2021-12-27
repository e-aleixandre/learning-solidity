pragma solidity >=0.7.0 <0.9.0;

contract calledContract {
    event callEvent(address sender, address origin, address from);

    function calledFunction() public {
        emit callEvent(msg.sender, tx.origin, address(this));
    }
}

library calledLibrary {
    event callEvent(address sender, address origin, address from);

    function calledFunction() public {
        emit callEvent(msg.sender, tx.origin, address(this));
    }
}

contract Caller {
    function make_calls(calledContract _calledContract) public {

        // Calling calledContract and calledLibrary directly
        _calledContract.calledFunction();
        calledLibrary.calledFunction();

        // Low-level calls using the address for calledContract
        (bool ok, ) = address(_calledContract).delegatecall(abi.encodeWithSignature("calledFunction()"));
        
        require(ok);

        (ok, ) = address(_calledContract).delegatecall(abi.encodeWithSignature("calledFunction()"));

        require(ok);
    }
}