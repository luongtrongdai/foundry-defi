// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.26;

// 2. Imports
import {Test, console} from "forge-std/Test.sol";
import {ManualTokenScript} from "script/ManualToken.s.sol";
import {ManualToken} from "src/ManualToken.sol";

// 3. Interfaces, Libraries, Contracts
contract ManualTokenTest is Test {
    uint256 public constant INITIAL_BALANCE = 10 ether;

    ManualToken public manualToken;
    address private bob = makeAddr("bob");
    address private alice = makeAddr("alice");

    function setUp() external {
        ManualTokenScript script = new ManualTokenScript();
        script.run();
        manualToken = script.manualToken();
    }

    modifier allowance() {
        vm.prank(msg.sender);
        manualToken.approve(alice, INITIAL_BALANCE);
        _;
    }

    function test_Initial() external view {
        assertEq(manualToken.symbol(), "MT");
        assertEq(manualToken.name(), "ManualToken");
        assertEq(manualToken.decimals(), 18);
        assertEq(1000 ether, manualToken.balanceOf(msg.sender));
    }

    function test_Transfer() external {
        vm.prank(msg.sender);
        manualToken.transfer(bob, INITIAL_BALANCE);

        assertEq(manualToken.balanceOf(bob), INITIAL_BALANCE);
    }

    function test_Allowances() public allowance {        
        assertEq(manualToken.allowance(msg.sender, alice), INITIAL_BALANCE);
    }

    function test_TransferFrom() public allowance {
        uint256 senderBalance = manualToken.balanceOf(msg.sender);
        
        vm.prank(alice);
        manualToken.transferFrom(msg.sender, bob, 1 ether);
        assertEq(senderBalance - 1 ether, manualToken.balanceOf(msg.sender));
        assertEq(INITIAL_BALANCE - 1 ether, manualToken.allowance(msg.sender, alice));
    }
}