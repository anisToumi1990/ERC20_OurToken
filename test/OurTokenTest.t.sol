// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;
    uint256 public constant STARTING_BALANCE = 100 ether;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
        vm.startPrank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
        ourToken.transfer(alice, STARTING_BALANCE);
        vm.stopPrank();
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testAllowance() public {
        uint256 allowanceAmount = 100 * 10 ** 18;
        vm.prank(alice);
        ourToken.approve(bob, allowanceAmount);

        assertEq(ourToken.allowance(alice, bob), allowanceAmount);
    }

    function testTransfer() public {
        uint256 transferAmount = 5 ether;

        vm.startPrank(alice);
        ourToken.approve(bob, transferAmount);
        ourToken.transfer(bob, transferAmount);
        vm.stopPrank();

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE + transferAmount);
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE - transferAmount);
    }

    function testTransferFrom() public {
        uint256 transferAmount = 5 ether;

        vm.startPrank(alice);
        ourToken.approve(bob, transferAmount);
        vm.stopPrank();
        vm.prank(bob); //bob is the allowed spender, so we prank bob
        ourToken.transferFrom(alice, bob, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE + transferAmount);
        assertEq(ourToken.balanceOf(alice), STARTING_BALANCE - transferAmount);
    }

    function testCannotTransferMoreThanBalance() public {
        uint256 transferAmount = deployer.INITIAL_SUPPLY() + 1;

        vm.startPrank(alice);
        vm.expectRevert();
        ourToken.transfer(bob, transferAmount);
        vm.stopPrank();
    }

    function testCannotTransferFromWithoutAllowance() public {
        uint256 transferAmount = 50 * 10 ** 18;

        vm.startPrank(bob);
        vm.expectRevert();
        ourToken.transferFrom(alice, bob, transferAmount);
        vm.stopPrank();
    }
}
