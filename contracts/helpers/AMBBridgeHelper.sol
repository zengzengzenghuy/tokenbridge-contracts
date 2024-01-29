pragma solidity 0.7.6;

interface IHomeBridge {
    function numMessagesSigned(bytes32 _message) external view returns (uint256);

    function isAlreadyProcessed(uint256 _number) external pure returns (bool);

    function signature(bytes32 _hash, uint256 _index) external view returns (bytes memory);
}

contract Helper {
    function unpackSignature(bytes memory _signature) internal pure returns (bytes32, bytes32, uint8) {
        require(_signature.length == 65, "AMBBridgeHelper: signature length must be 65");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := mload(add(_signature, 0x41))
        }
        return (r, s, v);
    }
}

contract AMBBridgeHelper is Helper {
    address payable owner;
    IHomeBridge public AMBcontract;

    constructor(address _homeBridge) {
        owner = msg.sender;
        AMBcontract = IHomeBridge(_homeBridge);
    }

    function getSignatures(bytes calldata _message) external view returns (bytes memory) {
        bytes32 msgHash = keccak256(abi.encodePacked(_message));
        uint256 signed = AMBcontract.numMessagesSigned(msgHash);

        require(AMBcontract.isAlreadyProcessed(signed), "message hasn't been confirmed");

        // recover number of confirmations sent by oracles
        signed = signed & 0x8fffffffffffffffffffffffffffffffffffffffffff;

        require(signed < 0x100, "AMBBridgeHelper: signed must be less  than 0x100");

        bytes memory signatures = new bytes(1 + signed * 65);

        assembly {
            mstore8(add(signatures, 32), signed)
        }

        for (uint256 i = 0; i < signed; i++) {
            bytes memory sig = AMBcontract.signature(msgHash, i);
            (bytes32 r, bytes32 s, uint8 v) = unpackSignature(sig);
            assembly {
                mstore8(add(add(signatures, 33), i), v)
                mstore(add(add(add(signatures, 33), signed), mul(i, 32)), r)
                mstore(add(add(add(signatures, 33), mul(signed, 33)), mul(i, 32)), s)
            }
        }

        return signatures;
    }

    function clean() external {
        require(msg.sender == owner, "not an owner");
        selfdestruct(owner);
    }
}
