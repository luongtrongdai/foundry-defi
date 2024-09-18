// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract InvariantsTest is StdInvariant, Test {
    DecentralizedStableCoin private dsc;
    DSCEngine private dscEngine;
    HelperConfig private helperConfig;
    Handler private handler;

    function setUp() external {
        DeployDSC deploy = new DeployDSC();
        deploy.run();

        dsc = deploy.dsc();
        dscEngine = deploy.dscEngine();
        helperConfig = deploy.helperConfig();
        handler = new Handler(dscEngine, dsc, helperConfig);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() external view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 protocolValue;

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        uint256 numberToken = networkConfig.tokenAddrs.length;
        for (uint256 i = 0; i < numberToken;) {
            address tokenAddr = networkConfig.tokenAddrs[i];
            uint256 tokenBalance = IERC20(tokenAddr).balanceOf(address(dscEngine));
            protocolValue += dscEngine.getTokenPrice(tokenAddr, tokenBalance);
            unchecked {
                i = i + 1;
            }
        }
        assert(protocolValue >= totalSupply);
        console.log("timesMintIsCalled: ", handler.timesMintIsCalled());
        console.log("protocolValue: ", protocolValue);
        console.log("totalSupply: ", totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        dscEngine.getMinHealthFactor();
        address token = dscEngine.getCollateralToken(0);
        dscEngine.getPriceFeed(token);
    }
}
