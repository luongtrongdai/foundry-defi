// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// 3. Interfaces, Libraries, Contracts
contract BasicNft is ERC721 {
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(string memory tokenURI_) public {
        uint256 tokenId = s_tokenCounter;

        s_tokenIdToUri[tokenId] = tokenURI_;
        s_tokenCounter = tokenId + 1;
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }

    function tokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }
}
