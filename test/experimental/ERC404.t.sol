// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import "../utils/mocks/MockERC404.sol";

contract ERC404Test is Test {
    MockERC404 mockErc404;

    function setUp() public {
        mockErc404 = new MockERC404();
        mockErc404.init("Test", "TST", "https://test.com/");
    }

    function testInit() public {
        assertEq(mockErc404.name(), "Test");
        assertEq(mockErc404.symbol(), "TST");
    }
}
