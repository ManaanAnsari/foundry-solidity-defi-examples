// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./IERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier updateReward(address _account) {
        // this will update the rewardPerTokenStored and updatedAt

        rewardPerTokenStored = rewardPerToken();
        updatedAt = min(block.timestamp, finishAt);
        if (_account != address(0)) {
            // this will update the rewards for the account
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        // if 0 address is passed then it will only update the rewardPerTokenStored and updatedAt

        _;
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(block.timestamp > finishAt, "Cannot change rewards duration after rewards have started");
        duration = _duration;
    }

    // when only reward is added we need to only update rewardPerTokenStored thats why we are passing address(0)
    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
        // this function add the reward to the contract
        // and rewardRate is calculated based on the duration (howmany token per second will be distributed to the users)
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remaining = finishAt - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_amount + leftover) / duration;
        }
        require(rewardRate > 0, "Invalid reward amount");
        require(rewardRate * duration <= rewardsToken.balanceOf(address(this)), "Not enough rewards token");
        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        //( 1 sec me kitna reward token * time kitna bacha h) / total supply token = to get 1 supply token ke liye kitna rewardtoken milega

        return rewardPerTokenStored + (rewardRate * (min(block.timestamp, finishAt) - updatedAt) * 1e18 / totalSupply);
    }

    function earned(address _account) public view returns (uint256) {
        return (balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18 + rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
