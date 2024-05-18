// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {DiscreteStakingRewards, IERC20} from "../src/DiscreteStaking.sol";

contract TestDiscreteStakingRewards is Test {
    Token public stakingToken;
    Token public rewardsToken;
    DiscreteStakingRewards public stakingRewards;

    uint256 public constant REWARD_AMOUNT = 10000e18;
    uint256 public constant STAKING_AMOUNT = 1000e18;
    uint256 public constant MINT_STAKING_TOKEN_AMOUNT = 1000000e18;

    function setUp() public {
        stakingToken = new Token("Staking Token", "STK", MINT_STAKING_TOKEN_AMOUNT);
        rewardsToken = new Token("Rewards Token", "RWD", REWARD_AMOUNT);
        stakingRewards = new DiscreteStakingRewards(address(stakingToken), address(rewardsToken));
        // send some rewards token to the staking rewards contract
        rewardsToken.transfer(address(stakingRewards), REWARD_AMOUNT);
    }

    function test_DiscreteRewards() public {
        // stake some tokens
        stakingToken.approve(address(stakingRewards), STAKING_AMOUNT);
        stakingRewards.stake(STAKING_AMOUNT);

        // check the total supply
        assertEq(stakingRewards.totalSupply(), STAKING_AMOUNT);
        // check the balance of the user
        assertEq(stakingRewards.balanceOf(address(this)), STAKING_AMOUNT);

        // update the rewards
        rewardsToken.approve(address(stakingRewards), REWARD_AMOUNT);
        stakingRewards.updateRewardIndex(REWARD_AMOUNT);

        // check the rewards
        uint256 rewards = stakingRewards.calculateRewardsEarned(address(this));
        console.log("rewards", rewards);
        assertEq(rewards, REWARD_AMOUNT);

        // unstake the tokens
        stakingRewards.unstake(STAKING_AMOUNT);
        console.log("total supply", stakingRewards.totalSupply());
        console.log("balance of", stakingRewards.balanceOf(address(this)));
        assertEq(stakingRewards.totalSupply(), 0);
        assertEq(stakingRewards.balanceOf(address(this)), 0);

        // claim the rewards
        stakingRewards.claim();
        console.log("rewards", rewardsToken.balanceOf(address(this)));
    }
}
