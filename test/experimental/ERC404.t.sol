// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import "../utils/mocks/MockERC404.sol";
import "../../src/experimental/ERC404/ERC404Mirror.sol";

contract ERC404Test is Test {
    MockERC404 mockErc404;
    ERC404Mirror mockErc404Mirror;

    uint96 private constant _WAD = 1e18;

    address private constant anh = address(111);
    address private constant dung = address(222);
    address private constant thuy = address(333);

    function setUp() public {
        mockErc404 = new MockERC404();
        mockErc404Mirror = new ERC404Mirror(msg.sender);
        mockErc404Mirror.link(address(mockErc404));
    }

    function testInit(uint96 initTotalSupply, string memory name, string memory symbol) public {
        mockErc404.init(initTotalSupply, name, symbol, "https://test.com/");
        assertEq(mockErc404.name(), name);
        assertEq(mockErc404.symbol(), symbol);
        assertEq(mockErc404.totalSupply(), initTotalSupply);
        assertEq(mockErc404.balanceOf(address(this)), initTotalSupply);
        assertEq(mockErc404Mirror.totalSupply(), 0);

        if (initTotalSupply > 0) {
            assertEq(mockErc404.getSkipERC721(address(this)), true);
        }
    }

    function testTokenURI(string memory baseUri, uint256 id) public {
        mockErc404.init(888888 * _WAD, "TEST", "TST", baseUri);
        assertEq(mockErc404.tokenURI(id), string(abi.encodePacked(baseUri, id)));
    }

    function testMint(uint32 initTotalSupply, uint32 mintAmount) public {
        mockErc404.init(initTotalSupply, "TEST", "TST", "https://test.com/");
        mockErc404.toggleLive();

        if (mintAmount == 0) {
            vm.expectRevert(ERC404.InvalidAmount.selector);
            mockErc404.mint(anh, mintAmount);
            return;
        }

        // overflow cases
        if (uint256(mintAmount) + uint256(initTotalSupply) > (type(uint32).max - 1) * _WAD) {
            console2.log("checking overflow");
            vm.expectRevert(ERC404.Overflow.selector);
            mockErc404.mint(anh, mintAmount);
            return;
        }

        mockErc404.mint(anh, mintAmount);
        assertEq(mockErc404.balanceOf(anh), mintAmount);

        // erc721
        uint32 tokenAmount = uint32(mintAmount / _WAD);
        assertEq(mockErc404Mirror.balanceOf(anh), tokenAmount);
    }

    // TODO: check overflow for init, mint, _transferRC20, _transferERC721

    // edgecases
    // function testMint()

    // TODO test interaction
    // function testGetAndSetApprovedForAll(address owner, address operator, bool approved) public {}

    // test mirror
}
