// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {MockAggregatorV3} from "./mocks/MockAggregatorV3.sol";

contract DSCEngineTest is Test {
    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant APPROVED_TOKEN_BALANCE = 10 ether;

    DecentralizedStableCoin private dsc;
    DSCEngine private dscEngine;

    function setUp() external {
        DeployDSC deploy = new DeployDSC();
        deploy.run();

        dsc = deploy.dsc();
        dscEngine = deploy.dscEngine();

        address depositToken = dscEngine.getCollateralToken(0);
        ERC20Mock(depositToken).mint(BOB, STARTING_BALANCE);
        vm.prank(BOB);
        ERC20Mock(depositToken).approve(address(dscEngine), APPROVED_TOKEN_BALANCE);
    }

    function test_DSCEngineInitSuccess() external view {
        address depositToken = dscEngine.getCollateralToken(0);
        assert(dscEngine.getPriceFeed(depositToken) != address(0));
        assertEq(address(dsc), dscEngine.getDSC());
        assertEq(dsc.owner(), address(dscEngine));
    }

    function test_DepositCollateralRevertIfTokenNotAllow() external {
        vm.expectRevert();
        dscEngine.depositCollateral(msg.sender, 1000);
    }

    function test_DepositCollateralRevertIfAmountIsZero() external {
        address depositToken = dscEngine.getCollateralToken(0);
        vm.expectRevert();
        dscEngine.depositCollateral(depositToken, 0);
    }

    function test_DepositCollateralRevertIfUserNotEnoughToken() external {
        address depositToken = dscEngine.getCollateralToken(0);
        vm.expectRevert();
        vm.prank(ALICE);
        dscEngine.depositCollateral(depositToken, 10);
    }

    function test_DepositCollateralSuccess() external {
        address depositToken = dscEngine.getCollateralToken(0);
        vm.prank(BOB);
        dscEngine.depositCollateral(depositToken, 1 ether);

        assertEq(1 ether, dscEngine.getCollateralDeposited(BOB, depositToken));
    }

    function test_GetAccountCollateralValue() external {
        address depositToken = dscEngine.getCollateralToken(0);
        address priceFeed = dscEngine.getPriceFeed(depositToken);
        (, int256 price,,,) = MockAggregatorV3(priceFeed).latestRoundData();
        vm.prank(BOB);
        dscEngine.depositCollateral(depositToken, 1 ether);
        console.log(price);

        assertEq(
            uint256(price) * 1 ether / 10 ** MockAggregatorV3(priceFeed).decimals(),
            dscEngine.getAccountCollateralValue(BOB)
        );
    }
}
