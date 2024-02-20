// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployAccountFactory} from "script/DeployAccountFactory.s.sol";
import {AccountFactory} from "src/AccountFactory.sol";
import {Account as SmartWallet} from "src/Account.sol";

/// @dev This is a dummy contract to test contract interactions with Smart Account.
contract Number {
    event FundsReceived(uint256 amount);
    uint256 public num;

    function setNum(uint256 _num) public {
        num = _num;
    }

    function doubleNum() public {
        num *= 2;
    }

    function incrementNum() public {
        num += 1;
    }

    receive() external payable {
        emit FundsReceived(msg.value);
    }
}

contract AccountTest is Test {
    event AccountCreated(address indexed smartWallet, address indexed admin);

    AccountFactory public factory;
    address public admin = makeAddr("admin");
    address private smartWalletExpected =
        0xc37B018236d49f24aD31273236a4C167C5BACf52;
    uint256 constant INITIAL_WALLET_BALANCE = 5e18;

    function setUp() external {
        DeployAccountFactory deployer = new DeployAccountFactory();
        factory = deployer.run();
        vm.deal(admin, 10 ether);
    }

    // creating a smart wallet account test
    function testSmartAccountCreated() external {
        vm.expectEmit(false, true, false, true);
        emit AccountCreated(makeAddr("addressUnChecked"), admin);
        address smartWallet = factory.createAccount(admin, "");
        assert(smartWallet != address(0));
    }

    // Transaction using smart wallet test
    function testTransactionThroughSmartWallet() external {
        Number numberContract = new Number();

        vm.startPrank(admin);
        address smartWallet = factory.createAccount(admin, "");

        SmartWallet(payable(smartWallet)).execute(
            address(numberContract),
            0,
            abi.encodeWithSignature("setNum(uint256)", 25)
        );
        vm.stopPrank();

        assertEq(numberContract.num(), 25);
    }

    // Funds transfer to smart wallet
    function testFundTransferToSmartWallet() external {
        vm.startPrank(admin);
        address smartWallet = factory.createAccount(admin, "");
        (bool success, bytes memory data) = payable(smartWallet).call{
            value: INITIAL_WALLET_BALANCE
        }("");

        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
        vm.stopPrank();

        assertEq(smartWallet.balance, INITIAL_WALLET_BALANCE);
    }

    // Funds transfer from smart wallet to other contract
    function testFundTransferFromSmartWallet() external {
        vm.startPrank(admin);
        address smartWallet = factory.createAccount(admin, "");
        (bool success, bytes memory data) = payable(smartWallet).call{
            value: INITIAL_WALLET_BALANCE
        }("");
        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
        vm.stopPrank();
        assertEq(smartWallet.balance, INITIAL_WALLET_BALANCE);

        // Forwarding to Number Contract
        Number numberContract = new Number();
        vm.prank(admin);
        SmartWallet(payable(smartWallet)).execute(
            payable(address(numberContract)),
            INITIAL_WALLET_BALANCE,
            ""
        );

        assertEq(smartWallet.balance, 0);
        assertEq(address(numberContract).balance, INITIAL_WALLET_BALANCE);
    }

    function testDeactivatingSmartWallet() external {
        vm.startPrank(admin);
        address smartWallet = factory.createAccount(admin, "");
        (bool success, bytes memory data) = payable(smartWallet).call{
            value: INITIAL_WALLET_BALANCE
        }("");
        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
        vm.stopPrank();

        assertEq(smartWallet.balance, INITIAL_WALLET_BALANCE);
        assertEq(SmartWallet(payable(smartWallet)).deactivated(), false);

        // lets deactivate
        vm.prank(admin);
        SmartWallet(payable(smartWallet)).deactivateSmartWallet();

        assertEq(SmartWallet(payable(smartWallet)).deactivated(), true);
        assertEq(smartWallet.balance, 0);
    }

    function testReactivatingSmartWallet() external {
        vm.startPrank(admin);
        address smartWallet = factory.createAccount(admin, "");
        (bool success, bytes memory data) = payable(smartWallet).call{
            value: INITIAL_WALLET_BALANCE
        }("");
        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
        vm.stopPrank();

        // Deactivating
        vm.prank(admin);
        SmartWallet(payable(smartWallet)).deactivateSmartWallet();

        // Reactivating
        vm.prank(admin);
        factory.activateSmartWallet();

        assertEq(SmartWallet(payable(smartWallet)).deactivated(), false);
        assertEq(smartWallet.balance, INITIAL_WALLET_BALANCE);
    }
}
