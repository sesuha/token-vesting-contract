// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public token;

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 amountReleased;
        uint256 startTime;
        uint256 cliffTime;
        uint256 releasePeriod;
        uint256 releaseCount;
    }

    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public isVesting;

    event TokensReleased(address beneficiary, uint256 amount);

    // Update: Pass msg.sender to the Ownable constructor to set the owner
    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    // Create a vesting schedule for a beneficiary
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffTime,
        uint256 releasePeriod,
        uint256 releaseCount
    ) external onlyOwner {
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting already exists for this beneficiary");
        require(startTime + cliffTime + releasePeriod * releaseCount > block.timestamp, "Invalid vesting time");
        
        vestingSchedules[beneficiary] = VestingSchedule(
            totalAmount,
            0,
            startTime,
            cliffTime,
            releasePeriod,
            releaseCount
        );
        isVesting[beneficiary] = true;
    }

    // Claim vested tokens
    function releaseTokens() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");

        uint256 vestedAmount = _vestedAmount(schedule);
        uint256 releasableAmount = vestedAmount - schedule.amountReleased;

        require(releasableAmount > 0, "No tokens to release");

        schedule.amountReleased += releasableAmount;
        token.transfer(msg.sender, releasableAmount);

        emit TokensReleased(msg.sender, releasableAmount);
    }

    // Calculate the vested amount based on time
    function _vestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.startTime + schedule.cliffTime) {
            return 0;
        }

        uint256 timeSinceStart = block.timestamp - (schedule.startTime + schedule.cliffTime);
        uint256 periodsPassed = timeSinceStart / schedule.releasePeriod;

        if (periodsPassed >= schedule.releaseCount) {
            return schedule.totalAmount;
        } else {
            return (schedule.totalAmount * periodsPassed) / schedule.releaseCount;
        }
    }

    // Withdraw unallocated tokens (only for the owner)
    function withdrawUnallocatedTokens(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens");
        token.transfer(owner(), amount);
    }
}
