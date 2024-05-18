// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "./../src/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vault} from "../src/Vault.sol";

contract TestVault is Test {
    Token public stakingToken;
    Vault public vault;

    uint256 public constant MINT_STAKING_TOKEN_AMOUNT = 1000000e18;

    function setUp() public {
        stakingToken = new Token("Staking Token", "STK", MINT_STAKING_TOKEN_AMOUNT);
        vault = new Vault(address(stakingToken));
    }

    function test_deposit() public {
        uint256 amount = 1000e18;
        stakingToken.approve(address(vault), amount);
        vault.deposit(amount);

        assertEq(vault.totalSupply(), amount);
        assertEq(vault.balanceOf(address(this)), amount);
        console.log("balance of", vault.balanceOf(address(this)));
        console.log("total supply", vault.totalSupply());
    }

    function test_withdraw() public {
        uint256 amount = 1000e18;
        stakingToken.approve(address(vault), amount);
        vault.deposit(amount);

        assertEq(vault.totalSupply(), amount);
        assertEq(vault.balanceOf(address(this)), amount);
        stakingToken.transfer(address(vault), 1000e18);

        vault.withdraw(vault.balanceOf(address(this)));
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.balanceOf(address(this)), 0);
    }
}
