// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {StakingRewards, IERC20} from "../src/StakingRewards.sol";

contract TestStakingReward is Test {
    Token public stakingToken;
    Token public rewardsToken;
    StakingRewards public stakingRewards;

    uint256 public constant DURATION = 604800;
    uint256 public constant REWARD_AMOUNT = 10000e18;
    uint256 public constant STAKING_AMOUNT = 1000e18;
    uint256 public constant MINT_STAKING_TOKEN_AMOUNT = 1000000e18;

    function setUp() public {
        stakingToken = new Token("Staking Token", "STK", MINT_STAKING_TOKEN_AMOUNT);
        rewardsToken = new Token("Rewards Token", "RWD", REWARD_AMOUNT);
        stakingRewards = new StakingRewards(address(stakingToken), address(rewardsToken));
        // send some rewards token to the staking rewards contract
        rewardsToken.transfer(address(stakingRewards), REWARD_AMOUNT);
    }

    function test_setRewards() public {
        // set durations1 week
        stakingRewards.setRewardsDuration(DURATION);
        // check the duration
        assertEq(stakingRewards.duration(), DURATION);
        // start the rewards
        stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
        // check the finish time
        assertEq(stakingRewards.finishAt(), block.timestamp + DURATION);
        // check the reward rate
        uint256 expected_rewardRate = REWARD_AMOUNT / DURATION;
        assertEq(stakingRewards.rewardRate(), expected_rewardRate);

        // stake some tokens
        stakingToken.approve(address(stakingRewards), STAKING_AMOUNT);
        stakingRewards.stake(STAKING_AMOUNT);

        // check the total supply
        assertEq(stakingRewards.totalSupply(), STAKING_AMOUNT);
        // check the balance of the user
        assertEq(stakingRewards.balanceOf(address(this)), STAKING_AMOUNT);
        // check the rewards
        uint256 finishedAt = stakingRewards.finishAt() + 10000;
        vm.warp(finishedAt);

        stakingRewards.getReward();
        console.log("rewards", rewardsToken.balanceOf(address(this)));
        console.log("rewards", stakingRewards.rewards(address(this)));
        assertGt(rewardsToken.balanceOf(address(this)), 0);
        assertEq(stakingRewards.rewards(address(this)), 0);
    }
}
