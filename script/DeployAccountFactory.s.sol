// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {AccountFactory} from "src/AccountFactory.sol";
import {IEntryPoint} from "interface/IEntryPoint.sol";

contract DeployAccountFactory is Script {
    address admin = makeAddr("admin");
    address constant EntryPoint =
        payable(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789); // Polygon (Mumbai) Entrypoint is a singleton contract. Will have one instance deployed on each chain.

    function run() external returns (AccountFactory) {
        AccountFactory factory = new AccountFactory(
            admin,
            IEntryPoint(EntryPoint)
        );

        return factory;
    }
}
