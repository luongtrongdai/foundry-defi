//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    error MoodNft__OnlyOwnerCanChangeMood();

    enum MoodType {
        HAPPY,
        SAD
    }
    uint256 private s_tokenCounter;
    string private s_sadSvg;
    string private s_happySvg;
    mapping(uint256 => MoodType) private s_tokenIdToMood;

    constructor(string memory name_, string memory symbol_,
        string memory happySvg_, string memory sadSvg_) ERC721(name_, symbol_) {
        s_happySvg = happySvg_;
        s_sadSvg = sadSvg_;
    }

    function mintNft() public {
        uint256 tokenId = s_tokenCounter;
        _safeMint(_msgSender(), tokenId);
        s_tokenIdToMood[tokenId] = MoodType.HAPPY;
        s_tokenCounter = tokenId + 1;
    }

    function flipMood(uint256 tokenId) public {
        if (getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender) {
            revert MoodNft__OnlyOwnerCanChangeMood();
        }

        MoodType moodType = s_tokenIdToMood[tokenId];
        if (moodType == MoodType.HAPPY) {
            s_tokenIdToMood[tokenId] = MoodType.SAD;
        } else {
            s_tokenIdToMood[tokenId] = MoodType.HAPPY;
        } 
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Base64.encode(
            bytes(
                abi.encodePacked('{"name": "', name(), '", "description": "My demo NFT", "image": "',
                getImageUri(s_tokenIdToMood[tokenId]), '", "attributes": [{"trait_type": "moodiness","value": 100}]}')
            ))));
    }

    function getImageUri(MoodType mood) internal view returns (string memory) {
        if (mood == MoodType.HAPPY) {
            return s_happySvg;
        }
        return s_sadSvg;
    }
}