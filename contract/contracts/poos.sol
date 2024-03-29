// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.1/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts@4.7.1/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.1/security/Pausable.sol";
import "@openzeppelin/contracts@4.7.1/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts@4.7.1/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts@4.7.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts@4.7.1/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts@4.7.1/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts@4.7.1/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts@4.7.1/security/PullPayment.sol";
import "@openzeppelin/contracts@4.7.1/security/ReentrancyGuard.sol";

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

contract POOS is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    ERC1155URIStorage,
    EIP712,
    PullPayment,
    ContextMixin,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint256 cost_per_token_set = 0.05 ether;
    uint256 costFactor = 3;
    uint256 MAX_MINTS = 20480;

    uint256 tokensetMinted = 0;
    bool hasSaleStarted = false;

    string storeMetaURL = "https://metapython.herokuapp.com/api/store/";
    string private constant SIGNING_DOMAIN = "POOS";
    string private constant SIGNATURE_VERSION = "1";

    address proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private _signerAddress = 0xb3857ebb2BB273e72adaB45B3417D1c111f3b21b;
    address private _ranSignerAddress = 0x6813b289fA4BB595C6b851e55C9Ffe097f5F3E74;

    mapping(string => uint256) public wlConsumed;
    mapping(string => uint256) public ranConsumed;

    event Minted(address to, uint256 tokenId, uint256 amount);
    event wlMinted(address to, uint256 tokenId, uint256 amount);

    event MintedBatch(address to, uint256[] ids, uint256[] amounts);
    event Merged(address to, uint256 tokenId, uint256 amount);
    event Split(address to, uint256 id);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor()
        ERC1155("https://metapython.herokuapp.com/api/element/{id}")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
    }

    function getContractURI() public view returns (string memory) {
        return storeMetaURL;
    }

    function setStoreMetaURL(string memory _storeMetaURL) public onlyOwner {
        storeMetaURL = _storeMetaURL;
    }

    function permanentURI(string memory _value, uint256 _id) public onlyOwner {
        emit PermanentURI(_value, _id);
    }

    function setCost(uint256 _cost_per_token_set) public onlyOwner {
        cost_per_token_set = _cost_per_token_set;
    } 

    function getCost() public view returns (uint256){
        return cost_per_token_set;
    }

    function setCostFactor(uint256 _costFactor) public onlyOwner {
        costFactor = _costFactor;
    }

    function getCostFactor() public view returns (uint256){
        return costFactor;
    }
    function setSigner(address signerAddress_) public onlyOwner {
        _signerAddress = signerAddress_;
    }

    function setRanSigner(address ranSignerAddress_) public onlyOwner {
        _ranSignerAddress = ranSignerAddress_;
    }

    function setProxy(address _proxyAddress) public onlyOwner {
        proxyAddress = _proxyAddress;
    }

    function getProxy() public view returns (address) {
        return proxyAddress;
    }

    function setMaxMints(uint256 max_mints) public onlyOwner {
        MAX_MINTS = max_mints;
    }

    function getMaxMints() public view returns (uint256) {
        return MAX_MINTS;
    }   

    function getHasSaleStarted() public view returns (bool) {
        return hasSaleStarted;
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function getTokensetMinted() public view returns (uint256) {
        return tokensetMinted;
    }    

    function hasSoldOut() public view returns (bool) {
        if (getTokensetMinted() >= MAX_MINTS) {
            return true;
        } else {
            return false;
        }
    }

    function mint(
        string memory ranId,
        uint256 randomNumber,
        bytes memory ranSignature
    ) public payable nonReentrant {
        require(hasSaleStarted || msg.sender == owner(), "Public sale hasn't started");
        require(msg.sender == tx.origin, "Minting from smart contracts is not allowed");
        require(msg.value == cost_per_token_set * costFactor, "Incorrect Ether amount.");
        require(ranConsumed[ranId] + 1 <= 1, "Random number already used.");
        require(randomNumber > 0, "Id cannot be 0");
        require(
            verify(ranId, randomNumber, msg.sender, ranSignature) ==
                _ranSignerAddress,
            "Random number invalid"
        );
        require(
            tokensetMinted + 1 <= MAX_MINTS || msg.sender == owner(),
            "sold out"
        );

        _mint(msg.sender, randomNumber, 1, "0x00");
        emit Minted(msg.sender, randomNumber, 1);
        ranConsumed[ranId] += 1;
        tokensetMinted +=1;
    }

    function wlMint(
        string memory wlId,
        uint256 maxWLTokenNum,
        bytes memory wlSignature,
        string memory ranId,
        uint256 randomNumber,
        bytes memory ranSignature
    ) public payable nonReentrant {
        require(msg.sender == tx.origin, "Minting from smart contracts is not allowed");
        require(msg.value == cost_per_token_set, "Incorrect Ether amount.");
        require(maxWLTokenNum >= wlConsumed[wlId] + 1, "Whitelist limit exceeded.");
        require(ranConsumed[ranId] + 1 <= 1, "Random number already used.");
        require(randomNumber > 0, "Id cannot be 0");
        require(
            verify(wlId, maxWLTokenNum, msg.sender, wlSignature) ==
                _signerAddress,
            "Whitelist voucher invalid"
        );
        require(
            verify(ranId, randomNumber, msg.sender, ranSignature) ==
                _ranSignerAddress,
            "Random number invalid"
        );
        require(
            tokensetMinted + 1 <= MAX_MINTS || msg.sender == owner(),
            "sold out"
        );

        _mint(msg.sender, randomNumber, 1, "0x00");
        emit wlMinted(msg.sender, randomNumber, 1);
        wlConsumed[wlId] += 1;
        ranConsumed[ranId] += 1;
        tokensetMinted +=1;
    }

    function merge(
        uint256[] memory ids,
        bytes memory data
    ) public nonReentrant {
        require(ids.length > 1, "Cannot merge single element");
        require(ids.length < 11, "Cannot merge more than 10 elements");
        require(msg.sender == tx.origin, "Merging from smart contracts is not allowed");
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
        _burnBatch(msg.sender, ids, amounts);
        _mint(msg.sender, id, 1, data);
        emit Merged(msg.sender, id, 1);
    }

    function split(
        uint256 id,
        bytes memory data
    ) public nonReentrant {
        require(id > 10000, "Cannot split basic element");
        require(msg.sender == tx.origin, "Spliting from smart contracts is not allowed");
        uint256 originalId = id;
        uint256 digits = 0;
        uint256 idCalLength = id;
        while (idCalLength != 0) {
            idCalLength /= 10000;
            digits++;
        }
        require(digits < 11, "Cannot be split into more than 10 elements");

        _burn(msg.sender, id, 1);

        uint256[] memory ids = new uint256[](digits);
        uint256[] memory amounts = new uint256[](digits);
        for (uint256 i = 0; i < digits; i++) {
            ids[i] = id % 10000;
            require(ids[i] > 0, "Basic element id cannot be 0");
            amounts[i] = 1;
            id = id / 10000;
        }

        _mintBatch(msg.sender, ids, amounts, data);
        emit Split(msg.sender, originalId);
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
        if (_operator == address(proxyAddress)) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }
    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(tokenId);
    }
    
    function setTokenURI(uint256 tokenId, string memory tokenURI)
        public
        onlyOwner
    {
        _setURI(tokenId, tokenURI);
    }

    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
        nonReentrant
    {
        super.withdrawPayments(payee);
    }

    function asyncTransfer(address payable dest, uint256 amount)
        public
        onlyOwner
    {
        _asyncTransfer(dest, amount);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function verify(
        string memory id,
        uint256 number,
        address minterAddress,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Web3Struct(string id,uint256 number,address address)"
                    ),
                    keccak256(bytes(id)),
                    number,
                    minterAddress
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }
}