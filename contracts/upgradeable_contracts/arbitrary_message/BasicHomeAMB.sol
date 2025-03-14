pragma solidity 0.4.24;

import "../../libraries/Message.sol";
import "../../libraries/ArbitraryMessage.sol";
import "./BasicAMB.sol";
import "./MessageDelivery.sol";

contract BasicHomeAMB is BasicAMB, MessageDelivery {
    event SignedForUserRequest(address indexed signer, bytes32 messageHash);
    event SignedForAffirmation(address indexed signer, bytes32 messageHash);

    event CollectedSignatures(
        address authorityResponsibleForRelay,
        bytes32 messageHash,
        uint256 NumberOfCollectedSignatures
    );

    uint256 internal constant SEND_TO_MANUAL_LANE = 0x80;

    function executeAffirmation(bytes message) external onlyValidator {
        bytes32 hashMsg = keccak256(abi.encodePacked(message));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));
        // Duplicated affirmations
        require(!affirmationsSigned(hashSender));
        setAffirmationsSigned(hashSender, true);

        uint256 signed = numAffirmationsSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        // the check above assumes that the case when the value could be overflew will not happen in the addition operation below
        signed = signed + 1;

        setNumAffirmationsSigned(hashMsg, signed);

        emit SignedForAffirmation(msg.sender, hashMsg);

        if (HASHI_IS_ENABLED && HASHI_IS_MANDATORY) {
            require(isApprovedByHashi(hashMsg));
        }

        if (signed >= requiredSignatures()) {
            setNumAffirmationsSigned(hashMsg, markAsProcessed(signed));
            handleMessage(message);
        }
    }

    function onMessage(
        uint256, /*messageId*/
        uint256 chainId,
        address sender,
        uint256 threshold,
        address[] adapters,
        bytes data
    ) external returns (bytes) {
        _validateHashiMessage(chainId, threshold, sender, adapters);
        bytes32 hashMsg = keccak256(abi.encodePacked(data));
        require(!isApprovedByHashi(hashMsg));
        _setHashiApprovalForMessage(hashMsg, true);
    }

    /**
    * @dev Requests message relay to the opposite network, message is sent to the manual lane.
    * @param _contract executor address on the other side.
    * @param _data calldata passed to the executor on the other side.
    * @param _gas gas limit used on the other network for executing a message.
    */
    function requireToConfirmMessage(address _contract, bytes memory _data, uint256 _gas) public returns (bytes32) {
        return _sendMessage(_contract, _data, _gas, SEND_TO_MANUAL_LANE);
    }

    /**
     * Parses given message, processes a call inside it
     * @param _message relayed message
     */
    function handleMessage(bytes _message) internal {
        bytes32 messageId;
        address sender;
        address executor;
        uint32 gasLimit;
        uint8 dataType;
        uint256[2] memory chainIds;
        bytes memory data;

        (messageId, sender, executor, gasLimit, dataType, chainIds, data) = ArbitraryMessage.unpackData(_message);

        require(_isMessageVersionValid(messageId));
        require(_isDestinationChainIdValid(chainIds[1]));
        processMessage(sender, executor, messageId, gasLimit, dataType, chainIds[0], data);
    }

    function submitSignature(bytes signature, bytes message) external onlyValidator {
        // ensure that `signature` is really `message` signed by `msg.sender`
        require(msg.sender == Message.recoverAddressFromSignedMessage(signature, message, true));
        bytes32 hashMsg = keccak256(abi.encodePacked(message));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));

        uint256 signed = numMessagesSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        // the check above assumes that the case when the value could be overflew
        // will not happen in the addition operation below
        signed = signed + 1;
        if (signed > 1) {
            // Duplicated signatures
            require(!messagesSigned(hashSender));
        } else {
            setMessages(hashMsg, message);
        }
        setMessagesSigned(hashSender, true);

        bytes32 signIdx = keccak256(abi.encodePacked(hashMsg, (signed.sub(1))));
        setSignatures(signIdx, signature);

        setNumMessagesSigned(hashMsg, signed);

        emit SignedForUserRequest(msg.sender, hashMsg);

        uint256 reqSigs = requiredSignatures();
        if (signed >= reqSigs) {
            setNumMessagesSigned(hashMsg, markAsProcessed(signed));
            emit CollectedSignatures(msg.sender, hashMsg, reqSigs);
        }
    }

    function isAlreadyProcessed(uint256 _number) public pure returns (bool) {
        return _number & (2**255) == 2**255;
    }

    function numMessagesSigned(bytes32 _message) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))];
    }

    function signature(bytes32 _hash, uint256 _index) public view returns (bytes) {
        bytes32 signIdx = keccak256(abi.encodePacked(_hash, _index));
        return bytesStorage[keccak256(abi.encodePacked("signatures", signIdx))];
    }

    function messagesSigned(bytes32 _message) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messagesSigned", _message))];
    }

    function message(bytes32 _hash) public view returns (bytes) {
        return messages(_hash);
    }

    function affirmationsSigned(bytes32 _hash) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _hash))];
    }

    function numAffirmationsSigned(bytes32 _hash) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _hash))];
    }

    function setMessagesSigned(bytes32 _hash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("messagesSigned", _hash))] = _status;
    }

    function messages(bytes32 _hash) internal view returns (bytes) {
        return bytesStorage[keccak256(abi.encodePacked("messages", _hash))];
    }

    function setSignatures(bytes32 _hash, bytes _signature) internal {
        bytesStorage[keccak256(abi.encodePacked("signatures", _hash))] = _signature;
    }

    function setMessages(bytes32 _hash, bytes _message) internal {
        bytesStorage[keccak256(abi.encodePacked("messages", _hash))] = _message;
    }

    function setNumMessagesSigned(bytes32 _message, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))] = _number;
    }

    function markAsProcessed(uint256 _v) internal pure returns (uint256) {
        return _v | (2**255);
    }

    function setAffirmationsSigned(bytes32 _hash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _hash))] = _status;
    }

    function setNumAffirmationsSigned(bytes32 _hash, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _hash))] = _number;
    }
}
