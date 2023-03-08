// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Shrooms is ERC721Enumerable, Ownable {
    
  using Strings for uint256;
  
  string private _baseTokenURI;
  address private constant admin = 0x27DF8590c11F2e5E7B0d0e00Ac8f39aFE0BA127E;
  uint256 internal constant MAX_ENTRIES = 2500;
  
  uint256[5] private PRICES = [35 ether, 50 ether, 75 ether, 100 ether, 0 ether];
  uint8[3] private MAX_BUYABLE = [3, 5, 1];
  uint8 private currentPriceId = 0;
  mapping (address => bool) public whitelisted;
  mapping (address => uint256) freeminted;
  
  enum STAGES { PRESALE, PUBLICSALE, FREESALE }
  STAGES stage = STAGES.PRESALE;
  
  uint256 public totalMinted;
  uint256 public sold;
  
  uint256[MAX_ENTRIES] internal availableIds;
  
  constructor(string memory baseURI) ERC721("Fantom Shrooms", "FTM.Shrooms") {
      setBaseURI(baseURI);
      for (uint256 i = 0; i < 250; i++) {
          _safeMint(admin, _getNewId(i));
      }
      totalMinted = 250;
      sold = 0;
      // whitelisted[0x2A0ecFb6364787F2B80A05C57B6A827Baf59b164] = true;
  }
  
  function _getNewId(uint256 _totalMinted) internal view returns (uint256) {
      uint256 remaining = MAX_ENTRIES - _totalMinted;
      uint256 rand = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, remaining))) % remaining;
      return availableIds[rand] != 0 ? availableIds[rand] + 1 : rand + 1 ;
  } 
  
  function mint(uint256 _amount) external payable {
      require(totalMinted + _amount <= MAX_ENTRIES, 'Amount exceed');
      if (stage == STAGES.PRESALE) {
          require(whitelisted[msg.sender], 'Only whitelisted address can mint first 250 NFTs');
          require(balanceOf(msg.sender) + _amount <= MAX_BUYABLE[0], 'BUYABLE LIMIT EXCEED');
      } else if (stage == STAGES.PUBLICSALE) {
          require(balanceOf(msg.sender) + _amount <= MAX_BUYABLE[1], 'BUYABLE LIMIT EXCEED');
          require(sold + _amount <= 2000, 'Public sale amount exceed');
      } else {
          require(balanceOf(msg.sender) > 0, 'Only a holder can mint this NFT');
          require(freeminted[msg.sender] + _amount <= MAX_BUYABLE[2], 'FREE MINT LIMIT EXCEED');
          freeminted[msg.sender] += _amount;
      }
      uint256 amountForNextPrice = 500 - (sold % 500);
      uint256 estimatedPrice;
      if (_amount > amountForNextPrice) {
          estimatedPrice = PRICES[currentPriceId] * amountForNextPrice + PRICES[currentPriceId + 1] * (_amount - amountForNextPrice);
      } else {
          estimatedPrice = PRICES[currentPriceId] * _amount;
      }
      require(msg.value >= estimatedPrice, "FTM.Shrooms: incorrect price");
      payable(admin).transfer(address(this).balance); 
      for (uint256 i = 0; i < _amount; i++) {
          _safeMint(msg.sender, _getNewId(totalMinted + i));
      }
      if (sold < 250 && sold + _amount >= 250) {
          stage = STAGES.PUBLICSALE;
      } else if (sold < 2000 && sold + _amount >= 2000) {
          stage = STAGES.FREESALE;
      }
      totalMinted += _amount;
      sold += _amount;
      if (_amount >= amountForNextPrice) {
          currentPriceId++;
      }
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  function toggleWhitelistedAddress(address _address) external onlyOwner {
    whitelisted[_address] = !whitelisted[_address];
  }
}