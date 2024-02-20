// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// Utils
import "utils/BaseAccountFactory.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Smart wallet implementation
import {Account} from "./Account.sol";

contract AccountFactory is BaseAccountFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal deactivatedSmartWallets;
    mapping(address => uint256) private previousBalance;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        IEntryPoint _entrypoint
    )
        BaseAccountFactory(
            address(new Account(_entrypoint, address(this))),
            address(_entrypoint)
        )
    {}

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(
        address _account,
        address _admin,
        bytes calldata _data
    ) internal override {
        Account(payable(_account)).initialize(_admin, _data);
    }

    /// @dev will be called when deactivating smart wallet
    receive() external payable {
        address smartWallet = msg.sender;
        require(
            isRegistered(smartWallet),
            "AccountFactory: Account not registered"
        );
        require(
            deactivatedSmartWallets.add(smartWallet),
            "AccountFactory: smart wallet already deactivated"
        );

        previousBalance[smartWallet] = msg.value;
    }

    /// @dev will be called by admin to activate their smart wallet and restore funds
    function activateSmartWallet() external {
        address senderSmartWallet = getAddress(msg.sender, "");

        require(
            deactivatedSmartWallets.contains(senderSmartWallet),
            "AccountFactory: smart wallet of admin not deactivated"
        );

        Account(payable(senderSmartWallet)).activateSmartWallet{
            value: previousBalance[senderSmartWallet]
        }();
    }
}
