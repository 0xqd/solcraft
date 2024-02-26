// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import "../utils/mocks/MockERC404.sol";
import "../../src/experimental/ERC404/ERC404Mirror.sol";

contract ERC404Test is Test {
    MockERC404 mockErc404;
    ERC404Mirror mirror;

    uint96 private constant _WAD = 1e18;

    address private constant anh = address(111);
    address private constant dung = address(222);
    address private constant thuy = address(333);
    address private constant vu = address(444);

    function setUp() public {
        mockErc404 = new MockERC404();
        mirror = new ERC404Mirror(msg.sender);
    }

    function testInit(uint96 initTotalSupply, string memory name, string memory symbol) public {
        mockErc404.init(initTotalSupply, name, symbol, "https://test.com/", address(mirror));
        assertEq(mockErc404.name(), name);
        assertEq(mockErc404.symbol(), symbol);
        assertEq(mockErc404.totalSupply(), initTotalSupply);
        assertEq(mockErc404.balanceOf(address(this)), initTotalSupply);
        assertEq(mockErc404.mirrorERC721(), address(mirror));
        assertEq(mirror.totalSupply(), 0);

        if (initTotalSupply > 0) {
            assertEq(mockErc404.getSkipERC721(address(this)), true);
        }
    }

    function testTokenURI(string memory baseUri, uint256 id) public {
        mockErc404.init(888888 * _WAD, "TEST", "TST", baseUri, address(mirror));
        assertEq(mockErc404.tokenURI(id), string(abi.encodePacked(baseUri, id)));
    }

    function testMint(uint32 initTotalSupply, uint32 mintAmount) external {
        mockErc404.init(0, "TEST", "TST", "https://test.com/", address(mirror));
        mockErc404.toggleLive();

        if (mintAmount == 0) {
            vm.expectRevert(ERC404.InvalidAmount.selector);
            mockErc404.mint(anh, mintAmount);
            return;
        }

        // overflow cases
        if (uint256(mintAmount) + uint256(initTotalSupply) > (type(uint32).max - 1) * _WAD) {
            vm.expectRevert(ERC404.Overflow.selector);
            mockErc404.mint(anh, mintAmount);
            return;
        }

        mockErc404.mint(anh, mintAmount);
        assertEq(mockErc404.balanceOf(anh), mintAmount);

        // erc721
        uint32 erc721Amt = uint32(mintAmount / _WAD);
        assertEq(mirror.balanceOf(anh), erc721Amt);
    }

    function testTransfer() external {
        uint96 mintAmount = 1e18;

        mockErc404.init(0, "TEST", "TST", "https://test.com/", address(mirror));
        mockErc404.toggleLive();
        mockErc404.mint(anh, mintAmount);

        vm.expectRevert(ERC404.EZeroAddress.selector);
        mockErc404.transfer(address(0), 1); // more than what anh has

        // transfer more than what you have
        vm.expectRevert(ERC404.InvalidAmount.selector);
        vm.prank(anh);
        mockErc404.transfer(dung, mintAmount + 1); // more than what anh has

        // transfer to another account
        vm.startPrank(anh);
        uint96 transferAmount = mintAmount / 2;
        mockErc404.approve(anh, transferAmount);
        mockErc404.transfer(dung, transferAmount);
        vm.stopPrank();

        assertEq(mockErc404.balanceOf(anh), mintAmount - transferAmount);
        assertEq(mockErc404.balanceOf(dung), transferAmount);
        assertEq(mirror.balanceOf(anh), (mintAmount - transferAmount) / _WAD);
        assertEq(mirror.balanceOf(dung), transferAmount / _WAD);

        // // transferFrom
        address thisAddr = address(this);
        vm.startPrank(dung);
        uint32 transferFromAmt = uint32(mockErc404.balanceOf(dung)) / 2;
        mockErc404.approve(thisAddr, transferFromAmt);
        vm.stopPrank();

        mockErc404.transferFrom(dung, thuy, transferFromAmt);

        assertEq(mockErc404.balanceOf(dung), transferAmount - transferFromAmt);
        assertEq(mockErc404.balanceOf(thuy), transferFromAmt);
        assertEq(mirror.balanceOf(dung), (transferAmount - transferFromAmt) / _WAD);
        assertEq(mirror.balanceOf(thuy), transferFromAmt / _WAD);
    }
}
