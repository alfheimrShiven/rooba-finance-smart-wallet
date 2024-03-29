// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "../utils/BaseAccount.sol";

// Extensions
import "../utils/AccountCore.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Utils
import "eip/ERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BaseAccountFactory} from "utils/BaseAccountFactory.sol";

contract Account is AccountCore, ERC1271, ERC721Holder, ERC1155Holder {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Events //
    event SmartWalletDeactivated(address indexed smartWallet, uint256 balance);
    event SmartWalletActivated(address indexed smartWallet, uint256 balance);

    // Errors //
    error NotFactory(address sender);

    bytes32 private constant MSG_TYPEHASH =
        keccak256("AccountMessage(bytes message)");

    bool public deactivated;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(
        IEntryPoint _entrypoint,
        address _factory
    ) AccountCore(_entrypoint, _factory) {
        deactivated = false;
    }

    /// @notice Checks whether the caller is the EntryPoint contract or the admin.
    modifier onlyAdminOrEntrypoint() virtual {
        require(
            msg.sender == address(entryPoint()) || isAdmin(msg.sender),
            "Account: not admin or EntryPoint."
        );
        _;
    }

    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    modifier onlyFactory() {
        if (factory != msg.sender) {
            revert NotFactory(msg.sender);
        }
        _;
    }

    modifier shouldBeActive() {
        if (deactivated) {
            revert("Smart Wallet is deactivated");
        }
        _;
    }

    /// @notice Lets the account receive native tokens.
    receive() external payable shouldBeActive {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice See EIP-1271
    function isValidSignature(
        bytes32 _message,
        bytes memory _signature
    ) public view virtual override returns (bytes4 magicValue) {
        bytes32 messageHash = getMessageHash(abi.encode(_message));
        address signer = messageHash.recover(_signature);

        if (isAdmin(signer)) {
            return MAGICVALUE;
        }
    }

    /**
     * @notice Returns the hash of message that should be signed for EIP1271 verification.
     * @param message Message to be hashed i.e. `keccak256(abi.encode(data))`
     * @return Hashed message
     */
    function getMessageHash(
        bytes memory message
    ) public view returns (bytes32) {
        bytes32 messageHash = keccak256(
            abi.encode(MSG_TYPEHASH, keccak256(message))
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainSeparatorV4(), messageHash)
            );
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a transaction (called directly from an admin, or by entryPoint)
    function execute(
        address _target,
        uint256 _value,
        bytes calldata _calldata
    ) external virtual onlyAdminOrEntrypoint shouldBeActive {
        _registerOnFactory();
        _call(_target, _value, _calldata);
    }

    /// @notice Executes a sequence transaction (called directly from an admin, or by entryPoint)
    function executeBatch(
        address[] calldata _target,
        uint256[] calldata _value,
        bytes[] calldata _calldata
    ) external virtual onlyAdminOrEntrypoint shouldBeActive {
        _registerOnFactory();

        require(
            _target.length == _calldata.length &&
                _target.length == _value.length,
            "Account: wrong array lengths."
        );
        for (uint256 i = 0; i < _target.length; i++) {
            _call(_target[i], _value[i], _calldata[i]);
        }
    }

    /// @dev Deactivates smart wallet
    /// @dev Using a flag `deactivated` design pattern instead of `selfDestruct()` to deactivate the smart wallet, as it's considered a better practice. Ref: https://docs.soliditylang.org/en/v0.8.20/introduction-to-smart-contracts.html#deactivate-and-self-destruct
    /// @notice Deactivates the smart wallet associated with the admin and transfers the tokens to AccountFactory. These funds will be restored on smart wallet activation.
    function deactivateSmartWallet()
        external
        onlyAdminOrEntrypoint
        shouldBeActive
    {
        deactivated = true;

        // tranfer out all native tokens to admin (EOA)
        emit SmartWalletDeactivated(address(this), address(this).balance);
        (bool success, bytes memory data) = payable(factory).call{
            value: address(this).balance
        }("");
        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
    }

    /// @dev Will be called by AccountFactory to reactivate the account and restore funds.
    function activateSmartWallet() external payable onlyFactory {
        deactivated = false;
        emit SmartWalletActivated(address(this), address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Registers the account on the factory if it hasn't been registered yet.
    function _registerOnFactory() internal virtual {
        BaseAccountFactory factoryContract = BaseAccountFactory(factory);
        if (!factoryContract.isRegistered(address(this))) {
            factoryContract.onRegister(AccountCoreStorage.data().creationSalt);
        }
    }

    /// @dev Calls a target contract and reverts if it fails.
    function _call(
        address _target,
        uint256 value,
        bytes memory _calldata
    ) internal virtual returns (bytes memory result) {
        bool success;
        (success, result) = _target.call{value: value}(_calldata);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
