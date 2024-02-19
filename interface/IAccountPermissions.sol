// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IAccountPermissions {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an admin is set or removed.
    event AdminUpdated(address indexed signer, bool isAdmin);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the given account is an admin.
    function isAdmin(address signer) external view returns (bool);

    /// @notice Returns all admins of the account.
    function getAllAdmins() external view returns (address[] memory admins);
}
