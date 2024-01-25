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

    function testInitializeReinititalize(uint256) public {
        MockInitializable.Args memory a = _args();

        // TODO: This can be the candidate for prop test
        if (a.recurse) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            if (_random() & 1 == 0) {
                mockInitializable.initialize(a);
            } else {
                mockInitializable.reinitialize(a);
            }
            return;
        }

        if (_random() & 1 == 0) {
            _expectEmitInitialized(1);
            mockInitializable.initialize(a);
            a.version = 1;
        } else {
            _expectEmitInitialized(a.version);
            mockInitializable.reinitialize(a);
        }
        assertEq(mockInitializable.x(), a.x);
        _checkVersion(a.version);

        if (_random() & 1 == 0) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            mockInitializable.initialize(a);
        }
        if (_random() & 1 == 0) {
            vm.expectRevert(Initializable.InvalidInitialization.selector);
            mockInitializable.reinitialize(a);
        }
        if (_random() & 1 == 0) {
            a.version = mockInitializable.version();
            uint64 newVersion = uint64(_random());
            if (newVersion > a.version) {
                a.version = newVersion;
                mockInitializable.reinitialize(a);
                _checkVersion(a.version);
            }
        }
    }

    function _args() internal returns (MockInitializable.Args memory a) {
        a.x = _random();
        a.version = uint64(_bound(_random(), 1, type(uint64).max));
        a.checkOnlyDuringInitializing = _random() & 1 == 0;
        a.recurse = _random() & 1 == 0;
    }

    function _checkVersion(uint64 version) internal {
        assertEq(mockInitializable.version(), version);
        assertFalse(mockInitializable.isInitializing());
    }

    function _expectEmitInitialized(uint64 version) internal {
        vm.expectEmit(true, true, true, true);
        emit Initialized(version);
    }
}
