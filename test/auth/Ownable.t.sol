pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Ownable} from "../../src/utils/auth/Ownable.sol";
import {MockOwnable, MockGuardOwnable} from "../utils/mocks/MockOwnable.sol";

contract OwnableTest is Test {
    address owner = address(0x01);
    address stranger = address(0x02);

    MockOwnable mockOwnable;
    MockGuardOwnable mockGuardOwnable;

    function setUp() public {
        vm.prank(owner);
        mockOwnable = new MockOwnable();
    }

    function testSanity() public {
        // owner can set flag
        vm.prank(owner);
        mockOwnable.setFlag(true);

        // but stranger cannot
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(stranger);
        mockOwnable.setFlag(false);
    }

    function testInitOwnerGuard() public {
        // doesn't work with guarded set to true
        vm.prank(owner);
        mockGuardOwnable = new MockGuardOwnable();
        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        mockGuardOwnable.tryReinitOwner();

        // work normally without guard setup ( default to false )
        vm.prank(owner);
        mockOwnable.tryReinitOwner();
    }
}
