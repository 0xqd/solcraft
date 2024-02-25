// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC404 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function balanceOfERC721(address owner) external view virtual returns (uint256);
    function totalERC721Supply() external view virtual returns (uint256);
}
