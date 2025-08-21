// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Take in the targeted amount / date
// check balance
//  check if targeted amount / date is met
//  withdrawal

/// @title TargetLock - Self-custodial savings vault (amount-based or time-based)
/// @notice Pick a mode & goal once, then deposit until it matures. withdrawal are all or nothing
/// @dev No global owner; each address controls only it's own vault.

contract TargetLock {
    // ---------- Errors ----------
    error AlreadyInitialized();
    error NotInitialized();
    error ZeroDeposit();
    error NothingToWithdraw();
    error AmountTargetNotReached(uint256 current, uint256 required);
    error TimeTargetNotReached(uint256 nowTs, uint256 unlockTime);
    error WrongMode();

    // ---------- Reentrancy Guard ----------
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        if (_status == _ENTERED) revert();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // ---------- Types / Storage ----------
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

    // ---------- event ----------
    event GoalInitialized(
        address indexed user,
        Mode mode,
        uint256 targetAmount,
        uint256 unlockTime,
        uint256 firstDeposit
    );
    event Save(
        address indexed from,
        address indexed user,
        uint256 amount,
        uint256 newBalance
    );
    event WithdrawAll(address indexed user, uint256 amount);

    // ----------- SETUP (one-time) -----------

    // Save based on Amount or Time based.
    /// @notice Initialize an amount-based goal and deposit the first ETH.
    function initAmountBased(uint256 targetAmount) external payable {
        if (msg.value == 0) revert ZeroDeposit();
        Saver storage saver = savers[msg.sender];
        if (saver.initialized) revert AlreadyInitialized();
        if (targetAmount == 0) revert AmountTargetNotReached(0, 1);

        saver.balance = msg.value;
        saver.mode = Mode.AmountBased;
        saver.targetAmount = targetAmount;
        saver.initialized = true;

        emit GoalInitialized(
            msg.sender,
            saver.mode,
            targetAmount,
            0,
            msg.value
        );
        emit Save(msg.sender, msg.sender, msg.value, saver.balance);
    }

    /// @notice Initialize a time-based goal and deposit the first ETH.
    function initTimeBased(uint256 unlockTime) external payable {
        if (msg.value == 0) revert ZeroDeposit();
        Saver storage saver = savers[msg.sender];
        if (saver.initialized) revert AlreadyInitialized();
        if (unlockTime <= block.timestamp) revert TimeTargetNotReached();

        saver.balance = msg.value;
        saver.mode = Mode.TimeBased;
        saver.unlockTime = unlockTime;
        saver.initialized = true;

        emit GoalInitialized(msg.sender, saver.mode, 0, unlockTime, msg.value);
        emit Save(msg.sender, msg.sender, msg.value, saver.balance);
    }

    // ----------- Deposit -----------
    /// @notice Deposit more to your own vault after initialization.
    function deposit() external payable {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NotInitialized();
        if (msg.value > 0) revert ZeroDeposit();

        saver.balance += msg.value;
        emit Save(msg.sender, msg.sender, msg.value, saver.balance);
    }

    // Get contributions from family & friends
    /// @notice Let family/friends contribute to our vault.
    function depositFor(address user) external payable {
        if (msg.value == 0) revert ZeroDeposit();
        Saver storage saver = savers[user];
        if (!saver.initialized) revert NotInitialized();

        saver.balance += msg.value;
        emit Save(msg.sender, user, msg.value, saver.balance);
    }

    // ----------- CHECK BALANCE -----------

    function balanceOf(address user) public view returns (uint256) {
        return savers[user].balance;
    }

    // withdraw (all or nothing - lol)
    /// @notice withdraw 100% of your balance once your goal is mature/meet
    function withdrawAll() external nonReentrant {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NotInitialized();
        uint256 userBalance = saver.balance;
        if (userBalance == 0) revert ZeroDeposit();

        if (saver.mode == Mode.AmountBased) {
            if (userBalance < saver.targetAmount) {
                revert AmountTargetNotReached(userBalance, saver.targetAmount);
            }
        } else if (block.timestamp < saver.unlockTime) {
            revert TimeTargetNotReached(block.timestamp, saver.unlockTime);
        } else {
            revert WrongMode();
        }

        // withdraw ALL
        saver.balance = 0;
        saver.initialized = false; // reset so user can start a new target if they want
        saver.targetAmount = 0;
        saver.unlockTime = 0;

        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        require(success, "Withdrawal failed");

        emit WithdrawAll(msg.sender, userBalance);
    }

    // ---------- Views ----------
    /// @notice user can view their details including set goals, balance, mode
    function goalOf(
        address user
    )
        external
        view
        returns (
            bool initialized,
            Mode mode,
            uint256 targetAmount,
            uint256 unlockTime,
            uint256 balance
        )
    {
        Saver storage saver = savers[user];
        return (
            saver.initialized,
            saver.mode,
            saver.targetAmount,
            saver.unlockTime,
            saver.balance
        );
    }

    // check if target goal is met.
    function hasMatured(address user) external view returns (bool) {
        Saver storage saver = savers[user];
        if (!saver.initialized) return false;
        if (saver.mode == Mode.AmountBased)
            return saver.balance >= saver.targetAmount;
        if (saver.mode == Mode.TimeBased)
            return block.timestamp >= saver.unlockTime;
        return false;
    }

    // check contract balance
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Direct sends only work for initialized users; otherwise revert to avoid lost funds.
    receive() external payable {
        Saver storage saver = savers[msg.sender];
        if (!saver.initialized) revert NotInitialized();
        if (msg.value == 0) revert ZeroDeposit();

        saver.balance += msg.value;
        emit Save(msg.sender, msg.sender, msg.value, saver.balance);
    }
}
