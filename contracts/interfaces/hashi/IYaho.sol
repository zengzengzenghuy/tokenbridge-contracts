pragma solidity 0.4.24;

interface IAdapter {
    function getHash(uint256 domain, uint256 id) external view returns (bytes32 hash);
}

interface IReporter {
    function dispatchBlocks(uint256 targetChainId, IAdapter adapter, uint256[] blockNumbers)
        external
        payable
        returns (bytes32);

    function dispatchMessages(uint256 targetChainId, IAdapter adapter, uint256[] messageIds, bytes32[] messageHashes)
        external
        payable
        returns (bytes32);
}

interface IYaho {
    function dispatchMessageToAdapters(
        uint256 targetChainId,
        uint256 threshold,
        address receiver,
        bytes data,
        IReporter[] reporters,
        IAdapter[] adapters
    ) external payable returns (uint256, bytes32[]);
}
