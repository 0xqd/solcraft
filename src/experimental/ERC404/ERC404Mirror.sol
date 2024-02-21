// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ERC404Mirror
/// @notice provides an interface interacting with NFT in ERC404
contract ERC404Mirror {
    struct ERC404NFTStorage {
        address baseERC20;
        address deployer;
        address owner;
    }

    /// Link to the ERC404 contract
    function link(address erc404) external {
        ERC404NFTStorage storage $ = _getERC404NFTStorage();
        $.baseERC20 = erc404;
    }

    function _getERC404NFTStorage() internal pure virtual returns (ERC404NFTStorage storage $) {
        assembly {
            // `uint72(bytes9(keccak256("ERC404_MIRROR_STORAGE")))`.
            $.slot := 0xd3606e58ec53da2493
        }
    }
}
