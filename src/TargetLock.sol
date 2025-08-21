// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Take in the targeted amount
//  Set the owner
//  function to check if targeted amount is reached
// function for withdrawal

contract TargetLock {
    error TargetAlreadySet();
    error TargetAmountNotReached(uint256 current, uint256 required);
    error WithdrawTimeNotReached(uint256 currentTime, uint256 unlockTime);
    error NoSavingsFound();

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
        bool initialized;
    }

    mapping(address => Saver) public savers;

    // event
    event Save(uint256 indexed _amount, address _addr);
    event Withdraw(uint256 indexed _amount, address _addr);

    // ----------- SETUP (one-time) -----------

    // Save based on Amount or Time based
    function initAmountBased(uint256 _targetAmount) external payable {
        require(msg.value > 0, "Must send some ETH");
        Saver storage saver = savers[msg.sender];
        if (saver.initialized) revert TargetAlreadySet();

        saver.balance = msg.value;
        saver.mode = Mode.AmountBased;
        saver.targetAmount = _targetAmount;
        saver.initialized = true;

        emit Save(msg.value, msg.sender);
    }

    function initTimeBased(uint256 _unlockTime) external payable {
        require(msg.value > 0, "Must send some ETH");
        Saver storage saver = savers[msg.sender];
        if (saver.initialized) revert TargetAlreadySet();

        saver.balance = msg.value;
        saver.mode = Mode.TimeBased;
        saver.unlockTime = _unlockTime;
        saver.initialized = true;

        emit Save(msg.value, msg.sender);
    }

    // ----------- SAVING -----------

    function save() external payable {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NoSavingsFound();
        require(msg.value > 0, "Must send ETH");

        saver.balance += msg.value;

        emit Save(msg.value, msg.sender);
    }

    // ----------- CHECK BALANCE -----------

    function getBalance(address _user) public view returns (uint256) {
        return savers[_user].balance;
    }

    // withdraw
    function withdraw() external {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NoSavingsFound();
        uint256 userBalance = saver.balance;
        require(userBalance > 0, "Nothing to withdraw");

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

        // withdraw ALL
        saver.balance = 0;
        saver.initialized = false; // reset so user can start a new target if they want

        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        require(success, "Withdrawal failed");

        emit Withdraw(userBalance, msg.sender);
    }

    // Allow contract to receive ETH
    receive() external payable {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NoSavingsFound();
        saver.balance += msg.value;
        emit Save(msg.value, msg.sender);
    }
}
