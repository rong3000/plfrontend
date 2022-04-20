// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC1155URIStorage.sol";

contract PL1155 is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage {
    using SafeMath for uint256;

    uint256 public MAX_MINTS = 204800;
    address proxyAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317;

    event Minted(address to, uint256 tokenId, uint256 amount);
    event MintedBatch(address to, uint256[] ids, uint256[] amounts);

    constructor() ERC1155("https://metapython.herokuapp.com/api/box/") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setProxy(address _proxyAddress) public onlyOwner {
        proxyAddress = _proxyAddress;
    }

    // function getProxy() public view onlyOwner returns (address) {
    //     return proxyAddress;
    // }

    function setMaxMints(uint256 max_mints) public onlyOwner {
        MAX_MINTS = max_mints;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
        emit Minted(account, id, amount);
    }

    function forge(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 id,
        bytes memory data
    ) public {
        _burnBatch(account, ids, amounts);
        _mint(account, id, 1, data);
        emit Minted(account, id, 1);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
        emit MintedBatch(to, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (_operator == address(proxyAddress)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
}
