// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "script/DeployBox.s.sol";
import {UpgradeBox} from "script/UpgradeBox.s.sol";
import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");

    BoxV1 public boxV1;
    BoxV2 public boxV2;

    function setUp() external {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();

        boxV1 = BoxV1(deployer.run());
    }

    function test_BoxVersionIs1() external view {
        assertEq(1, boxV1.version());
    }

    function test_UpgradeBox() external {
        boxV2 = new BoxV2();

        upgrader.upgradeBox(address(boxV1));
        assertEq(2, boxV1.version());
    }
}
