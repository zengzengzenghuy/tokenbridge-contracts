pragma solidity 0.4.24;

import "./Upgradeable.sol";
import "./InitializableBridge.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";
import "./Validatable.sol";
import "./Ownable.sol";
import "./Claimable.sol";
import "./VersionableBridge.sol";
import "./DecimalShiftBridge.sol";
import "../interfaces/hashi/IYaho.sol";
import "../interfaces/IHashiManager.sol";

contract BasicBridge is
    InitializableBridge,
    Validatable,
    Ownable,
    Upgradeable,
    Claimable,
    VersionableBridge,
    DecimalShiftBridge
{
    event GasPriceChanged(uint256 gasPrice);
    event RequiredBlockConfirmationChanged(uint256 requiredBlockConfirmations);

    bytes32 internal constant GAS_PRICE = 0x55b3774520b5993024893d303890baa4e84b1244a43c60034d1ced2d3cf2b04b; // keccak256(abi.encodePacked("gasPrice"))
    bytes32 internal constant REQUIRED_BLOCK_CONFIRMATIONS = 0x916daedf6915000ff68ced2f0b6773fe6f2582237f92c3c95bb4d79407230071; // keccak256(abi.encodePacked("requiredBlockConfirmations"))
    bytes32 internal constant HASHI_MANAGER = 0x660d8ed18395a9aa930e304e0bb5e6e51957af1fa215b11db48bfda3dd38d511; // keccak256(abi.encodePacked("hashiManager"))
    bool public constant HASHI_IS_ENABLED = true;
    bool public constant HASHI_IS_MANDATORY = false;

    function isApprovedByHashi(bytes32 hashMsg) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messagesApprovedByHashi", hashMsg))];
    }

    /**
    * @dev Public setter for fallback gas price value. Only bridge owner can call this method.
    * @param _gasPrice new value for the gas price.
    */
    function setGasPrice(uint256 _gasPrice) external onlyOwner {
        _setGasPrice(_gasPrice);
    }

    function gasPrice() external view returns (uint256) {
        return uintStorage[GAS_PRICE];
    }

    function setRequiredBlockConfirmations(uint256 _blockConfirmations) external onlyOwner {
        _setRequiredBlockConfirmations(_blockConfirmations);
    }

    function _setRequiredBlockConfirmations(uint256 _blockConfirmations) internal {
        require(_blockConfirmations > 0);
        uintStorage[REQUIRED_BLOCK_CONFIRMATIONS] = _blockConfirmations;
        emit RequiredBlockConfirmationChanged(_blockConfirmations);
    }

    function requiredBlockConfirmations() external view returns (uint256) {
        return uintStorage[REQUIRED_BLOCK_CONFIRMATIONS];
    }

    function hashiManager() public view returns (IHashiManager) {
        return IHashiManager(addressStorage[HASHI_MANAGER]);
    }

    function setHashiManager(address _hashiManager) external onlyOwner {
        addressStorage[HASHI_MANAGER] = _hashiManager;
    }

    /**
    * @dev Internal function for updating fallback gas price value.
    * @param _gasPrice new value for the gas price, zero gas price is allowed.
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        uintStorage[GAS_PRICE] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }

    function _setHashiApprovalForMessage(bytes32 hashMsg, bool status) internal {
        boolStorage[keccak256(abi.encodePacked("messagesApprovedByHashi", hashMsg))] = status;
    }

    function resendDataWithHashi(bytes data) external {
        require(boolStorage[keccak256(abi.encodePacked("dataSentWithHashi", data))]);
        _dispatchMessageWithHashi(data);
    }

    function _maybeSendDataWithHashi(bytes data) internal {
        if (HASHI_IS_ENABLED) {
            boolStorage[keccak256(abi.encodePacked("dataSentWithHashi", data))] = true;
            _dispatchMessageWithHashi(data);
        }
    }

    function _dispatchMessageWithHashi(bytes data) internal {
        IHashiManager manager = hashiManager();
        IYaho(manager.yaho()).dispatchMessage(
            manager.targetChainId(),
            manager.threshold(),
            manager.targetAddress(),
            data,
            manager.reporters(),
            manager.adapters()
        );
    }

    function _validateHashiMessage(uint256 chainId, uint256 threshold, address sender, address[] adapters) internal {
        IHashiManager manager = hashiManager();
        require(
            HASHI_IS_ENABLED &&
                msg.sender == manager.yaru() &&
                chainId == manager.targetChainId() &&
                sender == manager.targetAddress() &&
                threshold == manager.expectedThreshold() &&
                keccak256(abi.encodePacked(adapters)) == manager.expectedAdaptersHash()
        );
    }
}
