// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployTargetLock} from "../script/DeployTargetLock.s.sol";
import {TargetLock} from "../src/TargetLock.sol";

contract TargetLockTest is Test {
    TargetLock public targetLock;
    DeployTargetLock public deployer;

    uint256 public constant TARGETAMOUNT = 10 ether;

    function setUp() public {
        deployer = new DeployTargetLock();
        targetLock = deployer.run();
    }

    //_____ 1. Constructor & Deployment ______

    // test owner
    function testIsOwner() public view {
        assertEq(targetLock.owner(), msg.sender);
    }

    // test that the target amount is stored correctlly
    function testTargetAmountIsStoredCorrectly() public {
        TargetLock lock = new TargetLock(2 ether);
        assertEq(lock.targetAmount(), 2 ether);
    }

    // Initial balance is 0
    function testInitialBalanceIsZero() public view {
        address _addr = targetLock.owner();
        assertEq(targetLock.getBalance(_addr), 0 ether);
    }

    // _____2. Saving Funds (save) _____

    // test that Saving increases balance
    function testSavingsIncreases() public {
        address _addr = targetLock.owner();
        vm.prank(_addr);
        targetLock.save{value: 1 ether}();
        assertEq(targetLock.getBalance(_addr), 1 ether);
    }

    // Fails if savings < targetAmount
    function test_RevertIfSavingIsLessThanTargetAmount() public {
        vm.startPrank(targetLock.owner());
        vm.expectRevert(
            abi.encodeWithSelector(
                TargetLock.TargetAmountNotReached.selector,
                0,
                targetLock.targetAmount()
            )
        );
        targetLock.withdraw(1 ether);
        vm.stopPrank();
    }

    // Succeeds if savings >= targetAmount
    function testSuccedIfSavingsIsOrAboveTargetAmount() public {
        address _addr = targetLock.owner();
        vm.startPrank(_addr);
        targetLock.save{value: 5 ether}();

        vm.expectEmit(true, true, false, true);
        emit TargetLock.Withdraw(5 ether, _addr);

        targetLock.withdraw(5 ether);
        vm.stopPrank();
    }

    // revert if targetAmount is reached but withdrawal is more than targetAmount
    function test_RevertIfWithdrawMoreThanBlance() public {
        address _addr = targetLock.owner();
        vm.startPrank(_addr);
        targetLock.save{value: 5 ether}();
        vm.expectRevert();
        targetLock.withdraw(6 ether);
        vm.stopPrank();
    }

    // revert if not owner
    function test_RevertIfNonOwnerWithdraws() public {
        vm.expectRevert(TargetLock.OnlyOwnerCanWithdraw.selector);
        targetLock.withdraw(1 ether);
    }
}
