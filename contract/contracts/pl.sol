// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract PL1155 is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    ERC1155URIStorage,
    EIP712
{
    using ECDSA for bytes32;

    string storeMetaURL = "https://metapython.herokuapp.com/api/store/";
    string private constant SIGNING_DOMAIN = "PL"; //VIDEO
    string private constant SIGNATURE_VERSION = "1"; //VIDEO

    function contractURI() public view returns (string memory) {
        return storeMetaURL;
    }

    function setStoreMetaURL(string memory _storeMetaURL) public onlyOwner {
        storeMetaURL = _storeMetaURL;
    }

    using SafeMath for uint256;

    uint256 public MAX_MINTS = 204800;
    address proxyAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317;

    mapping(string => uint256) public wlConsumed;

    event Minted(address to, uint256 tokenId, uint256 amount);
    event MintedBatch(address to, uint256[] ids, uint256[] amounts);
    event Merged(address to, uint256 tokenId, uint256 amount);
    event Split(address to, uint256 id);
    event PermanentURI(string _value, uint256 indexed _id);

    address private _signerAddress;

    constructor(address signerAddress_)
        ERC1155("https://metapython.herokuapp.com/api/box/")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _signerAddress = signerAddress_;
    }

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
        bytes memory data,
        string memory wlId,
        uint256 maxWLTokenNum, 
        bytes memory wlSignature
    ) public onlyOwner {
        require(
            maxWLTokenNum >= wlConsumed[wlId] + 1,
            "WL limit exceeded."
        );
        require(id > 0, "Id cannot be 0");
        require(id < 10000, "Id must be smaller than 10000");
        require(verify(wlId, maxWLTokenNum, msg.sender, wlSignature) == _signerAddress, "Voucher invalid");

        _mint(account, id, amount, data);
        emit Minted(account, id, amount);
        wlConsumed[wlId] += 1;
    }

    function wlMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(id > 0, "Id cannot be 0");
        require(id < 10000, "Id must be smaller than 10000");
        _mint(account, id, amount, data);
        emit Minted(account, id, amount);
    }

    //need to revise to verify signature then mint

    function permanentURI(string memory _value, uint256 _id) public onlyOwner {
        emit PermanentURI(_value, _id);
    }

    function merge(
        address account,
        uint256[] memory ids,
        bytes memory data
    ) public {
        require(ids.length > 1, "Cannot merge single element");
        require(ids.length < 11, "Cannot merge more than 10 elements");
        uint256 id = 0;
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ids[i] < 10000,
                "Cannot merge with elements that had been merged"
            );
            require(ids[i] > 0, "Basic element id cannot be 0");
            id += ids[i] * (10000**i);
            amounts[i] = 1;
        }

        require(id > 10000, "Merged id cannot be basic element id");
        _burnBatch(account, ids, amounts);
        _mint(account, id, 1, data);
        emit Merged(account, id, 1);
    }

    function split(
        address to,
        uint256 id,
        bytes memory data
    ) public {
        require(id > 10000, "Cannot split basic element");
        uint256 originalId = id;
        uint256 digits = 0;
        uint256 idCalLength = id;
        while (idCalLength != 0) {
            idCalLength /= 10000;
            digits++;
        }
        require(digits < 11, "Cannot be split into more than 10 elements");

        _burn(to, id, 1);

        uint256[] memory ids = new uint256[](digits);
        uint256[] memory amounts = new uint256[](digits);
        for (uint256 i = 0; i < digits; i++) {
            ids[i] = id % 10000;
            require(ids[i] > 0, "Basic element id cannot be 0");
            amounts[i] = 1;
            id = id / 10000;
        }

        _mintBatch(to, ids, amounts, data);
        emit Split(to, originalId);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0, "Id cannot be 0");
            require(ids[i] < 10000, "Id must be smaller than 10000");
        }
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

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function verify(
        string memory id,
        uint256 number,
        address minterAddress,
        bytes memory signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Web3Struct(string id,uint256 number,address address)"
                    ),
                    id,
                    number,
                    minterAddress
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }
}
