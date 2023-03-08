// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract LazyKitties is ERC721Enumerable, Ownable, PaymentSplitter {
    using Strings for uint256;
    
    string public baseURI;// _baseTokenURI changed to public variable name
    uint256 public constant MAX_ENTRIES = 10077;
    uint256 public constant PRESALE_ENTRIES = 1000;
    uint private PRICE = 0.05 ether;
    uint8 private MAX_BUYABLE = 20;
    uint public startBlock;
    bool public revealState;
    uint256 public aDayBlock;
    mapping (address=>bool) public whitelisted;
    string public placeholderURI = "notreveal";

    enum STAGES { PENDING, PRESALE, PUBLICSALE }
    STAGES stage = STAGES.PENDING;
    
    uint256 public sold;
    uint256 public whitelistAccessCount;
    
    constructor(string memory _baseURI, address[] memory payees, uint256[] memory paymentShares)
        ERC721("LKC.LazyKittiesClub", "LKC")
        PaymentSplitter(payees, paymentShares) {
            revealState = false;
            baseURI = _baseURI; //_baseTokenURI replaced by baseURI
            sold = 0;
            aDayBlock = uint256(86400 / blockTime());
    }
    
    function mint(uint256 _amount) external payable {
        require(stage != STAGES.PENDING, "Sale not started yet.");
        require(sold + _amount < MAX_ENTRIES, 'Amount exceed');
        require(msg.value >= PRICE * _amount, "Lazy Kitties: incorrect price");
        if (block.number > startBlock + aDayBlock * 7) {
            stage = STAGES.PUBLICSALE;
        } else if (stage == STAGES.PRESALE) {
            require(whitelisted[msg.sender], 'Only whitelisted address can mint first PRESALE_ENTRIES NFTs');
            require(balanceOf(msg.sender)+_amount <= MAX_BUYABLE, 'BUYABLE LIMIT EXCEED');
            require(sold + _amount <= PRESALE_ENTRIES, "PRESALE LIMIT EXCEED");
            for (uint8 i = 1; i <= _amount; i++) {
                _safeMint(msg.sender, (sold + i));
            } 
            whitelistAccessCount++;//whitelistAccessCount incremented by one instead entire array at once 
            sold += _amount;
        } else {//else statement added to remove an unnecessary condition checking when presale is over
            require(_amount <= MAX_BUYABLE, 'BUYABLE LIMIT EXCEED');
            for (uint8 i = 1; i <= _amount; i++) {
                _safeMint(msg.sender, (sold + i));  
            } 
            sold += _amount;        
        }
        if (sold >= MAX_ENTRIES) {
            revealState = true;
        }
    }
    function setBlockTime(uint blockTimech) public onlyOwner {
        aDayBlock = 86400 / blockTimech;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if ((block.number >= startBlock + aDayBlock * 9) || revealState == true ) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
        return placeholderURI;  
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getCurrentStage() external view returns (uint) {
        return uint(stage);
    }

    function setPlaceHolderURI(string memory holderURI) public onlyOwner {
        placeholderURI = holderURI;
    }
    function addWhiteListAddresses(address[] calldata addresses) external onlyOwner {
        require ( whitelistAccessCount + addresses.length <= PRESALE_ENTRIES, "WHITELIST LIMIT EXCEED");
        for (uint8 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true; 
            whitelistAccessCount++;//whitelistAccessCount incremented by one instead entire array at once 
        }
    }

    function startSale() external onlyOwner {
        require(stage == STAGES.PENDING, 'Not in pending stage.');
        startBlock = block.number;
        stage = STAGES.PRESALE;
    }
}
