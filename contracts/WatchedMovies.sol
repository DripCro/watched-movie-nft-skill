// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}

/// @title Watched Movies (v2 — $0.05 mint fee)
/// @notice One collection per user (owner-only mint). Each mint costs $0.05 in ETH,
///         priced live via Chainlink ETH/USD on Base, paid to the skill creator.
///         The fee recipient mints free on their own collection.
contract WatchedMovies is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    /// @notice Skill creator wallet — receives the mint fee
    address public constant FEE_RECIPIENT = 0x35f3563C4BFc804bf60568bd7d2436d58be8064f;

    /// @notice Chainlink ETH/USD feed on Base
    AggregatorV3Interface public constant ETH_USD_FEED =
        AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70);

    /// @notice Mint fee in US cents ($0.05)
    uint256 public constant MINT_FEE_USD_CENTS = 5;

    constructor(address initialOwner) ERC721("Watched Movies", "WATCHED") Ownable(initialOwner) {}

    /// @notice Current mint fee in wei (ETH equivalent of $0.05)
    function mintFeeWei() public view returns (uint256) {
        (, int256 answer, , , ) = ETH_USD_FEED.latestRoundData();
        require(answer > 0, "bad price feed answer");
        return (MINT_FEE_USD_CENTS * 1e18 * (10 ** ETH_USD_FEED.decimals())) / (100 * uint256(answer));
    }

    /// @notice Mint a watched-movie NFT. Send msg.value >= mintFeeWei().
    ///         Entire msg.value is forwarded to FEE_RECIPIENT. Fee waived when
    ///         the fee recipient mints on their own collection.
    function mint(address to, string memory uri) external payable onlyOwner returns (uint256 tokenId) {
        if (msg.sender != FEE_RECIPIENT) {
            require(msg.value >= mintFeeWei(), "insufficient mint fee: send >= mintFeeWei()");
            (bool ok, ) = FEE_RECIPIENT.call{value: msg.value}("");
            require(ok, "fee transfer failed");
        } else if (msg.value > 0) {
            (bool ok, ) = FEE_RECIPIENT.call{value: msg.value}("");
            require(ok, "return transfer failed");
        }
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
