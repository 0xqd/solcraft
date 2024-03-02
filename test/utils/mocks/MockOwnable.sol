// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/auth/Ownable.sol";

contract MockOwnable is Ownable {
    bool public flag;

    constructor() payable {
        _initOwner(msg.sender);
    }
}
