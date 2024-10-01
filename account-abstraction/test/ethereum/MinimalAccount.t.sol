// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";
import {MinimalAccountScript} from "script/MinimalAccount.s.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SendPackedUserOp, PackedUserOperation} from "script/SendPackedUserOp.s.sol";

contract MinimalAccountTest is Test {
    address private PLAYER = makeAddr("player");

    MinimalAccount private minimalAccount;
    HelperConfig private helperConfig;
    ERC20Mock private token;
    address private configEntryPoint;
    address private configAccount;
    SendPackedUserOp private sendPackedUserOp;

    function setUp() external {
        MinimalAccountScript deployScript = new MinimalAccountScript();
        deployScript.run();

        minimalAccount = deployScript.minimalAccount();
        helperConfig = deployScript.helperConfig();
        (configEntryPoint, configAccount) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, 1 ether);
        vm.deal(address(minimalAccount), 1 ether);

        token = new ERC20Mock();
        token.mint(configAccount, 2 ether);

        sendPackedUserOp = new SendPackedUserOp();
    }

    function test_MinimalAccountInit() external view {
        IEntryPoint entryPoint = minimalAccount.getEntryPoint();
        address owner = minimalAccount.owner();
        assert(address(entryPoint) == configEntryPoint);
        assert(owner == configAccount);
    }

    function test_MinimalAccountOnlyEntryPointAndOwnerCanExecute() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                MinimalAccount.MinimalAccount__OnlyAcceptRequestFromEntryPointOrOwner.selector, PLAYER
            )
        );
        vm.prank(PLAYER);
        minimalAccount.execute(configAccount, 1 ether, "");
    }

    function test_MinimalAccountOwnerCanExecute() external {
        uint256 prevBalance = token.balanceOf(configAccount);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, configAccount, 1 ether);
        vm.prank(configAccount);
        minimalAccount.execute(address(token), 0, functionData);
        uint256 currentBalance = token.balanceOf(configAccount);
        assertEq(prevBalance + 1 ether, currentBalance);
    }

    function test_RecoverSignedOp() external view {
        assertEq(token.balanceOf(address(minimalAccount)), 0);

        address dest = address(token);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), 1 ether);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        PackedUserOperation memory packedUserOperation =
            sendPackedUserOp.generatedSignedUserOp(executeCallData, address(minimalAccount), helperConfig);
        bytes32 userOpHash = IEntryPoint(configEntryPoint).getUserOpHash(packedUserOperation);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        (address sender,,) = ECDSA.tryRecover(digest, packedUserOperation.signature);
        assertEq(sender, minimalAccount.owner());
    }

    function test_MinimalAccountValidationUserOp() external {
        address dest = address(token);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), 1 ether);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        PackedUserOperation memory packedUserOperation =
            sendPackedUserOp.generatedSignedUserOp(executeCallData, address(minimalAccount), helperConfig);
        bytes32 userOpHash = IEntryPoint(configEntryPoint).getUserOpHash(packedUserOperation);
        uint256 currentBalance = configEntryPoint.balance;
        vm.prank(configEntryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOperation, userOpHash, 1 ether);
        assertEq(validationData, SIG_VALIDATION_SUCCESS);
        assertEq(currentBalance + 1 ether, configEntryPoint.balance);
    }

    function test_EntryPointCanExecuteCommand() external {
        assertEq(token.balanceOf(address(minimalAccount)), 0);

        address dest = address(token);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), 1 ether);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, 0, functionData);
        PackedUserOperation memory packedUserOperation =
            sendPackedUserOp.generatedSignedUserOp(executeCallData, address(minimalAccount), helperConfig);

        PackedUserOperation[] memory packedUserOpParam = new PackedUserOperation[](1);
        packedUserOpParam[0] = packedUserOperation;
        vm.prank(PLAYER);
        IEntryPoint(configEntryPoint).handleOps(packedUserOpParam, payable(PLAYER));

        assertEq(token.balanceOf(address(minimalAccount)), 1 ether);
    }
}
