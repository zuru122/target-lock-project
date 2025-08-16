// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployTargetLock} from "../script/DeployTargetLock.s.sol";
import {TargetLock} from "../src/TargetLock.sol";

contract TargetLockTest is Test {
    TargetLock public targetLock;
    DeployTargetLock public deployer;

    uint256 public constant TARGETAMOUNT = 10 ether;

    // address bob = makeAddr("bob");

    function setUp() public {
        deployer = new DeployTargetLock();
        targetLock = deployer.run();
    }

    // test owner
    function testIsOwner() public view {
        assertEq(targetLock.owner(), msg.sender);
    }

    // test that the target amount is stored correctlly
}
