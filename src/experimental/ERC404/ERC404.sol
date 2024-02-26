// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/console2.sol";
import "./interfaces/IERC404Mirror.sol";

/// @title Experimental ERC404
/// @notice ERC404 is a hybrid implementation of ERC20 and ERC721 that mints
/// and burns NFT based on account's ERC20 token balance.
/// @author 0xqd (rhacker)
///
/// @dev This is a rewrite to learn from Vectorized original version https://github.com/Vectorized/dn404/blob/main/src/DN404.sol
/// TODO: 1. Support permit2 on ETH, BSC, Arbitrum
abstract contract ERC404 {
    // errors
    error AlreadyInitialized();
    error EUnitIsZero();
    error EZeroAddress();
    error InvalidAmount();
    error Overflow();

    // event
    uint256 private constant _BITMASK_ADDR =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff; // (1<<160)-1
    uint256 private constant _BITMASK_OWNED_INDEX =
        0xffffffffffffffffffffffff0000000000000000000000000000000000000000; // ((1<<96)-1)<<160

    struct ERC404Storage {
        uint32 nextTokenId; // indicate if this contract has minted or not
        uint32 totalNftSupply;
        uint96 totalSupply; // in wei
        // There are multiple ways to store and relieve the nft,
        // the most simple and efficient is just put to array, and pop it like stack. FILO
        uint32[] storedNftIds;
        // address of mirror ERC721
        address mirrorERC721;
        // ERC20 allowance
        mapping(address => mapping(address => uint256)) allowance;
        // NFT approval
        mapping(uint32 => address) nftApprovals;
        // nftId => packedData (12 bytes: index of of tokenId in ownedNfts, 20 bytes: owner address)
        mapping(uint32 => uint256) nftOwnedData;
        mapping(address => AddressData) addressData;
        /// @dev nftId => packed data
        mapping(uint32 => uint256) ownedData;
    }

    // AddressData.flags bit flag
    uint8 internal constant _ADDRESS_DATA_INIT_FLAG = 1 << 0;
    uint8 internal constant _ADDRESS_DATA_SKIP_ERC721_FLAG = 1 << 1;

    struct AddressData {
        uint88 aux; // Aux data for general use case
        uint8 flags; // skipNFT flat is 1
        uint32[] ownedNfts; // TODO: this would break the packed data
        uint96 balance; // total balance in wei
    }

    /// Fixed total token suply
    function _initERC404(uint96 initTokenSupply, address initSupplyOwner, address mirror)
        internal
        virtual
    {
        if (mirror == address(0)) revert EZeroAddress();
        if (unit() == 0) revert EUnitIsZero();

        IERC404Mirror(mirror).link(address(this));
        ERC404Storage storage $ = _getERC404Storage();
        if ($.nextTokenId != 0) revert AlreadyInitialized();

        $.mirrorERC721 = mirror;
        $.nextTokenId = 1;

        if (initTokenSupply != 0) {
            $.totalSupply = initTokenSupply;
            AddressData storage addressData = _addressData(initSupplyOwner);
            addressData.balance = initTokenSupply;

            // TODO: send log
            _setSkipERC721(initSupplyOwner, true);
        }
    }

    /// erc20 ops
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);

    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return uint256(_getERC404Storage().totalSupply);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return uint256(_getERC404Storage().addressData[owner].balance);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return uint256(_getERC404Storage().allowance[owner][spender]);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert EZeroAddress();

        _getERC404Storage().allowance[msg.sender][spender] = amount;
    }

    function transfer(address to, uint256 amount) external virtual returns (bool) {
        if (to == address(0)) revert EZeroAddress();

        _transferERC20WithERC721(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        virtual
        returns (bool)
    {
        if (from == address(0) || to == address(0)) revert EZeroAddress();

        uint256 allowed = _getERC404Storage().allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (amount > allowed) revert InvalidAmount();
            unchecked {
                _getERC404Storage().allowance[from][msg.sender] -= amount;
            }
        }

        _transferERC20WithERC721(from, to, amount);
        return true;
    }

    /// erc721 ops, it will be called through a mirror
    function ownerOf(uint256 nftId) external view virtual returns (address owner) {
        (, owner) = _getNftOwnedData(uint32(nftId));
        if (owner == address(0)) revert EZeroAddress();
    }

    function balanceOfERC721(address owner) external view virtual returns (uint256) {
        return _getERC404Storage().addressData[owner].ownedNfts.length;
    }

    function tokenURI(uint256 id) external view virtual returns (string memory);

    function totalERC721Supply() external view virtual returns (uint256) {
        return uint256(_getERC404Storage().totalNftSupply);
    }

    /// erc404 ops
    function unit() internal view virtual returns (uint256) {
        return 1e18;
    }

    function getSkipERC721(address owner) external view returns (bool) {
        return _getSkipERC721(owner);
    }

    function mirrorERC721() external view returns (address) {
        return _getERC404Storage().mirrorERC721;
    }

    function setSkipERC721(bool state) external {
        _setSkipERC721(msg.sender, state);
    }

    /// Core functions
    function _getERC404Storage() internal pure virtual returns (ERC404Storage storage $) {
        assembly {
            // `uint72(bytes9(keccak256("ERC404_STORAGE")))`.
            $.slot := 0x2e3e1402ee50ecd28c // Truncate to 9 bytes to reduce bytecode size.
        }
    }

    function _mint(address to, uint256 amount) internal virtual {
        if (to == address(0)) revert EZeroAddress();
        if (amount == 0) revert InvalidAmount();

        _transferERC20WithERC721(address(0), to, amount);
    }

    /// @notice from and to support 0x0
    function _transferERC20WithERC721(address from, address to, uint256 amount)
        internal
        virtual
        returns (bool)
    {
        bool fromSkipNFT = _getSkipERC721(from);
        bool toSkipNFT = _getSkipERC721(to);

        _transferERC20(from, to, amount); // m1

        // if both skip nft then do nothing
        if (fromSkipNFT && toSkipNFT) return true;

        // // Case 1) `From` doesn't skip NFT, we store NFT for `from`
        if (!fromSkipNFT) {
            AddressData storage fromData = _addressData(from);
            uint32 tokenToStore;
            unchecked {
                tokenToStore = uint32(fromData.ownedNfts.length) - uint32(fromData.balance / unit());
            }

            for (uint32 i = 0; i < tokenToStore;) {
                _storeNFT(from);
                unchecked {
                    ++i;
                }
            }
        }

        // Case 2) `To` doesn't skip NFT, we retrieve or mint NFT for `to`
        if (!toSkipNFT) {
            AddressData storage newToData = _addressData(to);
            // we can do unchecked, we already check overflow in _transferERC20 m1
            uint32 nftToRetrieveOrMint;
            unchecked {
                nftToRetrieveOrMint =
                    uint32(newToData.balance / unit() - newToData.ownedNfts.length);
            }

            for (uint32 i = 0; i < nftToRetrieveOrMint;) {
                _retrieveOrMintNFT(to);
                unchecked {
                    ++i;
                }
            }
        }

        return true;
    }

    function _retrieveOrMintNFT(address to) internal {
        if (to == address(0)) revert EZeroAddress();

        uint32 id;
        ERC404Storage storage $ = _getERC404Storage();
        if ($.storedNftIds.length != 0) {
            id = $.storedNftIds[$.storedNftIds.length - 1];
            delete $.storedNftIds[$.storedNftIds.length - 1];
        } else {
            $.nextTokenId++;

            // check overflow
            id = $.nextTokenId;
        }

        _transferERC721(address(0), to, id);
    }

    function _storeNFT(address from) internal {
        if (from == address(0)) revert EZeroAddress();

        ERC404Storage storage $ = _getERC404Storage();
        // @dev This can be customized based on implementor usecase.
        uint32 id = _addressData(from).ownedNfts[_addressData(from).ownedNfts.length - 1];

        _transferERC721(from, address(0), id);
        $.storedNftIds.push(id);
    }

    function _transferERC20(address from, address to, uint256 amount) internal virtual {
        ERC404Storage storage $ = _getERC404Storage();

        if (from == address(0)) {
            if (_totalSupplyOverflow($.totalSupply + amount)) {
                revert Overflow();
            }
            $.totalSupply += uint96(amount);
        } else {
            unchecked {
                if ($.addressData[from].balance < amount) {
                    revert InvalidAmount();
                }

                $.addressData[from].balance -= uint96(amount);
            }
        }

        // TODO: faster overflow check
        uint256 newTotalSupply = $.totalSupply + amount;
        if (_totalSupplyOverflow(newTotalSupply)) {
            revert Overflow();
        }

        unchecked {
            $.addressData[to].balance += uint96(amount);
        }

        // TODO: Emit event
    }

    /// @notice from and to can be 0x0
    /// @dev transfer NFT token with id from one address to another
    ///      if from is 0x0: Mint NFT
    ///      if to is 0x0  : Store NFT back to bank
    /// @notice The id should be completely not owned by address.
    function _transferERC721(address from, address to, uint32 id) internal virtual {
        ERC404Storage storage $ = _getERC404Storage();

        // Not a mint
        // Special case where nft receiver might not own any erc20 token
        // Make sure this nft isn't the same with NFT based on erc20 token. Wrong, normally they just use transferFromNFT
        if (from != address(0)) {
            delete $.nftApprovals[id];
            AddressData storage fromData = _addressData(from);
            fromData.ownedNfts.pop();
        }

        // Not a burn
        if (to != address(0)) {
            AddressData storage toData = _addressData(to);
            // 0. Push to ownerNFts
            toData.ownedNfts.push(id);
            // 1. Set owned data
            // TODO: Check overflow
            _setOwnedData(id, uint32(toData.ownedNfts.length - 1), to);
        } else {
            delete $.nftOwnedData[id];
        }

        // TODO: Emit event
    }

    function _addressData(address owner) internal virtual returns (AddressData storage ad) {
        ad = _getERC404Storage().addressData[owner];
        // other stuffs
    }

    function _getNftOwnedData(uint32 id)
        internal
        view
        virtual
        returns (uint32 idx, address owner)
    {
        uint256 nftData = _getERC404Storage().nftOwnedData[id];

        assembly {
            // idx := shr(160, nftData)
            owner := and(nftData, _BITMASK_ADDR)
        }
    }

    function _setOwnedData(uint32 nftId, uint32 idx, address owner) internal virtual {
        ERC404Storage storage $ = _getERC404Storage();
        uint256 data = $.nftOwnedData[nftId];

        assembly {
            // combine the first 12 bytes to index, and last 20 bytes to address
            data := or(shl(160, idx), and(owner, _BITMASK_ADDR))
        }
        $.nftOwnedData[nftId] = data;
    }

    function _setSkipERC721(address owner, bool state) internal virtual {
        AddressData storage d = _addressData(owner);
        if ((d.flags & _ADDRESS_DATA_SKIP_ERC721_FLAG != 0) != state) {
            d.flags ^= _ADDRESS_DATA_SKIP_ERC721_FLAG;
        }
        // TODO: Emit event
    }

    function _getSkipERC721(address owner) internal view virtual returns (bool) {
        AddressData storage d = _getERC404Storage().addressData[owner];
        return d.flags & _ADDRESS_DATA_SKIP_ERC721_FLAG != 0;
    }

    function _toUInt(bool b) internal pure virtual returns (uint256 res) {
        assembly {
            res := iszero(iszero(b))
        }
    }

    function _totalSupplyOverflow(uint256 totalSupply) internal view returns (bool) {
        unchecked {
            return _toUInt(totalSupply > type(uint96).max)
                | _toUInt(totalSupply / unit() > type(uint32).max - 1) != 0;
        }
    }
}
