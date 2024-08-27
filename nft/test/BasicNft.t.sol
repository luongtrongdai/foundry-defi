// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {Test, console} from "forge-std/Test.sol";
import {BasicNftScript} from "script/BasicNft.s.sol";
import {BasicNft} from "src/BasicNft.sol";

contract BasicNftTest is Test {
    address private USER = makeAddr("user");
    BasicNft private basicNft;

    function setUp() external {
         BasicNftScript script = new BasicNftScript();

         script.run();
         basicNft = script.basicNft();
    }

    function test_Init() external view {
        assertEq(basicNft.name(), "GameFi");
        assertEq(basicNft.symbol(), "KEN");
        assertEq(basicNft.tokenCounter(), 0);
    }

    function test_Mint() external {
        string memory uri = "ipfs://testttt";

        vm.prank(USER);
        basicNft.mint(uri);

        assertEq(uri, basicNft.tokenURI(0));
        assertEq(USER, basicNft.ownerOf(0));
        assertEq(1, basicNft.balanceOf(USER));
    }
}