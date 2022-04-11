// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract PL is ERC721A, Ownable, ContextMixin, PullPayment {
    using SafeMath for uint256;

    uint256 MAX_MINTS = 3;
    uint256 MAX_TOKENS = 10002;
    uint256 public wlMintRate = 0.025 ether;
    uint256 public mintRate = 0.05 ether;

    string public baseURI = "https://metapython.herokuapp.com/api/box/";

    event Minted(uint256 tokenId, address minter); //minter?

    constructor() ERC721A("P L", "pl") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    mapping(address => mapping(uint256 => uint256)) private _mintedTokens;
    mapping(uint256 => uint256) private _mintedTokensIndex;

    function wlMint(uint256 quantity) external payable callerIsUser {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            quantity + _numberMinted(msg.sender) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + quantity <= MAX_TOKENS,
            "Not enough tokens left"
        );
        require(msg.value >= (wlMintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
        emit Minted(totalSupply(), msg.sender);

        uint256 length = _addressData[msg.sender].numberMinted;

        for (uint256 i = quantity; i > 0; i--) {
            _mintedTokens[msg.sender][length - i] = totalSupply - 1 - i;
            // _mintedTokensIndex[totalSupply - 1] = length;
        }
    }

    function mintedTokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < _addressData[msg.sender].numberMinted,
            "ERC721Enumerable: owner index out of bounds"
        );
        return _mintedTokens[owner][index];
    }

    function mint(uint256 quantity) external payable callerIsUser {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            quantity + _numberMinted(msg.sender) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + quantity <= MAX_TOKENS,
            "Not enough tokens left"
        );
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
        emit Minted(totalSupply(), msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMAX_MINTS(uint256 _maxMints) public onlyOwner {
        MAX_MINTS = _maxMints;
    }

    function setMAX_TOKENS(uint256 _maxTokens) public onlyOwner {
        MAX_TOKENS = _maxTokens;
    }

    function setWlMintRate(uint256 _wlMintRate) public onlyOwner {
        wlMintRate = _wlMintRate;
    }

    function setmintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
    {
        super.withdrawPayments(payee);
    }

    //warning, proxy address to be updated
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721A.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
