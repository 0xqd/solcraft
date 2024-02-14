// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../../src/utils/cryptography/EIP712.sol";

/// @dev Mock contract for EIP-712 typed structured data hashing and signing.
/// Its purpose is to test, DO NOT USE in production.
contract MockEIP712 is EIP712 {
    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Solcraft";
        version = "0.1.0";
    }

    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }
}
