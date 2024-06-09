// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

// Spec: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3074.md
abstract contract AbstractAuth {
    uint8 constant MAGIC = 0x04;

    /// Returns the digest for authorizer to sign.
    function getDigest(bytes32 commit, uint256 nonce) public view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(MAGIC, bytes32(block.chainid), bytes32(nonce), bytes32(uint256(uint160(address(this)))), commit));
    }

    /// @notice: auth is the EIP-3074 auth precompile function.
    function authSimple(address authority, bytes32 commit, uint8 v, bytes32 r, bytes32 s)
        internal view returns (bool success)
    {
        bytes memory authArgs = abi.encodePacked(yParity(v), r, s, commit);
        assembly {
            success := auth(authority, add(authArgs, 0x20), mload(authArgs))
        }
    }

    /// @notice authCall is the EIP-3074 auth precompile function.
    function authCallSimple(address to, bytes memory data, uint256 value, uint256 gasLimit)
        internal pure returns (bool success)
    {
        assembly {
            success := authCall(gasLimit, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /// @dev Get the yParity from the v for AUTH
    function yParity(uint8 v) private pure returns (uint8 yParity_) {
        assembly {
            switch lt(v, 35)
            case true { yParity_ := eq(v, 28) }
            default { yParity_ := mod(sub(v, 35), 2) }
        }
    }
}