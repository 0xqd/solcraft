// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";

import "../../../src/experimental/ERC404/ERC404Mirror.sol";
import "../../utils/mocks/MockERC404.sol";
import {ERC404Handler} from "./ERC404Handler.sol";

contract ERC404InvariantTest is Test {
    address user0 = address(111);
    address user1 = address(222);
    address user2 = address(333);
    address user3 = address(444);
    address user4 = address(555);
    address[5] actors;

    uint256 private constant _WAD = 1e18;

    ERC404Handler erc404Handler;
    ERC404Mirror mirror;
    MockERC404 mockErc404;

    function setUp() public {
        mockErc404 = new MockERC404();
        mirror = new ERC404Mirror(address(this));
        mockErc404.init(0, "TEST", "TST", "uri", address(mirror));
        mockErc404.toggleLive();

        erc404Handler = new ERC404Handler(mockErc404);
        actors = [user0, user1, user2, user3, user4];

        // label all user through looping
        for (uint8 i = 0; i < 5; i++) {
            vm.label(actors[i], string(abi.encodePacked("user", i)));
        }

        targetContract(address(erc404Handler));
    }

    function invariantTotalSupplyReflectionInvalid() external {
        assertLe(
            mirror.totalSupply() * _WAD,
            mockErc404.totalSupply(),
            "ERC721 total supply should be less than or equal to ERC20 total supply"
        );
    }

    function invariantUserReflectionInvalid() external {
        for (uint256 i = 0; i < 5;) {
            assertLe(
                mirror.balanceOf(actors[i]) * _WAD,
                mockErc404.balanceOf(actors[i]),
                "ERC721 balance should be less than or equal to ERC20 balance"
            );

            unchecked {
                i++;
            }
        }
    }

    function invariantERC404totalSupply() external {
        uint256 total = 0;
        for (uint32 i = 0; i < actors.length - 1;) {
            total += mockErc404.balanceOf(actors[i]);

            unchecked {
                i++;
            }
        }

        assertEq(
            total,
            mockErc404.totalSupply(),
            "ERC404 total supply should be equal to sum of all balances"
        );
    }
}
