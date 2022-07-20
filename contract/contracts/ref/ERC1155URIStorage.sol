// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _urisStored;

    /**
     * @dev See {IERC1155Metadata-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {

        string memory _tokenURI = _urisStored[tokenId];
        string memory base = super.uri(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return string(abi.encodePacked(_tokenURI, "{id}"));
        }
        // If both are set, concatenate the baseURI and uri (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, "{id}"));
        }

        return string(abi.encodePacked(super.uri(tokenId), "{id}"));
    }

    /**
     * @dev Sets `_tokenURI` as the uri of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        // require(exists(tokenId), "ERC1155URIStorage: URI set of nonexistent token");
        _urisStored[tokenId] = _tokenURI;
    }
}
