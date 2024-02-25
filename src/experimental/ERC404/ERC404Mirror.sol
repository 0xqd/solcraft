// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC404.sol";

/// @title ERC404Mirror
/// @notice provides an interface interacting with NFT in ERC404
/// Modified from https://github.com/Vectorized/dn404/blob/main/src/DN404Mirror.sol
contract ERC404Mirror {
    error NotLinked();

    struct ERC404NFTStorage {
        address baseERC20;
        address deployer;
        address owner;
    }

    constructor(address deployer) {
        _getERC404NFTStorage().deployer = deployer;
    }

    // ERC721 ops

    /// @dev Returns the token name from the base ERC404 contract.
    function name() public view virtual returns (string memory) {
        return IERC404(baseERC20()).name();
    }

    /// @dev Returns the token symbol from the base ERC404 contract.
    function symbol() public view virtual returns (string memory) {
        return IERC404(baseERC20()).symbol();
    }

    function totalSupply() public view virtual returns (uint256) {
        return IERC404(baseERC20()).totalERC721Supply();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return IERC404(baseERC20()).balanceOfERC721(owner);
    }

    /// Link to the ERC404 contract
    function link(address erc404) external {
        ERC404NFTStorage storage $ = _getERC404NFTStorage();
        $.baseERC20 = erc404;
    }

    function baseERC20() public view returns (address base) {
        base = _getERC404NFTStorage().baseERC20;
        if (base == address(0)) revert NotLinked();
    }

    function _getERC404NFTStorage() internal pure virtual returns (ERC404NFTStorage storage $) {
        assembly {
            // `uint72(bytes9(keccak256("ERC404_MIRROR_STORAGE")))`.
            $.slot := 0xd3606e58ec53da2493
        }
    }
}
