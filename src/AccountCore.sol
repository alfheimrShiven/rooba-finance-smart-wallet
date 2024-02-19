// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "../utils/BaseAccount.sol";

// Utils
import "../utils/AccountCoreStorage.sol";
import "../utils/Initializable.sol";
import "../utils/AccountPermissions.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccountCore is BaseAccount, Initializable, AccountPermissions {
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Errors //
    error NotAdmin(address sender);

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP 4337 factory for this contract.
    address public immutable factory;

    /// @notice EIP 4337 Entrypoint contract.
    IEntryPoint private immutable entrypointContract;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(
        IEntryPoint _entrypoint,
        address _factory
    ) EIP712("Account", "1") {
        _disableInitializers();
        factory = _factory;
        entrypointContract = _entrypoint;
    }

    /// @notice Initializes the smart contract wallet.
    function initialize(
        address _defaultAdmin,
        bytes calldata _data
    ) public virtual initializer {
        // This is passed as data in the `_registerOnFactory()` call in `AccountExtension` / `Account`.
        AccountCoreStorage.data().creationSalt = _generateSalt(
            _defaultAdmin,
            _data
        );
        _setAdmin(_defaultAdmin, true);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the EIP 4337 entrypoint contract.
    function entryPoint() public view virtual override returns (IEntryPoint) {
        address entrypointOverride = AccountCoreStorage
            .data()
            .entrypointOverride;
        if (address(entrypointOverride) != address(0)) {
            return IEntryPoint(entrypointOverride);
        }
        return entrypointContract;
    }

    /* solhint-enable */

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit funds for this account in Entrypoint.
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public {
        _onlyAdmin();
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /// @notice Overrides the Entrypoint contract being used.
    function setEntrypointOverride(
        IEntryPoint _entrypointOverride
    ) public virtual {
        _onlyAdmin();
        AccountCoreStorage.data().entrypointOverride = address(
            _entrypointOverride
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the salt used when deploying an Account.
    function _generateSalt(
        address _admin,
        bytes memory _data
    ) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_admin, _data));
    }

    function decodeExecuteCalldata(
        bytes calldata data
    ) internal pure returns (address _target, uint256 _value) {
        require(data.length >= 4 + 32 + 32, "!Data");

        // Decode the address, which is bytes 4 to 35
        _target = abi.decode(data[4:36], (address));

        // Decode the value, which is bytes 36 to 68
        _value = abi.decode(data[36:68], (uint256));
    }

    function decodeExecuteBatchCalldata(
        bytes calldata data
    )
        internal
        pure
        returns (
            address[] memory _targets,
            uint256[] memory _values,
            bytes[] memory _callData
        )
    {
        require(data.length >= 4 + 32 + 32 + 32, "!Data");

        (_targets, _values, _callData) = abi.decode(
            data[4:],
            (address[], uint256[], bytes[])
        );
    }

    /// @notice Validates the signature of a user operation.
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (bool) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = hash.recover(userOp.signature);

        if (!isAdmin(signer)) {
            revert NotAdmin(signer);
        }

        return true;
    }
}
