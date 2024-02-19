// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IAccountPermissions.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library AccountPermissionsStorage {
    /// @custom:storage-location erc7201:account.permissions.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("account.permissions.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ACCOUNT_PERMISSIONS_STORAGE_POSITION =
        0x3181e78fc1b109bc611fd2406150bf06e33faa75f71cba12c3e1fd670f2def00;

    struct Data {
        /// @dev The set of all admins of the wallet.
        EnumerableSet.AddressSet allAdmins;
        /// @dev Map from address => whether the address is an admin.
        mapping(address => bool) isAdmin;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = ACCOUNT_PERMISSIONS_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract AccountPermissions is IAccountPermissions, EIP712 {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    function _onlyAdmin() internal virtual {
        require(isAdmin(msg.sender), "!admin");
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the given account is an admin.
    function isAdmin(address _account) public view virtual returns (bool) {
        return _accountPermissionsStorage().isAdmin[_account];
    }

    /// @notice Returns all admins of the account.
    function getAllAdmins() public view returns (address[] memory) {
        return _accountPermissionsStorage().allAdmins.values();
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Makes the given account an admin.
    function _setAdmin(address _account, bool _isAdmin) internal virtual {
        _accountPermissionsStorage().isAdmin[_account] = _isAdmin;

        if (_isAdmin) {
            _accountPermissionsStorage().allAdmins.add(_account);
        } else {
            _accountPermissionsStorage().allAdmins.remove(_account);
        }

        emit AdminUpdated(_account, _isAdmin);
    }

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(
        bytes memory _encoded,
        bytes calldata _signature
    ) internal view virtual returns (address) {
        return _hashTypedDataV4(keccak256(_encoded)).recover(_signature);
    }

    /// @dev Returns the AccountPermissions storage.
    function _accountPermissionsStorage()
        internal
        pure
        returns (AccountPermissionsStorage.Data storage data)
    {
        data = AccountPermissionsStorage.data();
    }
}
