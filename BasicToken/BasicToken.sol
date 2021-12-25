pragma solidity >=0.7.0 <0.9.0;

contract Token {
    string internal tokenName;
    string internal tokenSymbol;
    uint8 internal tokenDecimals;
    uint internal tokenTotalSupply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _initialOwnerBalance
    )
    {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenTotalSupply = _initialOwnerBalance;
        balances[msg.sender] = _initialOwnerBalance;
    }

    function name() external view returns (string memory _name) {
        _name = tokenName;
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = tokenSymbol;
    }

    function decimals() external view returns (uint8  _decimals) {
        _decimals = tokenDecimals;
    }

    function totalSupply() external view returns (uint _totalSupply) {
        _totalSupply = tokenTotalSupply;
    }

    function balanceOf(address _owner) external view returns (uint _balance) {
        _balance = balances[_owner];
    }

    function transfer(address payable _to, uint _value) public returns (bool _success) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        _success = true;
    }

    function approve(address _spender, uint _value) public returns (bool _success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        _success =  true;
    }

    function allowance(address _owner, address _spender) external view returns (uint _remaining) {
        _remaining = allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool _success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        _success = true;
    }
}