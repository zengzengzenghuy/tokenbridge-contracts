pragma solidity 0.4.24;

import "./Upgradeable.sol";
import "./InitializableBridge.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";
import "./Validatable.sol";
import "./Ownable.sol";
import "./Claimable.sol";
import "./VersionableBridge.sol";
import "./DecimalShiftBridge.sol";

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

    function hashiAdapters() public view returns (address[]) {
        uint256 nAdapters = uintStorage[keccak256(abi.encodePacked("nHashiAdapters"))];
        address[] memory adapters = new address[](nAdapters);
        for (uint256 i = 0; i < nAdapters; i++)
            adapters[i] = addressStorage[keccak256(abi.encodePacked("hashiAdapters", i))];
        return adapters;
    }

    function setHashiAdapters(address[] adapters) external onlyOwner {
        uint256 nCurrentHashiAdapters = uintStorage[keccak256(abi.encodePacked("nHashiAdapters"))];
        for (uint256 i = 0; i < nCurrentHashiAdapters; i++)
            delete addressStorage[keccak256(abi.encodePacked("hashiAdapters", i))];
        uintStorage[keccak256(abi.encodePacked("nHashiAdapters"))] = adapters.length;
        for (uint256 j = 0; j < adapters.length; j++)
            addressStorage[keccak256(abi.encodePacked("hashiAdapters", j))] = adapters[j];
    }

    function hashiReporters() public view returns (address[]) {
        uint256 nReporters = uintStorage[keccak256(abi.encodePacked("nHashiReporters"))];
        address[] memory reporters = new address[](nReporters);
        for (uint256 i = 0; i < nReporters; i++)
            reporters[i] = addressStorage[keccak256(abi.encodePacked("hashiReporters", i))];
        return reporters;
    }

    function setHashiReporters(address[] reporters) external onlyOwner {
        uint256 nCurrentHashiAdapters = uintStorage[keccak256(abi.encodePacked("nHashiReporters"))];
        for (uint256 i = 0; i < nCurrentHashiAdapters; i++)
            delete addressStorage[keccak256(abi.encodePacked("hashiReporters", i))];
        uintStorage[keccak256(abi.encodePacked("nHashiReporters"))] = reporters.length;
        for (uint256 j = 0; j < reporters.length; j++)
            addressStorage[keccak256(abi.encodePacked("hashiReporters", j))] = reporters[j];
    }

    function yaho() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("yaho"))];
    }

    function setYaho(address yaho_) external onlyOwner {
        addressStorage[keccak256(abi.encodePacked("yaho"))] = yaho_;
    }

    function yaru() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("yaru"))];
    }

    function setYaru(address yaru_) external onlyOwner {
        addressStorage[keccak256(abi.encodePacked("yaru"))] = yaru_;
    }

    function targetAmb() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("targetAmb"))];
    }

    function setTargetAmb(address targetAmb_) external onlyOwner {
        addressStorage[keccak256(abi.encodePacked("targetAmb"))] = targetAmb_;
    }

    function hashiTargetChainId() public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("hashiTargetChainId"))];
    }

    function setHashiTargetChainId(uint256 targetChainId_) external onlyOwner {
        uintStorage[keccak256(abi.encodePacked("hashiTargetChainId"))] = targetChainId_;
    }

    function hashiThreshold() public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("hashiThreshold"))];
    }

    function setHashiThreshold(uint256 threshold) external onlyOwner {
        uintStorage[keccak256(abi.encodePacked("hashiThreshold"))] = threshold;
    }

    /**
    * @dev Internal function for updating fallback gas price value.
    * @param _gasPrice new value for the gas price, zero gas price is allowed.
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        uintStorage[GAS_PRICE] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }
}
