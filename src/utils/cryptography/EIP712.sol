// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
///
/// @dev This implementation does not use salts and extensions.
/// If you still need it, please fork and modify.
abstract contract EIP712 {
    /// `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    uint256 private immutable _cacheThis;
    uint256 private immutable _cacheChainId;
    bytes32 private immutable _cacheNameHash;
    bytes32 private immutable _cacheVersionHash;
    bytes32 private immutable _cacheDomainSeparator;

    constructor() {
        _cacheThis = uint256(uint160(address(this)));
        _cacheChainId = block.chainid;

        string memory name;
        string memory version;
        if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
        bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
        bytes32 versionHash =
            _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
        _cacheNameHash = nameHash;
        _cacheVersionHash = versionHash;

        bytes32 domainSeparator;
        if (!_domainNameAndVersionMayChange()) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40) // Load the free memory pointer.
                mstore(m, _DOMAIN_TYPEHASH)
                mstore(add(m, 0x20), nameHash)
                mstore(add(m, 0x40), versionHash)
                mstore(add(m, 0x60), chainid())
                mstore(add(m, 0x80), address())
                domainSeparator := keccak256(m, 0xa0)
            }
        }
        _cacheDomainSeparator = domainSeparator;
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        returns (string memory name, string memory version);

    function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

    /// @dev Returns the fully encoded EIP712 message (digest) for this domain
    /// give `structHash` as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        if (_domainNameAndVersionMayChange()) {
            digest = _buildDomainSeparator();
        } else {
            digest = _cacheDomainSeparator;
            if (_cacheDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    // returns EIP712 domain separator
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        if (_domainNameAndVersionMayChange()) {
            separator = _buildDomainSeparator();
        } else {
            separator = _cacheDomainSeparator;
            if (_cacheDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
        }
    }

    /// EIP5267
    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    function _buildDomainSeparator() private view returns (bytes32 domainSeparator) {
        // We will use `domainSeparator` to store the name hash to save a bit of gas.
        bytes32 versionHash;
        if (_domainNameAndVersionMayChange()) {
            (string memory name, string memory version) = _domainNameAndVersion();
            domainSeparator = keccak256(bytes(name));
            versionHash = keccak256(bytes(version));
        } else {
            domainSeparator = _cacheNameHash;
            versionHash = _cacheVersionHash;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), domainSeparator) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            domainSeparator := keccak256(m, 0xa0)
        }
    }

    function _cacheDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cacheChainId;
        uint256 cachedThis = _cacheThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}
