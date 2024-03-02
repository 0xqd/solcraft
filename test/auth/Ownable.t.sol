pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockOwnable} from "../utils/mocks/MockOwnable.sol";

contract OwnableTest is Test {
    MockOwnable mockOwnable;

    function setUp() public {
        mockOwnable = new MockOwnable();
    }
}
