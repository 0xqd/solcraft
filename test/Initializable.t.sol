// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import "./utils/TestPlus.sol";

import "./utils/mocks/MockInitializable.sol";

contract InitializableTest is Test, TestPlus {
    event Initialized(uint64 version);

    MockInitializable mockInitializable;

    function setUp() public {
        MockInitializable.Args memory args;
        mockInitializable = new MockInitializable(args);
    }

    function testInitialing() public {
        MockInitializable.Args memory args;
        args.x = 123;
        mockInitializable.initialize(args);
        assert(mockInitializable.x() == args.x);
        _checkVersion(1);
    }

    function _checkVersion(uint64 version) internal {
        assertEq(mockInitializable.version(), version);
        assertFalse(mockInitializable.isInitializing());
    }
}
