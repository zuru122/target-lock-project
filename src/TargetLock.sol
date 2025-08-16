// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Take in the targeted amount
//  Set the owner
//  function to check if targeted amount is reached
// function for withdrawal

contract TargetLock {
    error TargetAmountNotReached(uint256, uint256 _targetAmount);
    error OnlyOwnerCanWithdraw();

    uint256 public targetAmount;
    address public owner;

    mapping(address => uint) public savings;

    // event
    event Save(uint256 indexed _amount, address _addr);
    event Withdraw(uint256 indexed _amount, address _addr);

    constructor(uint256 _targetAmount) {
        owner = msg.sender;
        targetAmount = _targetAmount;
    }

    function save() public payable {
        require(msg.value > 0, "Must send some ETH");
        savings[msg.sender] += msg.value;
        emit Save(msg.value, msg.sender);
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert OnlyOwnerCanWithdraw();
        }
        _;
    }

    function getBalance(address _user) public view returns (uint256) {
        return savings[_user];
    }

    // withdraw
    function withdraw(uint256 _amount) public onlyOwner {
        uint256 userBalance = savings[msg.sender];

        if (userBalance < targetAmount) {
            revert TargetAmountNotReached(userBalance, targetAmount);
        }

        require(_amount <= userBalance, "Not enough savings");

        savings[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdraw(_amount, msg.sender);
    }

    // Allow contract to receive ETH
    receive() external payable {
        savings[msg.sender] += msg.value;
        emit Save(msg.value, msg.sender);
    }
}
