// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import "../utils/mocks/MockERC404.sol";

contract ERC404Test is Test {
    MockERC404 mockErc404;
    uint96 private constant _WAD = 1e18;

    function setUp() public {
        mockErc404 = new MockERC404();
    }

    function testInit(uint96 initTotalSupply, string memory name, string memory symbol) public {
        mockErc404.init(initTotalSupply, name, symbol, "https://test.com/");
        assertEq(mockErc404.name(), name);
        assertEq(mockErc404.symbol(), symbol);
        assertEq(mockErc404.totalSupply(), initTotalSupply);
        assertEq(mockErc404.balanceOf(address(this)), initTotalSupply);

        if (initTotalSupply > 0) {
            assertEq(mockErc404.getSkipERC721(address(this)), true);
        }
    }

    function testTokenURI(string memory baseUri, uint256 id) public {
        mockErc404.init(888888 * _WAD, "TEST", "TST", baseUri);
        assertEq(mockErc404.tokenURI(id), string(abi.encodePacked(baseUri, id)));
    }

    // TODO test interaction
    function testGetAndSetApprovedForAll(address owner, address operator, bool approved) public {}

    // test mirror
}
