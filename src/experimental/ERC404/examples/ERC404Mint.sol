// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC404.sol";

contract ERC404Mint is ERC404 {
    string public _name;
    string private _symbol;
    string private _baseURI;
    bool public isLive;

    error NotLive();

    constructor(string memory name_, string memory symbol_, string memory baseUri_) public {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseUri_;

        _initERC404(1000000, msg.sender, address(this));
    }

    function toggleLive() public {
        isLive = !isLive;
    }

    modifier onlyLive() {
        if (!isLive) revert NotLive();
        _;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ""; // TODO
    }

    // TODO: mass mint
    function massMint(address[] calldata addrs, uint256[] calldata amounts) public onlyLive {}

    // emergency
    function withdraw() public {}
}
