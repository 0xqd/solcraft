// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/auth/Ownable.sol";

contract MockOwnable is Ownable {
    bool public flag;

    constructor() payable {
        _initOwner(msg.sender);
    }

    function setFlag(bool _flag) public onlyOwner {
        flag = _flag;
    }

    function tryReinitOwner() public {
        _initOwner(msg.sender);
    }
}

contract MockGuardOwnable is Ownable {
    constructor() payable {
        _initOwner(msg.sender);
    }

    function _guardInitOwner() internal pure override returns (bool) {
        return true;
    }

    function tryReinitOwner() public {
        _initOwner(msg.sender);
    }
}
