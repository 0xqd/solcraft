// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import { AbstractAuth } from "./AbstractAuth.sol";

/// @title Gas Sponsor invoker
/// @notice Invoker contract using EIP-3074 to sponsor gas for authorized txs.
contract GasSponsorInvoker is AbstractAuth {
    function sponsorCall(
        address authority,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data,
        uint256 value
    ) external returns (bool success) {
        bytes32 commit = keccak256(abi.encode(to, data));

        // Ensure tx is authorized
        require(authSimple(authority, commit, v, r, s), "Unauthorized");

        // Execute the call
        success = authCallSimple(to, data, value, 0);
        require(success, "Call failed");
    }
}