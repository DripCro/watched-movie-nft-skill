// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title WatchedMovies - mint an NFT for every movie you watch
contract WatchedMovies is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;

    constructor(address owner_) ERC721("Watched Movies", "WATCHED") Ownable(owner_) {}

    function mint(address to, string calldata uri) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
