// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract Handler is Test {
    DSCEngine private dscEngine;
    DecentralizedStableCoin private dsc;
    HelperConfig private helperConfig;

    uint256 public timesMintIsCalled;
    address[] public userDeposited;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc, HelperConfig _helperConfig) {
        dscEngine = _dscEngine;
        dsc = _dsc;
        helperConfig = _helperConfig;
    }

    // Redeem collateral <-

    function depositCollateral(uint256 collateralSeed, uint256 amount) external {
        ERC20Mock token = _getCollateralFromSeed(collateralSeed);
        amount = bound(amount, 1, type(uint96).max);
        vm.startPrank(msg.sender);
        token.mint(msg.sender, amount);
        token.approve(address(dscEngine), amount);
        dscEngine.depositCollateral(address(token), amount);
        vm.stopPrank();
        userDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amount) external {
        ERC20Mock token = _getCollateralFromSeed(collateralSeed);
        uint256 maxRedeemAmount = dscEngine.getCollateralDeposited(msg.sender, address(token));
        if (maxRedeemAmount == 0) {
            return;
        }
        amount = bound(amount, 1, maxRedeemAmount);
        vm.prank(msg.sender);
        dscEngine.redeemCollateral(address(token), amount);
    }

    function mintDSC(uint256 amount, uint256 userAddrSeed) public {
        uint256 totalDepositedUser = userDeposited.length;
        if (totalDepositedUser == 0) {
            return;
        }
        address sender = userDeposited[userAddrSeed % totalDepositedUser];
        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = dscEngine.getAccountInfo(sender);
        uint256 maxDSCToMinted = (collateralValueInUSD / 2) - totalDSCMinted;
        if (maxDSCToMinted <= 0) {
            return;
        }
        amount = bound(amount, 1, maxDSCToMinted);
        console.log("mintDSC: ", amount);
        vm.startPrank(sender);
        dscEngine.mintDSC(amount);
        vm.stopPrank();
        timesMintIsCalled += 1;
    }

    // function burnDSC(uint256 amount, uint256 userAddrSeed) public {
    //     console.log("burnDSC: ", amount);
    //     uint256 totalDepositedUser = userDeposited.length;
    //     if (totalDepositedUser == 0) {
    //         return;
    //     }
    //     address sender = userDeposited[userAddrSeed % totalDepositedUser];
    //     amount = dsc.balanceOf(sender);
    //     if (amount <= 0) {
    //         return;
    //     }
    //     //amount = bound(amount, 0, maxDSCToBurn);
    //     vm.startPrank(sender);
    //     dsc.approve(address(dscEngine), amount);
    //     dscEngine.burnDSC(amount);
    //     vm.stopPrank();
    // }

    function liquidate(uint256 collateralSeed, address userToBeLiquidated, uint256 debtToCover) public {
        uint256 minHealthFactor = dscEngine.getMinHealthFactor();
        uint256 userHealthFactor = dscEngine.getHealthFactor(userToBeLiquidated);
        if (userHealthFactor >= minHealthFactor) {
            return;
        }
        debtToCover = bound(debtToCover, 1, uint256(type(uint96).max));
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        dscEngine.liquidate(address(collateral), userToBeLiquidated, debtToCover);
    }

    function _getCollateralFromSeed(uint256 _seed) private view returns (ERC20Mock) {
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        uint256 index = _seed % networkConfig.tokenAddrs.length;

        return ERC20Mock(networkConfig.tokenAddrs[index]);
    }
}
