// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// Utils
import "utils/BaseAccountFactory.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

// Smart wallet implementation
import {Account} from "./Account.sol";

contract AccountFactory is BaseAccountFactory {
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
}
