// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Ownable {
    // errors
    error AlreadyInitialized();
    error NewOwnerIsZeroAddress();
    error Unauthorized();

    // events
    // compatible with OZ events
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIG =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    // storage

    /// @dev The owner slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _OWNER_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

    function _initOwner(address newOwner) internal virtual {
        if (_guardInitOwner()) {
            assembly {
                let ownerSlot := _OWNER_SLOT
                if sload(ownerSlot) {
                    mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
                    revert(0x1c, 0x04)
                }

                newOwner := shr(96, shl(96, newOwner)) // clean upper 96 bits
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIG, 0, newOwner)
            }
        } else {
            assembly {
                newOwner := shr(96, shl(96, newOwner)) // clean upper 96 bits
                sstore(_OWNER_SLOT, newOwner)
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIG, 0, newOwner)
            }
        }
    }

    /// @dev overrides to avoid double init
    function _guardInitOwner() internal pure virtual returns (bool) {}

    /// @dev Throws if sender is not the owner
    function _checkOwner() internal view virtual {
        assembly {
            if iszero(eq(caller(), sload(_OWNER_SLOT))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`, push32,) push, mstore
                revert(0x1c, 0x04)
            }
        }
    }

    // public functions
    /// @dev transfers ownership to newOwner
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        // revert if newOwner is zero address
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }

        assembly {
            newOwner := shr(96, shl(96, newOwner)) // clean upper 96 bits
            sstore(_OWNER_SLOT, newOwner)
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIG, 0, newOwner)
        }
    }

    /// @dev returns owner of the contract
    function owner() public view virtual returns (address res) {
        assembly {
            res := sload(_OWNER_SLOT)
        }
    }

    /// @dev marks function to be callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}
