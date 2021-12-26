pragma solidity >=0.7.0 <0.9.0;

contract Hello {
    string _message;

    function setMessage(string memory message) public payable{
        _message = message;
    }

    function hello() external view returns (string memory) {
        return _message;
    }
}
