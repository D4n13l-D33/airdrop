// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakingERC20} from "../src/Staking.sol";
import {GAU} from "../src/airdrop.sol";


contract StakingTest is Test {

    StakingERC20 staking;
    GAU token;
    address user1 = makeAddr("user1");
    

    function setUp() public {
        token = new GAU();
        staking = new StakingERC20(address(token));
        token.mint(address(staking), 1 ether);
    }

    function test_Fuzz(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 1 ether);
        token.mint(user1, amount);
        vm.startPrank(user1);
        token.approve(address(staking), amount);
        staking.deposit(amount);
        staking.openStake(amount);
        vm.warp(block.timestamp + 21 seconds);
        staking.closeStake(1);
        uint256 expectedBalance = amount + ((amount*2)/100);
        assertEq(staking.getUserBalance(user1), expectedBalance);
        staking.withdraw(expectedBalance);
        assertEq(token.balanceOf(user1), expectedBalance);

    }
}