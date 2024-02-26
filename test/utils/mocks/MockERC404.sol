// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/experimental/ERC404/ERC404.sol";

contract MockERC404 is ERC404 {
    string public _name;
    string private _symbol;
    string private _baseURI;
    bool public isLive;

    error NotLive();

    function init(
        uint96 initSupply,
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        address mirror
    ) public {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseUri_;

        _initERC404(initSupply, msg.sender, mirror);
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
        return string(abi.encodePacked(_baseURI, id));
    }

    function setBaseURI(string memory baseUri) public {
        _baseURI = baseUri;
    }

    // TODO: mass mint
    function massMint(address[] calldata addrs, uint256[] calldata amounts) public onlyLive {}

    function mint(address to, uint256 amount) public onlyLive {
        _mint(to, amount);
    }

    // emergency
    function withdraw() public {}
}
