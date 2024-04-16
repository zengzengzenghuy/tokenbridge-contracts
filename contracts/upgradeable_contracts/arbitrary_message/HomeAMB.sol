pragma solidity 0.4.24;

import "./AsyncInformationProcessor.sol";

contract HomeAMB is AsyncInformationProcessor {
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );

    function emitEventOnMessageRequest(bytes32 messageId, bytes encodedData) internal {
        emit UserRequestForSignature(messageId, encodedData);
    }

    function emitEventOnMessageProcessed(address sender, address executor, bytes32 messageId, bool status) internal {
        emit AffirmationCompleted(sender, executor, messageId, status);
    }

    // selector 88414e32
    function migrateTo_6_2_0() public {
        bytes32 upgradeStorage = 0x88414e324531481ad93973c16b3c225896f52a671f48e02a8d180df7c05108c1; // keccak256(abi.encodePacked('migrateTo_6_2_0()'))
        require(!boolStorage[upgradeStorage]);

        bytes32 sel = keccak256(abi.encodePacked("eth_call(address,bytes)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getBalance(address)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getBlockByNumber(uint256)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getBlockByHash(bytes32)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getStorageAt(address,bytes32)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getTransactionByHash(bytes32)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        sel = keccak256(abi.encodePacked("eth_getTransactionReceipt(bytes32)"));
        boolStorage[keccak256(abi.encodePacked("enableRequestSelector", sel))] = true;
        emit EnabledAsyncRequestSelector(sel, true);

        boolStorage[upgradeStorage] = true;
    }
}
