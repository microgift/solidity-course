pragma solidity 0.5.7;



contract SimpleERC20Token is ERC20, SafeMath {
  using SafeMath for uint256;

  // Track how many tokens are owned by each address.
  mapping(address => uint256) private _balanceOf;
  mapping(address => mapping(address => uint256)) private _allowance;

  // Modify this section
  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() public ERC20("Mr Key's Token", "MKT", 18) {
    _name = "Mr Key's Token";
    _symbol = "MKT";
    _decimals = 18;
    _totalSupply = 5000000000000000000000000000;

    _balanceOf[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

}
