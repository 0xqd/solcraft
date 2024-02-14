// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Experimental: This only work in Cancun upgrade when it's deployed on mainnet.
// Cancun introduces 2 new opcodes tload, tstore which we can use in place of sstore and sload to reduce gas fee.
// https://eips.ethereum.org/EIPS/eip-1153
abstract contract ReentrancyGuard {
    error Reentrancy();

    /// @dev Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.
    /// 9 bytes is large enough to avoid collisions with lower slots,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    modifier nonReentrant() virtual {
        assembly {
            if eq(tload(_REENTRANCY_GUARD_SLOT), 2) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
            tstore(_REENTRANCY_GUARD_SLOT, 2)
        }
        _;

        assembly {
            tstore(_REENTRANCY_GUARD_SLOT, 1)
        }
    }
}
