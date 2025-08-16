// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TargetLock} from "../src/TargetLock.sol";

contract DeployTargetLock is Script {
    TargetLock public targetLock;

    uint256 constant TARGET = 5 ether;

    // function setUp() public {}

    function run() external returns (TargetLock) {
        vm.startBroadcast();
        targetLock = new TargetLock(TARGET);
        vm.stopBroadcast();
        return targetLock;
    }
}
