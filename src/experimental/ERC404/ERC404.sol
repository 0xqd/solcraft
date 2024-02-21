// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC404Mirror.sol";

/// @title Experimental ERC404
/// @notice ERC404 is a hybrid implementation of ERC20 and ERC721 that mints
/// and burns NFT based on account's ERC20 token balance.
/// @author rhacker
///
/// @dev This is a rewrite to learn from Vectorized original version https://github.com/Vectorized/dn404/blob/main/src/DN404.sol
abstract contract ERC404 {
    // errors
    error EZeroAddress();
    error EUnitIsZero();
    error InvalidAmount();
    error AlreadyInitialized();

    // event
    uint256 private constant _BITMASK_ADDR =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff; // (1<<160)-1
    uint256 private constant _BITMASK_OWNED_INDEX =
        0xffffffffffffffffffffffff0000000000000000000000000000000000000000; // ((1<<96)-1)<<160

    struct ERC404Storage {
        uint32 nextTokenId; // indicate if this contract has minted or not
        uint32 totalNftSupply;
        uint96 totalSupply;
        // There are multiple ways to store and relieve the nft,
        // the most simple and efficient is just put to array, and pop it like stack. FILO
        uint32[] storedNftIds;
        // ERC20 allowance
        mapping(address => mapping(address => uint96)) allowance;
        // NFT approval
        mapping(uint32 => address) nftApprovals;
        // nftId => packedData (12 bytes: index of of tokenId in ownedNfts, 20 bytes: owner address)
        mapping(uint32 => uint256) nftOwnedData;
        mapping(address => AddressData) addressData;
        /// @dev nftId => packed data
        mapping(uint32 => uint256) ownedData;
    }

    struct AddressData {
        uint88 aux;
        // number of nft token
        uint8 flags; // skipNFT flat is 1
        uint32 nftBalance;
        uint32[] ownedNfts;
        uint96 balance;
    }

    /// Fixed total token suply
    function _initERC404(uint96 initTokenSupply, address initSupplyOwner, address mirror)
        internal
        virtual
    {
        if (mirror = address(0)) revert EZeroAddress();
        if (unit() == 0) revert EUnitIsZero();

        IERC404Mirror(mirror).link(address(this));
        ERC404Storage storage $ = _getERC404Storage();
        if ($.nextTokenId != 0) revert AlreadyInitialized();

        $.nextTokenId = 1;
        if (initTokenSupply != 0) {
            // TODO: check overflow

            $.totalSupply = uint96(initTokenSupply);
            AddressData storage addressData = _addressData(initSupplyOwner);
            addressData.balance = uint96(initTokenSupply);

            // TODO: send log

            // TODO: skip nFT for owner
        }
    }

    function _getERC404Storage() internal pure virtual returns (ERC404Storage storage $) {
        assembly {
            // `uint72(bytes9(keccak256("ERC404_STORAGE")))`.
            $.slot := 0x2e3e1402ee50ecd28c // Truncate to 9 bytes to reduce bytecode size.
        }
    }

    /// erc20 ops
    function name() external pure virtual returns (string memory);
    function symbol() external pure virtual returns (string memory);

    function decimals() external pure virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external pure returns (uint256) {
        return uint256(_getERC404Storage().totalSupply);
    }

    function balanceOf() external pure returns (uint256) {
        return uint256(_addressData(msg.sender).balance);
    }

    /// erc721 ops, it will be called through a mirror
    function ownerOf(uint256 nftId) public view virtual returns (address owner) {
        (, owner) = _getNftOwnedData(nftId);
        if (owner == address(0)) revert EZeroAddress();
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// erc404 properties and operations
    function unit() internal view virtual returns (uint256) {
        return 1e18;
    }

    /// Core functions
    function _mint(address to, uint256 amount) internal virtual {
        if (to == address(0)) revert EZeroAddress();
        if (amount == 0) revert InvalidAmount();

        AddressData storage toAddressData = _addressData(to);
        ERC404Storage storage $ = _getERC404Storage();
        // check overflow
    }

    /// @notice from and to support 0x0
    function _transferERC20WithNFT(address from, address to, uint256 amount)
        internal
        virtual
        returns (bool)
    {
        AddressData storage fromData = _addressData(from);
        AddressData storage toData = _addressData(to);

        bool fromSkipNFT = false;
        bool toSkipNFT = false;

        // transfer erc20 first
        // TODO
        // transferFrom(from, to, amount);

        // check skipNFT on both adresss

        // if both skip nft then do nothing
        if (fromSkipNFT && toSkipNFT) return true;

        // Case 1) `From` doesn't skip NFT, we store NFT for `from`
        if (!fromSkipNFT) {
            AddressData storage newFromData = _addressData(from);
            uint32 tokenToStore = fromData.ownedNfts.length - uint32(newFromData.balance / unit());
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
            uint32 nftToRetrieveOrMint =
                uint32(newFromData.balance / unit()) - newFromData.ownedNfts.length;

            for (uint32 i = 0; i < nftToRetrieveOrMint;) {
                _retrieveOrMintNFT(to);
                unchecked {
                    ++i;
                }
            }
            return true;
        }

        // TODO: testing

        return true;
    }

    function _retrieveOrMintNFT(address to) {
        if (to == address(0)) revert EZeroAddress();

        uint32 amountToRetrieveOrMInt = amount;

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

        _transferERC721(0x0, to, id);
    }

    function _storeNFT(address from) {
        if (from == address(0)) revert EZeroAddress();

        ERC404Storage storage $ = _getERC404Storage();
        uint32 id = _addressData(from).ownedNfts[_addressData(from).ownedNfts.length - 1];

        _transferERC721(from, 0x0, id);
        $.storedNftIds.push(id);
    }

    /// @notice from and to can be 0x0
    /// @dev transfer NFT token with id from one address to another
    ///      if from is 0x0: it's a mint
    ///      if to is 0x0  : it's a store back to bank
    /// @notice The id should be completely not owned by address.
    function _transferERC721(address from, address to, uint32 id) internal virtual {
        ERC404Storage storage $ = _getERC404Storage();

        AddressData storage fromData = _addressData(from);
        AddressData storage toData = _addressData(to);

        // This is not a mint
        // if (from != address(0)) {
        // 	// TODO Update ownedData in storage, update its value to set new Onwer
        // 	// TODO revoke approval for the nft token,
        //     delete _getERC404Storage().nftApprovals[id];

        //     (uint32 oldIdx, address owner) = _nftData(id);

        // }

        // Not a burn
        if (to != address(0)) {
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
        returns ((uint32 idx, address owner))
    {
        uint256 nftData = _getERC404Storage().nftOwnedData[id];

        assembly {
            idx := shr(160, nftData)
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
}
