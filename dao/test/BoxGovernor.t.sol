// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BoxGovernor} from "src/BoxGovernor.sol";
import {TimeLock} from "src/TimeLock.sol";
import {Box} from "src/Box.sol";
import {GovToken} from "src/GovToken.sol";

contract BoxGovernorTest is Test {
    uint256 private constant MIN_DELAY = 3600; // 1 hour
    uint256 private constant VOTING_DELAY = 7200; // 1 day
    uint256 private constant VOTING_PERIOD = 50400; // 1 week

    BoxGovernor private boxGovernor;
    GovToken private govToken;
    Box private box;
    TimeLock private timeLock;
    address private USER = makeAddr("user");
    address[] private proposers;
    address[] private executors;
    uint256[] private values;
    bytes[] private callDatas;
    address[] private targets;

    function setUp() external {
        govToken = new GovToken(address(this));
        govToken.mint(USER, 10 ether);

        vm.startPrank(USER);
        govToken.delegate(USER);
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);
        boxGovernor = new BoxGovernor(govToken, timeLock);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(boxGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function test_CantUpdateBoxWithoutGovernance() external {
        vm.expectRevert();

        box.storeNumber(1);
    }

    function test_GovernanceCanUpdateBox() external {
        uint256 newNumber = 888;
        string memory description = "store to the box";
        bytes memory callData = abi.encodeWithSignature("storeNumber(uint256)", newNumber);
        callDatas.push(callData);
        values.push(0);
        targets.push(address(box));

        uint256 proposalId = boxGovernor.propose(targets, values, callDatas, description);
        assertEq(uint256(boxGovernor.state(proposalId)), 0);
        vm.warp(block.timestamp + boxGovernor.votingDelay() + 1);
        vm.roll(block.number + boxGovernor.votingDelay() + 1);

        console.log("state: ", uint256(boxGovernor.state(proposalId)));
        console.log("timestamp: ", block.timestamp);
        console.log("block number: ", block.number);

        // cast vote
        string memory reason = "reason";
        vm.prank(USER);
        uint256 castResult = boxGovernor.castVoteWithReason(proposalId, 1, reason);
        console.log("castResult: ", castResult);

        vm.warp(block.timestamp + boxGovernor.votingPeriod() + 1);
        vm.roll(block.number + boxGovernor.votingPeriod() + 1);

        // queue tx before excute
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        vm.prank(USER);
        uint256 queueId = boxGovernor.queue(targets, values, callDatas, descriptionHash);
        assertEq(queueId, proposalId);

        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);
        // execute
        uint256 executeId = boxGovernor.execute(targets, values, callDatas, descriptionHash);

        assertEq(executeId, proposalId);
        assertEq(box.getNumber(), newNumber);
    }
}
