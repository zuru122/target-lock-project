// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployTargetLock} from "../script/DeployTargetLock.s.sol";
import {TargetLock} from "../src/TargetLock.sol";

contract TargetLockTest is Test {
    TargetLock public targetLock;
    DeployTargetLock public deployer;

    uint256 public constant TARGETAMOUNT = 10 ether;

    // address user = makeAddr("user");

    function setUp() public {
        deployer = new DeployTargetLock();
        targetLock = deployer.run();
    }

    // Check that the contract deploys with owner == deployer
    function testContractDeployerIsOwner() public {
        address user = makeAddr("user");
        vm.prank(user); // next call will come from "user"
        TargetLock deployed = new TargetLock();
        assertEq(deployed.owner(), user);
    }
}
