// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
// the difference betn normal and discrete staking is that
// in discrete staking the rewards can be diff for seconds

import {IERC20} from "./IERC20.sol";

contract DiscreteStakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    uint256 private constant MULTIPLIER = 1e18;
    uint256 private rewardIndex;
    mapping(address => uint256) private rewardIndexOf;
    mapping(address => uint256) private earned;

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    function updateRewardIndex(uint256 _reward) external {
        rewardToken.transferFrom(msg.sender, address(this), _reward);
        rewardIndex += (_reward * MULTIPLIER) / totalSupply;
        // this is the reward per token
    }

    function _calculateRewards(address _account) private view returns (uint256) {
        uint256 shares = balanceOf[_account];
        return (shares * (rewardIndex - rewardIndexOf[_account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(address _account) external view returns (uint256) {
        return earned[_account] + _calculateRewards(_account);
    }

    function updateRewards(address _account) external {
        earned[_account] += _calculateRewards(_account);
        rewardIndexOf[_account] = rewardIndex;
    }

    function stake(uint256 _amount) external {
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 _amount) external {
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function claim() external {
        uint256 rewards = earned[msg.sender];
        if (rewards == 0) return;
        earned[msg.sender] = 0;
        rewardToken.transfer(msg.sender, rewards);
    }
}
