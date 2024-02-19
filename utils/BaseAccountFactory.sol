// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./BaseAccount.sol";

// Interface
import "../interface/IEntrypoint.sol";

abstract contract BaseAccountFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    address public immutable accountImplementation;
    address public immutable entrypoint;

    EnumerableSet.AddressSet internal allAccounts;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _accountImpl, address _entrypoint) {
        accountImplementation = _accountImpl;
        entrypoint = _entrypoint;
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account for admin.
    function createAccount(
        address _admin,
        bytes calldata _data
    ) external virtual override returns (address) {
        address impl = accountImplementation;
        bytes32 salt = _generateSalt(_admin, _data);
        address account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        if (msg.sender != entrypoint) {
            require(
                allAccounts.add(account),
                "AccountFactory: account already registered"
            );
        }

        _initializeAccount(account, _admin, _data);

        emit AccountCreated(account, _admin);

        return account;
    }

    /// @notice Callback function for an Account to register itself on the factory.
    function onRegister(bytes32 _salt) external {
        address account = msg.sender;
        require(
            _isAccountOfFactory(account, _salt),
            "AccountFactory: not an account."
        );

        require(
            allAccounts.add(account),
            "AccountFactory: account already registered"
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether an account is registered on this factory.
    function isRegistered(address _account) external view returns (bool) {
        return allAccounts.contains(_account);
    }

    /// @notice Returns the total number of accounts.
    function totalAccounts() external view returns (uint256) {
        return allAccounts.length();
    }

    /// @notice Returns all accounts created on the factory.
    function getAllAccounts() external view returns (address[] memory) {
        return allAccounts.values();
    }

    /// @notice Returns the address of an Account that would be deployed with the given admin signer.
    function getAddress(
        address _admin,
        bytes calldata _data
    ) public view virtual returns (address) {
        bytes32 salt = _generateSalt(_admin, _data);
        return Clones.predictDeterministicAddress(accountImplementation, salt);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether the caller is an account deployed by this factory.
    function _isAccountOfFactory(
        address _account,
        bytes32 _salt
    ) internal view virtual returns (bool) {
        address predicted = Clones.predictDeterministicAddress(
            accountImplementation,
            _salt
        );
        return _account == predicted;
    }

    /// @dev Returns the salt used when deploying an Account.
    function _generateSalt(
        address _admin,
        bytes memory _data
    ) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_admin, _data));
    }

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(
        address _account,
        address _admin,
        bytes calldata _data
    ) internal virtual;
}
