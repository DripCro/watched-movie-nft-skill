---
name: watched-movie-nft
description: Mint an ERC-721 NFT on Base for every movie you watch, with movie metadata (title, year, genre, poster) pulled from the iTunes Search API. One contract per user, owner-only mint, on-chain tokenURI via base64 data URI.
---

# Watched Movie NFT

Mint a permanent on-chain memento for each movie you watch. Collection: "Watched Movies" (WATCHED), ERC-721 + URIStorage + Ownable (OpenZeppelin 5.1.0).

## Contract

- Source: `contracts/WatchedMovies.sol` (Solidity 0.8.24+, compiled with solc 0.8.28, optimizer 200 runs)
- Chain: Base (8453)
- Deployment: deterministic CREATE2 via the canonical deterministic-deployment-proxy at `0x4e59b44847b379578588920cA78FbF26c0B4956C`
- Constructor arg: owner address (only owner can mint)
- Mint function: `mint(address to, string uri) returns (uint256 tokenId)` — auto-incrementing tokenId starting at 0

## Deploy (Path B — raw CREATE2, no private key in sandbox)

1. Compile in the Bankr sandbox with `scripts/compile.js` (packages: `solc@0.8.28`, `@openzeppelin/contracts@5.1.0`, `viem@2.21.0`). It prints:
   - PREDICTED_ADDRESS (CREATE2 address)
   - the full deploy payload = `salt (32 bytes) ++ initcode (bytecode ++ abi-encoded owner)`
2. Broadcast with `submit_raw_transaction` to `0x4e59b44847b379578588920cA78FbF26c0B4956C` on Base, `data` = payload, `value` = 0.
   - Requires "arbitrary contract calls" ENABLED in Bankr Security settings.
3. Verify with `read_contract`: `owner() view returns (address)` at the predicted address.

Deployed instances:
- owner 0x35f3563c4bfc804bf60568bd7d2436d58be8064f → predicted address `0x8dCd5077514B2F18b80ACa553b575fc4a9B8D200` (salt keccak256("watched-movies-v1-0x35f3563c4bfc804bf60568bd7d2436d58be8064f"))

## Minting a movie

1. Fetch movie metadata (iTunes Search API, no key needed):
   `curl -s 'https://itunes.apple.com/search?term=<movie+name>&entity=movie&limit=1'`
   Extract: trackName, releaseDate (year), primaryGenreName, artworkUrl100 (replace `100x100` with `600x600` for the poster).
2. Build ERC-721 metadata JSON:
   `{"name":"<title> (<year>)","description":"Watched on <date>. <genre>.","image":"<poster url>","attributes":[{"trait_type":"Genre","value":"<genre>"},{"trait_type":"Year","value":"<year>"},{"trait_type":"Watched","value":"<ISO date>"}]}`
3. Encode as data URI: `data:application/json;base64,<base64(json)>` (base64 it in the sandbox with `bun -e`).
4. Call `write_contract` on Base:
   - to: the deployed contract
   - functionSignature: `mint(address to, string uri)`
   - args: [owner wallet, data URI]

## Notes

- Only the contract owner can mint; anyone can view.
- tokenURI is fully self-contained (base64 data URI) — no IPFS pinning needed, but poster image is a hotlink to iTunes CDN. For permanence, swap image to an IPFS upload later.
- To mint from X timeline posts: parse the movie title from the post text, then follow the minting steps above.
