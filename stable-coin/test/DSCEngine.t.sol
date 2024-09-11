// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";

contract DSCEngineTest is Test {
    address USER = makeAddr("defaultUser");
    uint256 constant STARTING_BALANCE = 10 ether;

    DecentralizedStableCoin private dsc;
    DSCEngine private dscEngine;

    function setUp() external {
        DeployDSC deploy = new DeployDSC();
        deploy.run();

        dsc = deploy.dsc();
        dscEngine = deploy.dscEngine();

        vm.deal(USER, STARTING_BALANCE);
    }
}
