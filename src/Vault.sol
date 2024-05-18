// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "./IERC20.sol";

contract Vault {
    IERC20 public immutable stakingToken;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function _mint(address _account, uint256 _amount) internal {
        balanceOf[_account] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _account, uint256 _amount) internal {
        balanceOf[_account] -= _amount;
        totalSupply -= _amount;
    }

    function deposit(uint256 _amount) external {
        /*
        a = amount
        B = balance of token before deposit
        T = total supply
        s = shares to mint

        (T + s) / T = (a + B) / B 

        s = aT / B
        */
        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / stakingToken.balanceOf(address(this));
        }
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 _shares) external {
        /*
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = shares to burn

        (T - s) / T = (B - a) / B 

        a = sB / T
        */

        uint256 amount = (_shares * stakingToken.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        stakingToken.transfer(msg.sender, amount);
    }
}
