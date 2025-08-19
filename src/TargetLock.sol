// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Take in the targeted amount
//  Set the owner
//  function to check if targeted amount is reached
// function for withdrawal

contract TargetLock {
    error TargetAmountNotReached(uint256, uint256 _targetAmount);
    error OnlyOwnerCanWithdraw();
    error WithdrawTimeNotReached(uint256 currentTime, uint256 unlockTime);

    // enum
    enum Mode {
        AmountBased,
        TimeBased
    }

    // struct
    struct Saver {
        uint256 balance;
        uint256 targetAmount;
        uint256 unlockTime;
        Mode mode;
    }

    address public owner;

    mapping(address => Saver) public savers;

    // event
    event Save(uint256 indexed _amount, address _addr);
    event Withdraw(uint256 indexed _amount, address _addr);

    constructor() {
        owner = msg.sender;
    }

    // Save based on Amount or Time based
    function saveAmountBased(uint256 _targetAmount) public payable {
        require(msg.value > 0, "Must send some ETH");
        Saver storage saver = savers[msg.sender];
        saver.balance += msg.value;
        saver.mode = Mode.AmountBased;
        saver.targetAmount = _targetAmount;

        emit Save(msg.value, msg.sender);
    }

    function saveTimeBased(uint256 _unlockTime) public payable {
        require(msg.value > 0, "Must send some ETH");
        Saver storage saver = savers[msg.sender];
        saver.balance += msg.value;
        saver.mode = Mode.TimeBased;
        saver.unlockTime = _unlockTime;

        emit Save(msg.value, msg.sender);
    }

    // modifier onlyOwner() {
    //     if (owner != msg.sender) {
    //         revert OnlyOwnerCanWithdraw();
    //     }
    //     _;
    // }

    function getBalance(address _user) public view returns (uint256) {
        return savers[_user].balance;
    }

    // withdraw
    function withdraw(uint256 _amount) public {
        Saver storage saver = savers[msg.sender];
        uint256 userBalance = saver.balance;

        require(_amount <= userBalance, "Not enough savings");

        if (saver.mode == Mode.AmountBased) {
            if (userBalance < saver.targetAmount) {
                revert TargetAmountNotReached(userBalance, saver.targetAmount);
            }
        } else {
            if (block.timestamp < saver.unlockTime) {
                revert WithdrawTimeNotReached(
                    block.timestamp,
                    saver.unlockTime
                );
            }
        }

        saver.balance -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdraw(_amount, msg.sender);
    }

    // Allow contract to receive ETH
    receive() external payable {
        Saver storage saver = savers[msg.sender];
        saver.balance += msg.value;
        emit Save(msg.value, msg.sender);
    }
}
