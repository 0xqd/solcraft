// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";

import "../../../src/experimental/ERC404/ERC404Mirror.sol";
import "../../utils/TestPlus.sol";
import "../../utils/mocks/MockERC404.sol";

contract ERC404Handler is Test, TestPlus {
    address user0 = address(111);
    address user1 = address(222);
    address user2 = address(333);
    address user3 = address(444);
    address user4 = address(555);
    address[5] actors;

    uint256 private constant _WAD = 1e18;

    MockERC404 mockErc404;
    ERC404Mirror mirror;

    constructor(MockERC404 _erc404) {
        mockErc404 = _erc404;
        mirror = ERC404Mirror(mockErc404.mirrorERC721());
        actors = [user0, user1, user2, user3, user4];

        for (uint32 i = 0; i < 5;) {
            vm.prank(actors[i]);
            mockErc404.approve(actors[i], type(uint256).max);

            unchecked {
                i++;
            }
        }
    }

    function approve(uint256 ownerIdxSeed, uint256 spenderIdxSeed, uint256 amount) external {
        address owner = randomActor(ownerIdxSeed);
        address spender = randomActor(spenderIdxSeed);

        if (owner == spender) return;

        vm.prank(owner);
        mockErc404.approve(spender, amount);
    }

    function mint(uint256 idxSeed, uint256 amount) external {
        amount = _hem(amount, 1e18, 100e18);

        address to = randomActor(idxSeed);
        mockErc404.mint(to, amount);
    }

    function transfer(uint256 fromIdxSeed, uint256 toIdxSeed, uint256 amount) external {
        amount = _hem(amount, 1e18, 100e18);
        address from = randomActor(fromIdxSeed);
        address to = randomActor(toIdxSeed);

        vm.prank(from);
        mockErc404.transfer(to, amount);
    }

    // helper
    function randomActor(uint256 seed) internal returns (address) {
        return actors[seed % (actors.length - 1)];
    }
}
